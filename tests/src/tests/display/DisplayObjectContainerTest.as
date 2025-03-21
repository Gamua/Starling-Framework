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

    import starling.display.DisplayObject;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.display.Stage;
    import starling.events.Event;
    import starling.unit.UnitTest;

    public class DisplayObjectContainerTest extends UnitTest
    {
        private static const E:Number = 0.0001;

        private var _added:int;
        private var _addedToStage:int;
        private var _addedChild:int;
        private var _removed:int;
        private var _removedFromStage:int;
        private var _removedChild:int;


        override public function setUp():void
        {
            _added = _addedToStage = _addedChild =
            _removed = _removedFromStage = _removedChild = 0;
        }

        override public function tearDown():void { }

        public function testChildParentHandling():void
        {
            var parent:Sprite = new Sprite();
            var child1:Sprite = new Sprite();
            var child2:Sprite = new Sprite();
            var returnValue:DisplayObject;

            assertEqual(0, parent.numChildren);
            assertNull(child1.parent);

            returnValue = parent.addChild(child1);
            assertEqual(child1, returnValue);
            assertEqual(1, parent.numChildren);
            assertEqual(parent, child1.parent);

            returnValue = parent.addChild(child2);
            assertEqual(child2, returnValue);
            assertEqual(2, parent.numChildren);
            assertEqual(parent, child2.parent);
            assertEqual(child1, parent.getChildAt(0));
            assertEqual(child2, parent.getChildAt(1));

            returnValue = parent.removeChild(child1);
            assertEqual(child1, returnValue);
            assertNull(child1.parent);
            assertEqual(child2, parent.getChildAt(0));
            returnValue = parent.removeChild(child1);
            assertNull(returnValue);
            child1.removeFromParent(); // should *not* throw an exception

            returnValue = child2.addChild(child1);
            assertEqual(child1, returnValue);
            assertTrue(parent.contains(child1));
            assertTrue(parent.contains(child2));
            assertEqual(child2, child1.parent);

            returnValue = parent.addChildAt(child1, 0);
            assertEqual(child1, returnValue);
            assertEqual(parent, child1.parent);
            assertFalse(child2.contains(child1));
            assertEqual(child1, parent.getChildAt(0));
            assertEqual(child2, parent.getChildAt(1));

            returnValue = parent.removeChildAt(0);
            assertEqual(child1, returnValue);
            assertEqual(child2, parent.getChildAt(0));
            assertEqual(1, parent.numChildren);
        }

        public function testRemoveChildren():void
        {
            var parent:Sprite;
            var numChildren:int = 10;

            // removing all children

            parent = createSprite(numChildren);
            assertEqual(10, parent.numChildren);

            parent.removeChildren();
            assertEqual(0, parent.numChildren);

            // removing a subset

            parent = createSprite(numChildren);
            parent.removeChildren(3, 5);
            assertEqual(7, parent.numChildren);
            assertEqual("2", parent.getChildAt(2).name);
            assertEqual("6", parent.getChildAt(3).name);

            // remove beginning from an id

            parent = createSprite(numChildren);
            parent.removeChildren(5);
            assertEqual(5, parent.numChildren);
            assertEqual("4", parent.getChildAt(4).name);

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

            assertEqual(child1, parent.getChildByName("child1"));
            assertEqual(child2, parent.getChildByName("child2"));
            assertEqual(child3, parent.getChildByName("child3"));
            assertNull(parent.getChildByName("non-existing"));

            child2.name = "child3";
            assertEqual(child2, parent.getChildByName("child3"));
        }

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
            assertEqual(parent.getChildAt(0), childB);
            assertEqual(parent.getChildAt(1), childA);
            assertEqual(parent.getChildAt(2), childC);

            parent.setChildIndex(childB, 1);
            assertEqual(parent.getChildAt(0), childA);
            assertEqual(parent.getChildAt(1), childB);
            assertEqual(parent.getChildAt(2), childC);

            parent.setChildIndex(childB, 2);
            assertEqual(parent.getChildAt(0), childA);
            assertEqual(parent.getChildAt(1), childC);
            assertEqual(parent.getChildAt(2), childB);

            assertEqual(3, parent.numChildren);
        }

        public function testGetChildAtWithNegativeIndices():void
        {
            var parent:Sprite = new Sprite();
            var childA:Sprite = new Sprite();
            var childB:Sprite = new Sprite();
            var childC:Sprite = new Sprite();

            parent.addChild(childA);
            parent.addChild(childB);
            parent.addChild(childC);

            assertEqual(parent.getChildAt(-3), childA);
            assertEqual(parent.getChildAt(-2), childB);
            assertEqual(parent.getChildAt(-1), childC);
        }

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
            assertEqual(parent.getChildAt(0), childC);
            assertEqual(parent.getChildAt(1), childB);
            assertEqual(parent.getChildAt(2), childA);

            parent.swapChildren(childB, childB); // should change nothing
            assertEqual(parent.getChildAt(0), childC);
            assertEqual(parent.getChildAt(1), childB);
            assertEqual(parent.getChildAt(2), childA);

            assertEqual(3, parent.numChildren);
        }

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

            assertEquivalent(sprite.width, 55);
            assertEquivalent(sprite.height, 65);

            quad1.rotation = Math.PI / 2;
            assertEquivalent(sprite.width, 75);
            assertEquivalent(sprite.height, 65);

            quad1.rotation = Math.PI;
            assertEquivalent(sprite.width, 65);
            assertEquivalent(sprite.height, 85);
        }

        public function testBounds():void
        {
            var quad:Quad = new Quad(10, 20);
            quad.x = -10;
            quad.y = 10;
            quad.rotation = Math.PI / 2;

            var sprite:Sprite = new Sprite();
            sprite.addChild(quad);

            var bounds:Rectangle = sprite.bounds;
            assertEquivalent(bounds.x, -30);
            assertEquivalent(bounds.y, 10);
            assertEquivalent(bounds.width, 20);
            assertEquivalent(bounds.height, 10);

            bounds = sprite.getBounds(sprite);
            assertEquivalent(bounds.x, -30);
            assertEquivalent(bounds.y, 10);
            assertEquivalent(bounds.width, 20);
            assertEquivalent(bounds.height, 10);
        }

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
            assertEqualRectangles(bounds, expectedBounds);

            // now rotate as well

            spriteA11.rotation = Math.PI / 4.0;
            spriteA21.rotation = Math.PI / -4.0;

            bounds = spriteA21.getBounds(spriteA11);
            expectedBounds = new Rectangle(0, 394.974762, 100, 100);
            assertEqualRectangles(bounds, expectedBounds);

            function addQuadToSprite(sprite:Sprite):void
            {
                sprite.addChild(new Quad(100, 100));
            }
        }

        public function testBoundsOfEmptyContainer():void
        {
            var sprite:Sprite = new Sprite();
            sprite.x = 100;
            sprite.y = 200;

            var bounds:Rectangle = sprite.bounds;

            assertEquivalent(bounds.x, 100);
            assertEquivalent(bounds.y, 200);
            assertEquivalent(bounds.width, 0);
            assertEquivalent(bounds.height, 0);
        }

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

            assertEquivalent(sprite.width, 200);
            assertEquivalent(sprite.height, 200);

            sprite.scaleX = 2.0;
            sprite.scaleY = 2.0;

            assertEquivalent(sprite.width, 400);
            assertEquivalent(sprite.height, 400);
        }

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

            assertEqual(s1, parent.getChildAt(0));
            assertEqual(s2, parent.getChildAt(1));
            assertEqual(s3, parent.getChildAt(2));
            assertEqual(s4, parent.getChildAt(3));

            parent.sortChildren(function(child1:DisplayObject, child2:DisplayObject):int
            {
                if (child1.y < child2.y) return -1;
                else if (child1.y > child2.y) return 1;
                else return 0;
            });

            assertEqual(s4, parent.getChildAt(0));
            assertEqual(s2, parent.getChildAt(1));
            assertEqual(s3, parent.getChildAt(2));
            assertEqual(s1, parent.getChildAt(3));
        }

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
            assertEqual(1, _added);
            assertEqual(1, _addedToStage);

            // add same child again
            sprite.addChild(quad);

            // nothing should change, actually.
            assertEqual(1, sprite.numChildren);
            assertEqual(0, sprite.getChildIndex(quad));

            // since the parent does not change, no events should be dispatched
            assertEqual(1, _added);
            assertEqual(1, _addedToStage);
            assertEqual(0, _removed);
            assertEqual(0, _removedFromStage);
        }

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

            assertDoesNotThrow(function():void
            {
                parent.removeChildAt(2);
            });

            assertNull(child2.parent);
            assertNull(child0.parent);
            assertEqual(child1, parent.getChildAt(0));
            assertEqual(1, parent.numChildren);
        }

        public function testIllegalRecursion():void
        {
            var sprite1:Sprite = new Sprite();
            var sprite2:Sprite = new Sprite();
            var sprite3:Sprite = new Sprite();

            sprite1.addChild(sprite2);
            sprite2.addChild(sprite3);

            assertThrows(function():void { sprite3.addChild(sprite1); }, ArgumentError );
        }

        public function testAddAsChildToSelf():void
        {
            var sprite:Sprite = new Sprite();
            assertThrows(function():void { sprite.addChild(sprite); }, ArgumentError );
        }

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
            assertEqual(1, _added);
            assertEqual(0, _removed);
            assertEqual(0, _addedToStage);
            assertEqual(0, _removedFromStage);
            assertEqual(0, _addedChild);
            assertEqual(0, _removedChild);

            stage.addChild(sprite);
            assertEqual(1, _added);
            assertEqual(0, _removed);
            assertEqual(1, _addedToStage);
            assertEqual(0, _removedFromStage);
            assertEqual(1, _addedChild);
            assertEqual(0, _removedChild);

            stage.removeChild(sprite);
            assertEqual(1, _added);
            assertEqual(0, _removed);
            assertEqual(1, _addedToStage);
            assertEqual(1, _removedFromStage);
            assertEqual(1, _addedChild);
            assertEqual(1, _removedChild);

            sprite.removeChild(quad);
            assertEqual(1, _added);
            assertEqual(1, _removed);
            assertEqual(1, _addedToStage);
            assertEqual(1, _removedFromStage);
            assertEqual(1, _addedChild);
            assertEqual(1, _removedChild);
        }

        public function testRemovedFromStage():void
        {
            var stage:Stage = new Stage(100, 100);
            var sprite:Sprite = new Sprite();
            stage.addChild(sprite);
            sprite.addEventListener(Event.REMOVED_FROM_STAGE, onSpriteRemovedFromStage);
            sprite.removeFromParent();
            assertEqual(1, _removedFromStage);

            function onSpriteRemovedFromStage(e:Event):void
            {
                // stage should still be accessible in event listener
                assertNotNull(sprite.stage);
                _removedFromStage++;
            }
        }

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
                assertEqual(0, childRemovedCount);

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