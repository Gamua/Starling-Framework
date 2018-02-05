package starling.assets
{
    import flash.media.Sound;
    import flash.media.SoundChannel;
    import flash.media.SoundTransform;
    import flash.net.URLRequest;
    import flash.system.System;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;
    import flash.utils.describeType;
    import flash.utils.getQualifiedClassName;
    import flash.utils.setTimeout;

    import starling.core.Starling;
    import starling.events.Event;
    import starling.events.EventDispatcher;
    import starling.text.BitmapFont;
    import starling.textures.Texture;
    import starling.textures.TextureAtlas;
    import starling.textures.TextureOptions;
    import starling.utils.MathUtil;
    import starling.utils.execute;

    public class AssetManager extends EventDispatcher
    {
        private var _starling:Starling;
        private var _assets:Dictionary;
        private var _verbose:Boolean;
        private var _numConnections:int;
        private var _urlLoader:UrlLoader;
        private var _textureOptions:TextureOptions;
        private var _queue:Vector.<AssetReference>;
        private var _registerBitmapFontsWithFontFace:Boolean;
        private var _assetFactories:Vector.<AssetFactory>;
        private var _numRestoredTextures:int;
        private var _numLostTextures:int;

        /** Regex for name / extension extraction from URLs. */
        private static const NAME_REGEX:RegExp = /([^?\/\\]+?)(?:\.([\w\-]+))?(?:\?.*)?$/;

        /** helper objects */
        private static var sNames:Vector.<String> = new <String>[];

        public function AssetManager(scaleFactor:Number=1)
        {
            _assets = new Dictionary();
            _verbose = true;
            _textureOptions = new TextureOptions(scaleFactor);
            _queue = new <AssetReference>[];
            _numConnections = 1;
            _urlLoader = new UrlLoader();
            _assetFactories = new <AssetFactory>[];

            registerFactory(new BitmapTextureFactory());
            registerFactory(new AtfTextureFactory());
            registerFactory(new SoundFactory());
            registerFactory(new JsonFactory());
            registerFactory(new XmlFactory());
            registerFactory(new ByteArrayFactory(), -100);
        }

        public function dispose():void
        {
            purgeQueue();

            for each (var store:Dictionary in _assets)
                for each (var asset:Object in store)
                    disposeAsset(asset);
        }

        /** Removes assets of all types (disposing them along the way), empties the queue and
         *  aborts any pending load operations. */
        public function purge():void
        {
            log("Purging all assets, emptying queue");

            purgeQueue();
            dispose();

            _assets = new Dictionary();
        }

        // queue processing

        public function enqueue(...assets):void
        {
            for each (var asset:Object in assets)
            {
                if (asset is Array)
                {
                    enqueue.apply(this, asset);
                }
                else if (asset is Class)
                {
                    var typeXml:XML = describeType(asset);
                    var childNode:XML;

                    if (_verbose)
                        log("Looking for static embedded assets in '" +
                            (typeXml.@name).split("::").pop() + "'");

                    for each (childNode in typeXml.constant.(@type == "Class"))
                        enqueueSingle(asset[childNode.@name], childNode.@name);

                    for each (childNode in typeXml.variable.(@type == "Class"))
                        enqueueSingle(asset[childNode.@name], childNode.@name);
                }
                else if (getQualifiedClassName(asset) == "flash.filesystem::File")
                {
                    if (!asset["exists"])
                    {
                        log("File or directory not found: '" + asset["url"] + "'");
                    }
                    else if (!asset["isHidden"])
                    {
                        if (asset["isDirectory"])
                            enqueue.apply(this, asset["getDirectoryListing"]());
                        else
                            enqueueSingle(asset);
                    }
                }
                else if (asset is String || asset is URLRequest)
                {
                    enqueueSingle(asset);
                }
                else
                {
                    log("Ignoring unsupported asset type: " + getQualifiedClassName(asset));
                }
            }
        }

        public function enqueueSingle(asset:Object, name:String=null,
                                      options:TextureOptions=null):String
        {
            if (asset is Class) asset = new asset();
            var assetReference:AssetReference = new AssetReference(asset, name);
            assetReference.setCallbacks(getNameFromUrl, getExtensionFromUrl);
            assetReference.textureOptions = options || _textureOptions;
            _queue.push(assetReference);
            log("Enqueuing '" + assetReference.filename + "'");
            return assetReference.name;
        }

        /** Empties the queue and aborts any pending load operations. */
        public function purgeQueue():void
        {
            _queue.length = 0;
            dispatchEventWith(Event.CANCEL);
        }

        public function loadQueue(onComplete:Function, onError:Function=null,
                                  onProgress:Function=null):void
        {
            if (_queue.length == 0)
            {
                execute(onProgress, 1.0);
                execute(onComplete);
                return;
            }

            _starling = Starling.current;

            if (_starling == null || _starling.context == null)
                throw new Error("The Starling instance needs to be ready before assets can be loaded.");

            // By using an event listener, we can make a call to "cancel" affect
            // only the currently active loading process(es).
            addEventListener(Event.CANCEL, onCanceled);

            var factoryHelper:AssetFactoryHelper = new AssetFactoryHelper();
            factoryHelper.getNameFromUrlFunc = getNameFromUrl;
            factoryHelper.getExtensionFromUrlFunc = getExtensionFromUrl;
            factoryHelper.addPostProcessorFunc = addPostProcessor;
            factoryHelper.onRestoreFunc = onAssetRestored;
            factoryHelper.urlLoader = _urlLoader;
            factoryHelper.logFunc = log;

            var i:int;
            var self:AssetManager = this;
            var canceled:Boolean = false;
            var queue:Vector.<AssetReference> = _queue.concat();
            var numAssets:int = queue.length;
            var numConnections:int = MathUtil.min(_numConnections, numAssets);
            var assetProgress:Vector.<Number> = new Vector.<Number>(numAssets, true);
            var postProcessors:Vector.<AssetPostProcessor> = new <AssetPostProcessor>[];

            _queue.length = 0;

            for (i=0; i<numAssets; ++i)
                assetProgress[i] = -1;

            for (i=0; i<numConnections; ++i)
                loadFromQueue(queue, assetProgress, i, factoryHelper,
                    onAssetLoaded, onAssetLoadError, onAssetLoadProgress);

            function onAssetLoaded(name:String, asset:Object,
                                   postProcessor:AssetPostProcessor=null):void
            {
                if (canceled) disposeAsset(asset);
                else
                {
                    if (postProcessor) postProcessors.push(postProcessor);
                    addAsset(name, asset);
                    setTimeout(loadNextAsset, 1);
                }
            }

            function onAssetLoadError(error:String):void
            {
                if (!canceled)
                {
                    execute(onError, error);
                    setTimeout(loadNextAsset, 1);
                }
            }

            function onAssetLoadProgress(ratio:Number):void
            {
                if (!canceled) execute(onProgress, ratio);
            }

            function loadNextAsset():void
            {
                if (canceled) return;

                for (var j:int=0; j<numAssets; ++j)
                {
                    if (assetProgress[j] < 0)
                    {
                        loadFromQueue(queue, assetProgress, j, factoryHelper,
                            onAssetLoaded, onAssetLoadError, onAssetLoadProgress);
                        break;
                    }
                }

                if (j == numAssets)
                {
                    postProcessors.sort(comparePriorities);
                    runPostProcessors(onPostProcessComplete, onError);
                }
            }

            function addPostProcessor(processorFunc:Function, priority:int):void
            {
                var processor:AssetPostProcessor = new AssetPostProcessor(processorFunc);
                processor.priority = priority;
                postProcessors.push(processor);
            }

            function runPostProcessors(onComplete:Function, onError:Function):void
            {
                if (postProcessors.length && !canceled)
                {
                    try { postProcessors.shift().execute(self); }
                    catch (e:Error) { execute(onError, e.message); }

                    setTimeout(runPostProcessors, 1, onComplete, onError);
                }
                else onComplete();
            }

            function onPostProcessComplete():void
            {
                if (!canceled)
                {
                    onCanceled();
                    execute(onComplete);
                }
            }

            function onCanceled():void
            {
                canceled = true;
                removeEventListener(Event.CANCEL, onCanceled);
            }
        }

        private function loadFromQueue(
            queue:Vector.<AssetReference>, progressRatios:Vector.<Number>, index:int,
            helper:AssetFactoryHelper, onComplete:Function, onError:Function, onProgress:Function):void
        {
            var assetCount:int = queue.length;
            var asset:AssetReference = queue[index];
            progressRatios[index] = 0;

            if (asset.data is String || ("url" in asset.data && asset.data["url"]))
                _urlLoader.load(asset.data, onLoadComplete, onLoadError, onLoadProgress);
            else
                setTimeout(onLoadComplete, 1, asset.data);

            function onLoadComplete(data:Object, mimeType:String=null):void
            {
                _starling.makeCurrent();
                onLoadProgress(1.0);
                asset.data = data;
                asset.mimeType ||= mimeType;

                var assetFactory:AssetFactory = getFactoryFor(asset);
                if (assetFactory == null)
                    execute(onAnyError, "Warning: no suitable factory found for '" + asset.name + "'");
                else
                    assetFactory.create(asset, helper, onComplete, onCreateError);
            }

            function onLoadProgress(ratio:Number):void
            {
                progressRatios[index] = ratio;

                var totalRatio:Number = 0;
                var multiplier:Number = 1.0 / assetCount;

                for (var k:int=0; k<assetCount; ++k)
                {
                    var r:Number = progressRatios[k];
                    if (r > 0) totalRatio += multiplier * r;
                }

                execute(onProgress, MathUtil.min(totalRatio, 1.0));
            }

            function onLoadError(error:String):void
            {
                onLoadProgress(1.0);
                execute(onAnyError, "Error loading " + asset.name + ": " + error);
            }

            function onCreateError(error:String):void
            {
                execute(onAnyError, "Error creating " + asset.name + ": " + error);
            }

            function onAnyError(error:String):void
            {
                log(error);
                execute(onError, error);
            }
        }

        private function getFactoryFor(asset:AssetReference):AssetFactory
        {
            var numFactories:int = _assetFactories.length;
            for (var i:int=0; i<numFactories; ++i)
            {
                var factory:AssetFactory = _assetFactories[i];
                if (factory.canHandle(asset)) return factory;
            }

            return null;
        }

        private function onAssetRestored(finished:Boolean):void
        {
            if (finished)
            {
                _numRestoredTextures++;
                _starling.stage.setRequiresRedraw();

                if (_numRestoredTextures == _numLostTextures)
                    dispatchEventWith(Event.TEXTURES_RESTORED);
            }
            else _numLostTextures++;
        }

        // basic accessing methods

        /** Add an asset with a certain name. The asset type will be figured out automatically,
         *  and the asset will be available right away.
         *
         *  <p>Beware: if the slot (name + type) was already taken, the existing object will be
         *  disposed and replaced by the new one.</p>
         *
         *  @param name       The name with which the asset can be retrieved later. Must be
         *                    unique within this asset type.
         *  @param asset      The actual asset to add (e.g. a texture, a sound, etc.)
         */
        public function addAsset(name:String, asset:Object):void
        {
            var assetType:String = AssetType.fromAsset(asset);

            var store:Dictionary = _assets[assetType];
            if (store == null)
            {
                store = new Dictionary();
                _assets[assetType] = store;
            }

            log("Adding " + assetType + " '" + name + "'");

            var prevAsset:Object = store[name];
            if (prevAsset && prevAsset != asset)
            {
                log("Warning: name was already in use; disposing the previous " + assetType);
                disposeAsset(prevAsset);
            }

            store[name] = asset;
        }

        public function getAsset(assetType:String, name:String):Object
        {
            var store:Dictionary = _assets[assetType];
            if (store && name in store) return store[name];
            else return null;
        }

        public function getAssetNames(assetType:String, prefix:String="",
                                      out:Vector.<String>=null):Vector.<String>
        {
            return getDictionaryKeys(_assets[assetType], prefix, out);
        }

        public function removeAsset(assetType:String, name:String, dispose:Boolean=true):void
        {
            var store:Dictionary = _assets[assetType];
            if (store)
            {
                var asset:Object = store[name];
                if (asset)
                {
                    log("Removing " + assetType + " '" + name + "'");
                    if (dispose) disposeAsset(asset);
                    delete store[name];
                }
            }
        }

        // convenience access methods

        /** Returns a texture with a certain name. Includes textures stored inside atlases. */
        public function getTexture(name:String):Texture
        {
            var atlasStore:Dictionary = _assets[AssetType.TEXTURE_ATLAS];
            if (atlasStore)
            {
                for each (var atlas:TextureAtlas in atlasStore)
                {
                    var texture:Texture = atlas.getTexture(name);
                    if (texture) return texture;
                }
            }
            return getAsset(AssetType.TEXTURE, name) as Texture;
        }

        /** Returns all textures that start with a certain string, sorted alphabetically
         *  (especially useful for "MovieClip"). Includes textures stored inside atlases. */
        public function getTextures(prefix:String="", out:Vector.<Texture>=null):Vector.<Texture>
        {
            if (out == null) out = new <Texture>[];

            for each (var name:String in getTextureNames(prefix, sNames))
                out[out.length] = getTexture(name); // avoid 'push'

            sNames.length = 0;
            return out;
        }

        /** Returns all texture names that start with a certain string, sorted alphabetically.
         *  Includes textures stored inside atlases. */
        public function getTextureNames(prefix:String="", out:Vector.<String>=null):Vector.<String>
        {
            out = getAssetNames(AssetType.TEXTURE, prefix, out);

            var atlasStore:Dictionary = _assets[AssetType.TEXTURE_ATLAS];
            if (atlasStore)
            {
                for each (var atlas:TextureAtlas in atlasStore)
                    atlas.getNames(prefix, out);
            }

            out.sort(Array.CASEINSENSITIVE);
            return out;
        }

        /** Returns a texture atlas with a certain name, or null if it's not found. */
        public function getTextureAtlas(name:String):TextureAtlas
        {
            return getAsset(AssetType.TEXTURE_ATLAS, name) as TextureAtlas;
        }

        /** Returns all texture atlas names that start with a certain string, sorted alphabetically.
         *  If you pass an <code>out</code>-vector, the names will be added to that vector. */
        public function getTextureAtlasNames(prefix:String="", out:Vector.<String>=null):Vector.<String>
        {
            return getAssetNames(AssetType.TEXTURE_ATLAS, prefix, out);
        }

        /** Returns a sound with a certain name, or null if it's not found. */
        public function getSound(name:String):Sound
        {
            return getAsset(AssetType.SOUND, name) as Sound;
        }

        /** Returns all sound names that start with a certain string, sorted alphabetically.
         *  If you pass an <code>out</code>-vector, the names will be added to that vector. */
        public function getSoundNames(prefix:String="", out:Vector.<String>=null):Vector.<String>
        {
            return getAssetNames(AssetType.SOUND, prefix, out);
        }

        /** Generates a new SoundChannel object to play back the sound. This method returns a
         *  SoundChannel object, which you can access to stop the sound and to control volume. */
        public function playSound(name:String, startTime:Number=0, loops:int=0,
                                  transform:SoundTransform=null):SoundChannel
        {
            var sound:Sound = getSound(name);
            if (sound) return sound.play(startTime, loops, transform);
            else return null;
        }

        /** Returns an XML with a certain name, or null if it's not found. */
        public function getXml(name:String):XML
        {
            return getAsset(AssetType.XML_DOCUMENT, name) as XML;
        }

        /** Returns all XML names that start with a certain string, sorted alphabetically.
         *  If you pass an <code>out</code>-vector, the names will be added to that vector. */
        public function getXmlNames(prefix:String="", out:Vector.<String>=null):Vector.<String>
        {
            return getAssetNames(AssetType.XML_DOCUMENT, prefix, out);
        }

        /** Returns an object with a certain name, or null if it's not found. Enqueued JSON
         *  data is parsed and can be accessed with this method. */
        public function getObject(name:String):Object
        {
            return getAsset(AssetType.OBJECT, name);
        }

        /** Returns all object names that start with a certain string, sorted alphabetically.
         *  If you pass an <code>out</code>-vector, the names will be added to that vector. */
        public function getObjectNames(prefix:String="", out:Vector.<String>=null):Vector.<String>
        {
            return getAssetNames(AssetType.OBJECT, prefix, out);
        }

        /** Returns a byte array with a certain name, or null if it's not found. */
        public function getByteArray(name:String):ByteArray
        {
            return getAsset(AssetType.BYTE_ARRAY, name) as ByteArray;
        }

        /** Returns all byte array names that start with a certain string, sorted alphabetically.
         *  If you pass an <code>out</code>-vector, the names will be added to that vector. */
        public function getByteArrayNames(prefix:String="", out:Vector.<String>=null):Vector.<String>
        {
            return getAssetNames(AssetType.BYTE_ARRAY, prefix, out);
        }

        /** Returns a bitmap font with a certain name, or null if it's not found. */
        public function getBitmapFont(name:String):BitmapFont
        {
            return getAsset(AssetType.BITMAP_FONT, name) as BitmapFont;
        }

        public function getBitmapFontNames(prefix:String="", out:Vector.<String>=null):Vector.<String>
        {
            return getAssetNames(AssetType.BITMAP_FONT, prefix, out);
        }

        /** Removes a certain texture, optionally disposing it. */
        public function removeTexture(name:String, dispose:Boolean=true):void
        {
            removeAsset(AssetType.TEXTURE, name, dispose);
        }

        /** Removes a certain texture atlas, optionally disposing it. */
        public function removeTextureAtlas(name:String, dispose:Boolean=true):void
        {
            removeAsset(AssetType.TEXTURE_ATLAS, name, dispose);
        }

        /** Removes a certain sound. */
        public function removeSound(name:String):void
        {
            removeAsset(AssetType.SOUND, name);
        }

        /** Removes a certain Xml object, optionally disposing it. */
        public function removeXml(name:String, dispose:Boolean=true):void
        {
            removeAsset(AssetType.XML_DOCUMENT, name, dispose);
        }

        /** Removes a certain object. */
        public function removeObject(name:String):void
        {
            removeAsset(AssetType.OBJECT, name);
        }

        /** Removes a certain byte array, optionally disposing its memory right away. */
        public function removeByteArray(name:String, dispose:Boolean=true):void
        {
            removeAsset(AssetType.BYTE_ARRAY, name, dispose);
        }

        /** Removes a certain bitmap font, optionally disposing it. */
        public function removeBitmapFont(name:String, dispose:Boolean=true):void
        {
            removeAsset(AssetType.BITMAP_FONT, name, dispose);
        }

        // registration of factories and post processors

        public function registerFactory(factory:AssetFactory, priority:int=0):void
        {
            factory.priority = priority;

            _assetFactories.push(factory);
            _assetFactories.sort(comparePriorities);
        }

        private static function comparePriorities(a:Object, b:Object):int
        {
            if (a.priority == b.priority) return 0;
            return a.priority > b.priority ? -1 : 1;
        }

        // helpers

        protected function getNameFromUrl(url:String):String
        {
            var matches:Array = NAME_REGEX.exec(decodeURIComponent(url));
            if (matches && matches.length > 0) return matches[1];
            else return "unknown";
        }

        protected function getExtensionFromUrl(url:String):String
        {
            var matches:Array = NAME_REGEX.exec(decodeURIComponent(url));
            if (matches && matches.length > 1) return matches[2];
            else return "";
        }

        protected function disposeAsset(asset:Object):void
        {
            if (asset is ByteArray) (asset as ByteArray).clear();
            if (asset is XML) System.disposeXML(asset as XML);
            if ("dispose" in asset) asset["dispose"]();
        }

        /** This method is called during loading of assets when 'verbose' is activated. Per
         *  default, it traces 'message' to the console. */
        protected function log(message:String):void
        {
            if (_verbose) trace("[AssetManager]", message);
        }

        private static function getDictionaryKeys(dictionary:Dictionary, prefix:String="",
                                                  out:Vector.<String>=null):Vector.<String>
        {
            if (out == null) out = new <String>[];
            if (dictionary)
            {
                for (var name:String in dictionary)
                    if (name.indexOf(prefix) == 0)
                        out[out.length] = name; // avoid 'push'

                out.sort(Array.CASEINSENSITIVE);
            }
            return out;
        }

        // properties

        /** When activated, the class will trace information about added/enqueued assets.
         *  @default true */
        public function get verbose():Boolean { return _verbose; }
        public function set verbose(value:Boolean):void { _verbose = value; }

        /** Returns the number of raw assets that have been enqueued, but not yet loaded. */
        public function get numQueuedAssets():int { return _queue.length; }

        /** The maximum number of parallel connections that are spawned when loading the queue.
         *  More connections can reduce loading times, but require more memory. @default 3. */
        public function get numConnections():int { return _numConnections; }
        public function set numConnections(value:int):void
        {
            _numConnections = MathUtil.min(1, value);
        }

        /** Indicates if bitmap fonts should be registered with their "face" attribute from the
         *  font XML file. Per default, they are registered with the name of the texture file.
         *  @default false */
        public function get registerBitmapFontsWithFontFace():Boolean
        {
            return _registerBitmapFontsWithFontFace;
        }

        public function set registerBitmapFontsWithFontFace(value:Boolean):void
        {
            _registerBitmapFontsWithFontFace = value;
        }
    }
}

import starling.assets.AssetManager;

class AssetPostProcessor
{
    private var _priority:int;
    private var _callback:Function;

    public function AssetPostProcessor(callback:Function)
    {
        if (callback == null || callback.length != 1)
            throw new ArgumentError("callback must be a function " +
                "accepting one 'AssetStore' parameter");

        _callback = callback;
    }

    internal function execute(store:AssetManager):void
    {
        _callback(store);
    }

    public function get priority():int { return _priority; }
    public function set priority(value:int):void { _priority = value; }
}