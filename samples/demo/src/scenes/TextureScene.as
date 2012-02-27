package scenes
{
    import starling.display.Image;
    import starling.textures.Texture;
    import starling.textures.TextureAtlas;

    public class TextureScene extends Scene
    {
        public function TextureScene()
        {
            // load textures from an atlas
            
            var atlas:TextureAtlas = Assets.getTextureAtlas();
            
            var image1:Image = new Image(atlas.getTexture("flight_00"));
            image1.x = -20;
            image1.y = 0;
            addChild(image1);
            
            var image2:Image = new Image(atlas.getTexture("flight_04"));
            image2.x = 80;
            image2.y = 90;
            addChild(image2);
            
            var image3:Image = new Image(atlas.getTexture("flight_08"));
            image3.x = 120;
            image3.y = -45;
            addChild(image3);
            
            // display a compressed texture
            
            var compressedTexture:Texture = Assets.getTexture("CompressedTexture");
            var image:Image = new Image(compressedTexture);
            image.x = Constants.CenterX - image.width / 2;
            image.y = 280;
            addChild(image);
            
        }
    }
}