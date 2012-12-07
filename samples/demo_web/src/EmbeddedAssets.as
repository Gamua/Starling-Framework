package
{
    public class EmbeddedAssets
    {
        // Texture Atlas
        
        [Embed(source="../../demo/media/textures/1x/atlas.xml", mimeType="application/octet-stream")]
        public static const AtlasXml:Class;
        
        [Embed(source="../../demo/media/textures/1x/atlas.png")]
        public static const AtlasTexture:Class;

        // Compressed textures
        
        [Embed(source = "../../demo/media/textures/1x/compressed_texture.atf", mimeType="application/octet-stream")]
        public static const CompressedTexture:Class;
        
        // Bitmap Fonts
        
        [Embed(source="../../demo/media/fonts/1x/desyrel.fnt", mimeType="application/octet-stream")]
        public static const DesyrelXml:Class;
        
        [Embed(source = "../../demo/media/fonts/1x/desyrel.png")]
        public static const DesyrelTexture:Class;
        
        // Sounds
        
        [Embed(source="../../demo/media/audio/wing_flap.mp3")]
        public static const WingFlap:Class;
    }
}