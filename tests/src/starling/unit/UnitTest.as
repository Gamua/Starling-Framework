package starling.unit
{
    import flash.utils.describeType;
    import flash.utils.getQualifiedClassName;
    import flash.geom.Rectangle;
    import flash.geom.Point;
    import flash.geom.Vector3D;
    import flash.utils.ByteArray;
    import flash.geom.Matrix;

    public class UnitTest
    {
        private var _assertFunction:Function;

        public function UnitTest()
        { }

        public function setUp():void
        { }

        public function setUpAsync(onComplete:Function):void
        {
            onComplete();
        }

        public function tearDown():void
        { }

        public function tearDownAsync(onComplete:Function):void
        {
            onComplete();
        }

        // basic assert methods

        protected function assert(condition:Boolean, message:String=null):void
        {
            if (_assertFunction != null)
                _assertFunction(condition, message);
        }

        protected function assertTrue(condition:Boolean, message:String=null):void
        {
            assert(condition, message);
        }

        protected function assertFalse(condition:Boolean, message:String=null):void
        {
            assert(!condition, message);
        }

        protected function assertEqual(objectA:Object, objectB:Object, message:String=null):void
        {
            assert(objectA == objectB, message);
        }

        protected function assertEqualObjects(objectA:Object, objectB:Object, message:String=null):void
        {
            assert(compareObjects(objectA, objectB), message);
        }

        protected function assertEquivalent(numberA:Number, numberB:Number,
                                             e:Number=0.0001, message:String=null):void
        {
            assert(numberA - e < numberB && numberA + e > numberB, message);
        }

        protected function assertNull(object:Object, message:String=null):void
        {
            assert(object == null, message);
        }

        protected function assertNotNull(object:Object, message:String=null):void
        {
            assert(object != null, message);
        }

        protected function assertThrows(block:Function, errorType:Class=null, message:String=null):void
        {
            try {
                block();
            }
            catch (e:Error)
            {
                assert(e is (errorType || Error), message);
                return;
            }
            assert(false, message);
        }

        protected function assertDoesNotThrow(block:Function):void
        {
            try
            {
                block();
            }
            catch (e:Error)
            {
                fail("Error thrown: " + e.message);
            }
        }

        protected function fail(message:String):void
        {
            assert(false, message);
        }

        protected function succeed(message:String):void
        {
            assert(true, message);
        }

        internal function get assertFunction():Function { return _assertFunction; }
        internal function set assertFunction(value:Function):void { _assertFunction = value; }

        // more specific assert methods

        protected function assertEqualRectangles(rect1:Rectangle, rect2:Rectangle,
                                                 e:Number=0.0001):void
        {
            assertEquivalent(rect1.x, rect2.x, e);
            assertEquivalent(rect1.y, rect2.y, e);
            assertEquivalent(rect1.width, rect2.width, e);
            assertEquivalent(rect1.height, rect2.height, e);
        }

        protected function assertEqualPoints(point1:Point, point2:Point, e:Number=0.0001):void
        {
            assertEquivalent(point1.x, point2.x, e);
            assertEquivalent(point1.y, point2.y, e);
        }

        protected function assertEqualVector3Ds(v1:Vector3D, v2:Vector3D, e:Number=0.0001):void
        {
            assertEquivalent(v1.x, v2.x, e);
            assertEquivalent(v1.y, v2.y, e);
            assertEquivalent(v1.z, v2.z, e);
            assertEquivalent(v1.w, v2.w, e);
        }

        protected function assertEqualArrays(array1:Array, array2:Array):void
        {
            assertEqual(array1.length, array2.length);

            for (var i:int=0; i<array1.length; ++i)
                assertEqual(array1[i], array2[i]);
        }

        protected function assertEqualVectorsOfNumbers(vector1:Vector.<Number>, vector2:Vector.<Number>,
                                              e:Number=0.0001):void
        {
            assertEqual(vector1.length, vector2.length);

            for (var i:int=0; i<vector1.length; ++i)
                assertEquivalent(vector1[i], vector2[i], e);
        }

        protected function assertEqualVectorsOfUints(vector1:Vector.<uint>, vector2:Vector.<uint>):void
        {
            assertEqual(vector1.length, vector2.length);

            for (var i:int=0; i<vector1.length; ++i)
                assertEqual(vector1[i], vector2[i]);
        }

        protected function assertEqualByteArrays(b1:ByteArray, b2:ByteArray):void
        {
            assertEqual(b1.endian, b2.endian);
            assertEqual(b1.length, b2.length);
            b1.position = b2.position = 0;

            while (b1.bytesAvailable)
                assertEqual(b1.readByte(), b2.readByte());
        }

        protected function assertEqualByteArraysOfFloats(b1:ByteArray, b2:ByteArray, e:Number=0.0001):void
        {
            assertEqual(b1.endian, b2.endian);
            assertEqual(b1.length, b2.length);
            b1.position = b2.position = 0;

            while (b1.bytesAvailable)
                assertEquivalent(b1.readFloat(), b2.readFloat(), e);
        }

        protected function assertEqualMatrices(matrix1:Matrix, matrix2:Matrix, e:Number=0.0001):void
        {
            assertEquivalent(matrix1.a,  matrix2.a, e);
            assertEquivalent(matrix1.b,  matrix2.b, e);
            assertEquivalent(matrix1.c,  matrix2.c, e);
            assertEquivalent(matrix1.d,  matrix2.d, e);
            assertEquivalent(matrix1.tx, matrix2.tx, e);
            assertEquivalent(matrix1.ty, matrix2.ty, e);
        }

        // helpers

        private function compareObjects(objectA:Object, objectB:Object):Boolean
        {
            if (objectA is int || objectA is uint || objectA is Number || objectA is Boolean)
                return objectA === objectB;
            else if (objectA is Date && objectB is Date)
                return objectA.time - 500 < objectB.time && objectA.time + 500 > objectB.time;
            else
            {
                var nameA:String = getQualifiedClassName(objectA);
                var nameB:String = getQualifiedClassName(objectB);
                var prop:String;

                if (nameA != nameB) return false;

                if (objectA is Array || nameA.indexOf("__AS3__.vec::Vector.") == 0)
                {
                    if (objectA.length != objectB.length) return false;

                    for (var i:int=0; i<objectA.length; ++i)
                        if (!compareObjects(objectA[i], objectB[i])) return false;
                }

                // we can iterate like this through 'Object', 'Array' and 'Vector'
                for (prop in objectA)
                {
                    if (!objectB.hasOwnProperty(prop)) return false;
                    else if (!compareObjects(objectA[prop], objectB[prop])) return false;
                }

                // other classes need to be iterated through with the type description
                var typeDescription:XML = describeType(objectA);
                for each (var accessor:XML in typeDescription.accessor)
                {
                    prop = accessor.@name.toString();
                    if (!compareObjects(objectA[prop], objectB[prop])) return false;
                }

                return true;
            }
        }
    }
}