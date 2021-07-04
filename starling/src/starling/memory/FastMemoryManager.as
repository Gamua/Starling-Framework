package starling.memory {

import flash.system.ApplicationDomain;
import flash.utils.ByteArray;
import flash.utils.Dictionary;
import flash.utils.Endian;

import avm2.intrinsics.memory.li8;
import avm2.intrinsics.memory.li32;
import avm2.intrinsics.memory.si8;
import avm2.intrinsics.memory.si32;

import starling.utils.FastMemoryPool;

public class FastMemoryManager {
    private static var sInstance:FastMemoryManager;

    public static function getInstance():FastMemoryManager {
        if (!sInstance) {
            sInstance = new FastMemoryManager(1048576); //1MB
        }
        return sInstance;
    }

    public static function copyHeapContent(targetHeapOffset:int, sourceHeapOffset:uint, length:uint):void {
        var fastHeap:ByteArray=FastMemoryManager.sInstance._fastHeap;
        fastHeap.position = targetHeapOffset;
        fastHeap.writeBytes(fastHeap, sourceHeapOffset, length);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    private var _fastByteArrays:Dictionary;
    private var _allocationController:AllocationController;
    private var _fastHeap:ByteArray;
    private var _defaultHeap:ByteArray;

    private var _heapLength:int;

    public function FastMemoryManager(size:uint) {
        if (sInstance) {
            throw new Error("DomainMemoryManager already exists.");
        }
        FastMemoryPool.reserveFastByteArray(3000);

        _fastByteArrays = new Dictionary();
        _defaultHeap = ApplicationDomain.currentDomain.domainMemory;
        _fastHeap = new ByteArray();
        _fastHeap.length = size;
        _fastHeap.endian = Endian.LITTLE_ENDIAN;
        _heapLength = size;
        _allocationController = new AllocationController(_fastHeap);
        ApplicationDomain.currentDomain.domainMemory = _fastHeap;
    }

    public function get fastHeap():ByteArray {
        return _fastHeap;
    }

    public function get defaultHeap():ByteArray {
        return _defaultHeap;
    }

    public function switchToFastHeap():void {
        ApplicationDomain.currentDomain.domainMemory = _fastHeap;
    }

    public function switchToDefaultHeap():void {
        ApplicationDomain.currentDomain.domainMemory = _defaultHeap;
    }

    public function allocate(allocationSize:uint):uint {
        if (allocationSize == 0) {
            throw new Error("Cannot perform empty allocation!");
        }

        var data:AllocationData = _allocationController.allocate(allocationSize);
        while (!data) {
            if (_fastHeap.length < 10485760) {//10MB
                growHeap();
                data = _allocationController.allocate(allocationSize);
                continue;
            }
            break;
        }

        if (!data) {
            var defragmentationMap:Dictionary = _allocationController.defragment();
            for each(var fba:FastByteArray in _fastByteArrays) {
                fba.updateOffset(defragmentationMap[fba.offset]);
            }

            data = _allocationController.allocate(allocationSize);

            if (data == null) {
                throw new Error("Could not perform allocation. MAX_HEAP_SIZE exceeded!");
            }
        }
        return data.start;
    }

    public function reallocate(fastByteArray:FastByteArray, newLength:uint):uint {
        var length:uint = fastByteArray.length;
        if (length >= newLength) {
            return fastByteArray.offset;
        }

        var newOffset:uint = allocate(newLength);

        //oldOffset can be changed as a result of defragmentation in allocate();
        var oldOffset:uint = fastByteArray.offset;

        if (length != 0) {
            copyHeapContent(newOffset, oldOffset, length);
        }

        freeMemory(oldOffset);
        return newOffset;
    }

    public function freeMemory(offset:uint):void {
        _allocationController.freeMemory(offset);
    }


    public function addFastByteArray(fastByteArray:FastByteArray):void {
        _fastByteArrays[fastByteArray] = 1;
    }

    public function removeFastByteArray(fastByteArray:FastByteArray):void {
        delete _fastByteArrays[fastByteArray];
    }

    private function growHeap():void {
        _heapLength *= 1.5;
        _fastHeap.length = _heapLength;
        _allocationController.growHeap();
    }
}
}
