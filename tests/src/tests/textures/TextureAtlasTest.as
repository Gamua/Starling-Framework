// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.textures
{
    import flash.display3D.Context3DTextureFormat;
    import flash.geom.Rectangle;
    
    import flexunit.framework.Assert;
    
    import starling.textures.ConcreteTexture;
    import starling.textures.SubTexture;
    import starling.textures.Texture;
    import starling.textures.TextureAtlas;

    public class TextureAtlasTest
    {		
        [Test]
        public function testXmlParsing():void
        {
            var format:String = Context3DTextureFormat.BGRA;
            var xml:XML = 
                <TextureAtlas>
                    <SubTexture name='ann' x='0'   y='0'  width='55.5' height='16' />
                    <SubTexture name='bob' x='16'  y='32' width='16'   height='32' />
                </TextureAtlas>;
            
            var texture:Texture = new ConcreteTexture(null, format, 64, 64, false, false);
            var atlas:TextureAtlas = new TextureAtlas(texture, xml);
            
            var ann:Texture = atlas.getTexture("ann");            
            var bob:Texture = atlas.getTexture("bob");
            
            Assert.assertTrue(ann is SubTexture);
            Assert.assertTrue(bob    is SubTexture);
            
            Assert.assertEquals(55.5, ann.width);
            Assert.assertEquals(16, ann.height);
            Assert.assertEquals(16, bob.width);
            Assert.assertEquals(32, bob.height);
            
            var annST:SubTexture = ann as SubTexture;
            var bobST:SubTexture = bob as SubTexture;
            
            Assert.assertEquals(0, annST.clipping.x);
            Assert.assertEquals(0, annST.clipping.y);
            Assert.assertEquals(0.25, bobST.clipping.x);
            Assert.assertEquals(0.5, bobST.clipping.y);
        }
        
        [Test]
        public function testManualCreation():void
        {
            var format:String = Context3DTextureFormat.BGRA;
            var texture:Texture = new ConcreteTexture(null, format, 64, 64, false, false);
            var atlas:TextureAtlas = new TextureAtlas(texture);
            
            atlas.addRegion("ann", new Rectangle(0, 0, 55.5, 16));
            atlas.addRegion("bob", new Rectangle(16, 32, 16, 32));
            
            Assert.assertNotNull(atlas.getTexture("ann"));
            Assert.assertNotNull(atlas.getTexture("bob"));
            Assert.assertNull(atlas.getTexture("carl"));
            
            atlas.removeRegion("carl"); // should not blow up
            atlas.removeRegion("bob");
            
            Assert.assertNull(atlas.getTexture("bob"));
        }
        
        [Test]
        public function testGetTextures():void
        {
            var format:String = Context3DTextureFormat.BGRA;
            var texture:Texture = new ConcreteTexture(null, format, 64, 64, false, false);
            var atlas:TextureAtlas = new TextureAtlas(texture);
            
            Assert.assertEquals(texture, atlas.texture);
            
            atlas.addRegion("ann", new Rectangle(0, 0, 8, 8));
            atlas.addRegion("prefix_3", new Rectangle(8, 0, 3, 8));
            atlas.addRegion("prefix_1", new Rectangle(16, 0, 1, 8));
            atlas.addRegion("bob", new Rectangle(24, 0, 8, 8));
            atlas.addRegion("prefix_2", new Rectangle(32, 0, 2, 8));
            
            var textures:Vector.<Texture> = atlas.getTextures("prefix_");
            
            Assert.assertEquals(3, textures.length);
            Assert.assertEquals(1, textures[0].width);
            Assert.assertEquals(2, textures[1].width);
            Assert.assertEquals(3, textures[2].width);
        }
    }
}