package starling.utils
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	public class ByteArrayReference {
		private var _bytes :ByteArray;
		private var _offset :uint;
		private var _length :uint;
		
		public function ByteArrayReference (bytes :uint) {
			_bytes = new ByteArray();
			_bytes.endian = Endian.LITTLE_ENDIAN;
			resize(bytes, true);
			_bytes.position = 0;
			_offset = 0;
		}
		
		public function writeBytes (source :ByteArrayReference, offset :uint = 0, length :uint = 0) :void {
			_bytes.writeBytes(source._bytes, offset + _offset, length);
		}
		
		public function get position () :uint {
			return _bytes.position - _offset;
		}
		
		public function set position (value :uint) :void {
			_bytes.position = value + _offset;
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
				return; // useless resize
			}
			
			if (! planned) {
				trace("PROBLEM! RESIZE TO SIZE", size);
			}
			// TODO FIXME - realloc here
			_bytes.length = size;
			this._length = size;
		}
	}
}