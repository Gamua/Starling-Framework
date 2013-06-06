// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests
{
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import flexunit.framework.Assert;
    
    import org.flexunit.assertThat;
    import org.flexunit.asserts.assertEquals;
    import org.hamcrest.number.closeTo;
    
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.display.Stage;
    import starling.utils.HAlign;
    import starling.utils.VAlign;
    import starling.utils.deg2rad;

    public class DisplayObjectTest
    {
        private static const E:Number = 0.0001;
        
        [Test]
        public function testBase():void
        {
            var object1:Sprite = new Sprite();
            var object2:Sprite = new Sprite();
            var object3:Sprite = new Sprite();
            
            object1.addChild(object2);
            object2.addChild(object3);
            
            Assert.assertEquals(object1, object1.base);
            Assert.assertEquals(object1, object2.base);
            Assert.assertEquals(object1, object3.base);
            
            var quad:Quad = new Quad(100, 100);
            Assert.assertEquals(quad, quad.base);
        }
        
        [Test]
        public function testRootAndStage():void
        {
            var object1:Sprite = new Sprite();
            var object2:Sprite = new Sprite();
            var object3:Sprite = new Sprite();
            
            object1.addChild(object2);
            object2.addChild(object3);
            
            Assert.assertEquals(null, object1.root);
            Assert.assertEquals(null, object2.root);
            Assert.assertEquals(null, object3.root);
            Assert.assertEquals(null, object1.stage);
            Assert.assertEquals(null, object2.stage);
            Assert.assertEquals(null, object3.stage);
            
            var stage:Stage = new Stage(100, 100);
            stage.addChild(object1);
            
            Assert.assertEquals(object1, object1.root);
            Assert.assertEquals(object1, object2.root);
            Assert.assertEquals(object1, object3.root);
            Assert.assertEquals(stage, object1.stage);
            Assert.assertEquals(stage, object2.stage);
            Assert.assertEquals(stage, object3.stage);
        }
        
        [Test]
        public function testGetTransformationMatrix():void
        {
            var sprite:Sprite = new Sprite();
            var child:Sprite = new Sprite();
            child.x = 30;
            child.y = 20;
            child.scaleX = 1.2;
            child.scaleY = 1.5;
            child.rotation = Math.PI / 4.0;
            sprite.addChild(child);
            
            var matrix:Matrix = sprite.getTransformationMatrix(child);
            var expectedMatrix:Matrix = child.transformationMatrix;
            expectedMatrix.invert();            
            Helpers.compareMatrices(expectedMatrix, matrix);
            
            matrix = child.getTransformationMatrix(sprite);
            Helpers.compareMatrices(child.transformationMatrix, matrix);
                        
            // more is tested indirectly via 'testBoundsInSpace' in DisplayObjectContainerTest            
        }
        
        [Test]
        public function testSetTransformationMatrix():void
        {
            var sprite:Sprite = new Sprite();
            var matrix:Matrix = new Matrix();
            matrix.scale(1.5, 2.0);
            matrix.rotate(0.25);
            matrix.translate(10, 20);
            sprite.transformationMatrix = matrix;
            
            assertThat(sprite.scaleX, closeTo(1.5, E));
            assertThat(sprite.scaleY, closeTo(2.0, E));
            assertThat(sprite.rotation, closeTo(0.25, E));
            assertThat(sprite.x, closeTo(10, E));
            assertThat(sprite.y, closeTo(20, E));
            
            Helpers.compareMatrices(matrix, sprite.transformationMatrix);
        }
        
        [Test]
        public function testSetTransformationMatrixWithPivot():void
        {
            // pivot point information is redundant; instead, x/y properties will be modified.
            
            var sprite:Sprite = new Sprite();
            sprite.pivotX = 50;
            sprite.pivotY = 20;
            
            var matrix:Matrix = sprite.transformationMatrix;
            sprite.transformationMatrix = matrix;
            
            assertThat(sprite.x, closeTo(-50, E));
            assertThat(sprite.y, closeTo(-20, E));
            assertThat(sprite.pivotX, closeTo(0.0, E));
            assertThat(sprite.pivotY, closeTo(0.0, E));
        }
        
        [Test]
        public function testBounds():void
        {
            var quad:Quad = new Quad(10, 20);
            quad.x = -10;
            quad.y =  10;
            quad.rotation = Math.PI / 2;
            
            var bounds:Rectangle = quad.bounds;            
            assertThat(bounds.x, closeTo(-30, E));
            assertThat(bounds.y, closeTo(10, E));
            assertThat(bounds.width, closeTo(20, E));
            assertThat(bounds.height, closeTo(10, E));
            
            bounds = quad.getBounds(quad);
            assertThat(bounds.x, closeTo(0, E));
            assertThat(bounds.y, closeTo(0, E));
            assertThat(bounds.width, closeTo(10, E));
            assertThat(bounds.height, closeTo(20, E));
        }
        
        [Test]
        public function testZeroSize():void
        {
            var sprite:Sprite = new Sprite();
            assertEquals(1.0, sprite.scaleX);
            assertEquals(1.0, sprite.scaleY);
            
            // sprite is empty, scaling should thus have no effect!
            sprite.width = 100;
            sprite.height = 200;
            assertEquals(1.0, sprite.scaleX);
            assertEquals(1.0, sprite.scaleY);
            assertEquals(0.0, sprite.width);
            assertEquals(0.0, sprite.height);
            
            // setting a value to zero should be no problem -- and the original size 
            // should be remembered.
            var quad:Quad = new Quad(100, 200);
            quad.scaleX = 0.0;
            quad.scaleY = 0.0;
            assertThat(quad.width, closeTo(0, E));
            assertThat(quad.height, closeTo(0, E));
            
            quad.scaleX = 1.0;
            quad.scaleY = 1.0;
            assertThat(quad.width, closeTo(100, E));
            assertThat(quad.height, closeTo(200, E));            
        }
        
        [Test]
        public function testLocalToGlobal():void
        {
            var root:Sprite = new Sprite();
            var sprite:Sprite = new Sprite();
            sprite.x = 10;
            sprite.y = 20;
            root.addChild(sprite);
            var sprite2:Sprite = new Sprite();
            sprite2.x = 150;
            sprite2.y = 200;
            sprite.addChild(sprite2);
            
            var localPoint:Point = new Point(0, 0);
            var globalPoint:Point = sprite2.localToGlobal(localPoint);
            var expectedPoint:Point = new Point(160, 220);
            Helpers.comparePoints(expectedPoint, globalPoint);
            
            // the position of the root object should be irrelevant -- we want the coordinates
            // *within* the root coordinate system!
            root.x = 50;
            globalPoint = sprite2.localToGlobal(localPoint);
            Helpers.comparePoints(expectedPoint, globalPoint);
        }
         
        [Test]
        public function testGlobalToLocal():void
        {
            var root:Sprite = new Sprite();
            var sprite:Sprite = new Sprite();
            sprite.x = 10;
            sprite.y = 20;
            root.addChild(sprite);
            var sprite2:Sprite = new Sprite();
            sprite2.x = 150;
            sprite2.y = 200;
            sprite.addChild(sprite2);
            
            var globalPoint:Point = new Point(160, 220);
            var localPoint:Point = sprite2.globalToLocal(globalPoint);
            var expectedPoint:Point = new Point();
            Helpers.comparePoints(expectedPoint, localPoint);
            
            // the position of the root object should be irrelevant -- we want the coordinates
            // *within* the root coordinate system!
            root.x = 50;
            localPoint = sprite2.globalToLocal(globalPoint);
            Helpers.comparePoints(expectedPoint, localPoint);
        }
        
        [Test]
        public function testHitTestPoint():void
        {
            var quad:Quad = new Quad(25, 10);            
            Assert.assertNotNull(quad.hitTest(new Point(15, 5), true));
            Assert.assertNotNull(quad.hitTest(new Point(0, 0), true));
            Assert.assertNotNull(quad.hitTest(new Point(24.99, 0), true));
            Assert.assertNotNull(quad.hitTest(new Point(24.99, 9.99), true));
            Assert.assertNotNull(quad.hitTest(new Point(0, 9.99), true));
            Assert.assertNull(quad.hitTest(new Point(-1, -1), true));
            Assert.assertNull(quad.hitTest(new Point(25.01, 10.01), true));
            
            quad.visible = false;
            Assert.assertNull(quad.hitTest(new Point(15, 5), true));
            
            quad.visible = true;
            quad.touchable = false;
            Assert.assertNull(quad.hitTest(new Point(10, 5), true));
            
            quad.visible = false;
            quad.touchable = false;
            Assert.assertNull(quad.hitTest(new Point(10, 5), true));
        }
        
        [Test]
        public function testRotation():void
        {
            var quad:Quad = new Quad(100, 100);
            quad.rotation = deg2rad(400);
            assertThat(quad.rotation, closeTo(deg2rad(40), E));
            quad.rotation = deg2rad(220);
            assertThat(quad.rotation, closeTo(deg2rad(-140), E));
            quad.rotation = deg2rad(180);
            assertThat(quad.rotation, closeTo(deg2rad(180), E));
            quad.rotation = deg2rad(-90);
            assertThat(quad.rotation, closeTo(deg2rad(-90), E));
            quad.rotation = deg2rad(-179);
            assertThat(quad.rotation, closeTo(deg2rad(-179), E));
            quad.rotation = deg2rad(-180);
            assertThat(quad.rotation, closeTo(deg2rad(-180), E));
            quad.rotation = deg2rad(-181);
            assertThat(quad.rotation, closeTo(deg2rad(179), E));
            quad.rotation = deg2rad(-300);
            assertThat(quad.rotation, closeTo(deg2rad(60), E));
            quad.rotation = deg2rad(-370);
            assertThat(quad.rotation, closeTo(deg2rad(-10), E));
        }
        
        [Test]
        public function testPivotPoint():void
        {
            var width:Number = 100.0;
            var height:Number = 150.0;
            
            // a quad with a pivot point should behave exactly as a quad without 
            // pivot point inside a sprite
            
            var sprite:Sprite = new Sprite();
            var innerQuad:Quad = new Quad(width, height);
            sprite.addChild(innerQuad);            
            var quad:Quad = new Quad(width, height);            
            Helpers.compareRectangles(sprite.bounds, quad.bounds);
            
            innerQuad.x = -50;
            quad.pivotX = 50;            
            innerQuad.y = -20;
            quad.pivotY = 20;            
            Helpers.compareRectangles(sprite.bounds, quad.bounds);
            
            sprite.rotation = quad.rotation = deg2rad(45);
            Helpers.compareRectangles(sprite.bounds, quad.bounds);
            
            sprite.scaleX = quad.scaleX = 1.5;
            sprite.scaleY = quad.scaleY = 0.6;
            Helpers.compareRectangles(sprite.bounds, quad.bounds);
            
            sprite.x = quad.x = 5;
            sprite.y = quad.y = 20;
            Helpers.compareRectangles(sprite.bounds, quad.bounds);
        }
        
        [Test]
        public function testPivotWithSkew():void
        {
            var width:int = 200;
            var height:int = 100;
            var skewX:Number = 0.2;
            var skewY:Number = 0.35;
            var scaleY:Number = 0.5;
            var rotation:Number = 0.5;
            
            // create a scaled, rotated and skewed object from a sprite and a quad
            
            var quad:Quad = new Quad(width, height);
            quad.x = width / -2;
            quad.y = height / -2;
            
            var sprite:Sprite = new Sprite();
            sprite.x = width / 2;
            sprite.y = height / 2;
            sprite.skewX = skewX;
            sprite.skewY = skewY;
            sprite.rotation = rotation;
            sprite.scaleY = scaleY;
            sprite.addChild(quad);
            
            // do the same without a sprite, but with a pivoted quad
            
            var pQuad:Quad = new Quad(width, height);
            pQuad.x = width / 2;
            pQuad.y = height / 2;
            pQuad.pivotX = width / 2;
            pQuad.pivotY = height / 2;
            pQuad.skewX = skewX;
            pQuad.skewY = skewY;
            pQuad.scaleY = scaleY;
            pQuad.rotation = rotation;
            
            // the bounds have to be the same
            
            Helpers.compareRectangles(sprite.bounds, pQuad.bounds, 1.0);
        }
        
        [Test]
        public function testAlignPivot():void
        {
            var sprite:Sprite = new Sprite();
            var quad:Quad = new Quad(100, 50);
            quad.x = 200;
            quad.y = -100;
            sprite.addChild(quad);
            
            sprite.alignPivot();
            assertThat(sprite.pivotX, closeTo(250, E));
            assertThat(sprite.pivotY, closeTo(-75, E));

            sprite.alignPivot(HAlign.LEFT, VAlign.TOP);
            assertThat(sprite.pivotX, closeTo(200, E));
            assertThat(sprite.pivotY, closeTo(-100, E));

            sprite.alignPivot(HAlign.RIGHT, VAlign.BOTTOM);
            assertThat(sprite.pivotX, closeTo(300, E));
            assertThat(sprite.pivotY, closeTo(-50, E));

            sprite.alignPivot(HAlign.LEFT, VAlign.BOTTOM);
            assertThat(sprite.pivotX, closeTo(200, E));
            assertThat(sprite.pivotY, closeTo(-50, E));
        }
        
        [Test]
        public function testName():void
        {
            var sprite:Sprite = new Sprite();
            Assert.assertNull(sprite.name);
            
            sprite.name = "hugo";
            Assert.assertEquals("hugo", sprite.name);
        }
    }
}