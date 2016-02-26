// =================================================================================================
//
//  Starling Framework
//  Copyright Gamua GmbH. All Rights Reserved.
//
//  This program is free software. You can redistribute and/or modify it
//  in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.utils
{
    import flash.media.Sound;
    import flash.utils.ByteArray;

    import org.flexunit.asserts.assertEquals;
    import org.flexunit.asserts.assertNull;
    import org.flexunit.asserts.assertStrictlyEquals;

    import starling.events.Event;
    import starling.textures.TextureAtlas;

    import tests.AsyncUtil;
    import tests.StarlingTestCase;

    public class AssetManagerTest extends StarlingTestCase
    {
        private var _manager:TestAssetManager;
        
        override public function setUp():void
        {
            super.setUp();
            _manager = new TestAssetManager();
            _manager.verbose = false;
        }
        
        override public function tearDown():void
        {
            _manager.purge();
            _manager = null;
            super.tearDown();
        }
        
        [Test(expects="ArgumentError")]
        public function loadQueueWithoutCallback():void
        {
            _manager.loadQueue(null);
        }
        
        [Test(async)]
        public function loadEmptyQueue():void
        {
            _manager.loadQueue(AsyncUtil.asyncHandler(this, function(ratio:Number):void
            {
                assertEquals(1.0, ratio);
            }));
        }
        
        [Test(async)]
        public function loadBitmapFromPngFile():void
        {
            _manager.enqueue("../fixtures/image.png");
            _manager.loadQueue(AsyncUtil.asyncHandler(this, function(ratio:Number):void
            {
                assertEquals(1, _manager.getTextures("image").length);
            }));
        }
        
        [Test(async)]
        public function loadBitmapFromJpgFile():void
        {
            _manager.enqueue("../fixtures/image.jpg");
            _manager.loadQueue(AsyncUtil.asyncHandler(this, function(ratio:Number):void
            {
                assertEquals(1, _manager.getTextures("image").length);
            }));
        }
        
        [Test(async)]
        public function loadBitmapFromGifFile():void
        {
            _manager.enqueue("../fixtures/image.gif");
            _manager.loadQueue(AsyncUtil.asyncHandler(this, function(ratio:Number):void
            {
                assertEquals(1, _manager.getTextures("image").length);
            }));
        }
        
        [Test(async)]
        public function loadXmlFromFile():void
        {
            _manager.enqueue("../fixtures/xml.xml");
            _manager.loadQueue(AsyncUtil.asyncHandler(this, function(ratio:Number):void
            {
                assertEquals(1, _manager.getXmlNames("xml").length);
            }));
        }
        
        [Test(async)]
        public function loadInvalidXmlFromFile():void
        {
            handleStarlingEvent(Event.PARSE_ERROR, _manager);
            _manager.enqueue("../fixtures/invalid.xml");
            _manager.loadQueue(function(ratio:Number):void { });
        }
        
        [Test(async)]
        public function loadJsonFromFile():void
        {
            _manager.enqueue("../fixtures/json.json");
            _manager.loadQueue(AsyncUtil.asyncHandler(this, function(ratio:Number):void
            {
                assertEquals(1, _manager.getObjectNames("json").length);
            }));
        }
        
        [Test(async)]
        public function loadInvalidJsonFromFile():void
        {
            handleStarlingEvent(Event.PARSE_ERROR, _manager);
            _manager.enqueue("../fixtures/invalid.json");
            _manager.loadQueue(function(ratio:Number):void { });
        }
        
        [Test(async)]
        public function loadSoundFromMp3File():void
        {
            _manager.enqueue("../fixtures/audio.mp3");
            _manager.loadQueue(AsyncUtil.asyncHandler(this, function(ratio:Number):void
            {
                assertEquals(1, _manager.getSoundNames("audio").length);
            }));
        }
        
        [Test(async)]
        public function loadTextureAtlasFromFile():void
        {
            _manager.enqueue("../fixtures/atlas.xml");
            _manager.loadQueue(AsyncUtil.asyncHandler(this, function(ratio:Number):void
            {
                assertEquals("-Enqueuing 'atlas'-Cannot create atlas: texture 'atlas' is missing.", _manager.logRecord);
            }));
        }
        
        [Test(async)]
        public function loadFontFromFile():void
        {
            _manager.enqueue("../fixtures/font.xml");
            _manager.loadQueue(AsyncUtil.asyncHandler(this, function(ratio:Number):void
            {
                assertEquals("-Enqueuing 'font'-Cannot create bitmap font: texture 'font' is missing.", _manager.logRecord);
            }));
        }
        
        [Test(async)]
        public function loadByteArrayFromFile():void
        {
            _manager.enqueue("../fixtures/data.txt");
            _manager.loadQueue(AsyncUtil.asyncHandler(this, function(ratio:Number):void
            {
                assertEquals(1, _manager.getByteArrayNames("data").length);
            }));
        }
        
        [Test(async)]
        public function loadXmlFromByteArray():void
        {
            _manager.verbose = true;
            _manager.enqueue(EmbeddedXml);
            _manager.loadQueue(AsyncUtil.asyncHandler(this, function(ratio:Number):void
            {
                assertEquals(1, _manager.getXmlNames("Data").length);
            }));
        }
        
        [Test(async)]
        public function loadJsonFromByteArray():void
        {
            _manager.verbose = true;
            _manager.enqueue(EmbeddedJson);
            _manager.loadQueue(AsyncUtil.asyncHandler(this, function(ratio:Number):void
            {
                assertEquals(1, _manager.getObjectNames("Data").length);
            }));
        }

        [Ignore("Incomplete because to atf.atf file is missing.")]
        [Test(async)]
        public function loadAtfFromByteArray():void
        {
            _manager.enqueue("../fixtures/atf.atf");
            _manager.loadQueue(AsyncUtil.asyncHandler(this, function(ratio:Number):void
            {
                assertEquals(1, _manager.getTextures("atf").length);
            }));
        }

        [Test(async)]
        public function purgeQueue():void
        {
            handleStarlingEvent(Event.CANCEL, _manager);
            _manager.purgeQueue();
            assertEquals(0, _manager.queueLength);
        }
        
        [Test]
        public function textureAsset():void
        {
            const NAME:String = "test_texture";
            var texture:TextureMock = new TextureMock();
            
            _manager.addTexture(NAME, texture);
            assertStrictlyEquals(texture, _manager.getTexture(NAME));
            assertEquals(1, _manager.getTextures(NAME).length);
            assertEquals(1, _manager.getTextureNames(NAME).length);
            assertEquals(NAME, _manager.getTextureNames(NAME)[0]);
            
            _manager.removeTexture(NAME);
            assertNull(_manager.getTexture(NAME));
            assertEquals(0, _manager.getTextures(NAME).length);
            assertEquals(0, _manager.getTextureNames(NAME).length);
        }
        
        [Test]
        public function textureAtlasAsset():void
        {
            const NAME:String = "test_textureAtlas";
            var atlas:TextureAtlas = new TextureAtlas(null);
            
            _manager.addTextureAtlas(NAME, atlas);
            assertStrictlyEquals(atlas, _manager.getTextureAtlas(NAME));
            assertEquals(1, _manager.getTextureAtlasNames(NAME).length);
            assertEquals(NAME, _manager.getTextureAtlasNames(NAME)[0]);
            
            _manager.removeTextureAtlas(NAME, false);// do not dispose, it holds no real texture
            assertNull(_manager.getTextureAtlas(NAME));
            assertEquals(0, _manager.getTextureAtlasNames(NAME).length);
        }
        
        [Test]
        public function soundAsset():void
        {
            const NAME:String = "test_sound";
            var sound:Sound = new Sound();
            
            _manager.addSound(NAME, sound);
            assertStrictlyEquals(sound, _manager.getSound(NAME));
            assertEquals(1, _manager.getSoundNames(NAME).length);
            assertEquals(NAME, _manager.getSoundNames(NAME)[0]);
            
            _manager.removeSound(NAME);
            assertNull(_manager.getSound(NAME));
            assertEquals(0, _manager.getSoundNames(NAME).length);
        }
        
        [Test]
        public function playUndefinedSound():void
        {
            assertNull(_manager.playSound("undefined"));
        }
        
        [Test]
        public function xmlAsset():void
        {
            const NAME:String = "test_xml";
            var xml:XML = new XML("<test/>");
            
            _manager.addXml(NAME, xml);
            assertStrictlyEquals(xml, _manager.getXml(NAME));
            assertEquals(1, _manager.getXmlNames(NAME).length);
            assertEquals(NAME, _manager.getXmlNames(NAME)[0]);
            
            _manager.removeXml(NAME);
            assertNull(_manager.getXml(NAME));
            assertEquals(0, _manager.getXmlNames(NAME).length);
        }
        
        [Test]
        public function objectAsset():void
        {
            const NAME:String = "test_object";
            var object:Object = {};
            
            _manager.addObject(NAME, object);
            assertStrictlyEquals(object, _manager.getObject(NAME));
            assertEquals(1, _manager.getObjectNames(NAME).length);
            assertEquals(NAME, _manager.getObjectNames(NAME)[0]);
            
            _manager.removeObject(NAME);
            assertNull(_manager.getObject(NAME));
            assertEquals(0, _manager.getObjectNames(NAME).length);
        }
        
        [Test]
        public function byteArrayAsset():void
        {
            const NAME:String = "test_bytearray";
            var bytes:ByteArray = new ByteArray();
            
            _manager.addByteArray(NAME, bytes);
            assertStrictlyEquals(bytes, _manager.getByteArray(NAME));
            assertEquals(1, _manager.getByteArrayNames(NAME).length);
            assertEquals(NAME, _manager.getByteArrayNames(NAME)[0]);
            
            _manager.removeByteArray(NAME);
            assertNull(_manager.getByteArray(NAME));
            assertEquals(0, _manager.getByteArrayNames(NAME).length);
        }
        
        [Test]
        public function getNameForStringAsRawAsset():void
        {
            assertEquals("a", _manager.__getName("a"));
            assertEquals("image", _manager.__getName("image.png"));
            assertEquals("my image 2", _manager.__getName("my%20image%202.png"));
        }
        
        [Test(expects="ArgumentError")]
        public function getNameForEmptyStringAsRawAsset():void
        {
            _manager.__getName("");
        }
        
        [Test]
        public function getNameForFileReferenceAsRawAsset():void
        {
            assertEquals("a", _manager.__getName(new FileReferenceMock("a")));
            assertEquals("image", _manager.__getName(new FileReferenceMock("image.png")));
            assertEquals("my image 2", _manager.__getName(new FileReferenceMock("my%20image%202.png")));
        }
        
        [Test(expects="ArgumentError")]
        public function getNameForUnsupportedTypeAsRawAsset():void
        {
            _manager.__getName({});
        }
        
        [Test]
        public function getBasenameFromUrl():void
        {
            assertEquals("a", _manager.__getBasenameFromUrl("a"));
            assertEquals("image", _manager.__getBasenameFromUrl("image.png"));
            assertEquals("image", _manager.__getBasenameFromUrl("http://example.com/dir/image.png"));
            assertNull(_manager.__getBasenameFromUrl("http://example.com/dir/image/"));
        }
        
        [Test]
        public function getExtensionFromUrl():void
        {
            assertEquals("png", _manager.__getExtensionFromUrl("image.png"));
            assertEquals("png", _manager.__getExtensionFromUrl("http://example.com/dir/image.png"));
            assertNull(_manager.__getExtensionFromUrl("http://example.com/dir/image/"));
        }
        
        [Test]
        public function enqueueWithName():void
        {
            _manager.enqueueWithName("a", "b");
            assertEquals(1, _manager.numQueuedAssets);
        }
        
        [Test]
        public function enqueueString():void
        {
            _manager.enqueue("a");
            assertEquals(1, _manager.numQueuedAssets);
        }
        
        [Test]
        public function enqueueArray():void
        {
            _manager.enqueue(["a", "b"]);
            assertEquals(2, _manager.numQueuedAssets);
        }
        
        [Test]
        public function enqueueClass():void
        {
            _manager.enqueue(EmbeddedBitmap);
            assertEquals(1, _manager.numQueuedAssets);
        }
        
        [Test]
        public function enqueueUnsupportedType():void
        {
            _manager.enqueue({});
            assertEquals(0, _manager.numQueuedAssets);
        }
        
    }
}

