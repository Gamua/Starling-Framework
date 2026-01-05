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

    import flash.display.IGraphicsData;
    import flash.display.GraphicsSolidFill;
    import flash.display.GraphicsPath;
    import flash.display.GraphicsPathCommand;
    import flash.display.GraphicsEndFill;
    import flash.geom.Point;

    import starling.geom.Polygon;
    import starling.rendering.IndexData;
    import starling.rendering.VertexData;
    import starling.rendering.Painter;
    import starling.utils.rad2deg;

    /** A display object supporting basic vector drawing functionality. In its current state,
     *  the main use of this class is to provide a range of forms that can be used as masks.
     */
    public class Canvas extends DisplayObjectContainer
    {
        private var _polygons:Vector.<Polygon>;
        private var _currentPath:Vector.<Number>;
        private var _fillColor:uint;
        private var _fillAlpha:Number;

        /** Creates a new (empty) Canvas. Call one or more of the 'draw' methods to add content. */
        public function Canvas()
        {
            _polygons  = new <Polygon>[];
            _currentPath = new <Number>[];
            _fillColor = 0xffffff;
            _fillAlpha = 1.0;
            touchGroup = true;
            
        }

        /** @inheritDoc */
        public override function render(painter:Painter):void
        {
            // Behave like Flash's Graphics: if path is attempted to be rendered and unfinished, force close it.
            closeCurrentPathIfNeeded();
            super.render(painter);
        }

        /** @inheritDoc */
        public override function dispose():void
        {
            _polygons.length = 0;
            _currentPath.length = 0;
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
            drawPolygon(Polygon.createCircle(x, y, radius, numSides));
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

            drawPolygon(Polygon.createEllipse(x + radiusX, y + radiusY, radiusX, radiusY, numSides));
        }

        /** Draws a rectangle. */
        public function drawRectangle(x:Number, y:Number, width:Number, height:Number):void
        {
            drawPolygon(Polygon.createRectangle(x, y, width, height));
        }

        /** Draws a rectangle with rounded corners. */
        public function drawRoundRectangle(x:Number, y:Number, width:Number, height:Number, ellipseWidth:Number, ellipseHeight:Number = NaN):void
        {
            drawPolygon(Polygon.createRoundRectangle(x, y, width, height, ellipseWidth, ellipseHeight));
        }

        /** Specifies a simple one-color fill that subsequent calls to drawing methods
         *  (such as <code>drawCircle()</code>) will use. */
        public function beginFill(color:uint=0xffffff, alpha:Number=1.0):void
        {
            closeCurrentPathIfNeeded();
            _fillColor = color;
            _fillAlpha = alpha;
        }

        /** Resets the color to 'white' and alpha to '1'. */
        public function endFill():void
        {
            closeCurrentPathIfNeeded();
            _fillColor = 0xffffff;
            _fillAlpha = 1.0;
        }

        /** Moves the current drawing position to (x, y).
         *
         * @param x  A number that indicates the horizontal position relative to the registration point of the parent display object (in pixels).
         * @param y  A number that indicates the vertical position relative to the registration point of the parent display object (in pixels).
         */
        public function moveTo(x:Number, y:Number):void
        {
            // If a previous path is still open, close it automatically before starting a new one.
            // This matches Flash's Graphics behavior, where a new MOVE_TO implicitly ends the
            // current sub-path.
            closeCurrentPathIfNeeded();

            _currentPath.length = 0;
            _currentPath.push(x, y);
        }

        /** Draws a line using the current line style from the current drawing position to (x, y); the current drawing position is then set to (x, y).
         *
         * @param x  A number that indicates the horizontal position relative to the registration point of the parent display object (in pixels).
         * @param y  A number that indicates the vertical position relative to the registration point of the parent display object (in pixels).
         */
        public function lineTo(x:Number, y:Number):void
        {
            // TODO: This implementation is too simple for strokes, only works for fills
            if(_currentPath.length == 0)
            {
                // Behave like Flash's Graphics: if there's no current point, start at (0, 0).
                _currentPath.push(0.0, 0.0);
            }
            _currentPath.push(x, y);
            drawPathIfClosed();
        }

        /**  Draws a quadratic Bezier curve using the current line style from the current drawing position to (anchorX, anchorY) and using the control point that (controlX, controlY) specifies.
         *
         * @param controlX  A number that specifies the horizontal position of the control point relative to the registration point of the parent display object.
         * @param controlY  A number that specifies the vertical position of the control point relative to the registration point of the parent display object.
         * @param anchorX   A number that specifies the horizontal position of the next anchor point relative to the registration point of the parent display object.
         * @param anchorY   A number that specifies the vertical position of the next anchor point relative to the registration point of the parent display object.
         */
        public function curveTo(controlX:Number, controlY:Number, anchorX:Number, anchorY:Number):void
        {
            if (_currentPath.length == 0)
            {
                // Behave like Flash's Graphics: if there's no current point, start at (0, 0).
                _currentPath.push(0.0, 0.0);
            }
            const lastX:Number = _currentPath[_currentPath.length - 2];
            const lastY:Number = _currentPath[_currentPath.length - 1];
            tesselateCurve(lastX, lastY, controlX, controlY, anchorX, anchorY, _currentPath);
            drawPathIfClosed();
        }

        public function cubicCurveTo(controlX1:Number, controlY1:Number, controlX2:Number, controlY2:Number, anchorX:Number, anchorY:Number):void
        {
            if (_currentPath.length == 0)
            {
                // Behave like Flash's Graphics: if there's no current point, start at (0, 0).
                _currentPath.push(0.0, 0.0);
            }
            const lastX:Number = _currentPath[_currentPath.length - 2];
            const lastY:Number = _currentPath[_currentPath.length - 1];
            tesselateCubicCurve(lastX, lastY, controlX1, controlY1, controlX2, controlY2, anchorX, anchorY, _currentPath, 0);
            drawPathIfClosed();
        }

        /** Closes the current path if it contains an unfinished polygon. */
        private function closeCurrentPathIfNeeded():void
        {
            if (_currentPath.length < 6) // fewer than 3 points -> nothing meaningful to close
                return;

            const firstX:Number = _currentPath[0];
            const firstY:Number = _currentPath[1];
            const lastX:Number  = _currentPath[_currentPath.length - 2];
            const lastY:Number  = _currentPath[_currentPath.length - 1];
            const isClosed:Boolean = lastX == firstX && lastY == firstY;

            if (!isClosed)
            {
                _currentPath.push(firstX, firstY);
            }

            // Now draw and reset the path ('drawPathIfClosed' clears '_currentPath').
            drawPathIfClosed();
        }

        /**  Submits a series of IGraphicsData instances for drawing.
         *
         * @param graphicsData      A Vector containing graphics objects, each of which must implement the flash.display.IGraphicsData interface.
         */
        public function drawGraphicsData(graphicsData:Vector.<IGraphicsData>):void
        {
            var graphicsDataLength:int = graphicsData.length;
            for (var graphPropIndex:int = 0; graphPropIndex < graphicsDataLength; graphPropIndex++)
            {
                var graphicsProperties:IGraphicsData = graphicsData[graphPropIndex];

                if (graphicsProperties is GraphicsSolidFill)
                    beginFill(
                        (graphicsProperties as GraphicsSolidFill).color, 
                        (graphicsProperties as GraphicsSolidFill).alpha
                    );

                else if (graphicsProperties is GraphicsPath)
                    drawPath((graphicsProperties as GraphicsPath).commands, (graphicsProperties as GraphicsPath).data, (graphicsProperties as GraphicsPath).winding);

                else if (graphicsProperties is GraphicsEndFill)
                    endFill();

                else
                    trace("[Starling] Canvas.drawGraphicsData: Unimplemented Graphics Data in input: ",
                            graphicsProperties, " at index ", graphicsData.indexOf(graphicsProperties));
            }
        }

        public function drawPath(commands:Vector.<int>, data:Vector.<Number>, winding:String = "evenOdd"):void
        {
            var i:int = 0;
            const commandLength:int = commands.length;
            for (var commandIndex:int = 0; commandIndex < commandLength; commandIndex++)
            {
                var command:int = commands[commandIndex];
                switch (command)
                {
                    case GraphicsPathCommand.MOVE_TO:
                        moveTo(data[i], data[i + 1]);
                        i += 2;
                        break;

                    case GraphicsPathCommand.LINE_TO:
                        lineTo(data[i], data[i + 1]);
                        i += 2;
                        break;

                    case GraphicsPathCommand.CURVE_TO:
                        curveTo(data[i], data[i + 1], data[i + 2], data[i + 3]);
                        i += 4;
                        break;

                    case GraphicsPathCommand.CUBIC_CURVE_TO:
                        cubicCurveTo(data[i], data[i + 1], data[i + 2], data[i + 3], data[i + 4], data[i + 5]);
                        i += 6;
                        break;

                    default:
                        trace("[Starling] Canvas.drawPath: Unimplemented Command in Graphics Path of type", command);
                        break;
                }
            }
        }

        /** Removes all existing vertices. */
        public function clear():void
        {
            removeChildren(0, -1, true);
            _polygons.length = 0;
            _currentPath.length = 0;
        }

        /** Draws an arbitrary polygon. */
        public function drawPolygon(polygon:Polygon):void
        {
            var vertexData:VertexData = new VertexData();
            var indexData:IndexData = new IndexData(polygon.numTriangles * 3);

            polygon.triangulate(indexData);
            polygon.copyToVertexData(vertexData);

            vertexData.colorize("color", _fillColor, _fillAlpha);

            addChild(new Mesh(vertexData, indexData));
            _polygons[_polygons.length] = polygon;
        }

        /**   Func to tesselate a quadratic curve using recursion, used in curveTo; converted to AS3 from AwayJS.
         *    https://github.com/awayjs/graphics/blob/19c9c9912d0254934ba54c9b7049d1b898bf97f2/lib/draw/GraphicsFactoryHelper.ts#L376-L468
         */
        private static function tesselateCurve(startx:Number, starty:Number, cx:Number, cy:Number, endx:Number,
                                               endy:Number, array_out:Vector.<Number>, iterationCnt:Number = 0):void
        {
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
            const angle_1:Number = rad2deg(Math.atan2(cy - starty, cx - startx));
            const angle_2:Number = rad2deg(Math.atan2(endy - cy, endx - cx));
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

        /**   Func to tesselate a cubic curve using recursion, used in curveTo; converted to AS3 from AwayJS.
         *    https://github.com/awayjs/graphics/blob/19c9c9912d0254934ba54c9b7049d1b898bf97f2/lib/draw/GraphicsFactoryHelper.ts#L470-L550
         */
        private static function tesselateCubicCurve(startx:Number, starty:Number, cx:Number, cy:Number, cx2:Number, cy2:Number, 
                                                    endx:Number, endy:Number, array_out:Vector.<Number>, iterationCnt:Number = 0):void
        {
            const maxIterations:Number = 6;
            const minAngle:Number = 1;
            const minLengthSqr:Number = 1;

            // calculate length of segment
            // this does not include the crtl-point positions
            const diff_x:Number = endx - startx;
            const diff_y:Number = endy - starty;
            const lenSq:Number= diff_x * diff_x + diff_y * diff_y;

            // stop subdividing if the angle or the length is to small
            if (lenSq < minLengthSqr) {
                array_out.push(endx, endy);
                return;
            }

            // subdivide the curve
            const c1x:Number = (startx + cx) * 0.5;// new controlpoint 1
            const c1y:Number = (starty + cy) * 0.5;
            const c2x:Number = (cx + cx2) * 0.5;// new controlpoint 2
            const c2y:Number = (cy + cy2) * 0.5;
            const c3x:Number = (cx2 + endx) * 0.5;// new controlpoint 3
            const c3y:Number = (cy2 + endy) * 0.5;

            const d1x:Number = (c1x + c2x) * 0.5;// new controlpoint 1
            const d1y:Number = (c1y + c2y) * 0.5;
            const d2x:Number = (c2x + c3x) * 0.5;// new controlpoint 2
            const d2y:Number = (c2y + c3y) * 0.5;

            const ax:Number = (d1x + d2x) * 0.5;// new middlepoint 1
            const ay:Number = (d1y + d2y) * 0.5;

            // stop tesselation on maxIteration level. Set it to 0 for no tesselation at all.
            if (iterationCnt >= maxIterations) {
                array_out.push(ax, ay, endx, endy);
                return;
            }

            // calculate angle between segments
            const angle_1:Number = rad2deg(Math.atan2(cy - starty, cx - startx));
            const angle_2:Number = rad2deg(Math.atan2(endy - cy, endx - cx));
            var angle_delta:Number = angle_2 - angle_1;

            // make sure angle is in range -180 - 180
            while (angle_delta > 180) {
                angle_delta -= 360;
            }
            while (angle_delta < -180) {
                angle_delta += 360;
            }

            angle_delta = angle_delta < 0 ? -angle_delta : angle_delta;

            // stop subdividing if the angle or the length is to small
            if (angle_delta <= minAngle) {
                array_out.push(endx, endy);
                return;
            }

            iterationCnt++;

            tesselateCubicCurve(
                startx, starty, c1x, c1y, d1x, d1y, ax, ay, array_out, iterationCnt);
            tesselateCubicCurve(
                ax, ay, d2x, d2y, c3x, c3y, endx, endy, array_out, iterationCnt);
	}

        private function drawPathIfClosed():void
        {
            if (_currentPath.length < 4) return; // need at least two points

            const lastX:Number = _currentPath[_currentPath.length - 2];
            const lastY:Number = _currentPath[_currentPath.length - 1];

            if (lastX == _currentPath[0] && lastY == _currentPath[1])
            {
                // Create a copy so we can safely clear the path afterwards.
                // Important: Polygon.fromVector() keeps a reference to the passed Vector (for
                // performance / to avoid allocations). If we passed '_currentPath' directly and
                // then cleared/reused it, we'd also modify the polygon's internal coordinates.
                var pathCopy:Vector.<Number> = _currentPath.concat();
                _currentPath.length = 0;

                drawPolygon(Polygon.fromVector(pathCopy));

                // Keep the current position at the end of the closed path.
                // This matches Flash Graphics semantics: subsequent lineTo/curveTo calls continue
                // from the last point (which equals the start point after closing).
                _currentPath.push(lastX, lastY);
            }
        }
    }
}
