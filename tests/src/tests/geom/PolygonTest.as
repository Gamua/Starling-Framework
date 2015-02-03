// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2015 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.geom
{
    import flash.geom.Point;

    import org.flexunit.asserts.assertEquals;
    import org.flexunit.asserts.assertFalse;
    import org.flexunit.asserts.assertTrue;

    import starling.geom.Polygon;

    import tests.Helpers;

    public class PolygonTest
    {
        [Test]
        public function testConstructorWithPoints():void
        {
            var polygon:Polygon = new Polygon(new Point(0, 1), new Point(2, 3), new Point(4, 5));
            assertEquals(3, polygon.numVertices);
            Helpers.comparePoints(new Point(0, 1), polygon.getVertex(0));
            Helpers.comparePoints(new Point(2, 3), polygon.getVertex(1));
            Helpers.comparePoints(new Point(4, 5), polygon.getVertex(2));
        }

        [Test]
        public function testConstructorWithCoords():void
        {
            var polygon:Polygon = new Polygon(0, 1,  2, 3,  4, 5);
            assertEquals(3, polygon.numVertices);
            Helpers.comparePoints(new Point(0, 1), polygon.getVertex(0));
            Helpers.comparePoints(new Point(2, 3), polygon.getVertex(1));
            Helpers.comparePoints(new Point(4, 5), polygon.getVertex(2));
        }

        [Test]
        public function testClone():void
        {
            var polygon:Polygon = new Polygon(0, 1,  2, 3,  4, 5);
            var clone:Polygon = polygon.clone();
            assertEquals(3, polygon.numVertices);
            Helpers.comparePoints(new Point(0, 1), polygon.getVertex(0));
            Helpers.comparePoints(new Point(2, 3), polygon.getVertex(1));
            Helpers.comparePoints(new Point(4, 5), polygon.getVertex(2));
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

            var polygon:Polygon = new Polygon(p0, p1, p2, p3, p4, p5);
            var indices:Vector.<uint> = polygon.triangulate();
            var expected:Vector.<uint> = new <uint>[1,2,3, 1,3,4, 0,1,4, 0,4,5];

            Helpers.compareVectorsOfUints(indices, expected);
        }

        [Test]
        public function testTriangulateFewPoints():void
        {
            var p0:Point = new Point(0, 0);
            var p1:Point = new Point(1, 0);
            var p2:Point = new Point(0, 1);

            var polygon:Polygon = new Polygon(p0);
            assertEquals(0, polygon.triangulate().length);

            polygon.addVertices(p1);
            assertEquals(0, polygon.triangulate().length);

            polygon.addVertices(p2);
            assertEquals(3, polygon.triangulate().length);
        }

        [Test]
        public function testTriangulateWeirdPolygon():void
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

            var polygon:Polygon = new Polygon(p0, p1, p2, p3);
            var indices:Vector.<uint> = polygon.triangulate();
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

            polygon = new Polygon(p0, p1, p2);
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

            polygon = new Polygon(p0, p1, p2, p3, p4, p5);
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
    }
}
