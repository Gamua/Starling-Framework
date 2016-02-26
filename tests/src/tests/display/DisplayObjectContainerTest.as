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
    
    import flexunit.framework.Assert;
    
    import org.flexunit.assertThat;
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
        
        private var mAdded:int;
        private var mAddedToStage:int;
        private var mAddedChild:int;
        private var mRemoved:int;
        private var mRemovedFromStage:int;
        private var mRemovedChild:int;
        
        [Before]
        public function setUp():void 
        {
            mAdded = mAddedToStage = mAddedChild = 
            mRemoved = mRemovedFromStage = mRemovedChild = 0;
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
            
            Assert.assertEquals(0, parent.numChildren);
            Assert.assertNull(child1.parent);
            
            returnValue = parent.addChild(child1);
            Assert.assertEquals(child1, returnValue);
            Assert.assertEquals(1, parent.numChildren);
            Assert.assertEquals(parent, child1.parent);
            
            returnValue = parent.addChild(child2);
            Assert.assertEquals(child2, returnValue);
            Assert.assertEquals(2, parent.numChildren);
            Assert.assertEquals(parent, child2.parent);
            Assert.assertEquals(child1, parent.getChildAt(0));
            Assert.assertEquals(child2, parent.getChildAt(1));
            
            returnValue = parent.removeChild(child1);
            Assert.assertEquals(child1, returnValue);
            Assert.assertNull(child1.parent);
            Assert.assertEquals(child2, parent.getChildAt(0));
            child1.removeFromParent(); // should *not* throw an exception
            
            returnValue = child2.addChild(child1);
            Assert.assertEquals(child1, returnValue);
            Assert.assertTrue(parent.contains(child1));
            Assert.assertTrue(parent.contains(child2));
            Assert.assertEquals(child2, child1.parent);
            
            returnValue = parent.addChildAt(child1, 0);
            Assert.assertEquals(child1, returnValue);
            Assert.assertEquals(parent, child1.parent);
            Assert.assertFalse(child2.contains(child1));
            Assert.assertEquals(child1, parent.getChildAt(0));
            Assert.assertEquals(child2, parent.getChildAt(1));
            
            returnValue = parent.removeChildAt(0);
            Assert.assertEquals(child1, returnValue);
            Assert.assertEquals(child2, parent.getChildAt(0));
            Assert.assertEquals(1, parent.numChildren);
        }
        
        [Test]
        public function testRemoveChildren():void
        {
            var parent:Sprite;
            var numChildren:int = 10;
            
            // removing all children
            
            parent = createSprite(numChildren);
            Assert.assertEquals(10, parent.numChildren);
            
            parent.removeChildren();
            Assert.assertEquals(0, parent.numChildren);
            
            // removing a subset
            
            parent = createSprite(numChildren);
            parent.removeChildren(3, 5);
            Assert.assertEquals(7, parent.numChildren);
            Assert.assertEquals("2", parent.getChildAt(2).name);
            Assert.assertEquals("6", parent.getChildAt(3).name);
            
            // remove beginning from an id
            
            parent = createSprite(numChildren);
            parent.removeChildren(5);
            Assert.assertEquals(5, parent.numChildren);
            Assert.assertEquals("4", parent.getChildAt(4).name);
            
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
            
            Assert.assertEquals(child1, parent.getChildByName("child1"));
            Assert.assertEquals(child2, parent.getChildByName("child2"));
            Assert.assertEquals(child3, parent.getChildByName("child3"));
            Assert.assertNull(parent.getChildByName("non-existing"));
            
            child2.name = "child3";
            Assert.assertEquals(child2, parent.getChildByName("child3"));
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
            Assert.assertEquals(parent.getChildAt(0), childB);
            Assert.assertEquals(parent.getChildAt(1), childA);
            Assert.assertEquals(parent.getChildAt(2), childC);
            
            parent.setChildIndex(childB, 1);
            Assert.assertEquals(parent.getChildAt(0), childA);
            Assert.assertEquals(parent.getChildAt(1), childB);
            Assert.assertEquals(parent.getChildAt(2), childC);
            
            parent.setChildIndex(childB, 2);
            Assert.assertEquals(parent.getChildAt(0), childA);
            Assert.assertEquals(parent.getChildAt(1), childC);
            Assert.assertEquals(parent.getChildAt(2), childB);
            
            Assert.assertEquals(3, parent.numChildren);
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

            Assert.assertEquals(parent.getChildAt(-3), childA);
            Assert.assertEquals(parent.getChildAt(-2), childB);
            Assert.assertEquals(parent.getChildAt(-1), childC);
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
            Assert.assertEquals(parent.getChildAt(0), childC);
            Assert.assertEquals(parent.getChildAt(1), childB);
            Assert.assertEquals(parent.getChildAt(2), childA);
            
            parent.swapChildren(childB, childB); // should change nothing
            Assert.assertEquals(parent.getChildAt(0), childC);
            Assert.assertEquals(parent.getChildAt(1), childB);
            Assert.assertEquals(parent.getChildAt(2), childA);
            
            Assert.assertEquals(3, parent.numChildren);
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
            
            Assert.assertEquals(s1, parent.getChildAt(0));
            Assert.assertEquals(s2, parent.getChildAt(1));
            Assert.assertEquals(s3, parent.getChildAt(2));
            Assert.assertEquals(s4, parent.getChildAt(3));
            
            parent.sortChildren(function(child1:DisplayObject, child2:DisplayObject):int
            {
                if (child1.y < child2.y) return -1;
                else if (child1.y > child2.y) return 1;
                else return 0;
            });
            
            Assert.assertEquals(s4, parent.getChildAt(0));
            Assert.assertEquals(s2, parent.getChildAt(1));
            Assert.assertEquals(s3, parent.getChildAt(2));
            Assert.assertEquals(s1, parent.getChildAt(3));
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
            Assert.assertEquals(1, mAdded);
            Assert.assertEquals(1, mAddedToStage);
            
            // add same child again
            sprite.addChild(quad);
            
            // nothing should change, actually.
            Assert.assertEquals(1, sprite.numChildren);
            Assert.assertEquals(0, sprite.getChildIndex(quad));
            
            // since the parent does not change, no events should be dispatched 
            Assert.assertEquals(1, mAdded);
            Assert.assertEquals(1, mAddedToStage);
            Assert.assertEquals(0, mRemoved);
            Assert.assertEquals(0, mRemovedFromStage);
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
            
            Assert.assertNull(child2.parent);
            Assert.assertNull(child0.parent);
            Assert.assertEquals(child1, parent.getChildAt(0));
            Assert.assertEquals(1, parent.numChildren);
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
            Assert.assertEquals(1, mAdded);
            Assert.assertEquals(0, mRemoved);
            Assert.assertEquals(0, mAddedToStage);
            Assert.assertEquals(0, mRemovedFromStage);
            Assert.assertEquals(0, mAddedChild);
            Assert.assertEquals(0, mRemovedChild);
            
            stage.addChild(sprite);
            Assert.assertEquals(1, mAdded);
            Assert.assertEquals(0, mRemoved);
            Assert.assertEquals(1, mAddedToStage);
            Assert.assertEquals(0, mRemovedFromStage);
            Assert.assertEquals(1, mAddedChild);
            Assert.assertEquals(0, mRemovedChild);
            
            stage.removeChild(sprite);
            Assert.assertEquals(1, mAdded);
            Assert.assertEquals(0, mRemoved);
            Assert.assertEquals(1, mAddedToStage);
            Assert.assertEquals(1, mRemovedFromStage);
            Assert.assertEquals(1, mAddedChild);
            Assert.assertEquals(1, mRemovedChild);
            
            sprite.removeChild(quad);
            Assert.assertEquals(1, mAdded);
            Assert.assertEquals(1, mRemoved);
            Assert.assertEquals(1, mAddedToStage);
            Assert.assertEquals(1, mRemovedFromStage);
            Assert.assertEquals(1, mAddedChild);
            Assert.assertEquals(1, mRemovedChild);
        }
        
        [Test]
        public function testRemovedFromStage():void
        {
            var stage:Stage = new Stage(100, 100);
            var sprite:Sprite = new Sprite();
            stage.addChild(sprite);
            sprite.addEventListener(Event.REMOVED_FROM_STAGE, onSpriteRemovedFromStage);
            sprite.removeFromParent();
            Assert.assertEquals(1, mRemovedFromStage);
            
            function onSpriteRemovedFromStage(e:Event):void
            {
                // stage should still be accessible in event listener
                Assert.assertNotNull(sprite.stage);
                mRemovedFromStage++;
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
                Assert.assertNotNull(child.stage);
                Assert.assertEquals(0, childRemovedCount);
                
                childRemovedCount++;
            }
        }
        
        private function onAdded(event:Event):void { mAdded++; }
        private function onAddedToStage(event:Event):void { mAddedToStage++; }
        private function onAddedChild(event:Event):void { mAddedChild++; }
        
        private function onRemoved(event:Event):void { mRemoved++; }
        private function onRemovedFromStage(event:Event):void { mRemovedFromStage++; }
        private function onRemovedChild(event:Event):void { mRemovedChild++; }
    }
}