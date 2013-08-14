package tests
{
	import org.flexunit.asserts.assertEquals;
	import org.flexunit.asserts.assertFalse;
	import org.flexunit.asserts.assertNotNull;
	import org.flexunit.asserts.assertTrue;
	
	import starling.utils.malloc.AllocationRecord;
	import starling.utils.malloc.Allocator;
	import starling.utils.malloc.DomainMemoryManager;

	public class AllocatorTest
	{
		[BeforeClass]
		public static function prepare () :void {
			// clean up from other tests
			if (DomainMemoryManager.isInitialized) {
				DomainMemoryManager.instance.dispose();
			}
		}
		
		[Test]
		public function testCreateAndDispose () :void {
			
			if (DomainMemoryManager.isInitialized) {
				DomainMemoryManager.instance.dispose();
			}
			
			assertFalse(DomainMemoryManager.isInitialized);
			
			var alloc :Allocator = DomainMemoryManager.instance.allocator;
			assertTrue(DomainMemoryManager.isInitialized);
			assertNotNull(DomainMemoryManager.instance);
			
			DomainMemoryManager.instance.dispose();
			assertFalse(DomainMemoryManager.isInitialized);
		}
		
		[Test]
		public function testAllocation () :void {
			
			var mem :DomainMemoryManager = new DomainMemoryManager(1024);
			
			// test simple allocation
			var pos :uint = mem.allocate(10);
			assertEquals(0, pos);
			verifyElement(mem.allocator.freeList, 0, 10, 1024 - 10);
			verifyAllocatorState(mem);
			
			DomainMemoryManager.instance.dispose();
		}

		[Test]
		public function testFreeAndMerge () :void {
			
			var mem :DomainMemoryManager = new DomainMemoryManager(1024);
			
			var first :uint = mem.allocate(10);
			var second :uint = mem.allocate(10);
			var third :uint = mem.allocate(10);
			
			assertEquals(0, first);
			assertEquals(10, second);
			assertEquals(20, third);
			verifyAllocatorState(mem);
			
			// free the first one
			mem.free(first);
			// make sure we have it back on the free list
			verifyElement(mem.allocator.freeList, 0, 0, 10);
			verifyElement(mem.allocator.freeList, 1, 30, 1024 - 30);
			// and not on used list
			verifyElement(mem.allocator.usedList, 0, 10, 10);
			verifyElement(mem.allocator.usedList, 1, 20, 10);
			
			verifyAllocatorState(mem);

			// free the second one
			mem.free(second);
			// make sure the first two got merged
			verifyElement(mem.allocator.freeList, 0, 0, 20);
			verifyElement(mem.allocator.freeList, 1, 30, 1024 - 30);
			// and the used list should be smaller
			verifyElement(mem.allocator.usedList, 0, 20, 10);
			verifyAllocatorState(mem);
			
			// free the last one
			mem.free(third);
			// make sure everything got merged again
			verifyElement(mem.allocator.freeList, 0, 0, 1024);
			assertEquals(0, mem.allocator.usedList.length);
			verifyAllocatorState(mem);

			DomainMemoryManager.instance.dispose();
		}

		[Test]
		public function testHeapGrowth () :void {
			
			var mem :DomainMemoryManager = new DomainMemoryManager(1024);
			
			var pos :uint = mem.allocate(1024);
			assertEquals(0, pos);
			verifyElement(mem.allocator.usedList, 0, 0, 1024);
			assertEquals(0, mem.allocator.freeList.length);
			verifyAllocatorState(mem);
			
			// now force a resize, when there are no free elements left
			var two :uint = mem.allocate(128);
			assertEquals(1024, two);
			verifyElement(mem.allocator.usedList, 1, 1024, 128);
			verifyAllocatorState(mem);
			
			// now force another resize, but this time we have a free list element - test this path as well
			var three :uint = mem.allocate(512);
			assertEquals(1024 + 128, three);
			verifyElement(mem.allocator.usedList, 2, 1024 + 128, 512);
			verifyAllocatorState(mem);
			
			DomainMemoryManager.instance.dispose();
		}

		private function verifyElement (list :Vector.<AllocationRecord>, index :uint, start :uint, length :uint) :void {
			assertEquals(start, list[index].start);
			assertEquals(length, list[index].length);
		}
		
		private function verifyAllocatorState (mem :DomainMemoryManager) :void {
			verifySortOrder(mem.allocator.freeList);
			verifySortOrder(mem.allocator.usedList);
		}
		
		public function verifySortOrder (list :Vector.<AllocationRecord>) :void {
			if (list.length > 1) {
				var start :uint = list[0].start;
				for (var i :int = 1, len :int = list.length; i < len; i++) {
					assertTrue(start < list[i].start);
					start = list[i].start;
				}
			}
		}
	}
}