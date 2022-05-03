package scenes
{
    import starling.display.Image;
    import starling.text.TextField;
    import starling.textures.Texture;

    public class TextureScene extends Scene
    {
        public function TextureScene()
        {
            // the flight textures are actually loaded from an atlas texture.
            // the "AssetManager" class wraps it away for us.
            
            var image1:Image = new Image(Game.assets.getTexture("flight_00"));
            image1.x = -20;
            image1.y = 0;
            addChild(image1);
            
            var image2:Image = new Image(Game.assets.getTexture("flight_04"));
            image2.x = 90;
            image2.y = 85;
            addChild(image2);
            
            var image3:Image = new Image(Game.assets.getTexture("flight_08"));
            image3.x = 100;
            image3.y = -60;
            addChild(image3);

            // display a compressed texture

            var compressedTexture:Texture = Game.assets.getTexture("compressed_texture");
            var image4:Image = new Image(compressedTexture);
            image4.x = Constants.CenterX - image4.width / 2;
            image4.y = 280;
            addChild(image4);
        }
    }
}