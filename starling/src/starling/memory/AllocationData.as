package starling.memory {
public class AllocationData {

    private var _start:uint;
    private var _size:uint;

    public function AllocationData(start:uint = 0, size:uint = 0) {
        setSize(start, size);
    }

    public function setSize(start:uint, size:uint):void {
        _start = start;
        _size = size;
    }

    public function get nextStart():uint {
        return _start + _size;
    }

    public function get start():uint {
        return _start;
    }

    public function get size():uint {
        return _size;
    }
}
}
