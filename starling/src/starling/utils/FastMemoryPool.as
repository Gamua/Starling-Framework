// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.utils
{
    import flash.geom.Matrix;
    import flash.geom.Matrix3D;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.geom.Vector3D;

    import starling.errors.AbstractClassError;
    import starling.memory.AllocationData;
    import starling.memory.FastByteArray;

    /** A simple object pool supporting the most basic utility objects.
     *
     *  <p>If you want to retrieve an object, but the pool does not contain any more instances,
     *  it will silently create a new one.</p>
     *
     *  <p>It's important that you use the pool in a balanced way, i.e. don't just "get" or "put"
     *  alone! Always make the calls in pairs; whenever you get an object, be sure to put it back
     *  later, and the other way round. Otherwise, the pool will empty or (even worse) grow
     *  in size uncontrolled.</p>
     */
    public class FastMemoryPool
    {
        private static var sFastByteArray:Vector.<FastByteArray> = new <FastByteArray>[];
        private static var sAllocationData:Vector.<AllocationData> = new <AllocationData>[];


        /** @private */
        public function FastMemoryPool() { throw new AbstractClassError(); }

        public static  function reserveFastByteArray(newSize:int):void{
            var oldSize:int = sFastByteArray.length;
            if (newSize > oldSize) {
                for (var i:int = oldSize; i < newSize; ++i) {
                    sFastByteArray.push(new FastByteArray());
                }
            }
        }

        public static function getFastByteArray():FastByteArray{
            if (sFastByteArray.length == 0){
                return new FastByteArray();
            }else{
                return sFastByteArray.pop();
            }
        }

        public static function putFastByteArray(fastByteArray:FastByteArray):void{
            if (fastByteArray) sFastByteArray[sFastByteArray.length] = fastByteArray;
        }

        public static  function reserveAllocationData(newSize:int){
            var oldSize:int = sAllocationData.length;
            if (newSize > oldSize) {
                for (var i:int = oldSize; i < newSize; ++i) {
                    sAllocationData.push(new AllocationData());
                }
            }
        }

        public static function getAllocationData():AllocationData{
            if (sAllocationData.length == 0){
                return new AllocationData();
            }else{
                return sAllocationData.pop();
            }
        }

        public static function putAllocationData(allocationData:AllocationData):void{
            if (allocationData) sAllocationData[sAllocationData.length] = allocationData;
        }
    }
}
