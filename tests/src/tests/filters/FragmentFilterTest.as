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

    import starling.display.Sprite;
    import starling.events.EnterFrameEvent;
    import starling.events.Event;
    import starling.filters.FragmentFilter;

    import tests.StarlingTestCase;

    public class FragmentFilterTest extends StarlingTestCase
    {
        [Test]
        public function testEnterFrameEvent():void
        {
            var eventCount:int = 0;
            var event:EnterFrameEvent = new EnterFrameEvent(Event.ENTER_FRAME, 0.1);
            var filter:FragmentFilter = new FragmentFilter();
            var sprite:Sprite = new Sprite();
            var sprite2:Sprite = new Sprite();

            filter.addEventListener(Event.ENTER_FRAME, onEvent);
            sprite.dispatchEvent(event);
            assertEquals(0, eventCount);

            sprite.filter = filter;
            sprite.dispatchEvent(event);
            assertEquals(1, eventCount);

            sprite.dispatchEvent(event);
            assertEquals(2, eventCount);

            sprite2.filter = filter;
            sprite.dispatchEvent(event);
            assertEquals(2, eventCount);

            sprite.filter = filter;
            sprite.dispatchEvent(event);
            assertEquals(3, eventCount);

            filter.removeEventListener(Event.ENTER_FRAME, onEvent);
            sprite.dispatchEvent(event);
            assertEquals(3, eventCount);

            function onEvent(event:EnterFrameEvent):void
            {
                ++eventCount;
            }
        }
    }
}
