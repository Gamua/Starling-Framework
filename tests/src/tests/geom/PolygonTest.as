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

    import org.flexunit.assertThat;
    import org.flexunit.asserts.assertEquals;
    import org.flexunit.asserts.assertFalse;
    import org.flexunit.asserts.assertTrue;
    import org.hamcrest.number.closeTo;

    import starling.geom.Polygon;

    import tests.Helpers;

    public class PolygonTest
    {
        private static const E:Number = 0.0001;

        [Test]
        public function testConstructorWithPoints():void
        {
            var polygon:Polygon = new Polygon([new Point(0, 1), new Point(2, 3), new Point(4, 5)]);
            assertEquals(3, polygon.numVertices);
            Helpers.comparePoints(new Point(0, 1), polygon.getVertex(0));
            Helpers.comparePoints(new Point(2, 3), polygon.getVertex(1));
            Helpers.comparePoints(new Point(4, 5), polygon.getVertex(2));
        }

        [Test]
        public function testConstructorWithCoords():void
        {
            var polygon:Polygon = new Polygon([0, 1,  2, 3,  4, 5]);
            assertEquals(3, polygon.numVertices);
            Helpers.comparePoints(new Point(0, 1), polygon.getVertex(0));
            Helpers.comparePoints(new Point(2, 3), polygon.getVertex(1));
            Helpers.comparePoints(new Point(4, 5), polygon.getVertex(2));
        }

        [Test]
        public function testClone():void
        {
            var polygon:Polygon = new Polygon([0, 1,  2, 3,  4, 5]);
            var clone:Polygon = polygon.clone();
            assertEquals(3, clone.numVertices);
            Helpers.comparePoints(new Point(0, 1), clone.getVertex(0));
            Helpers.comparePoints(new Point(2, 3), clone.getVertex(1));
            Helpers.comparePoints(new Point(4, 5), clone.getVertex(2));
        }

        [Test]
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

            Helpers.compareVectorsOfUints(indices, expected);
        }

        [Test]
        public function testTriangulateFewPoints():void
        {
            var p0:Point = new Point(0, 0);
            var p1:Point = new Point(1, 0);
            var p2:Point = new Point(0, 1);

            var polygon:Polygon = new Polygon([p0]);
            assertEquals(0, polygon.triangulate().numIndices);

            polygon.addVertices(p1);
            assertEquals(0, polygon.triangulate().numIndices);

            polygon.addVertices(p2);
            assertEquals(3, polygon.triangulate().numIndices);
        }

        [Test]
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

            Helpers.compareVectorsOfUints(indices, expected);
        }

        [Test]
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

        [Test]
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

        [Test]
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
            assertThat(polygon.area, closeTo(0.5, E));

            // 0--1
            // |  |
            // 3--2

            p2 = new Point(1, 1);
            p3 = new Point(0, 1);

            polygon = new Polygon([p0, p1, p2, p3]);
            assertThat(polygon.area, closeTo(1.0, E));

            // 0--1

            polygon = new Polygon([p0, p1]);
            assertThat(polygon.area, closeTo(0.0, E));

            polygon = new Polygon([p0]);
            assertThat(polygon.area, closeTo(0.0, E));
        }

        [Test]
        public function testReverse():void
        {
            var p0:Point = new Point(0, 1);
            var p1:Point = new Point(2, 3);
            var p2:Point = new Point(4, 5);

            var polygon:Polygon = new Polygon([p0]);
            polygon.reverse();

            Helpers.comparePoints(polygon.getVertex(0), p0);

            polygon.addVertices(p1, p2);
            polygon.reverse();

            Helpers.comparePoints(polygon.getVertex(0), p2);
            Helpers.comparePoints(polygon.getVertex(1), p1);
            Helpers.comparePoints(polygon.getVertex(2), p0);
        }

        [Test]
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

        [Test]
        public function testResize():void
        {
            var polygon:Polygon = new Polygon([0, 1, 2, 3]);
            assertEquals(2, polygon.numVertices);

            polygon.numVertices = 1;
            assertEquals(1, polygon.numVertices);

            polygon.numVertices = 0;
            assertEquals(0, polygon.numVertices);

            polygon.numVertices = 2;
            assertEquals(2, polygon.numVertices);

            assertEquals(0, polygon.getVertex(0).x);
            assertEquals(0, polygon.getVertex(0).y);
            assertEquals(0, polygon.getVertex(1).x);
            assertEquals(0, polygon.getVertex(1).y);
        }

    }
}
