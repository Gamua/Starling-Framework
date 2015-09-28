// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2015 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.utils
{
    import org.flexunit.asserts.assertEquals;

    import starling.utils.IndexData;

    import tests.Helpers;

    public class IndexDataTest
    {
        [Test]
        public function testCreate():void
        {
            var indexData:IndexData = new IndexData();
            assertEquals(0, indexData.numIndices);
        }

        [Test]
        public function testSetIndex():void
        {
            var indexData:IndexData = new IndexData();
            indexData.setIndex(0, 8);
            assertEquals(1, indexData.numIndices);
            assertEquals(8, indexData.getIndex(0));

            indexData.setIndex(2, 9);
            assertEquals(3, indexData.numIndices);
            assertEquals(8, indexData.getIndex(0));
            assertEquals(0, indexData.getIndex(1));
            assertEquals(9, indexData.getIndex(2));
        }

        [Test]
        public function testAppendTriangle():void
        {
            var indexData:IndexData = new IndexData();
            indexData.appendTriangle(1, 2, 3);
            indexData.appendTriangle(4, 5, 6);

            assertEquals(2, indexData.numTriangles);
            assertEquals(6, indexData.numIndices);

            assertEquals(1, indexData.getIndex(0));
            assertEquals(2, indexData.getIndex(1));
            assertEquals(3, indexData.getIndex(2));
            assertEquals(4, indexData.getIndex(3));
            assertEquals(5, indexData.getIndex(4));
            assertEquals(6, indexData.getIndex(5));

            indexData.numTriangles = 0;
            assertEquals(0, indexData.numIndices);
            assertEquals(0, indexData.numTriangles);
        }

        [Test]
        public function testClone():void
        {
            var indexData:IndexData = new IndexData();
            indexData.appendTriangle(1, 2, 3);
            indexData.appendTriangle(4, 5, 6);

            var clone:IndexData = indexData.clone();
            assertEquals(2, clone.numTriangles);
            assertEquals(1, clone.getIndex(0));
            assertEquals(3, clone.getIndex(2));
            assertEquals(5, clone.getIndex(4));

            clone = indexData.clone(3, 3);
            assertEquals(3, clone.numIndices);
            assertEquals(4, clone.getIndex(0));
            assertEquals(5, clone.getIndex(1));
            assertEquals(6, clone.getIndex(2));
        }

        [Test]
        public function testCopyTo():void
        {
            var source:IndexData = new IndexData();
            source.appendTriangle(1, 2, 3);
            source.appendTriangle(4, 5, 6);

            var target:IndexData = new IndexData();
            target.appendTriangle(7, 8, 9);
            source.copyTo(target, 0, 3, 3);

            assertEquals(3, target.numIndices);
            assertEquals(4, target.getIndex(0));
            assertEquals(5, target.getIndex(1));
            assertEquals(6, target.getIndex(2));

            source.copyTo(target, 3);
            assertEquals(9, target.numIndices);
        }

        [Test]
        public function testOffsetIndices():void
        {
            var indexData:IndexData = new IndexData();
            indexData.appendTriangle(1, 2, 3);
            indexData.appendTriangle(4, 5, 6);

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
            source.appendTriangle(1, 2, 3);
            source.appendTriangle(4, 5, 6);

            var expected:Vector.<uint> = new <uint>[1, 2, 3, 4, 5, 6];
            Helpers.compareVectorsOfUints(source.toVector(), expected);
        }
    }
}
