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
		public function testAllocationVariants () :void {
			testAllocation(false);
			testAllocation(true);
		}
		
		public function testAllocation (debug :Boolean) :void {
			var sentinelSize :uint = debug ? 4 : 0;
			var nodeOverhead :uint = sentinelSize * 2;
			var mem :DomainMemoryManager = new DomainMemoryManager(1024, debug);
			
			// test simple allocation, make sure sentinels are there
			var pos :uint = mem.allocate(10);
			assertEquals(sentinelSize, pos); // with sentinel
			verifyElement(mem.allocator.usedList, 0, 0, 10 + nodeOverhead);
			verifyElement(mem.allocator.freeList, 0, 10 + nodeOverhead, 1024 - (10 + nodeOverhead));
			verifyAllocatorState(mem);
			verifySentinels(mem);
			
			DomainMemoryManager.instance.dispose();
		}

		[Test]
		public function testFreeAndMergeVariants () :void {
			testFreeAndMerge(false);
			testFreeAndMerge(true);
		}
		
		public function testFreeAndMerge (debug :Boolean) :void {
			var sentinelSize :uint = debug ? 4 : 0;
			var nodeOverhead :uint = sentinelSize * 2;
			var mem :DomainMemoryManager = new DomainMemoryManager(1024, debug);
			
			var first :uint = mem.allocate(10);
			var second :uint = mem.allocate(10);
			var third :uint = mem.allocate(10);
			
			assertEquals(0 + sentinelSize, first);
			assertEquals(10 + sentinelSize + nodeOverhead, second);
			assertEquals(20 + sentinelSize + 2 * nodeOverhead, third);
			verifyAllocatorState(mem);
			
			// free the first one
			mem.free(first);
			// make sure we have it back on the free list
			verifyElement(mem.allocator.freeList, 0, 0, 10 + nodeOverhead);
			verifyElement(mem.allocator.freeList, 1, 30 + 3 * nodeOverhead, 1024 - (30 + 3 * nodeOverhead));
			// and not on used list
			verifyElement(mem.allocator.usedList, 0, 10 + 1 * nodeOverhead, 10 + nodeOverhead);
			verifyElement(mem.allocator.usedList, 1, 20 + 2 * nodeOverhead, 10 + nodeOverhead);
			
			verifyAllocatorState(mem);

			// free the second one
			mem.free(second);
			// make sure the first two got merged
			verifyElement(mem.allocator.freeList, 0, 0, 20 + 2 * nodeOverhead); // <-- two merged ones
			verifyElement(mem.allocator.freeList, 1, 30 + 3 * nodeOverhead, 1024 - (30 + 3 * nodeOverhead));
			// and the used list should be smaller
			verifyElement(mem.allocator.usedList, 0, 20 + 2 * nodeOverhead, 10 + nodeOverhead);
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
		public function testSentinelDetectsBufferOverrun () :void {
			var mem :DomainMemoryManager = new DomainMemoryManager(1024, true);
			
			var caughtOverrun :Boolean = false;
			var pos :uint = mem.allocate(4 * 4);
			mem.heap.position = pos;
			for (var i :int = 0; i <= 4; i++) { // buffer overrun! off by one
				mem.heap.writeInt(0xdeadbeef);
			}

			try {
				mem.free(pos);
			} catch (e :Error) {
				caughtOverrun = true;
			}
			
			assertTrue(caughtOverrun);
			DomainMemoryManager.instance.dispose();
		}
		
		[Test]
		public function testHeapGrowth () :void {
			
			var mem :DomainMemoryManager = new DomainMemoryManager(1024, false);
			
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

		private function verifyElement (list :Vector.<AllocationRecord>, index :uint, realstart :uint, reallength :uint) :void {
			assertEquals(realstart, list[index].start);
			assertEquals(reallength, list[index].size);
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
		
		public function verifySentinels (mem :DomainMemoryManager) :void {
			if (mem.debug) {
				verifyEachSentinel(mem, mem.allocator.usedList, 0xcccccccc, 0xcdcdcdcd);
				verifyEachSentinel(mem, mem.allocator.freeList, 0x00000000, 0x00000000);
			}
		}
		
		public function verifyEachSentinel (mem :DomainMemoryManager, list :Vector.<AllocationRecord>, before :uint, after :uint) :void {
			for each (var rec :AllocationRecord in list) {
				mem.heap.position = rec.start;
				assertEquals(before, mem.heap.readUnsignedInt());
				mem.heap.position = rec.datastart + rec.datasize;
				assertEquals(after, mem.heap.readUnsignedInt());
			}
		}
	}
}