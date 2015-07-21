// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2014 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.display
{
    import flexunit.framework.Assert;
    
    import starling.display.Sprite;
    import starling.display.Sprite3D;

    public class Sprite3DTest
    {
        [Test]
        public function testBasicProperties():void
        {
            var sprite:Sprite3D = new Sprite3D();
            Assert.assertEquals(0, sprite.numChildren);
            Assert.assertEquals(0, sprite.rotationX);
            Assert.assertEquals(0, sprite.rotationY);
            Assert.assertEquals(0, sprite.pivotZ);
            Assert.assertEquals(0, sprite.z);

            sprite.addChild(new Sprite());
            sprite.rotationX = 2;
            sprite.rotationY = 3;
            sprite.pivotZ = 4;
            sprite.z = 5;

            Assert.assertEquals(1, sprite.numChildren);
            Assert.assertEquals(2, sprite.rotationX);
            Assert.assertEquals(3, sprite.rotationY);
            Assert.assertEquals(4, sprite.pivotZ);
            Assert.assertEquals(5, sprite.z);
        }

        [Test]
        public function testIs3D():void
        {
            var sprite3D:Sprite3D = new Sprite3D();
            Assert.assertTrue(sprite3D.is3D);

            var sprite:Sprite = new Sprite();
            Assert.assertFalse(sprite.is3D);

            var child:Sprite = new Sprite();
            sprite.addChild(child);
            Assert.assertFalse(child.is3D);

            sprite3D.addChild(sprite);
            Assert.assertTrue(sprite.is3D);
            Assert.assertTrue(child.is3D);

            sprite.removeFromParent();
            Assert.assertFalse(sprite.is3D);
            Assert.assertFalse(child.is3D);
        }
    }
}