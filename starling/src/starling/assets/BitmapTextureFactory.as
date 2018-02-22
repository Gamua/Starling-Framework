package starling.assets
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Loader;
    import flash.display.LoaderInfo;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.system.ImageDecodingPolicy;
    import flash.system.LoaderContext;
    import flash.utils.ByteArray;

    import starling.textures.Texture;
    import starling.utils.execute;

    /** This AssetFactory creates texture assets from bitmaps and image files. */
    public class BitmapTextureFactory extends AssetFactory
    {
        /** Creates a new instance. */
        public function BitmapTextureFactory()
        {
            addMimeTypes("image/png", "image/jpg", "image/jpeg", "image/gif");
            addExtensions("png", "jpg", "jpeg", "gif");
        }

        /** @inheritDoc */
        override public function canHandle(reference:AssetReference):Boolean
        {
            return reference.data is Bitmap || reference.data is BitmapData ||
                super.canHandle(reference);
        }

        /** @inheritDoc */
        override public function create(reference:AssetReference, helper:AssetFactoryHelper,
                                        onComplete:Function, onError:Function):void
        {
            var texture:Texture;
            var url:String = reference.url;
            var data:Object = reference.data;

            if (data is Bitmap || data is BitmapData)
            {
                helper.executeWhenContextReady(createDownloadedTexture, data);
            }
            else if (data is ByteArray)
            {
                loadFromByteArray(data as ByteArray, onLoadComplete, onError);
            }

            function onLoadComplete(bitmap:Bitmap):void
            {
                helper.executeWhenContextReady(createDownloadedTexture, bitmap);
            }

            function createDownloadedTexture(bitmapOrBitmapData:Object):void
            {
                reference.textureOptions.onReady = function():void
                {
                    onComplete(reference.name, texture);
                };

                texture = Texture.fromData(bitmapOrBitmapData, reference.textureOptions);

                if (url)
                {
                    texture.root.onRestore = function():void
                    {
                        helper.onBeginRestore();

                        reload(url, function(bitmap:Bitmap):void
                        {
                            helper.executeWhenContextReady(function():void
                            {
                                texture.root.uploadBitmap(bitmap);
                                helper.onEndRestore();
                            });
                        });
                    };
                }
            }

            function reload(url:String, onComplete:Function):void
            {
                helper.loadDataFromUrl(url, function(data:ByteArray):void
                {
                   loadFromByteArray(data, onComplete, onReloadError);
                }, onReloadError);
            }

            function onReloadError(error:String):void
            {
                helper.log("Texture restoration failed for " + url + ". " + error);
                helper.onEndRestore();
            }
        }

        private function loadFromByteArray(data:ByteArray, onComplete:Function, onError:Function):void
        {
            var loader:Loader = new Loader();
            var loaderInfo:LoaderInfo = loader.contentLoaderInfo;
            loaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
            loaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete);
            var loaderContext:LoaderContext = new LoaderContext();
            loaderContext.imageDecodingPolicy = ImageDecodingPolicy.ON_LOAD;
            loader.loadBytes(data, loaderContext);

            function onIoError(event:IOErrorEvent):void
            {
                cleanup();
                execute(onError, event.text);
            }

            function onLoaderComplete(event:Object):void
            {
                complete(event.target.content);
            }

            function complete(asset:Object):void
            {
                cleanup();
                execute(onComplete, asset);
            }

            function cleanup():void
            {
                loaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onIoError);
                loaderInfo.removeEventListener(Event.COMPLETE, onLoaderComplete);
            }
        }
    }
}
