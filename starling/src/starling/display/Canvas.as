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
    import flash.geom.Point;

    import starling.geom.Polygon;
    import starling.rendering.IndexData;
    import starling.rendering.VertexData;

    /** A display object supporting basic vector drawing functionality. In its current state,
     *  the main use of this class is to provide a range of forms that can be used as masks.
     */
    public class Canvas extends DisplayObjectContainer
    {
        private var mPolygons:Vector.<Polygon>;
        private var mFillColor:uint;
        private var mFillAlpha:Number;

        /** Creates a new (empty) Canvas. Call one or more of the 'draw' methods to add content. */
        public function Canvas()
        {
            mPolygons  = new <Polygon>[];
            mFillColor = 0xffffff;
            mFillAlpha = 1.0;
            touchGroup = true;
        }

        /** @inheritDoc */
        public override function dispose():void
        {
            mPolygons.length = 0;
            super.dispose();
        }

        /** @inheritDoc */
        public override function hitTest(localPoint:Point, forTouch:Boolean=false):DisplayObject
        {
            if (forTouch && (!visible || !touchable)) return null;
            if (!hitTestMask(localPoint)) return null;

            // we could also use the standard hit test implementation, but the polygon class can
            // do that much more efficiently (it contains custom implementations for circles, etc).

            for (var i:int = 0, len:int = mPolygons.length; i < len; ++i)
                if (mPolygons[i].containsPoint(localPoint)) return this;

            return null;
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
            removeChildren(0, -1, true);
            mPolygons.length = 0;
        }

        private function appendPolygon(polygon:Polygon):void
        {
            var numVertices:int = polygon.numVertices;
            var vertexFormat:String = "position(float2), color(bytes4)";
            var vertexData:VertexData = new VertexData(vertexFormat, numVertices);
            var indexData:IndexData = new IndexData(polygon.numTriangles * 3);

            polygon.triangulate(indexData);
            polygon.copyToVertexData(vertexData);

            for (var i:int=0; i<numVertices; ++i)
                vertexData.setColorAndAlpha(i, "color", mFillColor, mFillAlpha);

            addChild(new Mesh(vertexData, indexData));
            mPolygons[mPolygons.length] = polygon;
        }
    }
}
