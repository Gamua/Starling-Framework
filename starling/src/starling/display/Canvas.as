// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2015 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.display
{
    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.VertexBuffer3D;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;

    import starling.core.Painter;
    import starling.core.RenderState;
    import starling.core.Starling;
    import starling.errors.MissingContextError;
    import starling.events.Event;
    import starling.geom.Polygon;
    import starling.rendering.Program;
    import starling.utils.IndexData;
    import starling.utils.VertexData;

    /** A display object supporting basic vector drawing functionality. In its current state,
     *  the main use of this class is to provide a range of forms that can be used as masks.
     */
    public class Canvas extends DisplayObject
    {
        private static const PROGRAM_NAME:String = "Canvas";

        private var mSyncRequired:Boolean;
        private var mPolygons:Vector.<Polygon>;

        private var mVertexData:VertexData;
        private var mVertexBuffer:VertexBuffer3D;
        private var mIndexData:IndexData;
        private var mIndexBuffer:IndexBuffer3D;
        private var mProgram:Program;

        private var mFillColor:uint;
        private var mFillAlpha:Number;

        // helper objects (to avoid temporary objects)
        private static var sHelperMatrix:Matrix = new Matrix();
        private static var sRenderAlpha:Vector.<Number> = new <Number>[1.0, 1.0, 1.0, 1.0];

        /** Creates a new (empty) Canvas. Call one or more of the 'draw' methods to add content. */
        public function Canvas()
        {
            mPolygons   = new <Polygon>[];
            mVertexData = new VertexData("position(float2), color(bytes4)");
            mIndexData  = new IndexData();
            mSyncRequired = false;

            mFillColor = 0xffffff;
            mFillAlpha = 1.0;

            registerProgram();

            // handle lost context
            Starling.current.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
        }

        private function onContextCreated(event:Object):void
        {
            syncBuffers();
        }

        /** @inheritDoc */
        public override function dispose():void
        {
            destroyBuffers();
            super.dispose();
        }

        /** Draws a circle. */
        public function drawCircle(x:Number, y:Number, radius:Number):void
        {
            appendPolygon(Polygon.createCircle(x, y, radius));
        }

        /** Draws an ellipse. */
        public function drawEllipse(x:Number, y:Number, width:Number, height:Number):void
        {
            var radiusX:Number = width  / 2.0;
            var radiusY:Number = height / 2.0;

            appendPolygon(Polygon.createEllipse(x + radiusX, y + radiusY, radiusX, radiusY));
        }

        /** Draws a rectangle. */
        public function drawRectangle(x:Number, y:Number, width:Number, height:Number):void
        {
            appendPolygon(Polygon.createRectangle(x, y, width, height));
        }

        /** Draws an arbitrary polygon. */
        public function drawPolygon(polygon:Polygon):void
        {
            appendPolygon(polygon);
        }

        /** Specifies a simple one-color fill that subsequent calls to drawing methods
         *  (such as <code>drawCircle()</code>) will use. */
        public function beginFill(color:uint=0xffffff, alpha:Number=1.0):void
        {
            mFillColor = color;
            mFillAlpha = alpha;
        }

        /** Resets the color to 'white' and alpha to '1'. */
        public function endFill():void
        {
            mFillColor = 0xffffff;
            mFillAlpha = 1.0;
        }

        /** Removes all existing vertices. */
        public function clear():void
        {
            mIndexData.clear();
            mVertexData.clear();
            mPolygons.length = 0;
            destroyBuffers();
        }

        /** @inheritDoc */
        public override function render(painter:Painter):void
        {
            if (mIndexData.numIndices == 0) return;
            if (mSyncRequired) syncBuffers();

            var state:RenderState = painter.state;
            var context:Context3D = Starling.context;
            if (context == null) throw new MissingContextError();

            sRenderAlpha[0] = sRenderAlpha[1] = sRenderAlpha[2] = 1.0;
            sRenderAlpha[3] = state.alpha;

            painter.finishQuadBatch();
            painter.drawCount += 1;
            painter.prepareToDraw(false);

            mProgram.activate(context);
            mVertexData.setVertexBufferAttribute(mVertexBuffer, 0, "position");
            mVertexData.setVertexBufferAttribute(mVertexBuffer, 1, "color");

            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, state.mvpMatrix3D, true);
            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, sRenderAlpha, 1);

            context.drawTriangles(mIndexBuffer, 0, mIndexData.numTriangles);

            context.setVertexBufferAt(0, null);
            context.setVertexBufferAt(1, null);
        }

        /** @inheritDoc */
        public override function getBounds(targetSpace:DisplayObject, out:Rectangle=null):Rectangle
        {
            if (out == null) out = new Rectangle();

            var transformationMatrix:Matrix = targetSpace == this ?
                null : getTransformationMatrix(targetSpace, sHelperMatrix);

            return mVertexData.getBounds("position", transformationMatrix, 0, -1, out);
        }

        /** @inheritDoc */
        public override function hitTest(localPoint:Point, forTouch:Boolean=false):DisplayObject
        {
            if (forTouch && (!visible || !touchable)) return null;
            if (!hitTestMask(localPoint)) return null;

            for (var i:int = 0, len:int = mPolygons.length; i < len; ++i)
                if (mPolygons[i].containsPoint(localPoint)) return this;

            return null;
        }

        private function appendPolygon(polygon:Polygon):void
        {
            var oldNumVertices:int = mVertexData.numVertices;

            polygon.triangulate(mIndexData, oldNumVertices);
            polygon.copyToVertexData(mVertexData, oldNumVertices);

            applyFillColor(oldNumVertices, polygon.numVertices);

            mPolygons[mPolygons.length] = polygon;
            mSyncRequired = true;
        }

        private function registerProgram():void
        {
            var painter:Painter = Starling.painter;
            mProgram = painter.getProgram(PROGRAM_NAME);

            if (mProgram == null)
            {
                var vertexShader:String =
                    "m44 op, va0, vc0 \n" + // 4x4 matrix transform to output space
                    "mul v0, va1, vc4 \n";  // multiply color with alpha, pass it to fragment shader

                var fragmentShader:String =
                    "mov oc, v0";           // just forward incoming color

                mProgram = Program.fromSource(vertexShader, fragmentShader);
                painter.registerProgram(PROGRAM_NAME, mProgram);
            }
        }

        private function applyFillColor(vertexIndex:int, numVertices:int):void
        {
            var endIndex:int = vertexIndex + numVertices;
            for (var i:int=vertexIndex; i<endIndex; ++i)
                mVertexData.setColorAndAlpha(i, "color", mFillColor, mFillAlpha);
        }

        private function syncBuffers():void
        {
            destroyBuffers();

            mIndexData.trim();
            mVertexData.trim();
            mIndexBuffer  = mIndexData.createIndexBuffer(true);
            mVertexBuffer = mVertexData.createVertexBuffer(true);
            mSyncRequired = false;
        }

        private function destroyBuffers():void
        {
            if (mVertexBuffer) mVertexBuffer.dispose();
            if (mIndexBuffer)  mIndexBuffer.dispose();

            mVertexBuffer = null;
            mIndexBuffer  = null;
            mSyncRequired = true;
        }
    }
}
