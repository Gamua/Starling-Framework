package tests
{
    import flexunit.framework.Assert;
    
    import starling.display.Sprite;
    import starling.events.Event;
    
    public class EventTest
    {		
        [Test]
        public function testBubbling():void
        {
            const eventType:String = "test";
            
            var grandParent:Sprite = new Sprite();
            var parent:Sprite = new Sprite();
            var child:Sprite = new Sprite();
            
            grandParent.addChild(parent);
            parent.addChild(child);
            
            var grandParentEventHandlerHit:Boolean = false;
            var parentEventHandlerHit:Boolean = false;
            var childEventHandlerHit:Boolean = false;
            var hitCount:int = 0;            
            
            // bubble up
            
            grandParent.addEventListener(eventType, onGrandParentEvent);
            parent.addEventListener(eventType, onParentEvent);
            child.addEventListener(eventType, onChildEvent);
            
            var event:Event = new Event(eventType, true);
            child.dispatchEvent(event);
            
            Assert.assertTrue(grandParentEventHandlerHit);
            Assert.assertTrue(parentEventHandlerHit);
            Assert.assertTrue(childEventHandlerHit);
            
            Assert.assertEquals(3, hitCount);
            
            // remove event handler
            
            parentEventHandlerHit = false;
            parent.removeEventListener(eventType, onParentEvent);
            child.dispatchEvent(event);
            
            Assert.assertFalse(parentEventHandlerHit);
            Assert.assertEquals(5, hitCount);
            
            // don't bubble
            
            event = new Event(eventType);
            
            grandParentEventHandlerHit = parentEventHandlerHit = childEventHandlerHit = false;
            parent.addEventListener(eventType, onParentEvent);
            child.dispatchEvent(event);
            
            Assert.assertEquals(6, hitCount);
            Assert.assertTrue(childEventHandlerHit);
            Assert.assertFalse(parentEventHandlerHit);
            Assert.assertFalse(grandParentEventHandlerHit);
            
            function onGrandParentEvent(event:Event):void
            {
                grandParentEventHandlerHit = true;                
                Assert.assertObjectEquals(child, event.target);
                Assert.assertObjectEquals(grandParent, event.currentTarget);
                hitCount++;
            }
            
            function onParentEvent(event:Event):void
            {
                parentEventHandlerHit = true;                
                Assert.assertEquals(child, event.target);
                Assert.assertEquals(parent, event.currentTarget);
                hitCount++;
            }
            
            function onChildEvent(event:Event):void
            {
                childEventHandlerHit = true;                               
                Assert.assertEquals(child, event.target);
                Assert.assertEquals(child, event.currentTarget);
                hitCount++;
            }
        }
        
        [Test]
        public function testStopPropagation():void
        {
            const eventType:String = "test";
            
            var grandParent:Sprite = new Sprite();
            var parent:Sprite = new Sprite();
            var child:Sprite = new Sprite();
            
            grandParent.addChild(parent);
            parent.addChild(child);
            
            var hitCount:int = 0;
            
            // stop propagation at parent
            
            child.addEventListener(eventType, onEvent);
            parent.addEventListener(eventType, onEvent_StopPropagation);
            parent.addEventListener(eventType, onEvent);
            grandParent.addEventListener(eventType, onEvent);
            
            child.dispatchEvent(new Event(eventType, true));
            
            Assert.assertEquals(3, hitCount);
            
            // stop immediate propagation at parent
            
            parent.removeEventListener(eventType, onEvent_StopPropagation);
            parent.removeEventListener(eventType, onEvent);
            
            parent.addEventListener(eventType, onEvent_StopImmediatePropagation);
            parent.addEventListener(eventType, onEvent);
            
            child.dispatchEvent(new Event(eventType, true));
            
            Assert.assertEquals(5, hitCount);
            
            function onEvent(event:Event):void
            {
                hitCount++;
            }
            
            function onEvent_StopPropagation(event:Event):void
            {
                event.stopPropagation();
                hitCount++;
            }
            
            function onEvent_StopImmediatePropagation(event:Event):void
            {
                event.stopImmediatePropagation();
                hitCount++;
            }
        }
        
    }
}
