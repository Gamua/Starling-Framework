package starling.utils.malloc
{
	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import avm2.intrinsics.memory.li32;
	import avm2.intrinsics.memory.si32;

	/**
	 * Manages a domain memory heap, from which the user can request specific sub-ranges
	 * using a call to allocate(), and release them with a call to free().
	 * 
	 * <p> Since the domain memory always points at this heap, client code can use
	 * fast memory access intrinsics (in the avm2.intrinsics.memory namespace) to access it.
	 */
	public class DomainMemoryManager
	{
		public static const DEFAULT_DEBUG_OPTION :Boolean = false;
		
		public static const HEAP_GROWTH_FACTOR :Number = 1.5;
		public static const INITIAL_HEAP_SIZE :uint = 1024 * 1024;
		
		private static var mInstance :DomainMemoryManager;

		/** Debug mode? */
		private var mDebug :Boolean;
		
		private var mAlloc :Allocator;
		private var mHeap :ByteArray;
		
		/** Returns an instance to the singleton DomainMemoryManager, creating one if needed. */
		public static function get instance () :DomainMemoryManager {
			if (mInstance == null) {
				mInstance = new DomainMemoryManager(INITIAL_HEAP_SIZE, DEFAULT_DEBUG_OPTION);
			}
			return mInstance;
		}
		
		/** Returns true if a singleton instance of DomainMemoryManager has been created. */
		public static function get isInitialized () :Boolean {
			return mInstance != null;
		}
		
		/** Creates a new instance of the domain memory manager, with specified initial heap size 
		 * (which will be scaled up automatically if needed). Also registers this instance
		 * as the global singleton instance. */
		public function DomainMemoryManager (heapSize :uint, debug :Boolean)
		{
			if (isInitialized) {
				throw new Error("DomainMemoryManager singleton instance already exists! Dispose it first.");
			}
		
			mDebug = debug;
			
			mHeap = new ByteArray();
			mHeap.endian = Endian.LITTLE_ENDIAN;
			mHeap.length = heapSize;
			
			mAlloc = new Allocator(this, (debug ? 4 : 0));

			ApplicationDomain.currentDomain.domainMemory = mHeap;
			
			mInstance = this;
		}
		
		/** Releases heap memory and destroys the global singleton instance */
		public function dispose () :void {
			mInstance = null;
			ApplicationDomain.currentDomain.domainMemory = null;
			
			mAlloc.dispose();
			mAlloc = null;

			mHeap.clear();
			mHeap = null;			
		}

		/** Is this running in debug mode? If so, sentinels will be added around allocation records */
		public function get debug () :Boolean { return mDebug; }
		
		/** Getter for the byte array that contains the entire heap. Use with caution! */
		public function get heap () :ByteArray { return mHeap; }

		/** This is only used in testing, should not be accessed directly. Use allocate() and free() instead. */
		public function get allocator () :Allocator { return mAlloc; }

		/** Allocates a memory range of given length in bytes, and returns its starting index
		 * in the heap. It's the caller's responsibility to not access bytes outside the range
		 * [index, index+length), and to call free(index) after this memory range is no longer needed. */
		public function allocate (length :uint) :uint {
			if (length == 0) {
				throw new Error("Cannot perform empty allocation!");
			}

			var newRecord :AllocationRecord = mAlloc.allocate(length);
			if (newRecord == null) {
				// we ran out of space, or the heap is too fragmented. let's get more space
				growHeap();
				newRecord = mAlloc.allocate(length);
			}

			// if in debug mode, set up sentinels
			if (mDebug) {
				addSentinels(newRecord);
			}
			
			return newRecord.datastart;
		}

		/** Helper function, extends the heap if it's been exhausted (whether to usage or fragmentation) */
		private function growHeap () :void {
			mHeap.length *= HEAP_GROWTH_FACTOR;
			// need to repoint domain memory at the new heap
			ApplicationDomain.currentDomain.domainMemory = mHeap;
			// make sure to let the allocator know
			mAlloc.onHeapGrowth();
			
			// trace("HEAP GROWN TO", mHeap.length);
		}
		
		/** Helper function: takes an old allocation, and a new desired size, and returns a new index
		 * to the new memory range. Data from the old range will be copied to the new one automatically.
		 * If the new range is equal size or smaller, this function call will actually be a no-op 
		 * (it will not truncate the byte range or allocate a new one) */
		public function reallocate (oldPosition :uint, oldLength :uint, newLength :uint) :uint {
			if (oldLength >= newLength) {
				return oldPosition; // nothing to be done
			}
			
			var newPosition :uint = allocate(newLength);
			if (oldLength == 0) {
				return newPosition; // no need for copies
			}

			mHeap.position = newPosition;
			mHeap.writeBytes(mHeap, oldPosition, oldLength); // is this right?
			
			free(oldPosition);
			return newPosition;
		}
		
		/** Releases the memory range starting at given index for future use.
		 * Note that released memory will not be set to null or otherwise manipulated. */
		public function free (position :uint) :void {
			if (mDebug) {
				var item :AllocationRecord = mAlloc.findUsedNodeAt(position);
				if (item != null) {
					checkSentinels(item);
				}
			}
			
			mAlloc.free(position);
		}	
		
		/** Adds sentinels before and after */
		private function addSentinels (rec :AllocationRecord) :void {
			si32(0xcccccccc, rec.start);
			si32(0xcdcdcdcd, rec.start + rec.size - 4); 
		}
		
		/** Checks sentinels to make sure they didn't get overwritten */
		private function checkSentinels (rec :AllocationRecord) :void {
			var before :uint = li32(rec.start);
			var after :uint = li32(rec.start + rec.size - 4);
			if (before != 0xcccccccc || after != 0xcdcdcdcd) {
				throw new Error("Buffer overrun of allocation record at " + rec.datastart + ", length " + rec.datasize);
			}
			
			si32(0, rec.start);
			si32(0, rec.start + rec.size - 4); 
		}
		
	}
}
