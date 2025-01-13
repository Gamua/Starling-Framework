// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.geom
{
    import flash.geom.Point;

    import starling.geom.Polygon;
    import starling.unit.UnitTest;

    public class PolygonTest extends UnitTest
    {
        private static const E:Number = 0.0001;

        public function testConstructorWithPoints():void
        {
            var polygon:Polygon = new Polygon([new Point(0, 1), new Point(2, 3), new Point(4, 5)]);
            assertEqual(3, polygon.numVertices);
            assertEqualPoints(new Point(0, 1), polygon.getVertex(0));
            assertEqualPoints(new Point(2, 3), polygon.getVertex(1));
            assertEqualPoints(new Point(4, 5), polygon.getVertex(2));
        }

        public function testConstructorWithCoords():void
        {
            var polygon:Polygon = new Polygon([0, 1,  2, 3,  4, 5]);
            assertEqual(3, polygon.numVertices);
            assertEqualPoints(new Point(0, 1), polygon.getVertex(0));
            assertEqualPoints(new Point(2, 3), polygon.getVertex(1));
            assertEqualPoints(new Point(4, 5), polygon.getVertex(2));
        }

        public function testConstructorWithVectorCoords():void
        {
            var polygon:Polygon = Polygon.fromVector(new <Number>[0, 1, 2, 3, 4, 5]);
            assertEqual(3, polygon.numVertices);
            assertEqualPoints(new Point(0, 1), polygon.getVertex(0));
            assertEqualPoints(new Point(2, 3), polygon.getVertex(1));
            assertEqualPoints(new Point(4, 5), polygon.getVertex(2));
        }

        public function testClone():void
        {
            var polygon:Polygon = new Polygon([0, 1,  2, 3,  4, 5]);
            var clone:Polygon = polygon.clone();
            assertEqual(3, clone.numVertices);
            assertEqualPoints(new Point(0, 1), clone.getVertex(0));
            assertEqualPoints(new Point(2, 3), clone.getVertex(1));
            assertEqualPoints(new Point(4, 5), clone.getVertex(2));
        }

        public function testTriangulate():void
        {
            // 0-------1
            // |       |
            // 5----4  |
            //      |  |
            //      |  |
            //      3--2

            var p0:Point = new Point(0, 0);
            var p1:Point = new Point(4, 0);
            var p2:Point = new Point(4, 4);
            var p3:Point = new Point(3, 4);
            var p4:Point = new Point(3, 1);
            var p5:Point = new Point(0, 1);

            var polygon:Polygon = new Polygon([p0, p1, p2, p3, p4, p5]);
            var indices:Vector.<uint> = polygon.triangulate().toVector();
            var expected:Vector.<uint> = new <uint>[1,2,3, 1,3,4, 0,1,4, 0,4,5];

            assertEqualVectorsOfUints(indices, expected);
        }

        public function testTriangulateFewPoints():void
        {
            var p0:Point = new Point(0, 0);
            var p1:Point = new Point(1, 0);
            var p2:Point = new Point(0, 1);

            var polygon:Polygon = new Polygon([p0]);
            assertEqual(0, polygon.triangulate().numIndices);

            polygon.addVertices(p1);
            assertEqual(0, polygon.triangulate().numIndices);

            polygon.addVertices(p2);
            assertEqual(3, polygon.triangulate().numIndices);
        }

        public function testTriangulateNonSimplePolygon():void
        {
            // 0---1
            //  \ /
            //   X
            //  / \
            // 2---3

            // The triangulation won't be meaningful, but at least it should work.

            var p0:Point = new Point(0, 0);
            var p1:Point = new Point(1, 0);
            var p2:Point = new Point(0, 1);
            var p3:Point = new Point(1, 1);

            var polygon:Polygon = new Polygon([p0, p1, p2, p3]);
            var indices:Vector.<uint> = polygon.triangulate().toVector();
            var expected:Vector.<uint> = new <uint>[0,1,2, 0,2,3];

            assertEqualVectorsOfUints(indices, expected);
        }

        public function testInside():void
        {
            var polygon:Polygon;
            var p0:Point, p1:Point, p2:Point, p3:Point, p4:Point, p5:Point;

            // 0--1
            // | /
            // 2

            p0 = new Point(0, 0);
            p1 = new Point(1, 0);
            p2 = new Point(0, 1);

            polygon = new Polygon([p0, p1, p2]);
            assertTrue(polygon.contains(0.25, 0.25));
            assertFalse(polygon.contains(0.75, 0.75));

            // 0------1
            // |    3 |
            // |   / \|
            // 5--4   2

            p1 = new Point(4, 0);
            p2 = new Point(4, 2);
            p3 = new Point(3, 1);
            p4 = new Point(2, 2);
            p5 = new Point(0, 2);

            polygon = new Polygon([p0, p1, p2, p3, p4, p5]);
            assertTrue(polygon.contains(1, 1));
            assertTrue(polygon.contains(1, 1.5));
            assertTrue(polygon.contains(2.5, 1.25));
            assertTrue(polygon.contains(3.5, 1.25));
            assertFalse(polygon.contains(3, 1.1));
            assertFalse(polygon.contains(-1, -1));
            assertFalse(polygon.contains(2, 3));
            assertFalse(polygon.contains(6, 1));
            assertFalse(polygon.contains(5, 3));
        }

        public function testIsConvex():void
        {
            var polygon:Polygon;
            var p0:Point, p1:Point, p2:Point, p3:Point, p4:Point, p5:Point;

            // 0--1
            // | /
            // 2

            p0 = new Point(0, 0);
            p1 = new Point(1, 0);
            p2 = new Point(0, 1);

            polygon = new Polygon([p0, p1, p2]);
            assertTrue(polygon.isConvex);

            polygon = new Polygon([p0, p2, p1]);
            assertFalse(polygon.isConvex);

            // 0--1
            // |  |
            // 3--2

            p2 = new Point(1, 1);
            p3 = new Point(0, 1);

            polygon = new Polygon([p0, p1, p2, p3]);
            assertTrue(polygon.isConvex);

            polygon = new Polygon([p0, p3, p2, p1]);
            assertFalse(polygon.isConvex);

            // 0------1
            // |    3 |
            // |   / \|
            // 5--4   2

            p1 = new Point(4, 0);
            p2 = new Point(4, 2);
            p3 = new Point(3, 1);
            p4 = new Point(2, 2);
            p5 = new Point(0, 2);

            polygon = new Polygon([p0, p1, p2, p3, p4, p5]);
            assertFalse(polygon.isConvex);
        }

        public function testArea():void
        {
            var polygon:Polygon;
            var p0:Point, p1:Point, p2:Point, p3:Point;

            // 0--1
            // | /
            // 2

            p0 = new Point(0, 0);
            p1 = new Point(1, 0);
            p2 = new Point(0, 1);

            polygon = new Polygon([p0, p1, p2]);
            assertEquivalent(polygon.area, 0.5);

            // 0--1
            // |  |
            // 3--2

            p2 = new Point(1, 1);
            p3 = new Point(0, 1);

            polygon = new Polygon([p0, p1, p2, p3]);
            assertEquivalent(polygon.area, 1.0);

            // 0--1

            polygon = new Polygon([p0, p1]);
            assertEquivalent(polygon.area, 0.0);

            polygon = new Polygon([p0]);
            assertEquivalent(polygon.area, 0.0);
        }

        public function testReverse():void
        {
            var p0:Point = new Point(0, 1);
            var p1:Point = new Point(2, 3);
            var p2:Point = new Point(4, 5);

            var polygon:Polygon = new Polygon([p0]);
            polygon.reverse();

            assertEqualPoints(polygon.getVertex(0), p0);

            polygon.addVertices(p1, p2);
            polygon.reverse();

            assertEqualPoints(polygon.getVertex(0), p2);
            assertEqualPoints(polygon.getVertex(1), p1);
            assertEqualPoints(polygon.getVertex(2), p0);
        }

        public function testIsSimple():void
        {
            var polygon:Polygon;
            var p0:Point, p1:Point, p2:Point, p3:Point, p4:Point, p5:Point;

            // 0------1
            // |    3 |
            // |   / \|
            // 5--4   2

            p0 = new Point(0, 0);
            p1 = new Point(4, 0);
            p2 = new Point(4, 2);
            p3 = new Point(3, 1);
            p4 = new Point(2, 2);
            p5 = new Point(0, 2);

            polygon = new Polygon([p0, p1, p2, p3, p4, p5]);
            assertTrue(polygon.isSimple);

            // move point (3) up

            polygon.setVertex(3, 3, -1);
            assertFalse(polygon.isSimple);

            // 0---1
            //  \ /
            //   X
            //  / \
            // 2---3

            p1 = new Point(1, 0);
            p2 = new Point(0, 1);
            p3 = new Point(1, 1);

            polygon = new Polygon([p0, p1, p2, p3]);
            assertFalse(polygon.isSimple);
        }

        public function testResize():void
        {
            var polygon:Polygon = new Polygon([0, 1, 2, 3]);
            assertEqual(2, polygon.numVertices);

            polygon.numVertices = 1;
            assertEqual(1, polygon.numVertices);

            polygon.numVertices = 0;
            assertEqual(0, polygon.numVertices);

            polygon.numVertices = 2;
            assertEqual(2, polygon.numVertices);

            assertEqual(0, polygon.getVertex(0).x);
            assertEqual(0, polygon.getVertex(0).y);
            assertEqual(0, polygon.getVertex(1).x);
            assertEqual(0, polygon.getVertex(1).y);
        }

    }
}
