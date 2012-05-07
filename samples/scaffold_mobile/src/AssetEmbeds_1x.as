package
{
    public class AssetEmbeds_1x
    {
        // Bitmaps
        
        [Embed(source = "../media/textures/1x/background.jpg")]
        public static const Background:Class;
        
        [Embed(source = "../media/textures/1x/loading.png")]
        public static const Loading:Class;
        
        // Texture Atlas
        
        [Embed(source="../media/textures/1x/atlas.xml", mimeType="application/octet-stream")]
        public static const AtlasXml:Class;
        
        [Embed(source="../media/textures/1x/atlas.png")]
        public static const AtlasTexture:Class;
        
        // Bitmap Fonts
        
        [Embed(source="../media/fonts/1x/desyrel.fnt", mimeType="application/octet-stream")]
        public static const DesyrelXml:Class;
        
        [Embed(source = "../media/fonts/1x/desyrel.png")]
        public static const DesyrelTexture:Class;
    }
}