import flash.net.FileReference;

import starling.textures.Texture;
import starling.utils.AssetManager;

class TestAssetManager extends AssetManager
{
    
    public var logRecord:String = "";
    
    public function get queueLength():uint
    {
        return queue.length;
    }
    
    override public function loadQueue(onProgress:Function):void
    {
        // onProgress function is hard to test, so onComplete is wrapped with onComplete,
        // which calls onProgress only if the load is completed (ratio == 1.0).
        //
        // If onProgress is set to null, then do not wrap it and pass null to super.
        
        var onComplete:Function = function(ratio:Number):void
        {
            if (ratio == 1.0) onProgress(ratio);
        };
        
        super.loadQueue(onProgress is Function ? onComplete : onProgress);
    }
    
    override protected function log(message:String):void
    {
        logRecord += "-" + message;
        super.log(message);
    }
    
    public function __getBasenameFromUrl(url:String):String
    {
        return getBasenameFromUrl(url);
    }
    
    public function __getExtensionFromUrl(url:String):String
    {
        return getExtensionFromUrl(url);
    }
    
    public function __getName(rawAsset:Object):String
    {
        return getName(rawAsset);
    }
    
}

class EmbeddedBitmap
{
    [Embed(source="../../../fixtures/image.png")]
    public static const Image:Class;
}

class EmbeddedXml
{
    [Embed(source="../../../fixtures/xml.xml", mimeType="application/octet-stream")]
    public static const Data:Class;
}

class EmbeddedJson
{
    [Embed(source="../../../fixtures/json.json", mimeType="application/octet-stream")]
    public static const Data:Class;
}

class TextureMock extends Texture
{
    public function TextureMock()
    {
        // do not call super()
    }
}

class FileReferenceMock extends FileReference
{
    private var _name:String;
    
    public function FileReferenceMock(name:String)
    {
        super();
        _name = name;
    }
    
    override public function get name():String
    {
        return _name;
    }
}