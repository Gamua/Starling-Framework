// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.display
{
    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DVertexBufferFormat;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.VertexBuffer3D;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;

    import starling.core.RenderSupport;
    import starling.core.Starling;
    import starling.errors.MissingContextError;
    import starling.events.Event;
    import starling.geom.Polygon;
    import starling.utils.VertexData;

    /** A display object supporting basic vector drawing functionality. In its current state,
     *  the main use of this class is to provide a range of forms that can be used as masks.
     */
    public class Canvas extends DisplayObject
    {
        private static const PROGRAM_NAME:String = "Shape";

        private var mSyncRequired:Boolean;
        private var mPolygons:Vector.<Polygon>;

        private var mVertexData:VertexData;
        private var mVertexBuffer:VertexBuffer3D;
        private var mIndexData:Vector.<uint>;
        private var mIndexBuffer:IndexBuffer3D;

        private var mFillColor:uint;
        private var mFillAlpha:Number;

        // helper objects (to avoid temporary objects)
        private static var sHelperMatrix:Matrix = new Matrix();
        private static var sRenderAlpha:Vector.<Number> = new <Number>[1.0, 1.0, 1.0, 1.0];

        /** Creates a new (empty) Canvas. Call one or more of the 'draw' methods to add content. */
        public function Canvas()
        {
            mPolygons   = new <Polygon>[];
            mVertexData = new VertexData(0);
            mIndexData  = new <uint>[];
            mSyncRequired = false;

            mFillColor = 0xffffff;
            mFillAlpha = 1.0;

            registerPrograms();

            // handle lost context
            Starling.current.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
        }

        private function onContextCreated(event:Object):void
        {
            registerPrograms();
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
            mVertexData.numVertices = 0;
            mIndexData.length = 0;
            mPolygons.length = 0;
            destroyBuffers();
        }

        /** @inheritDoc */
        public override function render(support:RenderSupport, parentAlpha:Number):void
        {
            if (mIndexData.length == 0) return;
            if (mSyncRequired) syncBuffers();

            support.finishQuadBatch();
            support.raiseDrawCount();

            sRenderAlpha[0] = sRenderAlpha[1] = sRenderAlpha[2] = 1.0;
            sRenderAlpha[3] = parentAlpha * this.alpha;

            var context:Context3D = Starling.context;
            if (context == null) throw new MissingContextError();

            // apply the current blend mode
            support.applyBlendMode(false);

            context.setProgram(Starling.current.getProgram(PROGRAM_NAME));
            context.setVertexBufferAt(0, mVertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
            context.setVertexBufferAt(1, mVertexBuffer, VertexData.COLOR_OFFSET, Context3DVertexBufferFormat.FLOAT_4);
            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, support.mvpMatrix3D, true);
            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, sRenderAlpha, 1);

            context.drawTriangles(mIndexBuffer, 0, mIndexData.length / 3);

            context.setVertexBufferAt(0, null);
            context.setVertexBufferAt(1, null);
        }

        /** @inheritDoc */
        public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
        {
            if (resultRect == null) resultRect = new Rectangle();

            var transformationMatrix:Matrix = targetSpace == this ?
                null : getTransformationMatrix(targetSpace, sHelperMatrix);

            return mVertexData.getBounds(transformationMatrix, 0, -1, resultRect);
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
            var oldNumIndices:int = mIndexData.length;

            polygon.triangulate(mIndexData);
            polygon.copyToVertexData(mVertexData, oldNumVertices);

            var newNumIndices:int = mIndexData.length;

            // triangulation was done with vertex-indices of polygon only; now add correct offset.
            for (var i:int=oldNumIndices; i<newNumIndices; ++i)
                mIndexData[i] += oldNumVertices;

            applyFillColor(oldNumVertices, polygon.numVertices);

            mPolygons[mPolygons.length] = polygon;
            mSyncRequired = true;
        }

        private static function registerPrograms():void
        {
            var target:Starling = Starling.current;
            if (target.hasProgram(PROGRAM_NAME)) return; // already registered

            var vertexShader:String =
                    "m44 op, va0, vc0 \n" + // 4x4 matrix transform to output space
                    "mul v0, va1, vc4 \n";  // multiply color with alpha, pass it to fragment shader

            var fragmentShader:String =
                    "mov oc, v0";           // just forward incoming color

            target.registerProgramFromSource(PROGRAM_NAME, vertexShader, fragmentShader);
        }

        private function applyFillColor(vertexIndex:int, numVertices:int):void
        {
            var endIndex:int = vertexIndex + numVertices;
            for (var i:int=vertexIndex; i<endIndex; ++i)
                mVertexData.setColorAndAlpha(i, mFillColor, mFillAlpha);
        }

        private function syncBuffers():void
        {
            destroyBuffers();

            var context:Context3D = Starling.context;
            if (context == null) throw new MissingContextError();

            var numVertices:Number = mVertexData.numVertices;
            var numIndices:Number  = mIndexData.length;

            mVertexBuffer = context.createVertexBuffer(numVertices, VertexData.ELEMENTS_PER_VERTEX);
            mVertexBuffer.uploadFromVector(mVertexData.rawData, 0, numVertices);

            mIndexBuffer = context.createIndexBuffer(numIndices);
            mIndexBuffer.uploadFromVector(mIndexData, 0, numIndices);

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
