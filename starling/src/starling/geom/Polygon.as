// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2015 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.geom
{
    import flash.geom.Point;

    import starling.utils.VertexData;

    public class Polygon
    {
        protected var mCoords:Vector.<Number>;

        public function Polygon(...args)
        {
            mCoords = new <Number>[];
            addVertices.apply(this, args);
        }

        public function clone():Polygon
        {
            var clone:Polygon = new Polygon();
            var numCoords:int = mCoords.length;

            for (var i:int=0; i<numCoords; ++i)
                clone.mCoords[i] = mCoords[i];

            return clone;
        }

        public function addVertices(...args):void
        {
            var i:int;
            var numArgs:int = args.length;
            var numCoords:int = mCoords.length;

            if (numArgs > 0)
            {
                if (args[0] is Point)
                {
                    for (i=0; i<numArgs; i++)
                    {
                        mCoords[numCoords + i * 2    ] = (args[i] as Point).x;
                        mCoords[numCoords + i * 2 + 1] = (args[i] as Point).y;
                    }
                }
                else if (args[0] is Number)
                {
                    for (i=0; i<numArgs; ++i)
                        mCoords[numCoords + i] = args[i];
                }
            }
        }

        public function setVertex(index:int, x:Number, y:Number):void
        {
            mCoords[index * 2    ] = x;
            mCoords[index * 2 + 1] = y;
        }

        public function getVertex(index:int, result:Point=null):Point
        {
            if (index >= 0 && index < numVertices)
            {
                result ||= new Point();
                result.setTo(mCoords[index * 2], mCoords[index * 2 + 1]);
                return result;
            }
            else
                throw new RangeError("Invalid index");
        }

        public function contains(x:Number, y:Number):Boolean
        {
            // Algorithm & implementation thankfully taken from:
            // -> http://alienryderflex.com/polygon/

            var i:int, j:int = numVertices - 1;
            var oddNodes:uint = 0;

            for (i=0; i<numVertices; ++i)
            {
                var ix:Number = mCoords[i * 2];
                var iy:Number = mCoords[i * 2 + 1];
                var jx:Number = mCoords[j * 2];
                var jy:Number = mCoords[j * 2 + 1];

                if ((iy < y && jy >= y || jy < y && iy >= y) && (ix <= x || jx <= x))
                    oddNodes ^= uint(ix + (y - iy) / (jy - iy) * (jx - ix) < x);

                j = i;
            }

            return oddNodes != 0;
        }

        public function containsPoint(point:Point):Boolean
        {
            return contains(point.x, point.y);
        }

        public function triangulate(result:Vector.<uint>=null):Vector.<uint>
        {
            // Algorithm "Ear clipping method" described here:
            // -> https://en.wikipedia.org/wiki/Polygon_triangulation
            //
            // Implementation inspired by:
            // -> http://polyk.ivank.net

            result ||= new <uint>[];

            var numVertices:int = this.numVertices;
            var i:int, restIndexPos:int, numRestIndices:int;

            if (numVertices < 3) return result;

            var restIndices:Vector.<uint> = new Vector.<uint>(numVertices);

            for (i=0; i<numVertices; ++i)
                restIndices[i] = i;

            restIndexPos = 0;
            numRestIndices = numVertices;

            while (numRestIndices > 3)
            {
                // In each step, we look at 3 subsequent vertices. If those vertices spawn up
                // a triangle that is convex and does not contain any other vertices, it is an 'ear'.
                // We remove those ears until only one remains -> each ear is one of our wanted
                // triangles.

                var i0:int = restIndices[ restIndexPos      % numRestIndices];
                var i1:int = restIndices[(restIndexPos + 1) % numRestIndices];
                var i2:int = restIndices[(restIndexPos + 2) % numRestIndices];

                var ax:Number = mCoords[2 * i0];
                var ay:Number = mCoords[2 * i0 + 1];
                var bx:Number = mCoords[2 * i1];
                var by:Number = mCoords[2 * i1 + 1];
                var cx:Number = mCoords[2 * i2];
                var cy:Number = mCoords[2 * i2 + 1];
                var earFound:Boolean = false;

                if (isConvexTriangle(ax, ay, bx, by, cx, cy))
                {
                    earFound = true;
                    for (i = 3; i < numRestIndices; ++i)
                    {
                        var otherIndex:int = restIndices[(restIndexPos + i) % numRestIndices];
                        if (isPointInTriangle(mCoords[2 * otherIndex], mCoords[2 * otherIndex + 1],
                                ax, ay, bx, by, cx, cy))
                        {
                            earFound = false;
                            break;
                        }
                    }
                }

                if (earFound)
                {
                    result.push(i0, i1, i2);
                    restIndices.splice((restIndexPos + 1) % numRestIndices, 1);
                    numRestIndices--;
                    restIndexPos = 0;
                }
                else
                {
                    restIndexPos++;
                    if (restIndexPos == numRestIndices) break; // no more ears
                }
            }

            result.push(restIndices[0], restIndices[1], restIndices[2]);
            return result;
        }

        public function copyVertexDataTo(target:VertexData, targetIndex:int=0):void
        {
            var requiredTargetLength:int = targetIndex + numVertices;
            if (target.numVertices < requiredTargetLength)
                target.numVertices = requiredTargetLength;

            copyVertexCoordsTo(target.rawData,
                targetIndex * VertexData.ELEMENTS_PER_VERTEX,
                VertexData.ELEMENTS_PER_VERTEX - 2);
        }

        public function copyVertexCoordsTo(target:Vector.<Number>, targetIndex:int=0,
                                           stride:int=0):void
        {
            var numVertices:int = this.numVertices;

            for (var i:int=0; i<numVertices; ++i)
            {
                target[targetIndex++] = mCoords[i * 2];
                target[targetIndex++] = mCoords[i * 2 + 1];
                targetIndex += stride;
            }
        }

        /** Creates a string that contains the values of all included points. */
        public function toString():String
        {
            var result:String = "[Polygon \n";
            var numPoints:int = this.numVertices;

            for (var i:int=0; i<numPoints; ++i)
            {
                result += "  [Vertex " + i + ": " +
                "x="   + mCoords[i * 2    ].toFixed(1) + ", " +
                "y="   + mCoords[i * 2 + 1].toFixed(1) + "]"  +
                (i == numPoints - 1 ? "\n" : ",\n");
            }

            return result + "]";
        }

        // factory methods

        public static function createCircle(x:Number, y:Number, radius:Number,
                                            numSegments:int=32):Polygon
        {
            var circle:Polygon = new Polygon();
            var angleDelta:Number = Math.PI / numSegments;

            for (var angle:Number=0; angle < Math.PI * 2; angle += angleDelta)
                circle.addVertices(Math.cos(angle) * radius + x,
                                   Math.sin(angle) * radius + y);

            return circle;
        }

        public static function createRectangle(x:Number, y:Number,
                                               width:Number, height:Number):Polygon
        {
            return new Polygon(x, y, x + width, y, x + width, y + height, x, y + height);
        }

        // helpers

        [Inline]
        private static function isConvexTriangle(ax:Number, ay:Number,
                                                 bx:Number, by:Number,
                                                 cx:Number, cy:Number):Boolean
        {
            // dot product of (b->a) and (b->c) must be positive
            return (ay - by) * (cx - bx) + (bx - ax) * (cy - by) >= 0;
        }

        /** Calculates if a point (px, py) is inside the area of a 2D triangle. */
        private static function isPointInTriangle(px:Number, py:Number,
                                                  ax:Number, ay:Number,
                                                  bx:Number, by:Number,
                                                  cx:Number, cy:Number):Boolean
        {
            // This algorithm is described well in this article:
            // http://www.blackpawn.com/texts/pointinpoly/default.html

            var v0x:Number = cx - ax;
            var v0y:Number = cy - ay;
            var v1x:Number = bx - ax;
            var v1y:Number = by - ay;
            var v2x:Number = px - ax;
            var v2y:Number = py - ay;

            var dot00:Number = v0x * v0x + v0y * v0y;
            var dot01:Number = v0x * v1x + v0y * v1y;
            var dot02:Number = v0x * v2x + v0y * v2y;
            var dot11:Number = v1x * v1x + v1y * v1y;
            var dot12:Number = v1x * v2x + v1y * v2y;

            var invDenom:Number = 1.0 / (dot00 * dot11 - dot01 * dot01);
            var u:Number = (dot11 * dot02 - dot01 * dot12) * invDenom;
            var v:Number = (dot00 * dot12 - dot01 * dot02) * invDenom;

            return (u >= 0) && (v >= 0) && (u + v < 1);
        }

        // properties

        /** Indicates if the polygon is simple (i.e. not self-intersecting). */
        public function get isSimple():Boolean
        {
            // TODO
            return false;
        }

        public function get isConvex():Boolean
        {
            // TODO
            return false;
        }

        public function get area():Number
        {
            // TODO
            return 0;
        }

        public function get numVertices():int
        {
            return mCoords.length / 2;
        }
    }
}
