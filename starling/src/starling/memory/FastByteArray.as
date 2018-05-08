package starling.memory {

import flash.utils.ByteArray;

import starling.utils.Pool;


public class FastByteArray {
    public static function create(length:int):FastByteArray {
        var out:FastByteArray = Pool.getFastByteArray();
        reset(out, length);
        return out;
    }

    protected static function reset(out:FastByteArray, length:int):void {
        out._fastMemoryManager = FastMemoryManager.getInstance();
        out._bytes = out._fastMemoryManager.fastHeap;
        out.allocate(length);
        out._disposed = false;
    }

    public static function switchMemory(fastByteArray1:FastByteArray, fastByteArray2:FastByteArray):void {
        if (fastByteArray1._disposed || fastByteArray2._disposed) {
            throw new Error("[ERROR] Can't switch memory when FastByteArray is disposed.")
        }
        var tempUInt:uint = fastByteArray1._offset;
        fastByteArray1._offset = fastByteArray2._offset;
        fastByteArray2._offset = tempUInt;

        tempUInt = fastByteArray1._length;
        fastByteArray1._length = fastByteArray2._length;
        fastByteArray2._length = tempUInt;

        tempUInt = fastByteArray1._allocatedMemoryLength;
        fastByteArray1._allocatedMemoryLength = fastByteArray2._allocatedMemoryLength;
        fastByteArray2._allocatedMemoryLength = tempUInt;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    protected var _bytes:ByteArray;
    protected var _offset:uint;
    protected var _length:uint;


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
        return _bytes;
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
            _offset = _fastMemoryManager.reallocate(_offset, _length, newLength);
            _allocatedMemoryLength = newLength;
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
        _bytes = null;
        _offset = 0;
        _length = 0;
        _allocatedMemoryLength = 0;
        _fastMemoryManager = null;
        _disposed = true;
        Pool.putFastByteArray(this);
    }

    public final function clear():void {
        _allocatedMemoryLength = 0;
        _length = 0;
    }

    private function allocate(length:uint):void {
        if (length < 4) {
            length = 4;
        }
        _offset = _fastMemoryManager.allocate(length);
        _allocatedMemoryLength = length;
        _length = length;
    }


}
}
