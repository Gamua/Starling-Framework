package starling.assets
{
    import flash.utils.ByteArray;

    import starling.textures.AtfData;
    import starling.textures.Texture;

    /** This AssetFactory creates texture assets from ATF files. */
    public class AtfTextureFactory extends AssetFactory
    {
        /** Creates a new instance. */
        public function AtfTextureFactory()
        {
            addExtensions("atf"); // not used, actually, since we can parse the ATF header, anyway.
        }

        /** @inheritDoc */
        override public function canHandle(reference:AssetReference):Boolean
        {
            return (reference.data is ByteArray && AtfData.isAtfData(reference.data as ByteArray));
        }

        /** @inheritDoc */
        override public function create(reference:AssetReference, helper:AssetFactoryHelper,
                                        onComplete:Function, onError:Function):void
        {
            helper.executeWhenContextReady(createTexture);

            function createTexture():void
            {
                reference.textureOptions.onReady = function():void
                {
                    onComplete(reference.name, texture);
                };

                var texture:Texture = Texture.fromData(reference.data, reference.textureOptions);
                var url:String = reference.url;

                if (url)
                {
                    texture.root.onRestore = function():void
                    {
                        helper.onBeginRestore();
                        helper.loadDataFromUrl(url, function(data:ByteArray):void
                        {
                            helper.executeWhenContextReady(function():void
                            {
                                texture.root.uploadAtfData(data);
                                helper.onEndRestore();
                            });
                        }, onReloadError);
                    };
                }
            }

            function onReloadError(error:String):void
            {
                helper.log("Texture restoration failed for " + reference.url + ". " + error);
                helper.onEndRestore();
            }
        }
    }
}
