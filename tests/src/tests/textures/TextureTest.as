// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2014 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.textures
{
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import org.flexunit.assertThat;
    import org.flexunit.asserts.assertEquals;
    import org.hamcrest.number.closeTo;
    
    import starling.textures.ConcreteTexture;
    import starling.textures.SubTexture;
    import starling.textures.Texture;
    import starling.utils.VertexData;
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
            Helpers.compareVectors(vertexData.rawData, adjustedVertexData.rawData);
            
            // test subtexture with 50% of the size of the base texture
            subTexture = new SubTexture(texture,
                new Rectangle(rootWidth/4, rootHeight/4, rootWidth/2, rootHeight/2));
            adjustedVertexData = vertexData.clone();
            subTexture.adjustVertexData(adjustedVertexData, 0, 4);
            
            adjustedVertexData.getTexCoords(0, texCoords);
            Helpers.comparePoints(new Point(0.25, 0.25), texCoords);
            adjustedVertexData.getTexCoords(1, texCoords);
            Helpers.comparePoints(new Point(0.75, 0.25), texCoords);
            adjustedVertexData.getTexCoords(2, texCoords);
            Helpers.comparePoints(new Point(0.25, 0.75), texCoords);            
            adjustedVertexData.getTexCoords(3, texCoords);
            Helpers.comparePoints(new Point(0.75, 0.75), texCoords);
            
            // test subtexture of subtexture
            subSubTexture = new SubTexture(subTexture,
                new Rectangle(subTexture.width/4, subTexture.height/4, 
                              subTexture.width/2, subTexture.height/2));
            adjustedVertexData = vertexData.clone();
            subSubTexture.adjustVertexData(adjustedVertexData, 0, 4);
            
            adjustedVertexData.getTexCoords(0, texCoords);
            Helpers.comparePoints(new Point(0.375, 0.375), texCoords);
            adjustedVertexData.getTexCoords(1, texCoords);
            Helpers.comparePoints(new Point(0.625, 0.375), texCoords);
            adjustedVertexData.getTexCoords(2, texCoords);
            Helpers.comparePoints(new Point(0.375, 0.625), texCoords);            
            adjustedVertexData.getTexCoords(3, texCoords);
            Helpers.comparePoints(new Point(0.625, 0.625), texCoords);
            
            // test subtexture over moved texture coords (same effect as above)
            vertexData = createVertexDataWithMovedTexCoords();
            adjustedVertexData = vertexData.clone(); 
            subTexture.adjustVertexData(adjustedVertexData, 0, 4);
            
            adjustedVertexData.getTexCoords(0, texCoords);
            Helpers.comparePoints(new Point(0.375, 0.375), texCoords);
            adjustedVertexData.getTexCoords(1, texCoords);
            Helpers.comparePoints(new Point(0.625, 0.375), texCoords);
            adjustedVertexData.getTexCoords(2, texCoords);
            Helpers.comparePoints(new Point(0.375, 0.625), texCoords);            
            adjustedVertexData.getTexCoords(3, texCoords);
            Helpers.comparePoints(new Point(0.625, 0.625), texCoords);
        }
        
        [Test]
        public function testRotation():void
        {
            var rootWidth:int = 256;
            var rootHeight:int = 128;
            var subTexture:SubTexture;
            var subSubTexture:SubTexture;
            var texCoords:Vector.<Number>;
            var texture:ConcreteTexture =
                new ConcreteTexture(null, null, rootWidth, rootHeight, false, false);
            
            // rotate full region once
            subTexture = new SubTexture(texture, null, false, null, true);
            texCoords = createStandardTexCoords();
            
            subTexture.adjustTexCoords(texCoords);
            Helpers.compareVectors(texCoords, new <Number>[1,0, 1,1, 0,0, 0,1]);
            
            // rotate again
            subSubTexture = new SubTexture(subTexture, null, false, null, true);
            texCoords = createStandardTexCoords();
            
            subSubTexture.adjustTexCoords(texCoords);
            Helpers.compareVectors(texCoords, new <Number>[1,1, 0,1, 1,0, 0,0]);
            
            // now get rotated region
            subTexture = new SubTexture(texture, 
                new Rectangle(rootWidth/4, rootHeight/2, rootWidth/2, rootHeight/4), 
                false, null, true);
            texCoords = createStandardTexCoords();
            
            subTexture.adjustTexCoords(texCoords);
            Helpers.compareVectors(texCoords, 
                new <Number>[0.75, 0.5,   0.75, 0.75,   0.25, 0.5,   0.25, 0.75]); 
            
            function createStandardTexCoords():Vector.<Number>
            {
                return new <Number>[0,0, 1,0, 0,1, 1,1];
            }
        }
        
        private function createStandardVertexData():VertexData
        {
            var vertexData:VertexData = new VertexData(4);
            vertexData.setTexCoords(0, 0.0, 0.0);
            vertexData.setTexCoords(1, 1.0, 0.0);
            vertexData.setTexCoords(2, 0.0, 1.0);
            vertexData.setTexCoords(3, 1.0, 1.0);
            return vertexData;            
        }
        
        private function createVertexDataWithMovedTexCoords():VertexData
        {
            var vertexData:VertexData = new VertexData(4);
            vertexData.setTexCoords(0, 0.25, 0.25);
            vertexData.setTexCoords(1, 0.75, 0.25);
            vertexData.setTexCoords(2, 0.25, 0.75);
            vertexData.setTexCoords(3, 0.75, 0.75);
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