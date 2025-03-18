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
    import flash.geom.Point;

    import starling.geom.Polygon;
    import starling.rendering.IndexData;
    import starling.rendering.VertexData;

    /** A display object supporting basic vector drawing functionality. In its current state,
     *  the main use of this class is to provide a range of forms that can be used as masks.
     */
    public class Canvas extends DisplayObjectContainer
    {
        private var _polygons:Vector.<Polygon>;
        private var _fillColor:uint;
        private var _fillAlpha:Number;
        private var _paths:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>(0);


        /** Creates a new (empty) Canvas. Call one or more of the 'draw' methods to add content. */
        public function Canvas()
        {
            _polygons  = new <Polygon>[];
            _fillColor = 0xffffff;
            _fillAlpha = 1.0;
            touchGroup = true;
        }

        /** @inheritDoc */
        public override function dispose():void
        {
            _polygons.length = 0;
            super.dispose();
        }

        /** @inheritDoc */
        public override function hitTest(localPoint:Point):DisplayObject
        {
            if (!visible || !touchable || !hitTestMask(localPoint)) return null;

            // we could also use the standard hit test implementation, but the polygon class can
            // do that much more efficiently (it contains custom implementations for circles, etc).

            for (var i:int = 0, len:int = _polygons.length; i < len; ++i)
                if (_polygons[i].containsPoint(localPoint)) return this;

            return null;
        }

        /** Draws a circle.
         *
         * @param x         x-coordinate of center point
         * @param y         y-coordinate of center point
         * @param radius    radius of circle
         * @param numSides  the number of lines used to draw the circle.
         *                  If you don't pass anything, Starling will pick a reasonable value.
         */
        public function drawCircle(x:Number, y:Number, radius:Number, numSides:int = -1):void
        {
            appendPolygon(Polygon.createCircle(x, y, radius, numSides));
        }

        /** Draws an ellipse.
         *
         * @param x         x-coordinate of bounding box
         * @param y         y-coordinate of bounding box
         * @param width     width of the ellipse
         * @param height    height of the ellipse
         * @param numSides  the number of lines used to draw the ellipse.
         *                  If you don't pass anything, Starling will pick a reasonable value.
         */
        public function drawEllipse(x:Number, y:Number, width:Number, height:Number, numSides:int = -1):void
        {
            var radiusX:Number = width  / 2.0;
            var radiusY:Number = height / 2.0;

            appendPolygon(Polygon.createEllipse(x + radiusX, y + radiusY, radiusX, radiusY, numSides));
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
            _fillColor = color;
            _fillAlpha = alpha;
        }

        /** Resets the color to 'white' and alpha to '1'. */
        public function endFill():void
        {
            _fillColor = 0xffffff;
            _fillAlpha = 1.0;
        }

        public function moveTo(x:Number, y:Number):void
        {
            // TODO: Check if previous path is open and force close it if so
            const curPath:Vector.<Number> = new Vector.<Number>();
            curPath.push(x);
            curPath.push(y);
            _paths.push(curPath);
        }

        public function lineTo(x:Number, y:Number):void
        {
            if(_paths[_paths.length - 1].length == 0)
            {
                curPath.push(0);
                curPath.push(0);
            }
            const curPath:Vector.<Number> = _paths[_paths.length - 1];
            curPath.push(x);
            curPath.push(y);
            checkIfClosed();
        }

        public function curveTo(controlX:Number, controlY:Number, anchorX:Number, anchorY:Number):void
        {
            if(_paths[_paths.length - 1].length == 0)
            {
                curPath.push(0);
                curPath.push(0);
            }
            const curPath:Vector.<Number> = _paths[_paths.length - 1];
            const lastX:Number = curPath[curPath.length - 2];
            const lastY:Number = curPath[curPath.length - 1];
            tesselateCurve(lastX, lastY, controlX, controlY, anchorX, anchorY, curPath);
            checkIfClosed();
        }
        
        /**   Func to tesselate a quadratic Curve using recursion, used in curveTo 
         *    Function converted to AS3 from AwayJS
         *    https://github.com/awayjs/graphics/blob/19c9c9912d0254934ba54c9b7049d1b898bf97f2/lib/draw/GraphicsFactoryHelper.ts#L376-L468
         */
        private static function tesselateCurve(startx:Number, starty:Number, cx:Number, cy:Number, endx:Number, 
                                              endy:Number, array_out:Vector.<Number>, iterationCnt:Number = 0):void
        {
            const RADIANS_TO_DEGREES:Number = 180 / Math.PI;
            const maxIterations:Number = 6;
            const minAngle:Number = 1;
            const minLengthSqr:Number = 1;

            // subdivide the curve
            const c1x:Number = (startx + cx) * 0.5; // new controlpoint 1
            const c1y:Number = (starty + cy) * 0.5;
            const c2x:Number = (cx + endx) * 0.5; // new controlpoint 2
            const c2y:Number = (cy + endy) * 0.5;
            const ax:Number = (c1x + c2x) * 0.5; // new middlepoint 1
            const ay:Number = (c1y + c2y) * 0.5;

            // stop tesselation on maxIteration level. Set it to 0 for no tesselation at all.
            if (iterationCnt >= maxIterations)
            {
                array_out.push(ax, ay, endx, endy);
                return;
            }

            // calculate length of segment
            // this does not include the crtl-point position
            const diff_x:Number = endx - startx;
            const diff_y:Number = endy - starty;
            const lenSq:Number = diff_x * diff_x + diff_y * diff_y;

            // stop subdividing if the angle or the length is to small
            if (lenSq < minLengthSqr)
            {
                array_out.push(endx, endy);
                return;
            }

            // calculate angle between segments
            const angle_1:Number = Math.atan2(cy - starty, cx - startx) * RADIANS_TO_DEGREES;
            const angle_2:Number = Math.atan2(endy - cy, endx - cx) * RADIANS_TO_DEGREES;
            var angle_delta:Number = angle_2 - angle_1;

            // make sure angle is in range -180 - 180
            while (angle_delta > 180)
            {
                angle_delta -= 360;
            }
            while (angle_delta < -180)
            {
                angle_delta += 360;
            }

            angle_delta = angle_delta < 0 ? -angle_delta : angle_delta;

            // stop subdividing if the angle or the length is to small
            if (angle_delta <= minAngle)
            {
                array_out.push(endx, endy);
                return;
            }

            iterationCnt++;

            tesselateCurve(startx, starty, c1x, c1y, ax, ay, array_out, iterationCnt);
            tesselateCurve(ax, ay, c2x, c2y, endx, endy, array_out, iterationCnt);
        }

        private function checkIfClosed():void
        {
            const curPath:Vector.<Number> = _paths[_paths.length - 1];
            
            const lastX:Number = curPath[curPath.length - 2];
            const lastY:Number = curPath[curPath.length - 1];
            
            if (lastX == curPath[0]&& lastY == curPath[1])
                this.drawPolygon(Polygon.fromVector(_paths[_paths.length - 1]));
        }

        /** Removes all existing vertices. */
        public function clear():void
        {
            removeChildren(0, -1, true);
            _polygons.length = 0;
        }

        private function appendPolygon(polygon:Polygon):void
        {
            var vertexData:VertexData = new VertexData();
            var indexData:IndexData = new IndexData(polygon.numTriangles * 3);

            polygon.triangulate(indexData);
            polygon.copyToVertexData(vertexData);

            vertexData.colorize("color", _fillColor, _fillAlpha);

            addChild(new Mesh(vertexData, indexData));
            _polygons[_polygons.length] = polygon;
        }
    }
}
