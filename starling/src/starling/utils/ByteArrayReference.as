package starling.utils
{
	import flash.system.ApplicationDomain;
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
//			_bytes = new ByteArray();
//			_bytes.length = bytes + 1024; // test
//			_bytes.endian = Endian.LITTLE_ENDIAN;
//			_offset = 0;
//			_length = bytes;
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
		
//		public function get position () :uint {
//			return _bytes.position - _offset;
//		}
//		
//		public function set position (value :uint) :void {
//			var rawMaxPos :uint = (_length + _offset) - 1;
//			var rawPos :uint = value + _offset;
//			if (rawPos <= rawMaxPos || value == 0) {
//				_bytes.position = rawPos;
//			} else {
//				throw new Error("Byte array reference out of bounds: got " + value + ", max " + (rawMaxPos - _offset));
//			}
//		}
		
		public function calculateRawAddress (pos :uint) :uint {
			return _offset + pos;
		}
		
		public function get raw () :ByteArray {
			return _bytes;
		}
		
		public function get rawOffset () :uint {
			return _offset;
		}
		
		public function get length () :uint {
			return _length;
		}
		
		public function readUnsignedInt (pos :uint) :uint {
			ApplicationDomain.currentDomain.domainMemory = raw;
			var loc :uint = _offset + pos;
			return li32(loc);
		}
		
		public function readByte (pos :uint) :uint {
			ApplicationDomain.currentDomain.domainMemory = raw;
			var loc :uint = _offset + pos;
			return li8(loc);
		}

		public function readFloat (pos :uint) :Number {
			ApplicationDomain.currentDomain.domainMemory = raw;
			var loc :uint = _offset + pos;
			return lf32(loc);
		}

		public function resize (size :uint, planned :Boolean = false) :void {
			if (_length == size) {
				return; // useless resize, ignore it
			}
			
			if (! planned) {
				trace("PROBLEM! RESIZE TO SIZE", size);
			}

			// allocate more memory (expensive!)
			var newOffset :uint = MemoryManager.instance.reallocate(_offset, _length, size);
			_offset = newOffset;
			_length = size;

//			var old :ByteArray = _bytes;
//			_bytes = new ByteArray();
//			_bytes.endian = Endian.LITTLE_ENDIAN;
//			_bytes.length = size;
//			_offset = 0;
//			_length = size;
//			_bytes.writeBytes(old, 0, old.length);

		}
	}
}
