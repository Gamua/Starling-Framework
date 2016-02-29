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
    import flash.geom.Rectangle;

    import org.flexunit.asserts.assertEquals;
    import org.flexunit.asserts.assertNotNull;
    import org.flexunit.asserts.assertNull;
    import org.flexunit.asserts.assertTrue;

    import starling.textures.SubTexture;
    import starling.textures.Texture;
    import starling.textures.TextureAtlas;

    import tests.utils.MockTexture;

    public class TextureAtlasTest
    {		
        [Test]
        public function testXmlParsing():void
        {
            var xml:XML =
                <TextureAtlas>
                    <SubTexture name='ann' x='0'   y='0'  width='55.5' height='16' />
                    <SubTexture name='bob' x='16'  y='32' width='16'   height='32' />
                </TextureAtlas>;
            
            var texture:Texture = new MockTexture(64, 64);
            var atlas:TextureAtlas = new TextureAtlas(texture, xml);
            
            var ann:Texture = atlas.getTexture("ann");            
            var bob:Texture = atlas.getTexture("bob");
            
            assertTrue(ann is SubTexture);
            assertTrue(bob    is SubTexture);
            
            assertEquals(55.5, ann.width);
            assertEquals(16, ann.height);
            assertEquals(16, bob.width);
            assertEquals(32, bob.height);
            
            var annST:SubTexture = ann as SubTexture;
            var bobST:SubTexture = bob as SubTexture;
            
            assertEquals(0, annST.region.x);
            assertEquals(0, annST.region.y);
            assertEquals(16, bobST.region.x);
            assertEquals(32, bobST.region.y);
        }
        
        [Test]
        public function testManualCreation():void
        {
            var texture:Texture = new MockTexture(64, 64);
            var atlas:TextureAtlas = new TextureAtlas(texture);
            
            atlas.addRegion("ann", new Rectangle(0, 0, 55.5, 16));
            atlas.addRegion("bob", new Rectangle(16, 32, 16, 32));
            
            assertNotNull(atlas.getTexture("ann"));
            assertNotNull(atlas.getTexture("bob"));
            assertNull(atlas.getTexture("carl"));
            
            atlas.removeRegion("carl"); // should not blow up
            atlas.removeRegion("bob");
            
            assertNull(atlas.getTexture("bob"));
        }
        
        [Test]
        public function testGetTextures():void
        {
            var texture:Texture = new MockTexture(64, 64);
            var atlas:TextureAtlas = new TextureAtlas(texture);
            
            assertEquals(texture, atlas.texture);
            
            atlas.addRegion("ann", new Rectangle(0, 0, 8, 8));
            atlas.addRegion("prefix_3", new Rectangle(8, 0, 3, 8));
            atlas.addRegion("prefix_1", new Rectangle(16, 0, 1, 8));
            atlas.addRegion("bob", new Rectangle(24, 0, 8, 8));
            atlas.addRegion("prefix_2", new Rectangle(32, 0, 2, 8));
            
            var textures:Vector.<Texture> = atlas.getTextures("prefix_");
            
            assertEquals(3, textures.length);
            assertEquals(1, textures[0].width);
            assertEquals(2, textures[1].width);
            assertEquals(3, textures[2].width);
        }
    }
}