package starling.utils
{
    import flash.display.Bitmap;
    import flash.display.Loader;
    import flash.events.HTTPStatusEvent;
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
    import flash.system.System;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;
    import flash.utils.clearTimeout;
    import flash.utils.describeType;
    import flash.utils.getQualifiedClassName;
    import flash.utils.setTimeout;
    
    import starling.core.Starling;
    import starling.events.Event;
    import starling.events.EventDispatcher;
    import starling.text.BitmapFont;
    import starling.text.TextField;
    import starling.textures.AtfData;
    import starling.textures.Texture;
    import starling.textures.TextureAtlas;
    import starling.textures.TextureOptions;
    
    /** Dispatched when all textures have been restored after a context loss. */
    [Event(name="texturesRestored", type="starling.events.Event")]
    
    /** The AssetManager handles loading and accessing a variety of asset types. You can 
     *  add assets directly (via the 'add...' methods) or asynchronously via a queue. This allows
     *  you to deal with assets in a unified way, no matter if they are loaded from a file, 
     *  directory, URL, or from an embedded object.
     *  
     *  <p>The class can deal with the following media types:
     *  <ul>
     *    <li>Textures, either from Bitmaps or ATF data</li>
     *    <li>Texture atlases</li>
     *    <li>Bitmap Fonts</li>
     *    <li>Sounds</li>
     *    <li>XML data</li>
     *    <li>JSON data</li>
     *    <li>ByteArrays</li>
     *  </ul>
     *  </p>
     *  
     *  <p>For more information on how to add assets from different sources, read the documentation
     *  of the "enqueue()" method.</p>
     * 
     *  <strong>Context Loss</strong>
     *  
     *  <p>When the stage3D context is lost (and you have enabled 'Starling.handleLostContext'),
     *  the AssetManager will automatically restore all loaded textures. To save memory, it will
     *  get them from their original sources. Since this is done asynchronously, your images might
     *  not reappear all at once, but during a timeframe of several seconds. If you want, you can
     *  pause your game during that time; the AssetManager dispatches an "Event.TEXTURES_RESTORED"
     *  event when all textures have been restored.</p>
     */
    public class AssetManager extends EventDispatcher
    {
        // This HTTPStatusEvent is only available in AIR
        private static const HTTP_RESPONSE_STATUS:String = "httpResponseStatus";

        private var mStarling:Starling;
        private var mNumLostTextures:int;
        private var mNumRestoredTextures:int;

        private var mDefaultTextureOptions:TextureOptions;
        private var mCheckPolicyFile:Boolean;
        private var mKeepAtlasXmls:Boolean;
        private var mKeepFontXmls:Boolean;
        private var mVerbose:Boolean;
        
        private var mQueue:Array;
        private var mIsLoading:Boolean;
        private var mTimeoutID:uint;
        
        private var mTextures:Dictionary;
        private var mAtlases:Dictionary;
        private var mSounds:Dictionary;
        private var mXmls:Dictionary;
        private var mObjects:Dictionary;
        private var mByteArrays:Dictionary;
        
        /** helper objects */
        private static var sNames:Vector.<String> = new <String>[];
        
        /** Regex for name / extension extraction from URL. */
        private static const NAME_REGEX:RegExp = /([^\?\/\\]+?)(?:\.([\w\-]+))?(?:\?.*)?$/;

        /** Create a new AssetManager. The 'scaleFactor' and 'useMipmaps' parameters define
         *  how enqueued bitmaps will be converted to textures. */
        public function AssetManager(scaleFactor:Number=1, useMipmaps:Boolean=false)
        {
            mDefaultTextureOptions = new TextureOptions(scaleFactor, useMipmaps);
            mTextures = new Dictionary();
            mAtlases = new Dictionary();
            mSounds = new Dictionary();
            mXmls = new Dictionary();
            mObjects = new Dictionary();
            mByteArrays = new Dictionary();
            mQueue = [];
        }
        
        /** Disposes all contained textures. */
        public function dispose():void
        {
            for each (var texture:Texture in mTextures)
                texture.dispose();
            
            for each (var atlas:TextureAtlas in mAtlases)
                atlas.dispose();
            
            for each (var xml:XML in mXmls)
                System.disposeXML(xml);
            
            for each (var byteArray:ByteArray in mByteArrays)
                byteArray.clear();
        }
        
        // retrieving
        
        /** Returns a texture with a certain name. The method first looks through the directly
         *  added textures; if no texture with that name is found, it scans through all 
         *  texture atlases. */
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
            result = getDictionaryKeys(mTextures, prefix, result);
            
            for each (var atlas:TextureAtlas in mAtlases)
                atlas.getNames(prefix, result);
            
            result.sort(Array.CASEINSENSITIVE);
            return result;
        }
        
        /** Returns a texture atlas with a certain name, or null if it's not found. */
        public function getTextureAtlas(name:String):TextureAtlas
        {
            return mAtlases[name] as TextureAtlas;
        }
        
        /** Returns a sound with a certain name, or null if it's not found. */
        public function getSound(name:String):Sound
        {
            return mSounds[name];
        }
        
        /** Returns all sound names that start with a certain string, sorted alphabetically.
         *  If you pass a result vector, the names will be added to that vector. */
        public function getSoundNames(prefix:String="", result:Vector.<String>=null):Vector.<String>
        {
            return getDictionaryKeys(mSounds, prefix, result);
        }
        
        /** Generates a new SoundChannel object to play back the sound. This method returns a 
         *  SoundChannel object, which you can access to stop the sound and to control volume. */ 
        public function playSound(name:String, startTime:Number=0, loops:int=0, 
                                  transform:SoundTransform=null):SoundChannel
        {
            if (name in mSounds)
                return getSound(name).play(startTime, loops, transform);
            else 
                return null;
        }
        
        /** Returns an XML with a certain name, or null if it's not found. */
        public function getXml(name:String):XML
        {
            return mXmls[name];
        }
        
        /** Returns all XML names that start with a certain string, sorted alphabetically. 
         *  If you pass a result vector, the names will be added to that vector. */
        public function getXmlNames(prefix:String="", result:Vector.<String>=null):Vector.<String>
        {
            return getDictionaryKeys(mXmls, prefix, result);
        }

        /** Returns an object with a certain name, or null if it's not found. Enqueued JSON
         *  data is parsed and can be accessed with this method. */
        public function getObject(name:String):Object
        {
            return mObjects[name];
        }
        
        /** Returns all object names that start with a certain string, sorted alphabetically. 
         *  If you pass a result vector, the names will be added to that vector. */
        public function getObjectNames(prefix:String="", result:Vector.<String>=null):Vector.<String>
        {
            return getDictionaryKeys(mObjects, prefix, result);
        }
        
        /** Returns a byte array with a certain name, or null if it's not found. */
        public function getByteArray(name:String):ByteArray
        {
            return mByteArrays[name];
        }
        
        /** Returns all byte array names that start with a certain string, sorted alphabetically. 
         *  If you pass a result vector, the names will be added to that vector. */
        public function getByteArrayNames(prefix:String="", result:Vector.<String>=null):Vector.<String>
        {
            return getDictionaryKeys(mByteArrays, prefix, result);
        }
        
        // direct adding
        
        /** Register a texture under a certain name. It will be available right away.
         *  If the name was already taken, the existing texture will be disposed and replaced
         *  by the new one. */
        public function addTexture(name:String, texture:Texture):void
        {
            log("Adding texture '" + name + "'");
            
            if (name in mTextures)
            {
                log("Warning: name was already in use; the previous texture will be replaced.");
                mTextures[name].dispose();
            }
            
            mTextures[name] = texture;
        }
        
        /** Register a texture atlas under a certain name. It will be available right away. 
         *  If the name was already taken, the existing atlas will be disposed and replaced
         *  by the new one. */
        public function addTextureAtlas(name:String, atlas:TextureAtlas):void
        {
            log("Adding texture atlas '" + name + "'");
            
            if (name in mAtlases)
            {
                log("Warning: name was already in use; the previous atlas will be replaced.");
                mAtlases[name].dispose();
            }
            
            mAtlases[name] = atlas;
        }
        
        /** Register a sound under a certain name. It will be available right away.
         *  If the name was already taken, the existing sound will be replaced by the new one. */
        public function addSound(name:String, sound:Sound):void
        {
            log("Adding sound '" + name + "'");
            
            if (name in mSounds)
                log("Warning: name was already in use; the previous sound will be replaced.");

            mSounds[name] = sound;
        }
        
        /** Register an XML object under a certain name. It will be available right away.
         *  If the name was already taken, the existing XML will be disposed and replaced
         *  by the new one. */
        public function addXml(name:String, xml:XML):void
        {
            log("Adding XML '" + name + "'");
            
            if (name in mXmls)
            {
                log("Warning: name was already in use; the previous XML will be replaced.");
                System.disposeXML(mXmls[name]);
            }

            mXmls[name] = xml;
        }
        
        /** Register an arbitrary object under a certain name. It will be available right away. 
         *  If the name was already taken, the existing object will be replaced by the new one. */
        public function addObject(name:String, object:Object):void
        {
            log("Adding object '" + name + "'");
            
            if (name in mObjects)
                log("Warning: name was already in use; the previous object will be replaced.");
            
            mObjects[name] = object;
        }
        
        /** Register a byte array under a certain name. It will be available right away.
         *  If the name was already taken, the existing byte array will be cleared and replaced
         *  by the new one. */
        public function addByteArray(name:String, byteArray:ByteArray):void
        {
            log("Adding byte array '" + name + "'");
            
            if (name in mByteArrays)
            {
                log("Warning: name was already in use; the previous byte array will be replaced.");
                mByteArrays[name].clear();
            }
            
            mByteArrays[name] = byteArray;
        }
        
        // removing
        
        /** Removes a certain texture, optionally disposing it. */
        public function removeTexture(name:String, dispose:Boolean=true):void
        {
            log("Removing texture '" + name + "'");
            
            if (dispose && name in mTextures)
                mTextures[name].dispose();
            
            delete mTextures[name];
        }
        
        /** Removes a certain texture atlas, optionally disposing it. */
        public function removeTextureAtlas(name:String, dispose:Boolean=true):void
        {
            log("Removing texture atlas '" + name + "'");
            
            if (dispose && name in mAtlases)
                mAtlases[name].dispose();
            
            delete mAtlases[name];
        }
        
        /** Removes a certain sound. */
        public function removeSound(name:String):void
        {
            log("Removing sound '"+ name + "'");
            delete mSounds[name];
        }
        
        /** Removes a certain Xml object, optionally disposing it. */
        public function removeXml(name:String, dispose:Boolean=true):void
        {
            log("Removing xml '"+ name + "'");
            
            if (dispose && name in mXmls)
                System.disposeXML(mXmls[name]);
            
            delete mXmls[name];
        }
        
        /** Removes a certain object. */
        public function removeObject(name:String):void
        {
            log("Removing object '"+ name + "'");
            delete mObjects[name];
        }
        
        /** Removes a certain byte array, optionally disposing its memory right away. */
        public function removeByteArray(name:String, dispose:Boolean=true):void
        {
            log("Removing byte array '"+ name + "'");
            
            if (dispose && name in mByteArrays)
                mByteArrays[name].clear();
            
            delete mByteArrays[name];
        }
        
        /** Empties the queue and aborts any pending load operations. */
        public function purgeQueue():void
        {
            mIsLoading = false;
            mQueue.length = 0;
            clearTimeout(mTimeoutID);
            dispatchEventWith(Event.CANCEL);
        }
        
        /** Removes assets of all types, empties the queue and aborts any pending load operations.*/
        public function purge():void
        {
            log("Purging all assets, emptying queue");
            
            purgeQueue();
            dispose();

            mTextures = new Dictionary();
            mAtlases = new Dictionary();
            mSounds = new Dictionary();
            mXmls = new Dictionary();
            mObjects = new Dictionary();
            mByteArrays = new Dictionary();
        }
        
        // queued adding
        
        /** Enqueues one or more raw assets; they will only be available after successfully 
         *  executing the "loadQueue" method. This method accepts a variety of different objects:
         *  
         *  <ul>
         *    <li>Strings containing an URL to a local or remote resource. Supported types:
         *        <code>png, jpg, gif, atf, mp3, xml, fnt, json, binary</code>.</li>
         *    <li>Instances of the File class (AIR only) pointing to a directory or a file.
         *        Directories will be scanned recursively for all supported types.</li>
         *    <li>Classes that contain <code>static</code> embedded assets.</li>
         *    <li>If the file extension is not recognized, the data is analyzed to see if
         *        contains XML or JSON data. If it's neither, it is stored as ByteArray.</li>
         *  </ul>
         *  
         *  <p>Suitable object names are extracted automatically: A file named "image.png" will be
         *  accessible under the name "image". When enqueuing embedded assets via a class, 
         *  the variable name of the embedded object will be used as its name. An exception
         *  are texture atlases: they will have the same name as the actual texture they are
         *  referencing.</p>
         *  
         *  <p>XMLs that contain texture atlases or bitmap fonts are processed directly: fonts are
         *  registered at the TextField class, atlas textures can be acquired with the
         *  "getTexture()" method. All other XMLs are available via "getXml()".</p>
         *  
         *  <p>If you pass in JSON data, it will be parsed into an object and will be available via
         *  "getObject()".</p>
         */
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
                    var typeXml:XML = describeType(rawAsset);
                    var childNode:XML;
                    
                    if (mVerbose)
                        log("Looking for static embedded assets in '" + 
                            (typeXml.@name).split("::").pop() + "'"); 
                    
                    for each (childNode in typeXml.constant.(@type == "Class"))
                        enqueueWithName(rawAsset[childNode.@name], childNode.@name);
                    
                    for each (childNode in typeXml.variable.(@type == "Class"))
                        enqueueWithName(rawAsset[childNode.@name], childNode.@name);
                }
                else if (getQualifiedClassName(rawAsset) == "flash.filesystem::File")
                {
                    if (!rawAsset["exists"])
                    {
                        log("File or directory not found: '" + rawAsset["url"] + "'");
                    }
                    else if (!rawAsset["isHidden"])
                    {
                        if (rawAsset["isDirectory"])
                            enqueue.apply(this, rawAsset["getDirectoryListing"]());
                        else
                            enqueueWithName(rawAsset);
                    }
                }
                else if (rawAsset is String)
                {
                    enqueueWithName(rawAsset);
                }
                else
                {
                    log("Ignoring unsupported asset type: " + getQualifiedClassName(rawAsset));
                }
            }
        }
        
        /** Enqueues a single asset with a custom name that can be used to access it later.
         *  If the asset is a texture, you can also add custom texture options.
         *  
         *  @param asset:   The asset that will be enqueued; accepts the same objects as the
         *                  'enqueue' method.
         *  @param name:    The name under which the asset will be found later. If you pass null or
         *                  omit the parameter, it's attempted to generate a name automatically.
         *  @param options: Custom options that will be used if 'asset' points to texture data.
         *  @return         the name under which the asset was registered. */
        public function enqueueWithName(asset:Object, name:String=null,
                                        options:TextureOptions=null):String
        {
            if (getQualifiedClassName(asset) == "flash.filesystem::File")
                asset = unescape(asset["url"]);
            
            if (name == null)    name = getName(asset);
            if (options == null) options = mDefaultTextureOptions;
            else                 options = options.clone();
            
            log("Enqueuing '" + name + "'");
            
            mQueue.push({
                name: name,
                asset: asset,
                options: options
            });
            
            return name;
        }
        
        /** Loads all enqueued assets asynchronously. The 'onProgress' function will be called
         *  with a 'ratio' between '0.0' and '1.0', with '1.0' meaning that it's complete.
         *
         *  <p>When you call this method, the manager will save a reference to "Starling.current";
         *  all textures that are loaded will be accessible only from within this instance. Thus,
         *  if you are working with more than one Starling instance, be sure to call
         *  "makeCurrent()" on the appropriate instance before processing the queue.</p>
         *
         *  @param onProgress: <code>function(ratio:Number):void;</code> 
         */
        public function loadQueue(onProgress:Function):void
        {
            mStarling = Starling.current;
            
            if (mStarling == null || mStarling.context == null)
                throw new Error("The Starling instance needs to be ready before textures can be loaded.");
            
            if (mIsLoading)
                throw new Error("The queue is already being processed");
            
            var xmls:Vector.<XML> = new <XML>[];
            var numElements:int = mQueue.length;
            var currentRatio:Number = 0.0;
            
            mIsLoading = true;
            resume();
            
            function resume():void
            {
                currentRatio = mQueue.length ? 1.0 - (mQueue.length / numElements) : 1.0;
                
                if (mQueue.length)
                    mTimeoutID = setTimeout(processNext, 1);
                else
                {
                    processXmls();
                    mIsLoading = false;
                }
                
                if (onProgress != null)
                    onProgress(currentRatio);
            }
            
            function processNext():void
            {
                var assetInfo:Object = mQueue.shift();
                clearTimeout(mTimeoutID);
                processRawAsset(assetInfo.name, assetInfo.asset, assetInfo.options,
                                xmls, progress, resume);
            }
            
            function processXmls():void
            {
                // xmls are processed seperately at the end, because the textures they reference
                // have to be available for other XMLs. Texture atlases are processed first:
                // that way, their textures can be referenced, too.
                
                xmls.sort(function(a:XML, b:XML):int { 
                    return a.localName() == "TextureAtlas" ? -1 : 1; 
                });
                
                for each (var xml:XML in xmls)
                {
                    var name:String;
                    var texture:Texture;
                    var rootNode:String = xml.localName();
                    
                    if (rootNode == "TextureAtlas")
                    {
                        name = getName(xml.@imagePath.toString());
                        texture = getTexture(name);
                        
                        if (texture)
                        {
                            addTextureAtlas(name, new TextureAtlas(texture, xml));

                            if (mKeepAtlasXmls) addXml(name, xml);
                            else System.disposeXML(xml);
                        }
                        else log("Cannot create atlas: texture '" + name + "' is missing.");
                    }
                    else if (rootNode == "font")
                    {
                        name = getName(xml.pages.page.@file.toString());
                        texture = getTexture(name);
                        
                        if (texture)
                        {
                            log("Adding bitmap font '" + name + "'");
                            TextField.registerBitmapFont(new BitmapFont(texture, xml), name);

                            if (mKeepFontXmls) addXml(name, xml);
                            else System.disposeXML(xml);
                        }
                        else log("Cannot create bitmap font: texture '" + name + "' is missing.");
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
        
        private function processRawAsset(name:String, rawAsset:Object, options:TextureOptions,
                                         xmls:Vector.<XML>,
                                         onProgress:Function, onComplete:Function):void
        {
            var canceled:Boolean = false;
            
            addEventListener(Event.CANCEL, cancel);
            loadRawAsset(rawAsset, progress, process);
            
            function process(asset:Object):void
            {
                var texture:Texture;
                var bytes:ByteArray;
                
                // the 'current' instance might have changed by now
                // if we're running in a set-up with multiple instances.
                mStarling.makeCurrent();
                
                if (canceled)
                {
                    // do nothing
                }
                else if (asset == null)
                {
                    onComplete();
                }
                else if (asset is Sound)
                {
                    addSound(name, asset as Sound);
                    onComplete();
                }
                else if (asset is XML)
                {
                    var xml:XML = asset as XML;
                    var rootNode:String = xml.localName();
                    
                    if (rootNode == "TextureAtlas" || rootNode == "font")
                        xmls.push(xml);
                    else
                        addXml(name, xml);
                    
                    onComplete();
                }
                else if (Starling.handleLostContext && mStarling.context.driverInfo == "Disposed")
                {
                    log("Context lost while processing assets, retrying ...");
                    setTimeout(process, 1, asset);
                    return; // to keep CANCEL event listener intact
                }
                else if (asset is Bitmap)
                {
                    texture = Texture.fromData(asset, options);
                    texture.root.onRestore = function():void
                    {
                        mNumLostTextures++;
                        loadRawAsset(rawAsset, null, function(asset:Object):void
                        {
                            try { texture.root.uploadBitmap(asset as Bitmap); }
                            catch (e:Error) { log("Texture restoration failed: " + e.message); }
                            
                            asset.bitmapData.dispose();
                            mNumRestoredTextures++;
                            
                            if (mNumLostTextures == mNumRestoredTextures)
                                dispatchEventWith(Event.TEXTURES_RESTORED);
                        });
                    };

                    asset.bitmapData.dispose();
                    addTexture(name, texture);
                    onComplete();
                }
                else if (asset is ByteArray)
                {
                    bytes = asset as ByteArray;
                    
                    if (AtfData.isAtfData(bytes))
                    {
                        options.onReady = onComplete;
                        texture = Texture.fromData(bytes, options);
                        texture.root.onRestore = function():void
                        {
                            mNumLostTextures++;
                            loadRawAsset(rawAsset, null, function(asset:Object):void
                            {
                                try { texture.root.uploadAtfData(asset as ByteArray, 0, true); }
                                catch (e:Error) { log("Texture restoration failed: " + e.message); }
                                
                                asset.clear();
                                mNumRestoredTextures++;
                                
                                if (mNumLostTextures == mNumRestoredTextures)
                                    dispatchEventWith(Event.TEXTURES_RESTORED);
                            });
                        };
                        
                        bytes.clear();
                        addTexture(name, texture);
                    }
                    else if (byteArrayStartsWith(bytes, "{") || byteArrayStartsWith(bytes, "["))
                    {
                        addObject(name, JSON.parse(bytes.readUTFBytes(bytes.length)));
                        bytes.clear();
                        onComplete();
                    }
                    else if (byteArrayStartsWith(bytes, "<"))
                    {
                        process(new XML(bytes));
                        bytes.clear();
                    }
                    else
                    {
                        addByteArray(name, bytes);
                        onComplete();
                    }
                }
                else
                {
                    log("Ignoring unsupported asset type: " + getQualifiedClassName(asset));
                    onComplete();
                }
                
                // avoid that objects stay in memory (through 'onRestore' functions)
                asset = null;
                bytes = null;
                
                removeEventListener(Event.CANCEL, cancel);
            }
            
            function progress(ratio:Number):void
            {
                if (!canceled) onProgress(ratio);
            }
            
            function cancel():void
            {
                canceled = true;
            }
        }
        
        private function loadRawAsset(rawAsset:Object, onProgress:Function, onComplete:Function):void
        {
            var extension:String = null;
            var urlLoader:URLLoader = null;
            var url:String = null;
            
            if (rawAsset is Class)
            {
                setTimeout(complete, 1, new rawAsset());
            }
            else if (rawAsset is String)
            {
                url = rawAsset as String;
                extension = getExtensionFromUrl(url);
                
                urlLoader = new URLLoader();
                urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
                urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
                urlLoader.addEventListener(HTTP_RESPONSE_STATUS, onHttpResponseStatus);
                urlLoader.addEventListener(ProgressEvent.PROGRESS, onLoadProgress);
                urlLoader.addEventListener(Event.COMPLETE, onUrlLoaderComplete);
                urlLoader.load(new URLRequest(url));
            }
            
            function onIoError(event:IOErrorEvent):void
            {
                log("IO error: " + event.text);
                complete(null);
            }
            
            function onHttpResponseStatus(event:HTTPStatusEvent):void
            {
                if (extension == null)
                {
                    var headers:Array = event["responseHeaders"];
                    var contentType:String = getHttpHeader(headers, "Content-Type");

                    if (contentType && /(audio|image)\//.exec(contentType))
                        extension = contentType.split("/").pop();
                }
            }

            function onLoadProgress(event:ProgressEvent):void
            {
                if (onProgress != null)
                    onProgress(event.bytesLoaded / event.bytesTotal);
            }
            
            function onUrlLoaderComplete(event:Object):void
            {
                var bytes:ByteArray = transformData(urlLoader.data as ByteArray, url);
                var sound:Sound;
                
                urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, onIoError);
                urlLoader.removeEventListener(HTTP_RESPONSE_STATUS, onHttpResponseStatus);
                urlLoader.removeEventListener(ProgressEvent.PROGRESS, onLoadProgress);
                urlLoader.removeEventListener(Event.COMPLETE, onUrlLoaderComplete);
                
                if (extension)
                    extension = extension.toLowerCase();

                switch (extension)
                {
                    case "mpeg":
                    case "mp3":
                        sound = new Sound();
                        sound.loadCompressedDataFromByteArray(bytes, bytes.length);
                        bytes.clear();
                        complete(sound);
                        break;
                    case "jpg":
                    case "jpeg":
                    case "png":
                    case "gif":
                        var loaderContext:LoaderContext = new LoaderContext(mCheckPolicyFile);
                        var loader:Loader = new Loader();
                        loaderContext.imageDecodingPolicy = ImageDecodingPolicy.ON_LOAD;
                        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete);
                        loader.loadBytes(bytes, loaderContext);
                        break;
                    default: // any XML / JSON / binary data 
                        complete(bytes);
                        break;
                }
            }
            
            function onLoaderComplete(event:Object):void
            {
                urlLoader.data.clear();
                event.target.removeEventListener(Event.COMPLETE, onLoaderComplete);
                complete(event.target.content);
            }
            
            function complete(asset:Object):void
            {
                // On mobile, it is not allowed / endorsed to make stage3D calls while the app
                // is in the background. Thus, we pause queue processing if that's the case.
                
                if (SystemUtil.isDesktop)
                    onComplete(asset);
                else
                    SystemUtil.executeWhenApplicationIsActive(onComplete, asset);
            }
        }
        
        // helpers
        
        /** This method is called by 'enqueue' to determine the name under which an asset will be
         *  accessible; override it if you need a custom naming scheme. Typically, 'rawAsset' is 
         *  either a String or a FileReference. Note that this method won't be called for embedded
         *  assets. */
        protected function getName(rawAsset:Object):String
        {
            var matches:Array;
            var name:String;
            
            if (rawAsset is String || rawAsset is FileReference)
            {
                name = rawAsset is String ? rawAsset as String : (rawAsset as FileReference).name;
                name = name.replace(/%20/g, " "); // URLs use '%20' for spaces
                name = getBasenameFromUrl(name);
                
                if (name) return name;
                else throw new ArgumentError("Could not extract name from String '" + rawAsset + "'");
            }
            else
            {
                name = getQualifiedClassName(rawAsset);
                throw new ArgumentError("Cannot extract names for objects of type '" + name + "'");
            }
        }

        /** This method is called when raw byte data has been loaded from an URL or a file.
         *  Override it to process the downloaded data in some way (e.g. decompression) or
         *  to cache it on disk. */
        protected function transformData(data:ByteArray, url:String):ByteArray
        {
            return data;
        }

        /** This method is called during loading of assets when 'verbose' is activated. Per
         *  default, it traces 'message' to the console. */
        protected function log(message:String):void
        {
            if (mVerbose) trace("[AssetManager]", message);
        }
        
        private function byteArrayStartsWith(bytes:ByteArray, char:String):Boolean
        {
            var start:int = 0;
            var length:int = bytes.length;
            var wanted:int = char.charCodeAt(0);
            
            // recognize BOMs
            
            if (length >= 4 &&
                (bytes[0] == 0x00 && bytes[1] == 0x00 && bytes[2] == 0xfe && bytes[3] == 0xff) ||
                (bytes[0] == 0xff && bytes[1] == 0xfe && bytes[2] == 0x00 && bytes[3] == 0x00))
            {
                start = 4; // UTF-32
            }
            else if (length >= 3 && bytes[0] == 0xef && bytes[1] == 0xbb && bytes[2] == 0xbf)
            {
                start = 3; // UTF-8
            }
            else if (length >= 2 &&
                (bytes[0] == 0xfe && bytes[1] == 0xff) || (bytes[0] == 0xff && bytes[1] == 0xfe))
            {
                start = 2; // UTF-16
            }
            
            // find first meaningful letter
            
            for (var i:int=start; i<length; ++i)
            {
                var byte:int = bytes[i];
                if (byte == 0 || byte == 10 || byte == 13 || byte == 32) continue; // null, \n, \r, space
                else return byte == wanted;
            }
            
            return false;
        }
        
        private function getDictionaryKeys(dictionary:Dictionary, prefix:String="",
                                           result:Vector.<String>=null):Vector.<String>
        {
            if (result == null) result = new <String>[];
            
            for (var name:String in dictionary)
                if (name.indexOf(prefix) == 0)
                    result.push(name);
            
            result.sort(Array.CASEINSENSITIVE);
            return result;
        }
        
        private function getHttpHeader(headers:Array, headerName:String):String
        {
            if (headers)
            {
                for each (var header:Object in headers)
                    if (header.name == headerName) return header.value;
            }
            return null;
        }

        private function getBasenameFromUrl(url:String):String
        {
            var matches:Array = NAME_REGEX.exec(url);
            if (matches && matches.length > 0) return matches[1];
            else return null;
        }

        private function getExtensionFromUrl(url:String):String
        {
            var matches:Array = NAME_REGEX.exec(url);
            if (matches && matches.length > 1) return matches[2];
            else return null;
        }

        // properties
        
        /** The queue contains one 'Object' for each enqueued asset. Each object has 'asset'
         *  and 'name' properties, pointing to the raw asset and its name, respectively. */
        protected function get queue():Array { return mQueue; }
        
        /** Returns the number of raw assets that have been enqueued, but not yet loaded. */
        public function get numQueuedAssets():int { return mQueue.length; }
        
        /** When activated, the class will trace information about added/enqueued assets. */
        public function get verbose():Boolean { return mVerbose; }
        public function set verbose(value:Boolean):void { mVerbose = value; }
        
        /** For bitmap textures, this flag indicates if mip maps should be generated when they 
         *  are loaded; for ATF textures, it indicates if mip maps are valid and should be
         *  used. */
        public function get useMipMaps():Boolean { return mDefaultTextureOptions.mipMapping; }
        public function set useMipMaps(value:Boolean):void { mDefaultTextureOptions.mipMapping = value; }
        
        /** Textures that are created from Bitmaps or ATF files will have the scale factor 
         *  assigned here. */
        public function get scaleFactor():Number { return mDefaultTextureOptions.scale; }
        public function set scaleFactor(value:Number):void { mDefaultTextureOptions.scale = value; }
        
        /** Specifies whether a check should be made for the existence of a URL policy file before
         *  loading an object from a remote server. More information about this topic can be found 
         *  in the 'flash.system.LoaderContext' documentation. */
        public function get checkPolicyFile():Boolean { return mCheckPolicyFile; }
        public function set checkPolicyFile(value:Boolean):void { mCheckPolicyFile = value; }

        /** Indicates if atlas XML data should be stored for access via the 'getXml' method.
         *  If true, you can access an XML under the same name as the atlas.
         *  If false, XMLs will be disposed when the atlas was created. @default false. */
        public function get keepAtlasXmls():Boolean { return mKeepAtlasXmls; }
        public function set keepAtlasXmls(value:Boolean):void { mKeepAtlasXmls = value; }

        /** Indicates if bitmap font XML data should be stored for access via the 'getXml' method.
         *  If true, you can access an XML under the same name as the bitmap font.
         *  If false, XMLs will be disposed when the font was created. @default false. */
        public function get keepFontXmls():Boolean { return mKeepFontXmls; }
        public function set keepFontXmls(value:Boolean):void { mKeepFontXmls = value; }
    }
}
