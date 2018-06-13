package starling.memory {

import flash.utils.ByteArray;
import flash.utils.Dictionary;

import starling.utils.FastMemoryPool;


public class AllocationController {
    private static function findIndex(dataList:Vector.<AllocationData>, offset:uint):int {
        var low:int = 0;
        var high:int = dataList.length - 1;

        while (low <= high) {
            var mid:int = int((low + high) * 0.5);
            var value:int = dataList[mid].start;

            if (value < offset) {
                low = mid + 1;
            }
            else if (value > offset) {
                high = mid - 1;
            }
            else {
                return mid;
            }
        }
        return -1;
    }

    private static function pushAndSort(list:Vector.<AllocationData>, data:AllocationData):int {
        var low:int = 0;
        var listLength:int = list.length;
        var high:int = listLength - 1;
        var pos:int = data.start;

        if (list.length == 0 || data.start > list[high].start) {
            list[listLength] = data;
            return listLength;
        }

        while (low <= high) {
            var mid:int = int((low + high) * 0.5);
            var value:int = list[mid].start;

            if (value < pos) {
                low = mid + 1;
            }
            else if (value > pos) {
                high = mid - 1;
            }
        }

        list.insertAt(low, data);
        return low;
    }

    private static function attemptMerge(dataList:Vector.<AllocationData>, index:int):void {
        if (index < 0 || index >= dataList.length - 1) {
            return;
        }
        var data1:AllocationData = dataList[index];
        var data2:AllocationData = dataList[int(index + 1)];
        if (data1.nextStart == data2.start) {
            data1.setSize(data1.start, data1.size + data2.size);
            FastMemoryPool.putAllocationData(dataList[index + 1]);
            dataList.removeAt(index + 1);
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    private var _fastHeap:ByteArray;
    private var _freeList:Vector.<AllocationData>;
    private var _usedList:Vector.<AllocationData>;


    public function AllocationController(fastHeap:ByteArray) {
        super();
        FastMemoryPool.reserveAllocationData(30000);
        _fastHeap = fastHeap;
        _freeList = new <AllocationData>[];
        _usedList = new <AllocationData>[];
        growHeap();
    }

    public function defragment():Dictionary {
        var startPosition:int = 0;
        var defragmentationMap:Dictionary = new Dictionary();
        for (var i:int = 0, i_len:int = _usedList.length; i < i_len; ++i) {
            var usedItem:AllocationData = _usedList[i];
            defragmentationMap[usedItem.start] = startPosition;
            if (usedItem.start != startPosition) {
                FastMemoryManager.copyHeapContent(startPosition, usedItem.start, usedItem.size);
                usedItem.setSize(startPosition, usedItem.size);
            }
            startPosition = usedItem.nextStart;
        }

        for (var j:int = 0, j_len:int = _freeList.length; j < j_len; j++) {
            FastMemoryPool.putAllocationData(_freeList[j]);
        }

        _freeList.length = 0;
        growHeap();
        return defragmentationMap;
    }

    public function allocate(allocationSize:uint):AllocationData {
        var i:int = 0;
        var freeListLength:int = _freeList.length;

        while (i < freeListLength) {
            var candidate:AllocationData = _freeList[i];
            if (candidate.size == allocationSize) {
                _freeList.removeAt(i);
                pushAndSort(_usedList, candidate);
                return candidate;
            }
            if (candidate.size > allocationSize) {
                var newData:AllocationData = FastMemoryPool.getAllocationData();
                newData.setSize(candidate.start, allocationSize);
                candidate.setSize(candidate.start + allocationSize, candidate.size - allocationSize);
                pushAndSort(_usedList, newData);
                return newData;
            }
            ++i;
        }
        return null;
    }

    public function freeMemory(offset:uint):void {
        var index:int = findIndex(_usedList, offset);
        if (index == -1) {
            throw new Error("[ERROR] Illegal attempt to free not used allocation at offset:", offset);
        }

        index = pushAndSort(_freeList, _usedList.removeAt(index) as AllocationData);
        attemptMerge(_freeList, index);
        attemptMerge(_freeList, index - 1);
    }

    public function growHeap():void {
        var lastFreeData:AllocationData = _freeList.length == 0 ? null : _freeList[int(_freeList.length - 1)];
        var lastUsedData:AllocationData = _usedList.length == 0 ? null : _usedList[int(_usedList.length - 1)];

        if (lastFreeData && (!lastUsedData || lastFreeData.nextStart > lastUsedData.nextStart)) {
            lastFreeData.setSize(lastFreeData.start, _fastHeap.length - lastFreeData.start);
            return;
        }

        var start:uint = lastUsedData ? lastUsedData.nextStart : 0;
        pushAndSort(_freeList, new AllocationData(start, _fastHeap.length - start));
    }

}
}
