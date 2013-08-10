package starling.utils
{
	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	public class MemoryManager
	{
		public static const HEAP_GROWTH_FACTOR :Number = 1.5;
		public static const INITIAL_HEAP_SIZE :uint = 128 * 1024;
		
		private static var mInstance :MemoryManager;

		private var mHeap :ByteArray;
		private var mTempNextFreeBlockIndex :uint = 0;
		
		public static function get instance () :MemoryManager {
			if (mInstance == null) {
				mInstance = new MemoryManager(INITIAL_HEAP_SIZE);
			}
			return mInstance;
		}
		
		public function MemoryManager(heapSize :uint)
		{
			mHeap = new ByteArray();
			mHeap.endian = Endian.LITTLE_ENDIAN;
			mHeap.length = heapSize;
			
			ApplicationDomain.currentDomain.domainMemory = mHeap;
			mInstance = this;
		}
		
		public function dispose () :void {
			mHeap.clear();
			mHeap = null;
		}
		
		public function allocate (length :uint) :uint {
			if (mTempNextFreeBlockIndex + length > mHeap.length) {
				// this allocate would cause the backing ByteArray to grow,
				// so let's trigger it manually and re-point domain memory at it
				mHeap.length *= HEAP_GROWTH_FACTOR;
				ApplicationDomain.currentDomain.domainMemory = mHeap;
			}
			
			var pos :uint = mTempNextFreeBlockIndex;
			mTempNextFreeBlockIndex += length;
			return pos;
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
			// one day, this function will do something.
			// today is not that day.
		}
		
		public function get heap () :ByteArray {
			return mHeap;
		}
	}
}