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
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;

    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.display.Stage;
    import starling.utils.Align;
    import starling.utils.deg2rad;
    import starling.unit.UnitTest;

    public class DisplayObjectTest extends UnitTest
    {
        private static const E:Number = 0.0001;

        public function testBase():void
        {
            var object1:Sprite = new Sprite();
            var object2:Sprite = new Sprite();
            var object3:Sprite = new Sprite();

            object1.addChild(object2);
            object2.addChild(object3);

           assertEqual(object1, object1.base);
           assertEqual(object1, object2.base);
           assertEqual(object1, object3.base);

            var quad:Quad = new Quad(100, 100);
            assertEqual(quad, quad.base);
        }

        public function testRootAndStage():void
        {
            var object1:Sprite = new Sprite();
            var object2:Sprite = new Sprite();
            var object3:Sprite = new Sprite();

            object1.addChild(object2);
            object2.addChild(object3);

            assertEqual(null, object1.root);
            assertEqual(null, object2.root);
            assertEqual(null, object3.root);
            assertEqual(null, object1.stage);
            assertEqual(null, object2.stage);
            assertEqual(null, object3.stage);

            var stage:Stage = new Stage(100, 100);
            stage.addChild(object1);

            assertEqual(object1, object1.root);
            assertEqual(object1, object2.root);
            assertEqual(object1, object3.root);
            assertEqual(stage, object1.stage);
            assertEqual(stage, object2.stage);
            assertEqual(stage, object3.stage);
        }

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
            assertEqualMatrices(expectedMatrix, matrix);

            matrix = child.getTransformationMatrix(sprite);
            assertEqualMatrices(child.transformationMatrix, matrix);

            // more is tested indirectly via 'testBoundsInSpace' in DisplayObjectContainerTest
        }

        public function testSetTransformationMatrix():void
        {
            var sprite:Sprite = new Sprite();
            var matrix:Matrix = new Matrix();
            matrix.scale(1.5, 2.0);
            matrix.rotate(0.25);
            matrix.translate(10, 20);
            sprite.transformationMatrix = matrix;

            assertEquivalent(sprite.scaleX, 1.5);
            assertEquivalent(sprite.scaleY, 2.0);
            assertEquivalent(sprite.rotation, 0.25);
            assertEquivalent(sprite.x, 10);
            assertEquivalent(sprite.y, 20);

            assertEqualMatrices(matrix, sprite.transformationMatrix);
        }

        public function testSetTransformationMatrixWithPivot():void
        {
            // pivot point information is redundant; instead, x/y properties will be modified.

            var sprite:Sprite = new Sprite();
            sprite.pivotX = 50;
            sprite.pivotY = 20;

            var matrix:Matrix = sprite.transformationMatrix;
            sprite.transformationMatrix = matrix;

            assertEquivalent(sprite.x, -50);
            assertEquivalent(sprite.y, -20);
            assertEquivalent(sprite.pivotX, 0.0);
            assertEquivalent(sprite.pivotY, 0.0);
        }

        public function testSetTransformationMatrixWithRightAngles():void
        {
            var sprite:Sprite = new Sprite();
            var matrix:Matrix = new Matrix();
            var angles:Array = [Math.PI / 2.0, Math.PI / -2.0];

            for each (var angle:Number in angles)
            {
                matrix.identity();
                matrix.rotate(angle);
                sprite.transformationMatrix = matrix;

                assertEquivalent(sprite.x, 0);
                assertEquivalent(sprite.y, 0);
                assertEquivalent(sprite.skewX, 0.0);
                assertEquivalent(sprite.skewY, 0.0);
                assertEquivalent(sprite.rotation, angle);
            }
        }

        public function testSetTransformationMatrixWithZeroValues():void
        {
            var sprite:Sprite = new Sprite();
            var matrix:Matrix = new Matrix(0, 0, 0, 0, 0, 0);
            sprite.transformationMatrix = matrix;

            assertEqual(0.0, sprite.x);
            assertEqual(0.0, sprite.y);
            assertEqual(0.0, sprite.scaleX);
            assertEqual(0.0, sprite.scaleY);
            assertEqual(0.0, sprite.rotation);
            assertEqual(0.0, sprite.skewX);
            assertEqual(0.0, sprite.skewY);
        }

        public function testBounds():void
        {
            var quad:Quad = new Quad(10, 20);
            quad.x = -10;
            quad.y =  10;
            quad.rotation = Math.PI / 2;

            var bounds:Rectangle = quad.bounds;
            assertEquivalent(bounds.x, -30);
            assertEquivalent(bounds.y, 10);
            assertEquivalent(bounds.width, 20);
            assertEquivalent(bounds.height, 10);

            bounds = quad.getBounds(quad);
            assertEquivalent(bounds.x, 0);
            assertEquivalent(bounds.y, 0);
            assertEquivalent(bounds.width, 10);
            assertEquivalent(bounds.height, 20);
        }

        public function testZeroSize():void
        {
            var sprite:Sprite = new Sprite();
            assertEqual(1.0, sprite.scaleX);
            assertEqual(1.0, sprite.scaleY);

            // sprite is empty, scaling should thus have no effect!
            sprite.width = 100;
            sprite.height = 200;
            assertEqual(1.0, sprite.scaleX);
            assertEqual(1.0, sprite.scaleY);
            assertEqual(0.0, sprite.width);
            assertEqual(0.0, sprite.height);

            // setting a value to zero should be no problem -- and the original size
            // should be remembered.
            var quad:Quad = new Quad(100, 200);
            quad.scaleX = 0.0;
            quad.scaleY = 0.0;
            assertEquivalent(quad.width, 0);
            assertEquivalent(quad.height, 0);

            quad.scaleX = 1.0;
            quad.scaleY = 1.0;
            assertEquivalent(quad.width, 100);
            assertEquivalent(quad.height, 200);

            // the same should work with width & height
            quad = new Quad(100, 200);
            quad.width = 0;
            quad.height = 0;
            assertEquivalent(quad.width, 0);
            assertEquivalent(quad.height, 0);

            quad.width = 50;
            quad.height = 100;
            assertEquivalent(quad.scaleX, 0.5);
            assertEquivalent(quad.scaleY, 0.5);
        }

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
            assertEqualPoints(expectedPoint, globalPoint);

            // the position of the root object should be irrelevant -- we want the coordinates
            // *within* the root coordinate system!
            root.x = 50;
            globalPoint = sprite2.localToGlobal(localPoint);
            assertEqualPoints(expectedPoint, globalPoint);
        }

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
            assertEqualPoints(expectedPoint, localPoint);

            // the position of the root object should be irrelevant -- we want the coordinates
            // *within* the root coordinate system!
            root.x = 50;
            localPoint = sprite2.globalToLocal(globalPoint);
            assertEqualPoints(expectedPoint, localPoint);
        }

        public function testHitTestPoint():void
        {
            var quad:Quad = new Quad(25, 10);
            assertNotNull(quad.hitTest(new Point(15, 5)));
            assertNotNull(quad.hitTest(new Point(0, 0)));
            assertNotNull(quad.hitTest(new Point(24.99, 0)));
            assertNotNull(quad.hitTest(new Point(24.99, 9.99)));
            assertNotNull(quad.hitTest(new Point(0, 9.99)));
            assertNull(quad.hitTest(new Point(-1, -1)));
            assertNull(quad.hitTest(new Point(25.01, 10.01)));

            quad.visible = false;
            assertNull(quad.hitTest(new Point(15, 5)));

            quad.visible = true;
            quad.touchable = false;
            assertNull(quad.hitTest(new Point(10, 5)));

            quad.visible = false;
            quad.touchable = false;
            assertNull(quad.hitTest(new Point(10, 5)));
        }

        public function testRotation():void
        {
            var quad:Quad = new Quad(100, 100);
            quad.rotation = deg2rad(400);
            assertEquivalent(quad.rotation, deg2rad(40));
            quad.rotation = deg2rad(220);
            assertEquivalent(quad.rotation, deg2rad(-140));
            quad.rotation = deg2rad(180);
            assertEquivalent(quad.rotation, deg2rad(180));
            quad.rotation = deg2rad(-90);
            assertEquivalent(quad.rotation, deg2rad(-90));
            quad.rotation = deg2rad(-179);
            assertEquivalent(quad.rotation, deg2rad(-179));
            quad.rotation = deg2rad(-180);
            assertEquivalent(quad.rotation, deg2rad(-180));
            quad.rotation = deg2rad(-181);
            assertEquivalent(quad.rotation, deg2rad(179));
            quad.rotation = deg2rad(-300);
            assertEquivalent(quad.rotation, deg2rad(60));
            quad.rotation = deg2rad(-370);
            assertEquivalent(quad.rotation, deg2rad(-10));
        }

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
            assertEqualRectangles(sprite.bounds, quad.bounds);

            innerQuad.x = -50;
            quad.pivotX = 50;
            innerQuad.y = -20;
            quad.pivotY = 20;
            assertEqualRectangles(sprite.bounds, quad.bounds);

            sprite.rotation = quad.rotation = deg2rad(45);
            assertEqualRectangles(sprite.bounds, quad.bounds);

            sprite.scaleX = quad.scaleX = 1.5;
            sprite.scaleY = quad.scaleY = 0.6;
            assertEqualRectangles(sprite.bounds, quad.bounds);

            sprite.x = quad.x = 5;
            sprite.y = quad.y = 20;
            assertEqualRectangles(sprite.bounds, quad.bounds);
        }

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

            assertEqualRectangles(sprite.bounds, pQuad.bounds, 1.0);
        }

        public function testAlignPivot():void
        {
            var sprite:Sprite = new Sprite();
            var quad:Quad = new Quad(100, 50);
            quad.x = 200;
            quad.y = -100;
            sprite.addChild(quad);

            sprite.alignPivot();
            assertEquivalent(sprite.pivotX, 250);
            assertEquivalent(sprite.pivotY, -75);

            sprite.alignPivot(Align.LEFT, Align.TOP);
            assertEquivalent(sprite.pivotX, 200);
            assertEquivalent(sprite.pivotY, -100);

            sprite.alignPivot(Align.RIGHT, Align.BOTTOM);
            assertEquivalent(sprite.pivotX, 300);
            assertEquivalent(sprite.pivotY, -50);

            sprite.alignPivot(Align.LEFT, Align.BOTTOM);
            assertEquivalent(sprite.pivotX, 200);
            assertEquivalent(sprite.pivotY, -50);
        }

        public function testName():void
        {
            var sprite:Sprite = new Sprite();
            assertNull(sprite.name);

            sprite.name = "hugo";
            assertEqual("hugo", sprite.name);
        }

        public function testUniformScale():void
        {
            var sprite:Sprite = new Sprite();
            assertEquivalent(sprite.scale, 1.0);

            sprite.scaleY = 0.5;
            assertEquivalent(sprite.scale, 1.0);

            sprite.scaleX = 0.25;
            assertEquivalent(sprite.scale, 0.25);

            sprite.scale = 0.75;
            assertEquivalent(sprite.scaleX, 0.75);
            assertEquivalent(sprite.scaleY, 0.75);
        }

        public function testSetWidthNegativeAndBack():void
        {
            // -> https://github.com/Gamua/Starling-Framework/issues/850

            var quad:Quad = new Quad(100, 100);

            quad.width = -10;
            quad.height = -10;

            assertEquivalent(quad.scaleX, -0.1);
            assertEquivalent(quad.scaleY, -0.1);

            quad.width = 100;
            quad.height = 100;

            assertEquivalent(quad.scaleX, 1.0);
            assertEquivalent(quad.scaleY, 1.0);
        }

        public function testSetWidthAndHeightToNaNAndBack():void
        {
            var quad:Quad = new Quad(100, 200);

            quad.width  = NaN;
            quad.height = NaN;

            assertTrue(isNaN(quad.width));
            assertTrue(isNaN(quad.height));

            quad.width = 100;
            quad.height = 200;

            assertEquivalent(quad.width, 100);
            assertEquivalent(quad.height, 200);
        }

        public function testSetWidthAndHeightToVerySmallValueAndBack():void
        {
            var sprite:Sprite = new Sprite();
            var quad:Quad = new Quad(100, 100);
            sprite.addChild(quad);
            sprite.x = sprite.y = 480;

            sprite.width = 2.842170943040401e-14;
            sprite.width = 100;

            sprite.height = 2.842170943040401e-14;
            sprite.height = 100;

            assertEquivalent(sprite.width, 100);
            assertEquivalent(sprite.height, 100);
        }
    }
}