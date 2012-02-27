package
{
    import flash.display.Bitmap;
    import flash.media.Sound;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;
    
    import starling.text.BitmapFont;
    import starling.text.TextField;
    import starling.textures.Texture;
    import starling.textures.TextureAtlas;

    public class Assets
    {
        // Bitmaps
        
        [Embed(source = "../media/textures/background.png")]
        private static const Background:Class;
        
        [Embed(source = "../media/textures/starling_sheet.png")]
        private static const StarlingSheet:Class;
        
        [Embed(source = "../media/textures/flash_egg.png")]
        private static const FlashEgg:Class;
        
        [Embed(source = "../media/textures/starling_front.png")]
        private static const StarlingFront:Class;
        
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
        
        // Compressed textures
        
        [Embed(source = "../media/textures/compressed_texture.atf", mimeType="application/octet-stream")]
        private static const CompressedTexture:Class;
        
        // Fonts
        
        // The 'embedAsCFF'-part IS REQUIRED!!!!
        [Embed(source="../media/fonts/Ubuntu-R.ttf", embedAsCFF="false", fontFamily="Ubuntu")]        
        private static const UbuntuRegular:Class;
        
        [Embed(source="../media/fonts/desyrel.fnt", mimeType="application/octet-stream")]
        private static const DesyrelXml:Class;
        
        [Embed(source = "../media/fonts/desyrel.png")]
        private static const DesyrelTexture:Class;
        
        // Texture Atlas
        
        [Embed(source="../media/textures/atlas.xml", mimeType="application/octet-stream")]
        private static const AtlasXml:Class;
        
        [Embed(source="../media/textures/atlas.png")]
        private static const AtlasTexture:Class;
        
        // Sounds
        
        [Embed(source="../media/audio/wing_flap.mp3")]
        private static const StepSound:Class;
        
        // Texture cache
        
        private static var sTextures:Dictionary = new Dictionary();
        private static var sSounds:Dictionary = new Dictionary();
        private static var sTextureAtlas:TextureAtlas;
        private static var sBitmapFontsLoaded:Boolean;
        
        public static function getTexture(name:String):Texture
        {
            if (sTextures[name] == undefined)
            {
                var data:Object = new Assets[name]();
                
                if (data is Bitmap)
                    sTextures[name] = Texture.fromBitmap(data as Bitmap);
                else if (data is ByteArray)
                    sTextures[name] = Texture.fromAtfData(data as ByteArray);
            }
            
            return sTextures[name];
        }
        
        public static function getSound(name:String):Sound
        {
            var sound:Sound = sSounds[name] as Sound;
            if (sound) return sound;
            else throw new ArgumentError("Sound not found: " + name);
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
        
        public static function loadBitmapFonts():void
        {
            if (!sBitmapFontsLoaded)
            {
                var texture:Texture = getTexture("DesyrelTexture");
                var xml:XML = XML(new DesyrelXml());
                TextField.registerBitmapFont(new BitmapFont(texture, xml));
                sBitmapFontsLoaded = true;
            }
        }
        
        public static function prepareSounds():void
        {
            sSounds["Step"] = new StepSound();   
        }
    }
}