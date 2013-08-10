package starling.utils
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	public class MemoryManager
	{
		// TODO: pull this out into a configuration variable
		public static const HEAPSIZE :uint = 1024 * 1024;
		
		private static var mInstance :MemoryManager;

		private var mHeap :ByteArray;
		private var mTempNextFreeBlockIndex :uint = 0;
		
		public static function get instance () :MemoryManager {
			if (mInstance == null) {
				mInstance = new MemoryManager(HEAPSIZE);
			}
			return mInstance;
		}
		
		public function MemoryManager(heapSize :uint)
		{
			mHeap = new ByteArray();
			mHeap.endian = Endian.LITTLE_ENDIAN;
			mHeap.length = heapSize;
			mHeap.position = 0;
			
			mInstance = this;
		}
		
		public function dispose () :void {
			mHeap.clear();
			mHeap = null;
		}
		
		public function allocate (length :uint) :uint {
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