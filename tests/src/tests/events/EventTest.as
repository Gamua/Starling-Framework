// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.events
{
    import flexunit.framework.Assert;
    
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.events.EventDispatcher;
    import tests.Helpers;
    
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
                Assert.assertEquals(child, event.target);
                Assert.assertEquals(grandParent, event.currentTarget);
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
        
        [Test]
        public function testRemoveEventListeners():void
        {
            var hitCount:int = 0;
            var dispatcher:EventDispatcher = new EventDispatcher();
            
            dispatcher.addEventListener("Type1", onEvent);
            dispatcher.addEventListener("Type2", onEvent);
            dispatcher.addEventListener("Type3", onEvent);
            
            hitCount = 0;
            dispatcher.dispatchEvent(new Event("Type1"));
            Assert.assertEquals(1, hitCount);
            
            dispatcher.dispatchEvent(new Event("Type2"));
            Assert.assertEquals(2, hitCount);
            
            dispatcher.dispatchEvent(new Event("Type3"));
            Assert.assertEquals(3, hitCount);
            
            hitCount = 0;
            dispatcher.removeEventListener("Type1", onEvent);
            dispatcher.dispatchEvent(new Event("Type1"));
            Assert.assertEquals(0, hitCount);
            
            dispatcher.dispatchEvent(new Event("Type3"));
            Assert.assertEquals(1, hitCount);
            
            hitCount = 0;
            dispatcher.removeEventListeners();
            dispatcher.dispatchEvent(new Event("Type1"));
            dispatcher.dispatchEvent(new Event("Type2"));
            dispatcher.dispatchEvent(new Event("Type3"));
            Assert.assertEquals(0, hitCount);
            
            function onEvent(event:Event):void
            {
                ++hitCount;
            }
        }
        
        [Test]
        public function testBlankEventDispatcher():void
        {
            var dispatcher:EventDispatcher = new EventDispatcher();
            
            Helpers.assertDoesNotThrow(function():void
            {
                dispatcher.removeEventListener("Test", null);
            });
            
            Helpers.assertDoesNotThrow(function():void
            {
                dispatcher.removeEventListeners("Test");
            });
        }
        
        [Test]
        public function testDuplicateEventHandler():void
        {
            var dispatcher:EventDispatcher = new EventDispatcher();
            var callCount:int = 0;
            
            dispatcher.addEventListener("test", onEvent);
            dispatcher.addEventListener("test", onEvent);
            
            dispatcher.dispatchEvent(new Event("test"));
            Assert.assertEquals(1, callCount);
            
            function onEvent(event:Event):void
            {
                callCount++;
            }
        }
        
        [Test]
        public function testBubbleWithModifiedChain():void
        {
            const eventType:String = "test";
            
            var grandParent:Sprite = new Sprite();
            var parent:Sprite = new Sprite();
            var child:Sprite = new Sprite();
            
            grandParent.addChild(parent);
            parent.addChild(child);
            
            var hitCount:int = 0;
            
            // listener on 'child' changes display list; bubbling must not be affected.
            
            grandParent.addEventListener(eventType, onEvent);
            parent.addEventListener(eventType, onEvent);
            child.addEventListener(eventType, onEvent);
            child.addEventListener(eventType, onEvent_removeFromParent);
            
            child.dispatchEvent(new Event(eventType, true));
            
            Assert.assertNull(parent.parent);
            Assert.assertEquals(3, hitCount);
            
            function onEvent():void
            {
                hitCount++;
            }
            
            function onEvent_removeFromParent():void
            {
                parent.removeFromParent();
            }
        }
        
        [Test]
        public function testRedispatch():void
        {
            const eventType:String = "test";
            
            var grandParent:Sprite = new Sprite();
            var parent:Sprite = new Sprite();
            var child:Sprite = new Sprite();
            
            grandParent.addChild(parent);
            parent.addChild(child);
            
            grandParent.addEventListener(eventType, onEvent);
            parent.addEventListener(eventType, onEvent);
            child.addEventListener(eventType, onEvent);
            parent.addEventListener(eventType, onEvent_redispatch);
            
            var targets:Array = [];
            var currentTargets:Array = [];
            
            child.dispatchEventWith(eventType, true);
            
            // main bubble
            Assert.assertEquals(targets[0], child);
            Assert.assertEquals(currentTargets[0], child);
            
            // main bubble
            Assert.assertEquals(targets[1], child);
            Assert.assertEquals(currentTargets[1], parent);
            
            // inner bubble
            Assert.assertEquals(targets[2], parent);
            Assert.assertEquals(currentTargets[2], parent);
            
            // inner bubble
            Assert.assertEquals(targets[3], parent);
            Assert.assertEquals(currentTargets[3], grandParent);
            
            // main bubble
            Assert.assertEquals(targets[4], child);
            Assert.assertEquals(currentTargets[4], grandParent);
            
            function onEvent(event:Event):void
            {
                targets.push(event.target);
                currentTargets.push(event.currentTarget);
            }
            
            function onEvent_redispatch(event:Event):void
            {
                parent.removeEventListener(eventType, onEvent_redispatch);
                parent.dispatchEvent(event);
            }
        }
    }
}
