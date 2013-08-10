package tests
{
	import org.flexunit.asserts.assertEquals;
	import org.flexunit.asserts.assertFalse;
	import org.flexunit.asserts.assertNotNull;
	import org.flexunit.asserts.assertTrue;
	
	import starling.utils.malloc.AllocationRecord;
	import starling.utils.malloc.Allocator;
	import starling.utils.malloc.MemoryManager;

	public class AllocatorTest
	{
		[Test]
		public function testCreateAndDispose () :void {
			
			if (MemoryManager.isInitialized) {
				MemoryManager.instance.dispose();
			}
			
			assertFalse(MemoryManager.isInitialized);
			
			var alloc :Allocator = MemoryManager.instance.allocator;
			assertTrue(MemoryManager.isInitialized);
			assertNotNull(MemoryManager.instance);
			
			MemoryManager.instance.dispose();
			assertFalse(MemoryManager.isInitialized);
		}
		
		[Test]
		public function testAllocation () :void {
			
			var mem :MemoryManager = new MemoryManager(1024);
			
			// test simple allocation
			var pos :uint = mem.allocate(10);
			assertEquals(0, pos);
			verifyElement(mem.allocator.freeList, 0, 10, 1024 - 10);
			verifyAllocatorState(mem);
			
			MemoryManager.instance.dispose();
		}
		
		[Test]
		public function testHeapGrowth () :void {
			
			var mem :MemoryManager = new MemoryManager(1024);
			
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
			
			MemoryManager.instance.dispose();
		}

		private function verifyElement (list :Vector.<AllocationRecord>, index :uint, start :uint, length :uint) :void {
			assertEquals(start, list[index].start);
			assertEquals(length, list[index].length);
		}
		
		private function verifyAllocatorState (mem :MemoryManager) :void {
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