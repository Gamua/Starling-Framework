package starling.utils.malloc
{
	/** This class manages allocation of subranges of a managed heap. */
	public class Allocator
	{
		/** If running in debug mode, this sentinel will be added before and after each allocated chunk. */
		private var mSentinelSize :uint = 0;
		
		/** Reference back to the memory manager */
		private var mMemory :DomainMemoryManager;
		
		public var freeList :Vector.<AllocationRecord>;
		public var usedList :Vector.<AllocationRecord>;

		public function Allocator (memory :DomainMemoryManager, sentinelsize :uint)
		{
			mMemory = memory;
			mSentinelSize = sentinelsize;
			
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
		 * splitting it if necessary. Current implementation is O(n) in the size of the free list. */
		public function allocate (size :uint) :AllocationRecord {
			var realsize :uint = size + 2 * mSentinelSize;
			
			for (var i :int = 0, len :int = freeList.length; i < len; i++) {
				var candidate :AllocationRecord = freeList[i];
				
				// do we have one that's exactly right? move it from free list to used list.
				if (candidate.size == realsize) {
					freeList.splice(i, 1);
					pushAndSort(usedList, candidate);
					return candidate;
				}
				
				// do we have a larger one that can fit this data inside it?
				// if so, split it. candidate becomes the 'leftovers' after split.
				if (candidate.size > (realsize + 2 * mSentinelSize)) { // additional 2 * sentinel for the new record
					var newrecord :AllocationRecord = new AllocationRecord(candidate.start, realsize, mSentinelSize);
					candidate.setSize(candidate.start + realsize, candidate.size - realsize, mSentinelSize);
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
				throw new Error("Invalid call to free at position " + position);
			}
			
			var item :AllocationRecord = usedList[index];
			usedList.splice(index, 1);
			pushAndSort(freeList, item);
			
			var freeListIndex :int = freeList.indexOf(item);
			attemptMerge(freeList, freeListIndex);
			attemptMerge(freeList, freeListIndex - 1);
		}
		
		/** Retrieves used node at the specified allocation position, or null if not found */
		public function findUsedNodeAt (position :uint) :AllocationRecord {
			var index :int = findIndex(usedList, position);
			return (index >= 0) ? usedList[index] : null;
		}
		
		/** Takes the last free record (if one exists), and extends it to the new heap length */
		public function onHeapGrowth () :void {
			
			var lastFreeElement :AllocationRecord = (freeList.length == 0) ? null : freeList[freeList.length - 1];
			var lastUsedElement :AllocationRecord = (usedList.length == 0) ? null : usedList[usedList.length - 1];

			// can we extend the last free node across the new heap?
			// (make sure the last free node is actually the last node in the heap)
			var shouldExtendLastFreeElement :Boolean = 
				(lastFreeElement != null && 
				 (lastUsedElement == null || lastFreeElement.nextstart > lastUsedElement.nextstart));
			
			if (shouldExtendLastFreeElement) {
				// extend the last free node
				lastFreeElement.setSize(lastFreeElement.start, mMemory.heap.length - lastFreeElement.start, mSentinelSize);
				return; // EARLY RETURN!
			}
			
			// we're going to add a new free node
			var start :uint, length :uint;
			
			if (lastUsedElement != null) {
				// the old heap ended on a used node. this is not likely, but let's deal with it
				start = lastUsedElement.nextstart;
				
			} else {
				// both used and free lists are empty, we're initializing for the first time
				start = 0;
			}

			length = mMemory.heap.length - start;
			pushAndSort(freeList, new AllocationRecord(start, length, mSentinelSize));
		}
		
		/** Given a free or used list, and a starting memory range position, returns the array index of the 
		 * allocation record for that starting position. O(n) in list size. */
		private function findIndex (list :Vector.<AllocationRecord>, startpos :uint) :uint {
			for (var i :int = 0, len :int = list.length; i < len; i++) {
				if (list[i].datastart == startpos) {
					return i;
				}
			}
			
			return -1;
		}
		
		/** Appends the specified element to the end of the list, and then bubbles it up
		 * towards the beginning, to ensure that all records are sorted by their start field. O(n) in list size. */
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

		/** Takes a free list, and an index to an element in that list. Attempts first to merge
		 * items at index and index+1, then items at index-1 and index. Merge will happen if
		 * the first and second items are exactly adjacent. */
		private function attemptMerge (list :Vector.<AllocationRecord>, index :uint) :void {
			if (index < 0 || index >= (list.length - 1)) {
				return; // not possible
			}
			
			var first :AllocationRecord = list[index];
			var second :AllocationRecord = list[index + 1];
			if (first.nextstart == second.start) {
				// merge these two by getting rid of the second one
				first.setSize(first.start, first.size + second.size, mSentinelSize);
				list.splice(index + 1, 1);
			}
		}
	}
}