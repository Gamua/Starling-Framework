package 
{
    import flash.display.Bitmap;
    import flash.display.Loader;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.ProgressEvent;
    import flash.media.Sound;
    import flash.media.SoundChannel;
    import flash.media.SoundTransform;
    import flash.net.FileReference;
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;
    import flash.system.ImageDecodingPolicy;
    import flash.system.LoaderContext;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;
    import flash.utils.clearTimeout;
    import flash.utils.describeType;
    import flash.utils.getQualifiedClassName;
    import flash.utils.setTimeout;
    
    import starling.core.Starling;
    import starling.text.BitmapFont;
    import starling.text.TextField;
    import starling.textures.Texture;
    import starling.textures.TextureAtlas;

    public class AssetManager
    {
        private var mScaleFactor:Number;
        private var mGenerateMipmaps:Boolean;
        private var mVerbose:Boolean;
        
        private var mRawAssets:Array;
        private var mTextures:Dictionary;
        private var mAtlases:Dictionary;
        private var mSounds:Dictionary;
        
        /** helper objects */
        private var sNames:Vector.<String> = new <String>[];
        
        public function AssetManager(scaleFactor:Number=-1, createMipmaps:Boolean=false)
        {
            mVerbose = false;
            mScaleFactor = scaleFactor > 0 ? scaleFactor : Starling.contentScaleFactor;
            mGenerateMipmaps = createMipmaps;
            mRawAssets = [];
            mTextures = new Dictionary();
            mAtlases = new Dictionary();
            mSounds = new Dictionary();
        }
        
        // retrieving
        
        public function getTexture(name:String):Texture
        {
            if (name in mTextures) return mTextures[name];
            else
            {
                for each (var atlas:TextureAtlas in mAtlases)
                {
                    var texture:Texture = atlas.getTexture(name);
                    if (texture) return texture;
                }
                return null;
            }
        }

        /** Returns all textures that start with a certain string, sorted alphabetically
         *  (especially useful for "MovieClip"). */
        public function getTextures(prefix:String="", result:Vector.<Texture>=null):Vector.<Texture>
        {
            if (result == null) result = new <Texture>[];
            
            for each (var name:String in getTextureNames(prefix, sNames)) 
                result.push(getTexture(name));
            
            sNames.length = 0;
            return result;
        }
        
        /** Returns all texture names that start with a certain string, sorted alphabetically. */
        public function getTextureNames(prefix:String="", result:Vector.<String>=null):Vector.<String>
        {
            if (result == null) result = new <String>[];
            
            for (var name:String in mTextures)
                if (name.indexOf(prefix) == 0)
                    result.push(name);                
            
            for each (var atlas:TextureAtlas in mAtlases)
                atlas.getNames(prefix, result);
            
            result.sort(Array.CASEINSENSITIVE);
            return result;
        }
        
        public function getSound(name:String):Sound
        {
            return mSounds[name];
        }
        
        /** Returns all sound names that start with a certain string, sorted alphabetically. */
        public function getSoundNames(prefix:String=""):Vector.<String>
        {
            var names:Vector.<String> = new <String>[];
            
            for (var name:String in mSounds)
                if (name.indexOf(prefix) == 0)
                    names.push(name);
            
            return names.sort(Array.CASEINSENSITIVE);
        }
        
        public function playSound(name:String, startTime:Number=0, loops:int=0, 
                                  transform:SoundTransform=null):SoundChannel
        {
            if (name in mSounds)
                return getSound(name).play(startTime, loops, transform);
            else 
                return null;
        }
        
        // direct adding
        
        public function addTexture(name:String, texture:Texture):void
        {
            log("Adding texture '" + name + "'");
            
            if (name in mTextures)
                throw new Error("Duplicate texture name: " + name);
            else
                mTextures[name] = texture;
        }
        
        public function addTextureAtlas(name:String, atlas:TextureAtlas):void
        {
            log("Adding texture atlas '" + name + "'");
            
            if (name in mAtlases)
                throw new Error("Duplicate texture atlas name: " + name);
            else
                mAtlases[name] = atlas;
        }
        
        public function addSound(name:String, sound:Sound):void
        {
            log("Adding sound '" + name + "'");
            
            if (name in mSounds)
                throw new Error("Duplicate sound name: " + name);
            else
                mSounds[name] = sound;
        }
        
        // removing
        
        public function removeTexture(name:String, dispose:Boolean=true):void
        {
            if (dispose && name in mTextures)
                mTextures[name].dispose();
            
            delete mTextures[name];
        }
        
        public function removeTextureAtlas(name:String, dispose:Boolean=true):void
        {
            if (dispose && name in mAtlases)
                mAtlases[name].dispose();
            
            delete mAtlases[name];
        }
        
        public function removeSound(name:String):void
        {
            delete mSounds[name];
        }
        
        // queued adding
        
        public function enqueue(...rawAssets):void
        {
            for each (var rawAsset:Object in rawAssets)
            {
                if (rawAsset is Array)
                {
                    enqueue.apply(this, rawAsset);
                }
                else if (rawAsset is Class)
                {
                    if (/\$[\d\w-]+$/.test(getQualifiedClassName(rawAsset)))
                    {
                        // embedded classes always end with a $HEX string -- yes, call it a hack ;)
                        push(rawAsset);
                    }
                    else
                    {
                        // find all members with "Embed" metadata
                        for each (var childNode:XML in describeType(rawAsset).*)
                        if (childNode.metadata.(@name == "Embed").hasComplexContent())
                            push(rawAsset[childNode.@name]);
                    }
                }
                else if (getQualifiedClassName(rawAsset) == "flash.filesystem::File")
                {
                    if (!rawAsset["isHidden"])
                    {
                        if (rawAsset["isDirectory"])
                            enqueue.apply(this, rawAsset["getDirectoryListing"]());
                        else
                            push(rawAsset["url"]);
                    }
                }
                else if (rawAsset is String)
                {
                    push(rawAsset);
                }
                else
                {
                    log("Ignoring unsupported asset type: " + getQualifiedClassName(rawAsset));
                }
            }
            
            function push(asset:Object, name:String=null):void
            {
                if (name == null) name = getName(asset);
                
                mRawAssets.push({ 
                    name: (name ? name : getName(asset)), 
                    asset: asset 
                });
            }
        }
        
        public function loadQueue(onProgress:Function):void
        {
            if (Starling.context == null)
                throw new Error("The Starling instance needs to be ready before textures can be loaded.");
            
            var xmls:Vector.<XML> = new <XML>[];
            var numElements:int = mRawAssets.length;
            var currentRatio:Number = 0.0;
            var timeoutID:uint;
            
            resume();
            
            function resume():void
            {
                currentRatio = 1.0 - (mRawAssets.length / numElements);
                
                if (mRawAssets.length)
                    timeoutID = setTimeout(processNext, 1);
                else
                    processXmls();
                
                onProgress(currentRatio);
            }
            
            function processNext():void
            {
                var assetInfo:Object = mRawAssets.pop();
                clearTimeout(timeoutID);
                loadRawAsset(assetInfo.name, assetInfo.asset, xmls, progress, resume);
            }
            
            function processXmls():void
            {
                // xmls are processed seperately at the end, because the textures they reference
                // have to be available
                
                for each (var xml:XML in xmls)
                {
                    var name:String;
                    var rootNode:String = xml.localName();
                    
                    if (rootNode == "TextureAtlas")
                    {
                        name = getName(xml.@imagePath.toString());
                        
                        var atlasTexture:Texture = getTexture(name);
                        addTextureAtlas(name, new TextureAtlas(atlasTexture, xml));
                        removeTexture(name, false);
                    }
                    else if (rootNode == "font")
                    {
                        name = getName(xml.pages.page.@file.toString());
                        
                        var fontTexture:Texture = getTexture(name);
                        TextField.registerBitmapFont(new BitmapFont(fontTexture, xml));
                        removeTexture(name, false);
                    }
                    else
                        throw new Error("XML contents not recognized: " + rootNode);
                }
            }
            
            function progress(ratio:Number):void
            {
                onProgress(currentRatio + (1.0 / numElements) * Math.min(1.0, ratio) * 0.99);
            }
        }
        
        private function loadRawAsset(name:String, rawAsset:Object, xmls:Vector.<XML>,
                                      onProgress:Function, onComplete:Function):void
        {
            var extension:String = null;
            
            if (rawAsset is Class)
            {
                var asset:Object = new rawAsset();
                
                if (asset is Sound)
                    addSound(name, asset as Sound);
                else if (asset is Bitmap)
                    addTexture(name, 
                        Texture.fromBitmap(asset as Bitmap, mGenerateMipmaps, false, mScaleFactor));
                else if (asset is ByteArray)
                {
                    var bytes:ByteArray = asset as ByteArray;
                    var signature:String = String.fromCharCode(bytes[0], bytes[1], bytes[2]);
                    if (signature == "ATF")
                        addTexture(name, Texture.fromAtfData(asset as ByteArray, mScaleFactor));
                    else
                        xmls.push(new XML(bytes));
                }
                
                onComplete();
            }
            else if (rawAsset is String)
            {
                var url:String = rawAsset as String;
                extension = url.split(".").pop().toLowerCase();
                
                var urlLoader:URLLoader = new URLLoader();
                urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
                urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
                urlLoader.addEventListener(ProgressEvent.PROGRESS, onLoadProgress);
                urlLoader.addEventListener(Event.COMPLETE, onUrlLoaderComplete);
                urlLoader.load(new URLRequest(url));
            }
            
            function onIoError(event:IOErrorEvent):void
            {
                log("IO error: " + event.text);
                onComplete();
            }
            
            function onLoadProgress(event:ProgressEvent):void
            {
                onProgress(event.bytesLoaded / event.bytesTotal);
            }
            
            function onUrlLoaderComplete(event:Event):void
            {
                var urlLoader:URLLoader = event.target as URLLoader;
                var bytes:ByteArray = urlLoader.data as ByteArray;
                var sound:Sound;
                
                urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, onIoError);
                urlLoader.removeEventListener(ProgressEvent.PROGRESS, onProgress);
                urlLoader.removeEventListener(Event.COMPLETE, onUrlLoaderComplete);
                
                switch (extension)
                {
                    case "atf":
                        addTexture(name, Texture.fromAtfData(bytes, mScaleFactor));
                        onComplete();
                        break;
                    case "fnt":
                    case "xml":
                        xmls.push(new XML(bytes));
                        onComplete();
                        break;
                    case "mp3":
                        sound = new Sound();
                        sound.loadCompressedDataFromByteArray(bytes, bytes.length);
                        addSound(name, sound);
                        onComplete();
                        break;
                    default:
                        var loaderContext:LoaderContext = new LoaderContext();
                        var loader:Loader = new Loader();
                        loaderContext.imageDecodingPolicy = ImageDecodingPolicy.ON_LOAD;
                        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete);
                        loader.loadBytes(urlLoader.data as ByteArray, loaderContext);
                        break;
                }
            }
            
            function onLoaderComplete(event:Event):void
            {
                event.target.removeEventListener(Event.COMPLETE, onLoaderComplete);
                var content:Object = event.target.content;
                
                if (content is Bitmap)
                    addTexture(name,
                        Texture.fromBitmap(content as Bitmap, mGenerateMipmaps, false, mScaleFactor));
                else
                    throw new Error("Unsupported asset type: " + getQualifiedClassName(content));
                
                onComplete();
            }
        }
        
        // helpers
        
        private function getName(rawAsset:Object):String
        {
            var matches:Array;
            var name:String;
            
            if (rawAsset is String || rawAsset is FileReference)
            {
                name = rawAsset is String ? rawAsset as String : (rawAsset as FileReference).name;
                name = name.replace(/%20/g, " "); // URLs use '%20' for spaces
                matches = /(.*[\\/])?([\w\s\-]+)(\.[\w]{1,4})?/.exec(name);
                
                if (matches && matches.length == 4) return matches[2];
                else throw new ArgumentError("Could not extract name from String '" + rawAsset + "'");
            }
            else if (rawAsset is Class)
            {
                name = getQualifiedClassName(rawAsset);
                matches = /([\w\d-]+)_\w{1,4}/.exec(name);
                
                if (matches && matches.length == 2) return matches[1];
                else throw new ArgumentError("Could not extract name from Class '" + name + "'");
            }
            else
            {
                name = getQualifiedClassName(rawAsset);
                throw new ArgumentError("Cannot extract names for objects of type '" + name + "'");
            }
        }
        
        private function log(message:String):void
        {
            if (verbose) trace("[AssetManager]", message);
        }
        
        // properties
        
        public function get verbose():Boolean { return mVerbose; }
        public function set verbose(value:Boolean):void { mVerbose = value; }
        
        public function get generateMipMaps():Boolean { return mGenerateMipmaps; }
        public function set generateMipMaps(value:Boolean):void { mGenerateMipmaps = value; }
        
        public function get scaleFactor():Number { return mScaleFactor; }
        public function set scaleFactor(value:Number):void { mScaleFactor = value; }
    }
}