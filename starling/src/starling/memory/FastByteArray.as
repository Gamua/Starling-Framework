package starling.memory {

import flash.utils.ByteArray;

import starling.utils.FastMemoryPool;


public class FastByteArray {
    public static function create(length:int, owner:IHeapOwner = null):FastByteArray {
        var out:FastByteArray = FastMemoryPool.getFastByteArray();
        reset(out, length, owner);
        return out;
    }

    protected static function reset(out:FastByteArray, length:int, owner:IHeapOwner):void {
        var fastMemoryManager:FastMemoryManager = out._fastMemoryManager = FastMemoryManager.getInstance();
        out._owner = owner;
        out._heap = fastMemoryManager.fastHeap;
        out.allocate(length);
        out._disposed = false;
        fastMemoryManager.addFastByteArray(out);
    }

    public static function switchMemory(fastByteArray1:FastByteArray, fastByteArray2:FastByteArray):void {
        if (fastByteArray1._disposed || fastByteArray2._disposed) {
            throw new Error("[ERROR] Can't switch memory when FastByteArray is disposed.")
        }
        var tempUInt:uint = fastByteArray1._offset;
        fastByteArray1.updateOffset(fastByteArray2._offset);
        fastByteArray2.updateOffset(tempUInt);

        tempUInt = fastByteArray1._length;
        fastByteArray1._length = fastByteArray2._length;
        fastByteArray2._length = tempUInt;

        tempUInt = fastByteArray1._allocatedMemoryLength;
        fastByteArray1._allocatedMemoryLength = fastByteArray2._allocatedMemoryLength;
        fastByteArray2._allocatedMemoryLength = tempUInt;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    protected var _heap:ByteArray;
    protected var _offset:uint;
    protected var _length:uint;
    protected var _owner:IHeapOwner;


    private var _disposed:Boolean;
    private var _fastMemoryManager:FastMemoryManager;
    private var _allocatedMemoryLength:uint;

    public function FastByteArray() {
        super();
    }

    public final function get offset():uint {
        return _offset;
    }

    public final function get heap():ByteArray {
        return _heap;
    }

    public function get length():uint {
        return _length;
    }

    public final function set length(value:uint):void {
        if (_allocatedMemoryLength > 0) {
            resize(value);
            _length = value;
        } else {
            allocate(value)
        }
    }

    public final function resize(newLength:uint):void {
        if (newLength > _allocatedMemoryLength) {
            _allocatedMemoryLength = newLength;
            updateOffset(_fastMemoryManager.reallocate(this, newLength))
        }
    }

    public final function getHeapAddress(addr:uint = 0):uint {
        return _offset + addr;
    }

    public final function dispose():void {
        if (_disposed) {
            return;
        }
        _fastMemoryManager.freeMemory(_offset);
        _fastMemoryManager.removeFastByteArray(this);
        _heap = null;
        _offset = 0;
        _length = 0;
        _allocatedMemoryLength = 0;
        _fastMemoryManager = null;
        _owner = null;
        _disposed = true;
        FastMemoryPool.putFastByteArray(this);
    }

    public final function clear():void {
        _length = 0;
    }

    public function updateOffset(newOffset:int):void {
        _offset = newOffset;
        if (_owner) {
            _owner.updateHeapOffset(_offset);
        }
    }

    private function allocate(length:uint):void {
        if (length < 4) {
            length = 4;
        }
        _allocatedMemoryLength = length;
        _length = length;
        updateOffset(_fastMemoryManager.allocate(length));
    }
}
}
