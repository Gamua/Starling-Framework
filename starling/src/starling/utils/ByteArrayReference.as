package starling.utils
{
	import flash.utils.ByteArray;
	
	import avm2.intrinsics.memory.lf32;
	import avm2.intrinsics.memory.li32;
	import avm2.intrinsics.memory.li8;
	
	import starling.utils.malloc.DomainMemoryManager;

	/** 
	 * Reference to a sub-range of a managed heap. The particular position and length inside
	 * the heap may change over time, as the byte array acquires additional data and grows.
	 */
	public class ByteArrayReference {
		private var _bytes :ByteArray;
		private var _offset :uint;
		private var _length :uint;

		/** Allocates a range of at least the specified number of bytes (potentially larger),
		 * and initializes this reference. */
		public function ByteArrayReference (bytes :uint) {
			
			if (bytes < 4) { bytes = 4; } // allocate at least a word
			
			var mem :DomainMemoryManager = DomainMemoryManager.instance;
			_bytes = mem.heap;
			_offset = mem.allocate(bytes);
			_length = bytes;
		}
		
		/** Deallocates this managed byte range */
		public function dispose () :void {
			DomainMemoryManager.instance.free(_offset);
			
			_bytes = null;
			_offset = _length = 0;
		}
		
		/** Appends bytes from the source byte array reference, starting at given offset, 
		 * and copying over given number of bytes. This will reallocate the current reference
		 * to a new, larger location in the heap. */
		public function appendBytes (source :ByteArrayReference, offset :uint = 0, length :uint = 0) :void {
			var end :uint = _length;
			resize(_length + length);
			
			// write data at the end
			overwriteBytesAt(end, source, offset, length);
		}
		
		/** Overwrites bytes in the reference, starting at specified offset, and of specified length.
		 * Writing past byte array bounds is neither detected nor prevented - proceed with caution! */
		public function overwriteBytesAt (targetOffset :uint, source :ByteArrayReference, offset :uint = 0, length :uint = 0) :void {
			var rawSourcePos :uint = offset + source._offset;
			_bytes.position = targetOffset + _offset;
			_bytes.writeBytes(source._bytes, rawSourcePos, length);
		}
		
		/** Given on offset in the byte array reference, returns its raw address in the managed heap. */
		[Inline] public final function calculateRawAddress (pos :uint) :uint {
			return _offset + pos;
		}
		
		/** Reference to the raw managed heap. */
		public function get raw () :ByteArray {
			return _bytes;
		}
		
		/** Returns the length of this byte array reference, in bytes. */
		public function get length () :uint {
			return _length;
		}
		
		/** Helper function for reading an uint at given position inside the range. 
		 * Only used as a helper, please use fast memory intrinsics directly instead. */
		public function readUnsignedInt (pos :uint) :uint {
			return li32(_offset + pos);
		}
		
		/** Helper function for reading a byte at given position inside the range. 
		 * Only used as a helper, please use fast memory intrinsics directly instead. */
		public function readByte (pos :uint) :uint {
			return li8(_offset + pos);
		}

		/** Helper function for reading a float at given position inside the range. 
		 * Only used as a helper, please use fast memory intrinsics directly instead. */
		public function readFloat (pos :uint) :Number {
			return lf32(_offset + pos);
		}

		/** Grows this byte array reference to the new size, allocating new memory 
		 * and moving data over if necessary. */
		public function resize (size :uint, planned :Boolean = false) :void {
			if (_length == size) {
				return; // useless resize, ignore it
			}
			
			if (! planned) {
				// trace("RESIZE TO SIZE", size);
			}

			// allocate more memory (expensive!)
			var newOffset :uint = DomainMemoryManager.instance.reallocate(_offset, _length, size);
			_offset = newOffset;
			_length = size;
		}
	}
}
