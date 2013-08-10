package starling.utils
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	public class ByteArrayReference {
		private var _bytes :ByteArray;
		private var _offset :uint;
		private var _length :uint;
		
		public const TEST_OFFSET :uint = 128;
		public function ByteArrayReference (bytes :uint) {
			// TODO: alloc here
			_bytes = new ByteArray();
			_bytes.endian = Endian.LITTLE_ENDIAN;
			resize(bytes, true);
			_bytes.position = TEST_OFFSET;
			_offset = TEST_OFFSET;
		}
		
		public function dispose () :void {
			// TODO: dealloc here
		}
		
		public function appendBytes (source :ByteArrayReference, offset :uint = 0, length :uint = 0) :void {
			var end :uint = _length;
			resize(_length + length);
			position = end;
			overwriteBytes(source, offset, length);
		}
		
		public function overwriteBytes (source :ByteArrayReference, offset :uint = 0, length :uint = 0) :void {
			_bytes.writeBytes(source._bytes, offset + _offset, length);
		}
		
		public function get position () :uint {
			return _bytes.position - _offset;
		}
		
		public function set position (value :uint) :void {
			var maxpos :uint = (_length + _offset) - 1;
			if (value <= maxpos || value == 0) {
				_bytes.position = value + _offset;
			} else {
				throw new Error("Byte array reference out of bounds: got " + value + ", max " + maxpos);
			}
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
		
		public function get bytesAvailable () :Boolean {
			return _bytes.position < (_offset + _length);
		}
		
		public function resize (size :uint, planned :Boolean = false) :void {
			if (_length == size) {
				return; // useless resize, ignore it
			}
			
			if (! planned) {
				trace("PROBLEM! RESIZE TO SIZE", size);
			}
			
			// TODO FIXME - realloc here
			_bytes.length = size + TEST_OFFSET;
			this._length = size;
		}
	}
}