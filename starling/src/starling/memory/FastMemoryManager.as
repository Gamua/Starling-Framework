package starling.memory {

import flash.system.ApplicationDomain;
import flash.utils.ByteArray;
import flash.utils.Endian;

import starling.utils.Pool;

public class FastMemoryManager {
    private static var sInstance:FastMemoryManager;

    private var _allocationController:AllocationController;
    private var _fastHeap:ByteArray;
    private var _defaultHeap:ByteArray;
    private var _heapLength:int;

    public function FastMemoryManager(size:uint) {
        super();
        if (sInstance) {
            throw new Error("DomainMemoryManager already exists.");
        }
        Pool.reserveFastByteArray(3000);

        sInstance = this;
        _defaultHeap = ApplicationDomain.currentDomain.domainMemory;
        _fastHeap = new ByteArray();
        _fastHeap.length = size;
        _fastHeap.endian = Endian.LITTLE_ENDIAN;
        _heapLength = size;
        _allocationController = new AllocationController(this);
        ApplicationDomain.currentDomain.domainMemory = _fastHeap;
    }

    public static function getInstance():FastMemoryManager {
        if (!sInstance) {
            sInstance = new FastMemoryManager(1048576); //2^20
        }
        return sInstance;
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
            if (_fastHeap.length < 10485760) {//2^21+2^23
                growHeap();
                data = _allocationController.allocate(allocationSize);
                continue;
            }
            break;
        }
        if (!data) {
            throw new Error("Could not perform allocation. MAX_HEAP_SIZE exceeded!");
        }
        return data.start;
    }

    public function reallocate(offset:uint, length:uint, newLength:uint):uint {
        if (length >= newLength) {
            return offset;
        }
        var newOffset:uint = allocate(newLength);

        if (length == 0) {
            return newOffset;
        }

        _fastHeap.position = newOffset;
        _fastHeap.writeBytes(_fastHeap, offset, length);
        freeMemory(offset);
        return newOffset;
    }

    public function freeMemory(offset:uint):void {
        _allocationController.freeMemory(offset);
    }

    private function growHeap():void {
        _heapLength *= 1.5;
        _fastHeap.length = _heapLength;
        _allocationController.growHeap();
    }

    public function get fastHeap():ByteArray {
        return _fastHeap;
    }

    public function get defaultHeap():ByteArray {
        return _defaultHeap;
    }
}
}
