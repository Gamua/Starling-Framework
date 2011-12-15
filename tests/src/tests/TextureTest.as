// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests
{
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import flexunit.framework.Assert;
    
    import starling.textures.ConcreteTexture;
    import starling.textures.SubTexture;
    import starling.textures.Texture;
    import starling.utils.VertexData;

    public class TextureTest
    {
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
            var texture:ConcreteTexture = new ConcreteTexture(null, rootWidth, rootHeight, false, false);
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
    }
}