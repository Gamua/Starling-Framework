package starling.assets
{
    import flash.utils.ByteArray;

    import starling.text.BitmapFont;
    import starling.text.TextField;
    import starling.textures.Texture;
    import starling.textures.TextureAtlas;
    import starling.utils.ByteArrayUtil;

    public class XmlFactory extends AssetFactory
    {
        public function XmlFactory()
        {
            addMimeTypes("application/xml", "text/xml");
            addExtensions("xml", "fnt");
        }

        override public function canHandle(reference:AssetReference):Boolean
        {
            return super.canHandle(reference) || (reference.data is ByteArray &&
                ByteArrayUtil.startsWithString(reference.data as ByteArray, "<"));
        }

        override public function create(reference:AssetReference, helper:AssetFactoryHelper,
                                        onComplete:Function, onError:Function):void
        {
            var xml:XML = reference.data as XML;
            var bytes:ByteArray = reference.data as ByteArray;

            if (bytes)
            {
                try { xml = new XML(bytes); }
                catch (e:Error)
                {
                    onError("Could not parse XML: " + e.message);
                    return;
                }
            }

            var rootNode:String = xml.localName();

            if (rootNode == "TextureAtlas")
                helper.addPostProcessor(function(store:AssetManager):void
                {
                    var name:String = helper.getNameFromUrl(xml.@imagePath.toString());
                    var texture:Texture = store.getTexture(name);
                    store.addAsset(name, new TextureAtlas(texture, xml));
                }, 100);
            else if (rootNode == "font")
                helper.addPostProcessor(function(store:AssetManager):void
                {
                    var textureName:String = helper.getNameFromUrl(xml.pages.page.@file.toString());
                    var fontName:String = store.registerBitmapFontsWithFontFace ? xml.info.@face.toString() : textureName;
                    var texture:Texture = store.getTexture(textureName);
                    var bitmapFont:BitmapFont = new BitmapFont(texture, xml);

                    store.addAsset(fontName, bitmapFont);
                    TextField.registerCompositor(bitmapFont, fontName);
                });

            onComplete(reference.name, xml);
        }
    }
}
