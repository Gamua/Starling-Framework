// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.display
{
    import flash.geom.Rectangle;

    import org.flexunit.assertThat;
    import org.flexunit.asserts.assertEquals;
    import org.flexunit.asserts.assertFalse;
    import org.flexunit.asserts.assertNotNull;
    import org.flexunit.asserts.assertNull;
    import org.flexunit.asserts.assertTrue;
    import org.hamcrest.number.closeTo;

    import starling.display.DisplayObject;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.display.Stage;
    import starling.events.Event;

    import tests.Helpers;

    public class DisplayObjectContainerTest
    {
        private static const E:Number = 0.0001;
        
        private var _added:int;
        private var _addedToStage:int;
        private var _addedChild:int;
        private var _removed:int;
        private var _removedFromStage:int;
        private var _removedChild:int;
        
        [Before]
        public function setUp():void 
        {
            _added = _addedToStage = _addedChild =
            _removed = _removedFromStage = _removedChild = 0;
        }
        
        [After]
        public function tearDown():void { }
        
        [Test]
        public function testChildParentHandling():void
        {
            var parent:Sprite = new Sprite();
            var child1:Sprite = new Sprite();
            var child2:Sprite = new Sprite();
            var returnValue:DisplayObject;
            
            assertEquals(0, parent.numChildren);
            assertNull(child1.parent);
            
            returnValue = parent.addChild(child1);
            assertEquals(child1, returnValue);
            assertEquals(1, parent.numChildren);
            assertEquals(parent, child1.parent);
            
            returnValue = parent.addChild(child2);
            assertEquals(child2, returnValue);
            assertEquals(2, parent.numChildren);
            assertEquals(parent, child2.parent);
            assertEquals(child1, parent.getChildAt(0));
            assertEquals(child2, parent.getChildAt(1));
            
            returnValue = parent.removeChild(child1);
            assertEquals(child1, returnValue);
            assertNull(child1.parent);
            assertEquals(child2, parent.getChildAt(0));
            returnValue = parent.removeChild(child1);
            assertNull(returnValue);
            child1.removeFromParent(); // should *not* throw an exception
            
            returnValue = child2.addChild(child1);
            assertEquals(child1, returnValue);
            assertTrue(parent.contains(child1));
            assertTrue(parent.contains(child2));
            assertEquals(child2, child1.parent);
            
            returnValue = parent.addChildAt(child1, 0);
            assertEquals(child1, returnValue);
            assertEquals(parent, child1.parent);
            assertFalse(child2.contains(child1));
            assertEquals(child1, parent.getChildAt(0));
            assertEquals(child2, parent.getChildAt(1));
            
            returnValue = parent.removeChildAt(0);
            assertEquals(child1, returnValue);
            assertEquals(child2, parent.getChildAt(0));
            assertEquals(1, parent.numChildren);
        }
        
        [Test]
        public function testRemoveChildren():void
        {
            var parent:Sprite;
            var numChildren:int = 10;
            
            // removing all children
            
            parent = createSprite(numChildren);
            assertEquals(10, parent.numChildren);
            
            parent.removeChildren();
            assertEquals(0, parent.numChildren);
            
            // removing a subset
            
            parent = createSprite(numChildren);
            parent.removeChildren(3, 5);
            assertEquals(7, parent.numChildren);
            assertEquals("2", parent.getChildAt(2).name);
            assertEquals("6", parent.getChildAt(3).name);
            
            // remove beginning from an id
            
            parent = createSprite(numChildren);
            parent.removeChildren(5);
            assertEquals(5, parent.numChildren);
            assertEquals("4", parent.getChildAt(4).name);
            
            function createSprite(numChildren:int):Sprite
            {
                var sprite:Sprite = new Sprite();                
                for (var i:int=0; i<numChildren; ++i)
                {
                    var child:Sprite = new Sprite();
                    child.name = i.toString();
                    sprite.addChild(child);
                }
                return sprite;
            }
        }
        
        [Test]
        public function testGetChildByName():void
        {
            var parent:Sprite = new Sprite();
            var child1:Sprite = new Sprite();
            var child2:Sprite = new Sprite();
            var child3:Sprite = new Sprite();
            
            parent.addChild(child1);
            parent.addChild(child2);
            parent.addChild(child3);
            
            child1.name = "child1";
            child2.name = "child2";
            child3.name = "child3";
            
            assertEquals(child1, parent.getChildByName("child1"));
            assertEquals(child2, parent.getChildByName("child2"));
            assertEquals(child3, parent.getChildByName("child3"));
            assertNull(parent.getChildByName("non-existing"));
            
            child2.name = "child3";
            assertEquals(child2, parent.getChildByName("child3"));
        }
        
        [Test]
        public function testSetChildIndex():void
        {
            var parent:Sprite = new Sprite();
            var childA:Sprite = new Sprite();
            var childB:Sprite = new Sprite();
            var childC:Sprite = new Sprite();
            
            parent.addChild(childA);
            parent.addChild(childB);
            parent.addChild(childC);
            
            parent.setChildIndex(childB, 0);
            assertEquals(parent.getChildAt(0), childB);
            assertEquals(parent.getChildAt(1), childA);
            assertEquals(parent.getChildAt(2), childC);
            
            parent.setChildIndex(childB, 1);
            assertEquals(parent.getChildAt(0), childA);
            assertEquals(parent.getChildAt(1), childB);
            assertEquals(parent.getChildAt(2), childC);
            
            parent.setChildIndex(childB, 2);
            assertEquals(parent.getChildAt(0), childA);
            assertEquals(parent.getChildAt(1), childC);
            assertEquals(parent.getChildAt(2), childB);
            
            assertEquals(3, parent.numChildren);
        }

        [Test]
        public function testGetChildAtWithNegativeIndices():void
        {
            var parent:Sprite = new Sprite();
            var childA:Sprite = new Sprite();
            var childB:Sprite = new Sprite();
            var childC:Sprite = new Sprite();

            parent.addChild(childA);
            parent.addChild(childB);
            parent.addChild(childC);

            assertEquals(parent.getChildAt(-3), childA);
            assertEquals(parent.getChildAt(-2), childB);
            assertEquals(parent.getChildAt(-1), childC);
        }
        
        [Test]
        public function testSwapChildren():void
        {
            var parent:Sprite = new Sprite();
            var childA:Sprite = new Sprite();
            var childB:Sprite = new Sprite();
            var childC:Sprite = new Sprite();
            
            parent.addChild(childA);
            parent.addChild(childB);
            parent.addChild(childC);
            
            parent.swapChildren(childA, childC);            
            assertEquals(parent.getChildAt(0), childC);
            assertEquals(parent.getChildAt(1), childB);
            assertEquals(parent.getChildAt(2), childA);
            
            parent.swapChildren(childB, childB); // should change nothing
            assertEquals(parent.getChildAt(0), childC);
            assertEquals(parent.getChildAt(1), childB);
            assertEquals(parent.getChildAt(2), childA);
            
            assertEquals(3, parent.numChildren);
        }
        
        [Test]
        public function testWidthAndHeight():void
        {
            var sprite:Sprite = new Sprite();
            
            var quad1:Quad = new Quad(10, 20);
            quad1.x = -10;
            quad1.y = -15;
            
            var quad2:Quad = new Quad(15, 25);
            quad2.x = 30;
            quad2.y = 25;
            
            sprite.addChild(quad1);
            sprite.addChild(quad2);
            
            assertThat(sprite.width, closeTo(55, E));
            assertThat(sprite.height, closeTo(65, E));
            
            quad1.rotation = Math.PI / 2;
            assertThat(sprite.width, closeTo(75, E));
            assertThat(sprite.height, closeTo(65, E));
            
            quad1.rotation = Math.PI;
            assertThat(sprite.width, closeTo(65, E));
            assertThat(sprite.height, closeTo(85, E));
        }
        
        [Test]
        public function testBounds():void
        {
            var quad:Quad = new Quad(10, 20);
            quad.x = -10;
            quad.y = 10;
            quad.rotation = Math.PI / 2;
            
            var sprite:Sprite = new Sprite();
            sprite.addChild(quad);
            
            var bounds:Rectangle = sprite.bounds;
            assertThat(bounds.x, closeTo(-30, E));
            assertThat(bounds.y, closeTo(10, E));
            assertThat(bounds.width, closeTo(20, E));
            assertThat(bounds.height, closeTo(10, E));
            
            bounds = sprite.getBounds(sprite);
            assertThat(bounds.x, closeTo(-30, E));
            assertThat(bounds.y, closeTo(10, E));
            assertThat(bounds.width, closeTo(20, E));
            assertThat(bounds.height, closeTo(10, E));            
        }
        
        [Test]
        public function testBoundsInSpace():void
        {
            var root:Sprite = new Sprite();
            
            var spriteA:Sprite = new Sprite();
            spriteA.x = 50;
            spriteA.y = 50;
            addQuadToSprite(spriteA);
            root.addChild(spriteA);
            
            var spriteA1:Sprite = new Sprite();
            spriteA1.x = 150;
            spriteA1.y = 50;
            spriteA1.scaleX = spriteA1.scaleY = 0.5;
            addQuadToSprite(spriteA1);
            spriteA.addChild(spriteA1);
            
            var spriteA11:Sprite = new Sprite();
            spriteA11.x = 25;
            spriteA11.y = 50;
            spriteA11.scaleX = spriteA11.scaleY = 0.5;
            addQuadToSprite(spriteA11);
            spriteA1.addChild(spriteA11);
            
            var spriteA2:Sprite = new Sprite();
            spriteA2.x = 50;
            spriteA2.y = 150;
            spriteA2.scaleX = spriteA2.scaleY = 0.5;
            addQuadToSprite(spriteA2);
            spriteA.addChild(spriteA2);
            
            var spriteA21:Sprite = new Sprite();
            spriteA21.x = 50;
            spriteA21.y = 25;
            spriteA21.scaleX = spriteA21.scaleY = 0.5;
            addQuadToSprite(spriteA21);
            spriteA2.addChild(spriteA21);
            
            // ---
            
            var bounds:Rectangle = spriteA21.getBounds(spriteA11);
            var expectedBounds:Rectangle = new Rectangle(-350, 350, 100, 100);
            Helpers.compareRectangles(bounds, expectedBounds);
            
            // now rotate as well
            
            spriteA11.rotation = Math.PI / 4.0;
            spriteA21.rotation = Math.PI / -4.0;
            
            bounds = spriteA21.getBounds(spriteA11);
            expectedBounds = new Rectangle(0, 394.974762, 100, 100);
            Helpers.compareRectangles(bounds, expectedBounds);
            
            function addQuadToSprite(sprite:Sprite):void
            {
                sprite.addChild(new Quad(100, 100));
            }
        }
        
        [Test]
        public function testBoundsOfEmptyContainer():void
        {
            var sprite:Sprite = new Sprite();
            sprite.x = 100;
            sprite.y = 200;
            
            var bounds:Rectangle = sprite.bounds;
            assertThat(bounds.x, closeTo(100, E));
            assertThat(bounds.y, closeTo(200, E));
            assertThat(bounds.width, closeTo(0, E));
            assertThat(bounds.height, closeTo(0, E));            
        }
        
        [Test]
        public function testSize():void
        {
            var quad1:Quad = new Quad(100, 100);
            var quad2:Quad = new Quad(100, 100);
            quad2.x = quad2.y = 100;
            
            var sprite:Sprite = new Sprite();
            var childSprite:Sprite = new Sprite();
            
            sprite.addChild(childSprite);
            childSprite.addChild(quad1);
            childSprite.addChild(quad2);
            
            assertThat(sprite.width, closeTo(200, E));
            assertThat(sprite.height, closeTo(200, E));
            
            sprite.scaleX = 2.0;
            sprite.scaleY = 2.0;
            
            assertThat(sprite.width, closeTo(400, E));
            assertThat(sprite.height, closeTo(400, E));
        }
        
        [Test]
        public function testSort():void
        {
            var s1:Sprite = new Sprite(); s1.y = 8;
            var s2:Sprite = new Sprite(); s2.y = 3;
            var s3:Sprite = new Sprite(); s3.y = 6;
            var s4:Sprite = new Sprite(); s4.y = 1;
            
            var parent:Sprite = new Sprite();
            parent.addChild(s1);
            parent.addChild(s2);
            parent.addChild(s3);
            parent.addChild(s4);
            
            assertEquals(s1, parent.getChildAt(0));
            assertEquals(s2, parent.getChildAt(1));
            assertEquals(s3, parent.getChildAt(2));
            assertEquals(s4, parent.getChildAt(3));
            
            parent.sortChildren(function(child1:DisplayObject, child2:DisplayObject):int
            {
                if (child1.y < child2.y) return -1;
                else if (child1.y > child2.y) return 1;
                else return 0;
            });
            
            assertEquals(s4, parent.getChildAt(0));
            assertEquals(s2, parent.getChildAt(1));
            assertEquals(s3, parent.getChildAt(2));
            assertEquals(s1, parent.getChildAt(3));
        }
        
        [Test]
        public function testAddExistingChild():void
        {
            var stage:Stage = new Stage(400, 300);
            var sprite:Sprite = new Sprite();
            var quad:Quad = new Quad(100, 100);
            quad.addEventListener(Event.ADDED, onAdded);
            quad.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            quad.addEventListener(Event.REMOVED, onRemoved);
            quad.addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
            
            stage.addChild(sprite);
            sprite.addChild(quad);
            assertEquals(1, _added);
            assertEquals(1, _addedToStage);
            
            // add same child again
            sprite.addChild(quad);
            
            // nothing should change, actually.
            assertEquals(1, sprite.numChildren);
            assertEquals(0, sprite.getChildIndex(quad));
            
            // since the parent does not change, no events should be dispatched 
            assertEquals(1, _added);
            assertEquals(1, _addedToStage);
            assertEquals(0, _removed);
            assertEquals(0, _removedFromStage);
        }
        
        [Test]
        public function testRemoveWithEventHandler():void
        {
            var parent:Sprite = new Sprite();
            var child0:Sprite = new Sprite();
            var child1:Sprite = new Sprite();
            var child2:Sprite = new Sprite();
            
            parent.addChild(child0);
            parent.addChild(child1);
            parent.addChild(child2);
            
            // Remove last child, and in its event listener remove first child.
            // That must work, even though the child changes its index in the event handler.
            
            child2.addEventListener(Event.REMOVED, function():void
            {
                child0.removeFromParent();
            });
            
            Helpers.assertDoesNotThrow(function():void
            {
                parent.removeChildAt(2);
            });
            
            assertNull(child2.parent);
            assertNull(child0.parent);
            assertEquals(child1, parent.getChildAt(0));
            assertEquals(1, parent.numChildren);
        }
        
        [Test(expects="ArgumentError")]
        public function testIllegalRecursion():void
        {
            var sprite1:Sprite = new Sprite();
            var sprite2:Sprite = new Sprite();
            var sprite3:Sprite = new Sprite();
            
            sprite1.addChild(sprite2);
            sprite2.addChild(sprite3);
            
            // this should throw an error
            sprite3.addChild(sprite1);
        }
        
        [Test(expects="ArgumentError")]
        public function testAddAsChildToSelf():void
        {
            var sprite:Sprite = new Sprite();
            sprite.addChild(sprite);
        }
        
        [Test]
        public function testDisplayListEvents():void
        {
            var stage:Stage = new Stage(100, 100);
            var sprite:Sprite = new Sprite();
            var quad:Quad = new Quad(20, 20);
            
            quad.addEventListener(Event.ADDED, onAdded);
            quad.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            quad.addEventListener(Event.REMOVED, onRemoved);
            quad.addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
            
            stage.addEventListener(Event.ADDED, onAddedChild);
            stage.addEventListener(Event.REMOVED, onRemovedChild);
            
            sprite.addChild(quad);            
            assertEquals(1, _added);
            assertEquals(0, _removed);
            assertEquals(0, _addedToStage);
            assertEquals(0, _removedFromStage);
            assertEquals(0, _addedChild);
            assertEquals(0, _removedChild);
            
            stage.addChild(sprite);
            assertEquals(1, _added);
            assertEquals(0, _removed);
            assertEquals(1, _addedToStage);
            assertEquals(0, _removedFromStage);
            assertEquals(1, _addedChild);
            assertEquals(0, _removedChild);
            
            stage.removeChild(sprite);
            assertEquals(1, _added);
            assertEquals(0, _removed);
            assertEquals(1, _addedToStage);
            assertEquals(1, _removedFromStage);
            assertEquals(1, _addedChild);
            assertEquals(1, _removedChild);
            
            sprite.removeChild(quad);
            assertEquals(1, _added);
            assertEquals(1, _removed);
            assertEquals(1, _addedToStage);
            assertEquals(1, _removedFromStage);
            assertEquals(1, _addedChild);
            assertEquals(1, _removedChild);
        }
        
        [Test]
        public function testRemovedFromStage():void
        {
            var stage:Stage = new Stage(100, 100);
            var sprite:Sprite = new Sprite();
            stage.addChild(sprite);
            sprite.addEventListener(Event.REMOVED_FROM_STAGE, onSpriteRemovedFromStage);
            sprite.removeFromParent();
            assertEquals(1, _removedFromStage);
            
            function onSpriteRemovedFromStage(e:Event):void
            {
                // stage should still be accessible in event listener
                assertNotNull(sprite.stage);
                _removedFromStage++;
            }
        }
        
        [Test]
        public function testRepeatedStageRemovedEvent():void
        {
            var stage:Stage = new Stage(100, 100);
            var grandParent:Sprite = new Sprite();
            var parent:Sprite = new Sprite();
            var child:Sprite = new Sprite();
            
            stage.addChild(grandParent);
            grandParent.addChild(parent);
            parent.addChild(child);
            
            grandParent.addEventListener(Event.REMOVED_FROM_STAGE, onGrandParentRemovedFromStage);
            child.addEventListener(Event.REMOVED_FROM_STAGE, onChildRemovedFromStage);
            
            // in this set-up, the child could receive the REMOVED_FROM_STAGE event more than
            // once -- which must be avoided. Furthermore, "stage" must always be accessible
            // in such an event handler.
            
            var childRemovedCount:int = 0;
            grandParent.removeFromParent();
            
            function onGrandParentRemovedFromStage():void
            {
                parent.removeFromParent();
            }
            
            function onChildRemovedFromStage():void
            {
                assertNotNull(child.stage);
                assertEquals(0, childRemovedCount);
                
                childRemovedCount++;
            }
        }
        
        private function onAdded(event:Event):void { _added++; }
        private function onAddedToStage(event:Event):void { _addedToStage++; }
        private function onAddedChild(event:Event):void { _addedChild++; }
        
        private function onRemoved(event:Event):void { _removed++; }
        private function onRemovedFromStage(event:Event):void { _removedFromStage++; }
        private function onRemovedChild(event:Event):void { _removedChild++; }
    }
}