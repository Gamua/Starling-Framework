// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.rendering
{
    import org.flexunit.asserts.assertEquals;
    import org.flexunit.asserts.assertFalse;
    import org.flexunit.asserts.assertTrue;

    import starling.rendering.IndexData;

    import tests.Helpers;

    public class IndexDataTest
    {
        [Test]
        public function testCreate():void
        {
            var indexData:IndexData = new IndexData();
            assertEquals(0, indexData.numIndices);
            assertTrue(indexData.useQuadLayout);
        }

        [Test]
        public function testClear():void
        {
            var indexData:IndexData = new IndexData();
            indexData.addTriangle(1, 2, 4);
            indexData.clear();

            assertEquals(0, indexData.numIndices);
            assertTrue(indexData.useQuadLayout);
        }

        [Test]
        public function testSetIndex():void
        {
            var indexData:IndexData = new IndexData();

            // basic quad data

            indexData.setIndex(0, 0);
            indexData.setIndex(1, 1);
            indexData.setIndex(2, 2);

            assertTrue(indexData.useQuadLayout);
            assertEquals(0, indexData.getIndex(0));
            assertEquals(1, indexData.getIndex(1));
            assertEquals(2, indexData.getIndex(2));
            assertEquals(3, indexData.numIndices);

            // setting outside the bounds while keeping quad index rules -> fill up with quad data

            indexData.setIndex(5, 2);
            assertTrue(indexData.useQuadLayout);
            assertEquals(2, indexData.numTriangles);
            assertEquals(1, indexData.getIndex(3));
            assertEquals(3, indexData.getIndex(4));
            assertEquals(2, indexData.getIndex(5));

            // arbitrary data

            indexData.setIndex(6, 5);
            assertFalse(indexData.useQuadLayout);
            assertEquals(7, indexData.numIndices);
            assertEquals(5, indexData.getIndex(6));

            // settings outside the bounds -> fill up with zeroes

            indexData.setIndex(9, 1);
            assertEquals(10, indexData.numIndices);
            assertEquals(0, indexData.getIndex(7));
            assertEquals(0, indexData.getIndex(8));
            assertEquals(1, indexData.getIndex(9));
        }

        [Test]
        public function testAppendTriangle():void
        {
            var indexData:IndexData = new IndexData();

            // basic quad data

            indexData.addTriangle(0, 1, 2);
            indexData.addTriangle(1, 3, 2);

            assertTrue(indexData.useQuadLayout);
            assertEquals(1, indexData.numQuads);
            assertEquals(2, indexData.numTriangles);
            assertEquals(6, indexData.numIndices);

            assertEquals(0, indexData.getIndex(0));
            assertEquals(1, indexData.getIndex(1));
            assertEquals(2, indexData.getIndex(2));
            assertEquals(1, indexData.getIndex(3));
            assertEquals(3, indexData.getIndex(4));
            assertEquals(2, indexData.getIndex(5));

            indexData.numTriangles = 0;
            assertEquals(0, indexData.numIndices);
            assertEquals(0, indexData.numTriangles);

            // arbitrary data

            indexData.addTriangle(1, 3, 2);
            assertFalse(indexData.useQuadLayout);
            assertEquals(1, indexData.numTriangles);
            assertEquals(3, indexData.numIndices);

            assertEquals(1, indexData.getIndex(0));
            assertEquals(3, indexData.getIndex(1));
            assertEquals(2, indexData.getIndex(2));
        }

        [Test]
        public function testAppendQuad():void
        {
            var indexData:IndexData = new IndexData();

            // basic quad data

            indexData.addQuad(0, 1, 2, 3);
            indexData.addQuad(4, 5, 6, 7);

            assertTrue(indexData.useQuadLayout);
            assertEquals(2, indexData.numQuads);
            assertEquals(4, indexData.numTriangles);
            assertEquals(12, indexData.numIndices);

            assertEquals(0, indexData.getIndex(0));
            assertEquals(1, indexData.getIndex(1));
            assertEquals(2, indexData.getIndex(2));
            assertEquals(1, indexData.getIndex(3));
            assertEquals(3, indexData.getIndex(4));
            assertEquals(2, indexData.getIndex(5));
            assertEquals(4, indexData.getIndex(6));
            assertEquals(5, indexData.getIndex(7));
            assertEquals(6, indexData.getIndex(8));
            assertEquals(5, indexData.getIndex(9));
            assertEquals(7, indexData.getIndex(10));
            assertEquals(6, indexData.getIndex(11));

            indexData.numTriangles = 0;
            assertEquals(0, indexData.numIndices);
            assertEquals(0, indexData.numQuads);

            // arbitrary data

            indexData.addQuad(0, 1, 3, 2);
            assertFalse(indexData.useQuadLayout);
            assertEquals(1, indexData.numQuads);
            assertEquals(2, indexData.numTriangles);
            assertEquals(6, indexData.numIndices);

            assertEquals(0, indexData.getIndex(0));
            assertEquals(1, indexData.getIndex(1));
            assertEquals(3, indexData.getIndex(2));
            assertEquals(1, indexData.getIndex(3));
            assertEquals(2, indexData.getIndex(4));
            assertEquals(3, indexData.getIndex(5));
        }

        [Test]
        public function testClone():void
        {
            var indexData:IndexData;
            var clone:IndexData;

            // with basic quad data

            indexData = new IndexData();
            indexData.addTriangle(1, 2, 3);
            indexData.addTriangle(4, 5, 6);

            clone = indexData.clone();
            assertEquals(2, clone.numTriangles);
            assertEquals(1, clone.getIndex(0));
            assertEquals(3, clone.getIndex(2));
            assertEquals(5, clone.getIndex(4));

            // with arbitrary data

            indexData = new IndexData();
            indexData.addTriangle(0, 1, 2);
            indexData.addTriangle(1, 3, 2);

            clone = indexData.clone();
            assertEquals(2, clone.numTriangles);
            assertEquals(1, clone.getIndex(1));
            assertEquals(2, clone.getIndex(2));
            assertEquals(3, clone.getIndex(4));
        }

        [Test]
        public function testSetNumIndices():void
        {
            var indexData:IndexData = new IndexData();
            indexData.numIndices = 6;

            assertEquals(0, indexData.getIndex(0));
            assertEquals(1, indexData.getIndex(1));
            assertEquals(2, indexData.getIndex(2));
            assertEquals(1, indexData.getIndex(3));
            assertEquals(3, indexData.getIndex(4));
            assertEquals(2, indexData.getIndex(5));

            indexData.numIndices = 0;
            assertEquals(0, indexData.numIndices);

            indexData.setIndex(0, 1);
            assertFalse(indexData.useQuadLayout);

            indexData.numIndices = 3;
            assertEquals(1, indexData.getIndex(0));
            assertEquals(0, indexData.getIndex(1));
            assertEquals(0, indexData.getIndex(2));

            indexData.numIndices = 0;
            assertEquals(0, indexData.numIndices);
            assertTrue(indexData.useQuadLayout);
        }

        [Test]
        public function testCopyTo():void
        {
            // arbitrary data -> arbitrary data

            var source:IndexData = new IndexData();
            source.addTriangle(1, 2, 3);
            source.addTriangle(4, 5, 6);

            var target:IndexData = new IndexData();
            target.addTriangle(7, 8, 9);
            source.copyTo(target, 0, 0, 3, 3);

            assertEquals(3, target.numIndices);
            assertEquals(4, target.getIndex(0));
            assertEquals(5, target.getIndex(1));
            assertEquals(6, target.getIndex(2));

            source.copyTo(target, 3);
            assertEquals(9, target.numIndices);

            // quad data -> quad data

            source.clear();
            target.clear();

            source.addTriangle(0, 1, 2);
            target.addQuad(0, 1, 2, 3);
            source.copyTo(target, 6, 4);

            assertTrue(target.useQuadLayout);
            assertEquals(9, target.numIndices);
            assertEquals(2, target.getIndex(5));
            assertEquals(4, target.getIndex(6));
            assertEquals(5, target.getIndex(7));
            assertEquals(6, target.getIndex(8));

            // quad data -> arbitrary data

            target.clear();
            target.addQuad(1, 2, 3, 4);
            source.copyTo(target, 6, 4);

            assertTrue(source.useQuadLayout);
            assertFalse(target.useQuadLayout);
            assertEquals(9, target.numIndices);
            assertEquals(3, target.getIndex(5));
            assertEquals(4, target.getIndex(6));
            assertEquals(5, target.getIndex(7));
            assertEquals(6, target.getIndex(8));

            // arbitrary data -> quad data

            source.clear();
            source.addTriangle(1, 2, 3);
            target.clear();
            target.addQuad(0, 1, 2, 3);
            source.copyTo(target, 6, 4);

            assertFalse(source.useQuadLayout);
            assertFalse(target.useQuadLayout);
            assertEquals(9, target.numIndices);
            assertEquals(2, target.getIndex(5));
            assertEquals(5, target.getIndex(6));
            assertEquals(6, target.getIndex(7));
            assertEquals(7, target.getIndex(8));
        }

        [Test]
        public function testCopyToEdgeCases():void
        {
            var source:IndexData = new IndexData();
            source.numIndices = 6;

            var target:IndexData = new IndexData();
            target.numIndices = 6;

            source.copyTo(target, 1, 1, 0, 1);
            assertTrue(target.useQuadLayout);

            source.copyTo(target, 3, 0, 1, 1);
            assertTrue(target.useQuadLayout);

            source.copyTo(target, 1, 1, 0, 2);
            assertTrue(target.useQuadLayout);

            source.copyTo(target, 10, 5, 2, 2);
            assertTrue(target.useQuadLayout);

            source.copyTo(target, 13, 8, 1, 4);
            assertTrue(target.useQuadLayout);

            source.copyTo(target, 10, 3, 4, 1);
            assertFalse(target.useQuadLayout);
            assertEquals(6, target.getIndex(10));
        }

        [Test]
        public function testCopyToWithOffset():void
        {
            var source:IndexData = new IndexData();
            source.addTriangle(1, 2, 3);
            source.addTriangle(4, 5, 6);

            var target:IndexData = new IndexData();
            target.addTriangle(7, 8, 9);
            source.copyTo(target, 1, 10, 3, 3);

            assertEquals(4, target.numIndices);
            assertEquals(7, target.getIndex(0));
            assertEquals(14, target.getIndex(1));
            assertEquals(15, target.getIndex(2));
            assertEquals(16, target.getIndex(3));
        }

        [Test]
        public function testOffsetIndices():void
        {
            var indexData:IndexData = new IndexData();
            indexData.addTriangle(1, 2, 3);
            indexData.addTriangle(4, 5, 6);

            indexData.offsetIndices(10, 1, 3);
            assertEquals( 1, indexData.getIndex(0));
            assertEquals(12, indexData.getIndex(1));
            assertEquals(13, indexData.getIndex(2));
            assertEquals(14, indexData.getIndex(3));
            assertEquals( 5, indexData.getIndex(4));
        }

        [Test]
        public function testToVector():void
        {
            var source:IndexData = new IndexData();
            source.addTriangle(1, 2, 3);
            source.addTriangle(4, 5, 6);

            var expected:Vector.<uint> = new <uint>[1, 2, 3, 4, 5, 6];
            Helpers.compareVectorsOfUints(source.toVector(), expected);
        }

        [Test]
        public function testSetIsBasicQuadData():void
        {
            var indexData:IndexData = new IndexData();
            indexData.numIndices = 6;
            assertTrue(indexData.useQuadLayout);
            assertEquals(1, indexData.getIndex(3));

            indexData.setIndex(3, 10);
            assertFalse(indexData.useQuadLayout);

            indexData.useQuadLayout = true;
            assertEquals(1, indexData.getIndex(3));

            // basic quad data must be sized correctly
            indexData.useQuadLayout = false;
            indexData.numIndices = 12;
            indexData.useQuadLayout = true;
            indexData.useQuadLayout = false;
            assertEquals(6, indexData.getIndex(11));
        }
    }
}
