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
    import org.flexunit.asserts.assertEquals;
    import org.flexunit.asserts.assertFalse;
    import org.flexunit.asserts.assertTrue;

    import starling.display.Sprite;
    import starling.display.Sprite3D;

    public class Sprite3DTest
    {
        [Test]
        public function testBasicProperties():void
        {
            var sprite:Sprite3D = new Sprite3D();
            assertEquals(0, sprite.numChildren);
            assertEquals(0, sprite.rotationX);
            assertEquals(0, sprite.rotationY);
            assertEquals(0, sprite.pivotZ);
            assertEquals(0, sprite.z);

            sprite.addChild(new Sprite());
            sprite.rotationX = 2;
            sprite.rotationY = 3;
            sprite.pivotZ = 4;
            sprite.z = 5;

            assertEquals(1, sprite.numChildren);
            assertEquals(2, sprite.rotationX);
            assertEquals(3, sprite.rotationY);
            assertEquals(4, sprite.pivotZ);
            assertEquals(5, sprite.z);
        }

        [Test]
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