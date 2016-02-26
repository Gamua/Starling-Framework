// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.utils
{
    import org.flexunit.asserts.assertEquals;

    import starling.utils.ArrayUtil;

    import tests.Helpers;

    public class ArrayUtilTest
    {
        [Test]
        public function testInsertAt():void
        {
            var array:Array;

            array = createArray();
            ArrayUtil.insertAt(array, 7, 'x');
            Helpers.compareArrays(array, ['a', 'b', 'c', 'd', null, null, null, 'x']);

            array = createArray();
            ArrayUtil.insertAt(array, 0, 'x');
            Helpers.compareArrays(array, ['x', 'a', 'b', 'c', 'd']);

            array = createArray();
            ArrayUtil.insertAt(array, 4, 'x');
            Helpers.compareArrays(array, ['a', 'b', 'c', 'd', 'x']);

            array = createArray();
            ArrayUtil.insertAt(array, 5, 'x');
            Helpers.compareArrays(array, ['a', 'b', 'c', 'd', null, 'x']);

            array = createArray();
            ArrayUtil.insertAt(array, 3, 'x');
            Helpers.compareArrays(array, ['a', 'b', 'c', 'x', 'd']);

            array = createArray();
            ArrayUtil.insertAt(array, -1, 'x');
            Helpers.compareArrays(array, ['a', 'b', 'c', 'd', 'x']);

            array = createArray();
            ArrayUtil.insertAt(array, -2, 'x');
            Helpers.compareArrays(array, ['a', 'b', 'c', 'x', 'd']);

            array = createArray();
            ArrayUtil.insertAt(array, -100, 'x');
            Helpers.compareArrays(array, ['x', 'a', 'b', 'c', 'd']);
        }

        [Test]
        public function testRemoveAt():void
        {
            var array:Array;
            var retVal:Object;

            array = createArray();
            retVal = ArrayUtil.removeAt(array, 0);
            Helpers.compareArrays(array, ['b', 'c', 'd']);
            assertEquals(retVal, 'a');

            array = createArray();
            retVal = ArrayUtil.removeAt(array, 3);
            Helpers.compareArrays(array, ['a', 'b', 'c']);
            assertEquals(retVal, 'd');

            array = createArray();
            retVal = ArrayUtil.removeAt(array, 4);
            Helpers.compareArrays(array, ['a', 'b', 'c']);
            assertEquals(retVal, 'd');

            array = createArray();
            retVal = ArrayUtil.removeAt(array, 1);
            Helpers.compareArrays(array, ['a', 'c', 'd']);
            assertEquals(retVal, 'b');

            array = createArray();
            retVal = ArrayUtil.removeAt(array, -1);
            Helpers.compareArrays(array, ['a', 'b', 'c']);
            assertEquals(retVal, 'd');

            array = createArray();
            retVal = ArrayUtil.removeAt(array, -100);
            Helpers.compareArrays(array, ['b', 'c', 'd']);
            assertEquals(retVal, 'a');

            array = createArray();
            retVal = ArrayUtil.removeAt(array, 100);
            Helpers.compareArrays(array, ['a', 'b', 'c']);
            assertEquals(retVal, 'd');
        }

        private function createArray():Array
        {
            return ['a', 'b', 'c', 'd'];
        }
    }
}
