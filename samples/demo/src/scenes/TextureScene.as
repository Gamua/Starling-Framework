package scenes
{
    import starling.display.Image;
    import starling.text.TextField;
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
            image2.x = 90;
            image2.y = 85;
            addChild(image2);
            
            var image3:Image = new Image(atlas.getTexture("flight_08"));
            image3.x = 100;
            image3.y = -60;
            addChild(image3);
            
            try
            {
                // display a compressed texture
                var compressedTexture:Texture = Assets.getTexture("CompressedTexture");
                var image:Image = new Image(compressedTexture);
                image.x = Constants.CenterX - image.width / 2;
                image.y = 280;
                addChild(image);
            }
            catch (e:Error)
            {
                // if it fails, it's probably not supported
                var textField:TextField = new TextField(220, 128, 
                    "Update to Flash Player 11.4 or AIR 3.4 (swf-version=17) to see a compressed " +
                    "ATF texture instead of this boring text.", "Verdana", 14);
                textField.x = Constants.CenterX - textField.width / 2;
                textField.y = 280;
                addChild(textField);
            }
        }
    }
}