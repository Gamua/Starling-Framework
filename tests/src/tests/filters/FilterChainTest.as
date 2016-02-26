// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.filters
{
    import org.flexunit.asserts.assertEquals;

    import starling.events.Event;
    import starling.filters.BlurFilter;
    import starling.filters.ColorMatrixFilter;
    import starling.filters.FilterChain;
    import starling.filters.FragmentFilter;

    import tests.StarlingTestCase;

    public class FilterChainTest extends StarlingTestCase
    {
        [Test]
        public function testConstructor():void
        {
            var filters:Vector.<FragmentFilter> = getTestFilters();
            var chain:FilterChain = new FilterChain(filters[0], filters[1], filters[2]);

            for (var i:int=0; i<filters.length; ++i)
                assertEquals(filters[i], chain.getFilterAt(i));

            assertEquals(filters.length, chain.numFilters);
        }

        [Test]
        public function testAddFilter():void
        {
            var filters:Vector.<FragmentFilter> = getTestFilters();
            var chain:FilterChain = new FilterChain();

            chain.addFilter(filters[0]);
            chain.addFilter(filters[2]);
            chain.addFilterAt(filters[1], 1);

            for (var i:int=0; i<filters.length; ++i)
                assertEquals(filters[i], chain.getFilterAt(i));

            assertEquals(filters.length, chain.numFilters);
        }

        [Test]
        public function testRemoveFilter():void
        {
            var filters:Vector.<FragmentFilter> = getTestFilters();
            var chain:FilterChain = new FilterChain(filters[0], filters[1], filters[2]);
            var removedFilter:FragmentFilter = chain.removeFilter(filters[1]);

            assertEquals(removedFilter, filters[1]);
            assertEquals(filters.length - 1, chain.numFilters);

            removedFilter = chain.removeFilterAt(0);
            assertEquals(removedFilter, filters[0]);
            assertEquals(filters.length - 2, chain.numFilters);
            assertEquals(filters[2], chain.getFilterAt(0));
        }

        [Test]
        public function testGetFilterAt():void
        {
            var filters:Vector.<FragmentFilter> = getTestFilters();
            var chain:FilterChain = new FilterChain(filters[0], filters[1], filters[2]);

            assertEquals(filters[2], chain.getFilterAt(2));
            assertEquals(filters[2], chain.getFilterAt(-1));
            assertEquals(filters[0], chain.getFilterAt(-3));
        }

        [Test]
        public function testDispatchEvent():void
        {
            var changeCount:int = 0;
            var chain:FilterChain = new FilterChain();
            var colorFilter:ColorMatrixFilter = new ColorMatrixFilter();

            chain.addEventListener(Event.CHANGE, onChange);
            chain.addFilter(colorFilter);
            assertEquals(1, changeCount);

            colorFilter.invert();
            assertEquals(2, changeCount);

            function onChange():void
            {
                changeCount++;
            }
        }

        private function getTestFilters():Vector.<FragmentFilter>
        {
            return new <FragmentFilter>[
                new FragmentFilter(), new ColorMatrixFilter(), new BlurFilter()];
        }
    }
}
