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
    import flash.geom.Point;
    import flash.geom.Rectangle;

    import starling.rendering.VertexData;
    import starling.textures.SubTexture;
    import starling.textures.Texture;
    import starling.unit.UnitTest;

    import utils.MockTexture;

    public class TextureTest extends UnitTest
    {
        private static const E:Number = 0.0001;

        public function testCreateTexture():void
        {
            assertThrows(function():void { new Texture(); });
        }

        public function testTextureCoordinates():void
        {
            var rootWidth:int = 256;
            var rootHeight:int = 128;
            var subTexture:SubTexture;
            var subSubTexture:SubTexture;
            var texCoords:Point = new Point();
            var expected:Point = new Point();
            var texture:Texture = new MockTexture(rootWidth, rootHeight);

            // test sub texture filling the whole base texture
            subTexture = new SubTexture(texture, new Rectangle(0, 0, rootWidth, rootHeight));
            subTexture.localToGlobal(1, 1, texCoords);
            expected.setTo(1, 1);
            assertEqualPoints(expected, texCoords);

            // test subtexture with 50% of the size of the base texture
            subTexture = new SubTexture(texture,
                new Rectangle(rootWidth/4, rootHeight/4, rootWidth/2, rootHeight/2));
            subTexture.localToGlobal(1, 0.5, texCoords);
            expected.setTo(0.75, 0.5);
            assertEqualPoints(expected, texCoords);

            // test subtexture of subtexture
            subSubTexture = new SubTexture(subTexture,
                new Rectangle(subTexture.width/4, subTexture.height/4,
                              subTexture.width/2, subTexture.height/2));
            subSubTexture.localToGlobal(1, 0.5, texCoords);
            expected.setTo(0.625, 0.5);
            assertEqualPoints(expected, texCoords);
        }

        public function testRotation():void
        {
            var rootWidth:int = 256;
            var rootHeight:int = 128;
            var subTexture:SubTexture;
            var subSubTexture:SubTexture;
            var texCoords:Point = new Point();
            var expected:Point = new Point();
            var texture:Texture = new MockTexture(rootWidth, rootHeight);

            // rotate full region once
            subTexture = new SubTexture(texture, null, false, null, true);
            subTexture.localToGlobal(1, 1, texCoords);
            expected.setTo(0, 1);
            assertEqualPoints(expected, texCoords);

            // rotate again
            subSubTexture = new SubTexture(subTexture, null, false, null, true);
            subSubTexture.localToGlobal(1, 1, texCoords);
            expected.setTo(0, 0);
            assertEqualPoints(expected, texCoords);

            // now get rotated region
            subTexture = new SubTexture(texture,
                new Rectangle(rootWidth/4, rootHeight/2, rootWidth/2, rootHeight/4),
                false, null, true);
            subTexture.localToGlobal(1, 1, texCoords);
            expected.setTo(0.25, 0.75);
            assertEqualPoints(expected, texCoords);
        }

        public function testSetupVertexPositions():void
        {
            var size:Rectangle = new Rectangle(0, 0, 60, 40);
            var frame:Rectangle = new Rectangle(-20, -30, 100, 100);
            var texture:Texture = new MockTexture(size.width, size.height);
            var subTexture:SubTexture = new SubTexture(texture, null, false, frame);
            var vertexData:VertexData = new VertexData("pos:float2");
            var expected:Rectangle = new Rectangle();
            var result:Rectangle, bounds:Rectangle;

            assertEqual(100, subTexture.frameWidth);
            assertEqual(100, subTexture.frameHeight);

            subTexture.setupVertexPositions(vertexData, 0, "pos");
            assertEqual(4, vertexData.numVertices);

            result = vertexData.getBounds("pos");
            expected.setTo(20, 30, 60, 40);
            assertEqualRectangles(expected, result);

            bounds = new Rectangle(1, 2, 200, 50);
            subTexture.setupVertexPositions(vertexData, 0, "pos", bounds);
            result = vertexData.getBounds("pos");
            expected.setTo(41, 17, 120, 20);
            assertEqualRectangles(expected, result);
        }

        public function testGetRoot():void
        {
            var texture:Texture = new MockTexture(32, 32);
            var subTexture:SubTexture = new SubTexture(texture, new Rectangle(0, 0, 16, 16));
            var subSubTexture:SubTexture = new SubTexture(texture, new Rectangle(0, 0, 8, 8));

            assertEqual(texture, texture.root);
            assertEqual(texture, subTexture.root);
            assertEqual(texture, subSubTexture.root);
            assertEqual(texture.base, subSubTexture.base);
        }

        public function testGetSize():void
        {
            var texture:Texture = new MockTexture(32, 16, 2);
            var subTexture:SubTexture = new SubTexture(texture, new Rectangle(0, 0, 12, 8));

            assertEquivalent(texture.width, 16);
            assertEquivalent(texture.height, 8);
            assertEquivalent(texture.nativeWidth, 32);
            assertEquivalent(texture.nativeHeight, 16);

            assertEquivalent(subTexture.width, 12);
            assertEquivalent(subTexture.height, 8);
            assertEquivalent(subTexture.nativeWidth, 24);
            assertEquivalent(subTexture.nativeHeight, 16);
        }

        public function testScaleModifier():void
        {
            var texCoords:Point;
            var region:Rectangle;
            var texture:Texture = new MockTexture(32, 16, 2);
            var subTexture:SubTexture = new SubTexture(texture, null, false, null, false, 0.5);

            // construct texture with scale factor 1
            assertEquivalent(subTexture.scale, 1.0);
            assertEquivalent(subTexture.width, texture.nativeWidth);
            assertEquivalent(subTexture.height, texture.nativeHeight);
            assertEquivalent(subTexture.nativeWidth, texture.nativeWidth);
            assertEquivalent(subTexture.nativeHeight, texture.nativeHeight);

            // and from the one above, back to the original factor of 2
            var subSubTexture:SubTexture = new SubTexture(subTexture, null, false, null, false, 2.0);
            assertEquivalent(subSubTexture.scale, 2.0);
            assertEquivalent(subSubTexture.width, texture.width);
            assertEquivalent(subSubTexture.height, texture.height);
            assertEquivalent(subSubTexture.nativeWidth, texture.nativeWidth);
            assertEquivalent(subSubTexture.nativeHeight, texture.nativeHeight);

            // now make the resolution of the original texture even higher
            subTexture = new SubTexture(texture, null, false, null, false, 2);
            assertEquivalent(subTexture.scale, 4.0);
            assertEquivalent(subTexture.width, texture.width / 2);
            assertEquivalent(subTexture.height, texture.height / 2);
            assertEquivalent(subTexture.nativeWidth, texture.nativeWidth);
            assertEquivalent(subTexture.nativeHeight, texture.nativeHeight);

            // test region
            region = new Rectangle(8, 4, 8, 4);
            subTexture = new SubTexture(texture, region, false, null, false, 0.5);
            assertEquivalent(subTexture.width, region.width * 2);
            assertEquivalent(subTexture.height, region.height * 2);
            assertEquivalent(subTexture.nativeWidth, texture.nativeWidth / 2);
            assertEquivalent(subTexture.nativeHeight, texture.nativeHeight / 2);

            texCoords = subTexture.localToGlobal(0, 0);
            assertEqualPoints(new Point(0.5, 0.5), texCoords);

            texCoords = subTexture.localToGlobal(1, 1);
            assertEqualPoints(new Point(1, 1), texCoords);
        }
    }
}