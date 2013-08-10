package starling.utils.malloc
{
	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	public class MemoryManager
	{
		public static const HEAP_GROWTH_FACTOR :Number = 1.5;
		public static const INITIAL_HEAP_SIZE :uint = 1024 * 1024;
		
		private static var mInstance :MemoryManager;

		private var mAlloc :Allocator;
		private var mHeap :ByteArray;
		
		public static function get instance () :MemoryManager {
			if (mInstance == null) {
				mInstance = new MemoryManager(INITIAL_HEAP_SIZE);
			}
			return mInstance;
		}
		
		public static function get isInitialized () :Boolean {
			return mInstance != null;
		}
		
		
		public function MemoryManager(heapSize :uint)
		{
			mHeap = new ByteArray();
			mHeap.endian = Endian.LITTLE_ENDIAN;
			mHeap.length = heapSize;
			
			mAlloc = new Allocator(this);

			ApplicationDomain.currentDomain.domainMemory = mHeap;
			mInstance = this;
		}
		
		public function dispose () :void {
			mInstance = null;
			ApplicationDomain.currentDomain.domainMemory = null;
			
			mAlloc.dispose();
			mAlloc = null;

			mHeap.clear();
			mHeap = null;			
		}

		/** This is only used in testing, should not be accessed directly.
		 * Use allocate() and free() instead. */
		public function get allocator () :Allocator {
			return mAlloc;
		}

		public function allocate (length :uint) :uint {

			var newRecord :AllocationRecord = mAlloc.allocate(length);
			if (newRecord == null) {
				// we ran out of space, or the heap is too fragmented. let's get more space
				growHeap();
				newRecord = mAlloc.allocate(length);
			}

			return newRecord.start;
		}

		private function growHeap () :void {
			mHeap.length *= HEAP_GROWTH_FACTOR;
			// need to repoint domain memory at the new heap
			ApplicationDomain.currentDomain.domainMemory = mHeap;
			// make sure to let the allocator know
			mAlloc.onHeapGrowth();
			
			// trace("HEAP GROWN TO", mHeap.length);
		}
		
		public function reallocate (oldPosition :uint, oldLength :uint, newLength :uint) :uint {
			if (oldLength >= newLength) {
				return oldPosition; // nothing to be done
			}
			
			var newPosition :uint = allocate(newLength);
			// todo: get rid of oldLength, that should come from segment records
			mHeap.position = newPosition;
			mHeap.writeBytes(mHeap, oldPosition, oldLength); // is this right?
			
			free(oldPosition);
			return newPosition;
		}
		
		public function free (pos :uint) :void {
			trace(pos);
			mAlloc.free(pos);
		}
		
		public function get heap () :ByteArray {
			return mHeap;
		}
		
		
	}
}
