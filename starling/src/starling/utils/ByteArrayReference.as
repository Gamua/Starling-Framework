package starling.utils
{
	import flash.utils.ByteArray;
	
	import avm2.intrinsics.memory.lf32;
	import avm2.intrinsics.memory.li32;
	import avm2.intrinsics.memory.li8;
	
	public class ByteArrayReference {
		private var _bytes :ByteArray;
		private var _offset :uint;
		private var _length :uint;
		
		public const TEST_OFFSET :uint = 128;
		
		public function ByteArrayReference (bytes :uint) {
			var mem :MemoryManager = MemoryManager.instance;
			_bytes = mem.heap;
			_offset = mem.allocate(bytes);
			_length = bytes;
		}
		
		public function dispose () :void {
			MemoryManager.instance.free(_offset);
			
			_bytes = null;
			_offset = _length = 0;
		}
		
		public function appendBytes (source :ByteArrayReference, offset :uint = 0, length :uint = 0) :void {
			var end :uint = _length;
			resize(_length + length);
			
			// write data at the end
			overwriteBytesAt(end, source, offset, length);
		}
		
		public function overwriteBytesAt (targetOffset :uint, source :ByteArrayReference, offset :uint = 0, length :uint = 0) :void {
			var rawSourcePos :uint = offset + source._offset;
			_bytes.position = targetOffset + _offset;
			_bytes.writeBytes(source._bytes, rawSourcePos, length);
		}
		
		[Inline] public final function calculateRawAddress (pos :uint) :uint {
			return _offset + pos;
		}
		
		public function get raw () :ByteArray {
			return _bytes;
		}
		
		public function get length () :uint {
			return _length;
		}
		
		public function readUnsignedInt (pos :uint) :uint {
			return li32(_offset + pos);
		}
		
		public function readByte (pos :uint) :uint {
			return li8(_offset + pos);
		}

		public function readFloat (pos :uint) :Number {
			return lf32(_offset + pos);
		}

		public function resize (size :uint, planned :Boolean = false) :void {
			if (_length == size) {
				return; // useless resize, ignore it
			}
			
			if (! planned) {
				// trace("RESIZE TO SIZE", size);
			}

			// allocate more memory (expensive!)
			var newOffset :uint = MemoryManager.instance.reallocate(_offset, _length, size);
			_offset = newOffset;
			_length = size;
		}
	}
}
