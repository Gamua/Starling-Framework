package
{
    import flash.display.Bitmap;
    import flash.utils.Dictionary;
    
    import starling.textures.Texture;
    import starling.textures.TextureAtlas;

    public class Assets
    {
        // Bitmaps
        
        [Embed(source = "../media/textures/background.png")]
        private static const Background:Class;
        
        [Embed(source = "../media/textures/egg_closed.png")]
        private static const EggClosed:Class;
        
        [Embed(source = "../media/textures/egg_opened.png")]
        private static const EggOpened:Class;
        
        [Embed(source = "../media/textures/logo.png")]
        private static const Logo:Class;
        
        [Embed(source = "../media/textures/button_back.png")]
        private static const ButtonBack:Class;
        
        [Embed(source = "../media/textures/button_big.png")]
        private static const ButtonBig:Class;
        
        [Embed(source = "../media/textures/button_normal.png")]
        private static const ButtonNormal:Class;
        
        [Embed(source = "../media/textures/button_square.png")]
        private static const ButtonSquare:Class;
        
        [Embed(source = "../media/textures/benchmark_object.png")]
        private static const BenchmarkObject:Class;
        
        // Fonts
        
        // The 'embedAsCFF'-part IS REQUIRED!!!!
        [Embed(source="../media/fonts/Ubuntu-R.ttf", embedAsCFF="false", fontFamily="Ubuntu")]        
        private static const UbuntuRegular:Class;
        
        // Texture Atlas
        
        [Embed(source="../media/textures/atlas.xml", mimeType="application/octet-stream")]
        public static const AtlasXml:Class;
        
        [Embed(source="../media/textures/atlas.png")]
        public static const AtlasTexture:Class;
        
        // Texture cache
        
        private static var sTextures:Dictionary = new Dictionary();
        private static var sTextureAtlas:TextureAtlas;
        
        public static function getTexture(name:String):Texture
        {
            if (sTextures[name] == undefined)
            {
                var bitmap:Bitmap = new Assets[name]();
                sTextures[name] = Texture.fromBitmap(bitmap);
            }
            
            return sTextures[name];
        }
        
        public static function getTextureAtlas():TextureAtlas
        {
            if (sTextureAtlas == null)
            {
                var texture:Texture = getTexture("AtlasTexture");
                var xml:XML = XML(new AtlasXml());
                sTextureAtlas = new TextureAtlas(texture, xml);
            }
            
            return sTextureAtlas;
        }
    }
}