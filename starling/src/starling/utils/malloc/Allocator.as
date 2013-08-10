package starling.utils.malloc
{
	public class Allocator
	{
		private var mMemory :MemoryManager;
		
		public var freeList :Vector.<AllocationRecord>;
		public var usedList :Vector.<AllocationRecord>;

		public function Allocator (memory :MemoryManager)
		{
			mMemory = memory;
			freeList = new <AllocationRecord> [ ];
			usedList = new <AllocationRecord> [ ];
			onHeapGrowth();
		}
		
		public function dispose () :void {
			freeList = null;
			usedList = null;
			mMemory = null;
		}
		
		/** Allocates a new element from the free list, taking the first element of sufficient size,
		 * splitting it if necessary. */
		public function allocate (size :uint) :AllocationRecord {
			for (var i :int = 0, len :int = freeList.length; i < len; i++) {
				var candidate :AllocationRecord = freeList[i];
				
				if (candidate.length == size) {
					// found one that's exactly right, move it from free list to used list
					freeList.splice(i, 1);
					pushAndSort(usedList, candidate);
					return candidate;
				}
				
				if (candidate.length > size) {
					// found a larger one, split it. candidate becomes the 'leftovers' after split
					var newrecord :AllocationRecord = new AllocationRecord(candidate.start, size);
					candidate.start += size;
					candidate.length -= size;
					pushAndSort(usedList, newrecord);
					return newrecord;
				}
			}
			
			// we don't have enough space! abandon all hope 
			return null;
		}
		
		/** Frees the specified range by moving it to the free list (does not actually clear the data).
		 * Current implementation is O(n) in the size of the used list. */
		public function free (position :uint) :void {
			var index :int = findIndex(usedList, position);
			if (index < 0) {
				throw new Error("Invalid call to free at position" + position);
			}
			
			var item :AllocationRecord = usedList[index];
			usedList.splice(index, 1);
			pushAndSort(freeList, item);
			
			var freeListIndex :int = freeList.indexOf(item);
			attemptMerge(freeList, freeListIndex);
			attemptMerge(freeList, freeListIndex - 1);
		}
		
		/** Takes the last free record (if one exists), and extends it to the new heap length */
		public function onHeapGrowth () :void {
			var lastFreeElement :AllocationRecord = (freeList.length == 0) ? null : freeList[freeList.length - 1];
			
			if (lastFreeElement != null) {
				// extend the last free element
				lastFreeElement.length = mMemory.heap.length - lastFreeElement.start;
				return; // EARLY RETURN!
			}
			
			// we're going to add a new free node
			
			var start :uint, length :uint;
			if (usedList.length > 0) {
				// the heap is completely full. this is not likely, but let's deal with it
				var lastUsedElement :AllocationRecord = usedList[usedList.length - 1];
				start = lastUsedElement.start + lastUsedElement.length;
				
			} else {
				// both used and free lists are empty, we're initializing for the first time
				start = 0;
			}

			length = mMemory.heap.length - start;
			pushAndSort(freeList, new AllocationRecord(start, length));
		}
		
		private function findIndex (list :Vector.<AllocationRecord>, startpos :uint) :uint {
			for (var i :int = 0, len :int = list.length; i < len; i++) {
				if (list[i].start == startpos) {
					return i;
				}
			}
			
			return -1;
		}
		
		private function pushAndSort (list :Vector.<AllocationRecord>, element :AllocationRecord) :void {
			list[list.length] = element;
			if (list.length < 2) {
				return;
			}

			for (var i :int = list.length - 2; i >= 0; i--) {
				var first :AllocationRecord = list[i];
				var second :AllocationRecord = list[i + 1];
				if (first.start < second.start) {
					return; // we're done
				}
				
				// otherwise swap them and continue
				list[i + 1] = first;
				list[i] = second;
			}
		}
		
		private function attemptMerge (list :Vector.<AllocationRecord>, index :uint) :void {
			if (index < 0 || index >= (list.length - 1)) {
				return; // not possible
			}
			
			var first :AllocationRecord = list[index];
			var second :AllocationRecord = list[index + 1];
			if ((first.start + first.length) == second.start) {
				// merge these two by getting rid of the second one
				first.length += second.length;
				list.splice(index + 1, 1);
			}
		}
	}
}