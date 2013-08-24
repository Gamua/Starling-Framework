package starling.utils.malloc
{
	public class AllocationRecord {
		
		/** Start of the allocation record. In debug mode, this is the sentinel position. 
		 * In non-debug, this is the same as datastart. */ 
		public var start :uint;
		
		/** Length of the full allocation, including both sentinels (if present). */
		public var size :uint;
		
		/** Position where data starts. In debug mode, this is right after the starting sentinel.
		 * In non-debug, this is the same as the start position. */
		public var datastart :uint;

		/** Length of the data segment, excluding sentinels (if present). */
		public var datasize :uint;
				
		public function AllocationRecord (start :uint, size :uint, sentinel :uint) :void {
			setSize(start, size, sentinel);
		}
		
		public function setSize (start :uint, size :uint, sentinel :uint) :void {
			this.start = start;
			this.size = size;
			this.datastart = start + sentinel;
			this.datasize = size - sentinel * 2; 
		}
		
		/** Returns the start position of the next node (if one exists) */
		public function get nextstart () :uint { 
			return start + size;
		}
	}
}
