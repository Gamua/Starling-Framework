package starling.utils.malloc
{
	public class AllocationRecord {
		
		public var start :uint;
		public var length :uint;
		
		public function AllocationRecord (start :uint, length :uint) {
			this.start = start;
			this.length = length;
		}
	}
}
