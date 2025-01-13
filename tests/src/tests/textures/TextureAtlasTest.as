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

    import starling.display.Image;
    import starling.textures.SubTexture;
    import starling.textures.Texture;
    import starling.textures.TextureAtlas;
    import starling.unit.UnitTest;

    import utils.MockTexture;

    public class TextureAtlasTest extends UnitTest
    {
        private const E:Number = 0.0001;

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
            assertTrue(bob is SubTexture);

            assertEqual(55.5, ann.width);
            assertEqual(16, ann.height);
            assertEqual(16, bob.width);
            assertEqual(32, bob.height);

            var annST:SubTexture = ann as SubTexture;
            var bobST:SubTexture = bob as SubTexture;

            assertEqual(0, annST.region.x);
            assertEqual(0, annST.region.y);
            assertEqual(16, bobST.region.x);
            assertEqual(32, bobST.region.y);
        }

        public function testPivotParsing():void
        {
            var xml:XML =
                <TextureAtlas>
                  <SubTexture name='ann' x='0' y='0' width='16' height='32' pivotX='8' pivotY='16'/>
                  <SubTexture name='bob' x='16' y='0' width='16' height='32' pivotX='4.0'/>
                  <SubTexture name='cal' x='32' y='0' width='16' height='32'/>
                </TextureAtlas>;

            var texture:Texture = new MockTexture(64, 64);
            var atlas:TextureAtlas = new TextureAtlas(texture, xml);

            var ann:Texture = atlas.getTexture("ann");
            var bob:Texture = atlas.getTexture("bob");
            var cal:Texture = atlas.getTexture("cal");

            var annImage:Image = new Image(ann);
            assertEquivalent(annImage.pivotX, 8.0);
            assertEquivalent(annImage.pivotY, 16.0);

            var bobImage:Image = new Image(bob);
            assertEqual(bobImage.pivotX, 4.0);
            assertEqual(bobImage.pivotY, 0.0);

            var calImage:Image = new Image(cal);
            assertEqual(calImage.pivotX, 0.0);
            assertEqual(calImage.pivotY, 0.0);
        }

        public function testPivotDuplication():void
        {
            var xml:XML =
                <TextureAtlas>
                    <SubTexture name='ann0001' x='0' y='0' width='16' height='32' pivotX='8' pivotY='16'/>
                    <SubTexture name='ann0002' x='16' y='0' width='16' height='32'/>
                    <SubTexture name='anne' x='32' y='0' width='16' height='32'/>
                </TextureAtlas>;

            var texture:Texture = new MockTexture(64, 64);
            var atlas:TextureAtlas = new TextureAtlas(texture, xml);

            var ann1:Texture = atlas.getTexture("ann0001");
            var ann2:Texture = atlas.getTexture("ann0002");
            var anne:Texture = atlas.getTexture("anna");

            var annImage1:Image = new Image(ann1);
            assertEquivalent(annImage1.pivotX, 8.0);
            assertEquivalent(annImage1.pivotY, 16.0);

            var annImage2:Image = new Image(ann2);
            assertEquivalent(annImage2.pivotX, 8.0);
            assertEquivalent(annImage2.pivotY, 16.0);

            var anneImage:Image = new Image(anne);
            assertEqual(anneImage.pivotX, 0.0);
            assertEqual(anneImage.pivotY, 0.0);
        }

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

        public function testAddSubTexture():void
        {
            var texture:Texture = new MockTexture(64, 64);
            var subTexture:SubTexture = new SubTexture(texture, new Rectangle(32, 32, 32, 32));
            var atlas:TextureAtlas = new TextureAtlas(texture);
            atlas.addSubTexture("subTexture", subTexture);
            assertEqual(atlas.getTexture("subTexture"), subTexture);
        }

        public function testGetTextures():void
        {
            var texture:Texture = new MockTexture(64, 64);
            var atlas:TextureAtlas = new TextureAtlas(texture);

            assertEqual(texture, atlas.texture);

            atlas.addRegion("ann", new Rectangle(0, 0, 8, 8));
            atlas.addRegion("prefix_3", new Rectangle(8, 0, 3, 8));
            atlas.addRegion("prefix_1", new Rectangle(16, 0, 1, 8));
            atlas.addRegion("bob", new Rectangle(24, 0, 8, 8));
            atlas.addRegion("prefix_2", new Rectangle(32, 0, 2, 8));

            var textures:Vector.<Texture> = atlas.getTextures("prefix_");

            assertEqual(3, textures.length);
            assertEqual(1, textures[0].width);
            assertEqual(2, textures[1].width);
            assertEqual(3, textures[2].width);
        }

        public function testRemoveRegion():void
        {
            var texture:Texture = new MockTexture(64, 64);
            var atlas:TextureAtlas = new TextureAtlas(texture);

            atlas.addRegion("ann", new Rectangle(0, 0, 10, 10));
            atlas.addRegion("bob", new Rectangle(10, 0, 10, 10));

            atlas.removeRegion("ann");

            assertNull(atlas.getTexture("ann"));
            assertNotNull(atlas.getTexture("bob"));
        }

        public function testRemoveRegions():void
        {
            var texture:Texture = new MockTexture(64, 64);
            var atlas:TextureAtlas = new TextureAtlas(texture);

            atlas.addRegion("albert", new Rectangle(0, 0, 10, 10));
            atlas.addRegion("anna", new Rectangle(0, 10, 10, 10));
            atlas.addRegion("bastian", new Rectangle(0, 20, 10, 10));
            atlas.addRegion("cesar", new Rectangle(0, 30, 10, 10));

            atlas.removeRegions("a");

            assertNull(atlas.getTexture("albert"));
            assertNull(atlas.getTexture("anna"));
            assertNotNull(atlas.getTexture("bastian"));
            assertNotNull(atlas.getTexture("cesar"));

            atlas.removeRegions();

            assertNull(atlas.getTexture("bastian"));
            assertNull(atlas.getTexture("cesar"));
        }
    }
}