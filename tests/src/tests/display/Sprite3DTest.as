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
    import starling.display.Sprite;
    import starling.display.Sprite3D;
    import starling.unit.UnitTest;

    public class Sprite3DTest extends UnitTest
    {
        public function testBasicProperties():void
        {
            var sprite:Sprite3D = new Sprite3D();
            assertEqual(0, sprite.numChildren);
            assertEqual(0, sprite.rotationX);
            assertEqual(0, sprite.rotationY);
            assertEqual(0, sprite.pivotZ);
            assertEqual(0, sprite.z);

            sprite.addChild(new Sprite());
            sprite.rotationX = 2;
            sprite.rotationY = 3;
            sprite.pivotZ = 4;
            sprite.z = 5;

            assertEqual(1, sprite.numChildren);
            assertEqual(2, sprite.rotationX);
            assertEqual(3, sprite.rotationY);
            assertEqual(4, sprite.pivotZ);
            assertEqual(5, sprite.z);
        }

        public function testIs3D():void
        {
            var sprite3D:Sprite3D = new Sprite3D();
            assertTrue(sprite3D.is3D);

            var sprite:Sprite = new Sprite();
            assertFalse(sprite.is3D);

            var child:Sprite = new Sprite();
            sprite.addChild(child);
            assertFalse(child.is3D);

            sprite3D.addChild(sprite);
            assertTrue(sprite.is3D);
            assertTrue(child.is3D);

            sprite.removeFromParent();
            assertFalse(sprite.is3D);
            assertFalse(child.is3D);
        }
    }
}