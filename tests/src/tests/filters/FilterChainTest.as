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
    import starling.events.Event;
    import starling.filters.BlurFilter;
    import starling.filters.ColorMatrixFilter;
    import starling.filters.FilterChain;
    import starling.filters.FragmentFilter;
    import starling.unit.UnitTest;

    public class FilterChainTest extends UnitTest
    {
        public function testConstructor():void
        {
            var filters:Vector.<FragmentFilter> = getTestFilters();
            var chain:FilterChain = new FilterChain(filters[0], filters[1], filters[2]);

            for (var i:int=0; i<filters.length; ++i)
                assertEqual(filters[i], chain.getFilterAt(i));

            assertEqual(filters.length, chain.numFilters);
        }

        public function testAddFilter():void
        {
            var filters:Vector.<FragmentFilter> = getTestFilters();
            var chain:FilterChain = new FilterChain();

            chain.addFilter(filters[0]);
            chain.addFilter(filters[2]);
            chain.addFilterAt(filters[1], 1);

            for (var i:int=0; i<filters.length; ++i)
                assertEqual(filters[i], chain.getFilterAt(i));

            assertEqual(filters.length, chain.numFilters);
        }

        public function testRemoveFilter():void
        {
            var filters:Vector.<FragmentFilter> = getTestFilters();
            var chain:FilterChain = new FilterChain(filters[0], filters[1], filters[2]);
            var removedFilter:FragmentFilter = chain.removeFilter(filters[1]);

            assertEqual(removedFilter, filters[1]);
            assertEqual(filters.length - 1, chain.numFilters);

            removedFilter = chain.removeFilterAt(0);
            assertEqual(removedFilter, filters[0]);
            assertEqual(filters.length - 2, chain.numFilters);
            assertEqual(filters[2], chain.getFilterAt(0));
        }

        public function testGetFilterAt():void
        {
            var filters:Vector.<FragmentFilter> = getTestFilters();
            var chain:FilterChain = new FilterChain(filters[0], filters[1], filters[2]);

            assertEqual(filters[2], chain.getFilterAt(2));
            assertEqual(filters[2], chain.getFilterAt(-1));
            assertEqual(filters[0], chain.getFilterAt(-3));
        }

        public function testDispatchEvent():void
        {
            var changeCount:int = 0;
            var chain:FilterChain = new FilterChain();
            var colorFilter:ColorMatrixFilter = new ColorMatrixFilter();

            chain.addEventListener(Event.CHANGE, onChange);
            chain.addFilter(colorFilter);
            assertEqual(1, changeCount);

            colorFilter.invert();
            assertEqual(2, changeCount);

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
