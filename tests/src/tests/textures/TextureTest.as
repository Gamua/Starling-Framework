// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2015 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.textures
{
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;
    import flash.utils.Endian;

    import org.flexunit.assertThat;
    import org.flexunit.asserts.assertEquals;
    import org.hamcrest.number.closeTo;

    import starling.rendering.VertexData;

    import starling.textures.ConcreteTexture;
    import starling.textures.SubTexture;
    import starling.textures.Texture;

    import tests.Helpers;

    public class TextureTest
    {
        private static const E:Number = 0.0001;
        
        [Test(expects="starling.errors.AbstractClassError")]
        public function testCreateTexture():void
        {
            new Texture();
        }
        
        [Test]
        public function testTextureCoordinates():void
        {
            var rootWidth:int = 256;
            var rootHeight:int = 128;
            var subTexture:SubTexture;
            var subSubTexture:SubTexture;
            var vertexData:VertexData = createStandardVertexData();
            var adjustedVertexData:VertexData;            
            var texture:ConcreteTexture = new ConcreteTexture(null, null, rootWidth, rootHeight, false, false);
            var texCoords:Point = new Point();
            
            // test subtexture filling the whole base texture
            subTexture = new SubTexture(texture, new Rectangle(0, 0, rootWidth, rootHeight));            
            adjustedVertexData = vertexData.clone(); 
            subTexture.adjustVertexData(adjustedVertexData, 0, 4);
            Helpers.compareByteArrays(vertexData.rawData, adjustedVertexData.rawData);

            // test subtexture with 50% of the size of the base texture
            subTexture = new SubTexture(texture,
                new Rectangle(rootWidth/4, rootHeight/4, rootWidth/2, rootHeight/2));
            adjustedVertexData = vertexData.clone();
            subTexture.adjustVertexData(adjustedVertexData, 0, 4);
            
            adjustedVertexData.getPoint(0, "texCoords", texCoords);
            Helpers.comparePoints(new Point(0.25, 0.25), texCoords);
            adjustedVertexData.getPoint(1, "texCoords", texCoords);
            Helpers.comparePoints(new Point(0.75, 0.25), texCoords);
            adjustedVertexData.getPoint(2, "texCoords", texCoords);
            Helpers.comparePoints(new Point(0.25, 0.75), texCoords);            
            adjustedVertexData.getPoint(3, "texCoords", texCoords);
            Helpers.comparePoints(new Point(0.75, 0.75), texCoords);
            
            // test subtexture of subtexture
            subSubTexture = new SubTexture(subTexture,
                new Rectangle(subTexture.width/4, subTexture.height/4, 
                              subTexture.width/2, subTexture.height/2));
            adjustedVertexData = vertexData.clone();
            subSubTexture.adjustVertexData(adjustedVertexData, 0, 4);
            
            adjustedVertexData.getPoint(0, "texCoords", texCoords);
            Helpers.comparePoints(new Point(0.375, 0.375), texCoords);
            adjustedVertexData.getPoint(1, "texCoords", texCoords);
            Helpers.comparePoints(new Point(0.625, 0.375), texCoords);
            adjustedVertexData.getPoint(2, "texCoords", texCoords);
            Helpers.comparePoints(new Point(0.375, 0.625), texCoords);            
            adjustedVertexData.getPoint(3, "texCoords", texCoords);
            Helpers.comparePoints(new Point(0.625, 0.625), texCoords);
            
            // test subtexture over moved texture coords (same effect as above)
            vertexData = createVertexDataWithMovedTexCoords();
            adjustedVertexData = vertexData.clone(); 
            subTexture.adjustVertexData(adjustedVertexData, 0, 4);
            
            adjustedVertexData.getPoint(0, "texCoords", texCoords);
            Helpers.comparePoints(new Point(0.375, 0.375), texCoords);
            adjustedVertexData.getPoint(1, "texCoords", texCoords);
            Helpers.comparePoints(new Point(0.625, 0.375), texCoords);
            adjustedVertexData.getPoint(2, "texCoords", texCoords);
            Helpers.comparePoints(new Point(0.375, 0.625), texCoords);            
            adjustedVertexData.getPoint(3, "texCoords", texCoords);
            Helpers.comparePoints(new Point(0.625, 0.625), texCoords);
        }
        
        [Test]
        public function testRotation():void
        {
            var rootWidth:int = 256;
            var rootHeight:int = 128;
            var subTexture:SubTexture;
            var subSubTexture:SubTexture;
            var texCoords:ByteArray;
            var texture:ConcreteTexture =
                new ConcreteTexture(null, null, rootWidth, rootHeight, false, false);

            // rotate full region once
            subTexture = new SubTexture(texture, null, false, null, true);
            texCoords = createStandardTexCoords();

            subTexture.adjustTexCoords(texCoords);
            Helpers.compareByteArraysOfFloats(texCoords, createTexCoords(1,0, 1,1, 0,0, 0,1));

            // rotate again
            subSubTexture = new SubTexture(subTexture, null, false, null, true);
            texCoords = createStandardTexCoords();

            subSubTexture.adjustTexCoords(texCoords);
            Helpers.compareByteArraysOfFloats(texCoords, createTexCoords(1,1, 0,1, 1,0, 0,0));

            // now get rotated region
            subTexture = new SubTexture(texture,
                new Rectangle(rootWidth/4, rootHeight/2, rootWidth/2, rootHeight/4),
                false, null, true);
            texCoords = createStandardTexCoords();

            subTexture.adjustTexCoords(texCoords);
            Helpers.compareByteArraysOfFloats(texCoords,
                createTexCoords(0.75, 0.5,   0.75, 0.75,   0.25, 0.5,   0.25, 0.75));

            function createStandardTexCoords():ByteArray
            {
                return createTexCoords(0, 0, 1, 0, 0, 1, 1, 1);
            }

            function createTexCoords(u0:Number, v0:Number, u1:Number, v1:Number,
                                     u2:Number, v2:Number, u3:Number, v3:Number):ByteArray
            {
                var bytes:ByteArray = new ByteArray();
                bytes.endian = Endian.LITTLE_ENDIAN;
                bytes.writeFloat(u0); bytes.writeFloat(v0);
                bytes.writeFloat(u1); bytes.writeFloat(v1);
                bytes.writeFloat(u2); bytes.writeFloat(v2);
                bytes.writeFloat(u3); bytes.writeFloat(v3);
                return bytes;
            }
        }
        
        private function createStandardVertexData():VertexData
        {
            var vertexData:VertexData = new VertexData("texCoords(float2)", 4);
            vertexData.setPoint(0, "texCoords", 0.0, 0.0);
            vertexData.setPoint(1, "texCoords", 1.0, 0.0);
            vertexData.setPoint(2, "texCoords", 0.0, 1.0);
            vertexData.setPoint(3, "texCoords", 1.0, 1.0);
            return vertexData;            
        }
        
        private function createVertexDataWithMovedTexCoords():VertexData
        {
            var vertexData:VertexData = new VertexData("texCoords(float2)", 4);
            vertexData.setPoint(0, "texCoords", 0.25, 0.25);
            vertexData.setPoint(1, "texCoords", 0.75, 0.25);
            vertexData.setPoint(2, "texCoords", 0.25, 0.75);
            vertexData.setPoint(3, "texCoords", 0.75, 0.75);
            return vertexData;
        }
        
        [Test]
        public function testGetRoot():void
        {
            var texture:ConcreteTexture = new ConcreteTexture(null, null, 32, 32, false, false);
            var subTexture:SubTexture = new SubTexture(texture, new Rectangle(0, 0, 16, 16));
            var subSubTexture:SubTexture = new SubTexture(texture, new Rectangle(0, 0, 8, 8));
            
            assertEquals(texture, texture.root);
            assertEquals(texture, subTexture.root);
            assertEquals(texture, subSubTexture.root);
            assertEquals(texture.base, subSubTexture.base);
        }
        
        [Test]
        public function testGetSize():void
        {
            var texture:ConcreteTexture = new ConcreteTexture(null, null, 32, 16, false, false, false, 2);
            var subTexture:SubTexture = new SubTexture(texture, new Rectangle(0, 0, 12, 8));
            
            assertThat(texture.width, closeTo(16, E));
            assertThat(texture.height, closeTo(8, E));
            assertThat(texture.nativeWidth, closeTo(32, E));
            assertThat(texture.nativeHeight, closeTo(16, E));
            
            assertThat(subTexture.width, closeTo(12, E));
            assertThat(subTexture.height, closeTo(8, E));
            assertThat(subTexture.nativeWidth, closeTo(24, E));
            assertThat(subTexture.nativeHeight, closeTo(16, E));
        }
    }
}