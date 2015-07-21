// =================================================================================================
//
//  Starling Framework
//  Copyright 2011-2014 Gamua. All Rights Reserved.
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
    import org.flexunit.asserts.assertNotNull;
    import org.flexunit.asserts.assertNull;
    import org.flexunit.asserts.assertStrictlyEquals;
    
    import starling.events.Event;
    import starling.textures.TextureAtlas;
    import starling.utils.AssetManager;
    
    import tests.AsyncUtil;
    import tests.StarlingTestCase;
    
    public class AssetManagerTest extends StarlingTestCase
    {
        private var manager:TestAssetManager;
        
        override public function setUp():void
        {
            super.setUp();
            manager = new TestAssetManager();
            manager.verbose = false;
        }
        
        override public function tearDown():void
        {
            manager.purge();
            manager = null;
            super.tearDown();
        }
        
        [Test(expects="ArgumentError")]
        public function loadQueueWithoutCallback():void
        {
            manager.loadQueue(null);
        }
        
        [Test(async)]
        public function loadEmptyQueue():void
        {
            manager.loadQueue(AsyncUtil.asyncHandler(this, function(ratio:Number):void
            {
                assertEquals(1.0, ratio);
            }));
        }
        
        [Test(async)]
        public function loadBitmapFromPngFile():void
        {
            manager.enqueue("../fixtures/image.png");
            manager.loadQueue(AsyncUtil.asyncHandler(this, function(ratio:Number):void
            {
                assertEquals(1, manager.getTextures("image").length);
            }));
        }
        
        [Test(async)]
        public function loadBitmapFromJpgFile():void
        {
            manager.enqueue("../fixtures/image.jpg");
            manager.loadQueue(AsyncUtil.asyncHandler(this, function(ratio:Number):void
            {
                assertEquals(1, manager.getTextures("image").length);
            }));
        }
        
        [Test(async)]
        public function loadBitmapFromGifFile():void
        {
            manager.enqueue("../fixtures/image.gif");
            manager.loadQueue(AsyncUtil.asyncHandler(this, function(ratio:Number):void
            {
                assertEquals(1, manager.getTextures("image").length);
            }));
        }
        
        [Test(async)]
        public function loadXmlFromFile():void
        {
            manager.enqueue("../fixtures/xml.xml");
            manager.loadQueue(AsyncUtil.asyncHandler(this, function(ratio:Number):void
            {
                assertEquals(1, manager.getXmlNames("xml").length);
            }));
        }
        
        [Test(async)]
        public function loadInvalidXmlFromFile():void
        {
            handleStarlingEvent(Event.PARSE_ERROR, manager);
            manager.enqueue("../fixtures/invalid.xml");
            manager.loadQueue(function(ratio:Number):void { });
        }
        
        [Test(async)]
        public function loadJsonFromFile():void
        {
            manager.enqueue("../fixtures/json.json");
            manager.loadQueue(AsyncUtil.asyncHandler(this, function(ratio:Number):void
            {
                assertEquals(1, manager.getObjectNames("json").length);
            }));
        }
        
        [Test(async)]
        public function loadInvalidJsonFromFile():void
        {
            handleStarlingEvent(Event.PARSE_ERROR, manager);
            manager.enqueue("../fixtures/invalid.json");
            manager.loadQueue(function(ratio:Number):void { });
        }
        
        [Test(async)]
        public function loadSoundFromMp3File():void
        {
            manager.enqueue("../fixtures/audio.mp3");
            manager.loadQueue(AsyncUtil.asyncHandler(this, function(ratio:Number):void
            {
                assertEquals(1, manager.getSoundNames("audio").length);
            }));
        }
        
        [Test(async)]
        public function loadTextureAtlasFromFile():void
        {
            manager.enqueue("../fixtures/atlas.xml");
            manager.loadQueue(AsyncUtil.asyncHandler(this, function(ratio:Number):void
            {
                assertEquals("-Enqueuing 'atlas'-Cannot create atlas: texture 'atlas' is missing.", manager.logRecord);
            }));
        }
        
        [Test(async)]
        public function loadFontFromFile():void
        {
            manager.enqueue("../fixtures/font.xml");
            manager.loadQueue(AsyncUtil.asyncHandler(this, function(ratio:Number):void
            {
                assertEquals("-Enqueuing 'font'-Cannot create bitmap font: texture 'font' is missing.", manager.logRecord);
            }));
        }
        
        [Test(async)]
        public function loadByteArrayFromFile():void
        {
            manager.enqueue("../fixtures/data.txt");
            manager.loadQueue(AsyncUtil.asyncHandler(this, function(ratio:Number):void
            {
                assertEquals(1, manager.getByteArrayNames("data").length);
            }));
        }
        
        [Test(async)]
        public function loadXmlFromByteArray():void
        {
            manager.verbose = true;
            manager.enqueue(EmbeddedXml);
            manager.loadQueue(AsyncUtil.asyncHandler(this, function(ratio:Number):void
            {
                assertEquals(1, manager.getXmlNames("Data").length);
            }));
        }
        
        [Test(async)]
        public function loadJsonFromByteArray():void
        {
            manager.verbose = true;
            manager.enqueue(EmbeddedJson);
            manager.loadQueue(AsyncUtil.asyncHandler(this, function(ratio:Number):void
            {
                assertEquals(1, manager.getObjectNames("Data").length);
            }));
        }

        [Ignore("Incomplete because to atf.atf file is missing.")]
        [Test(async)]
        public function loadAtfFromByteArray():void
        {
            manager.enqueue("../fixtures/atf.atf");
            manager.loadQueue(AsyncUtil.asyncHandler(this, function(ratio:Number):void
            {
                assertEquals(1, manager.getTextures("atf").length);
            }));
        }

        [Test(async)]
        public function purgeQueue():void
        {
            handleStarlingEvent(starling.events.Event.CANCEL, manager);
            manager.purgeQueue();
            assertEquals(0, manager.queueLength);
        }
        
        [Test]
        public function textureAsset():void
        {
            const NAME:String = "test_texture";
            var texture:TextureMock = new TextureMock();
            
            manager.addTexture(NAME, texture);
            assertStrictlyEquals(texture, manager.getTexture(NAME));
            assertEquals(1, manager.getTextures(NAME).length);
            assertEquals(1, manager.getTextureNames(NAME).length);
            assertEquals(NAME, manager.getTextureNames(NAME)[0]);
            
            manager.removeTexture(NAME);
            assertNull(manager.getTexture(NAME));
            assertEquals(0, manager.getTextures(NAME).length);
            assertEquals(0, manager.getTextureNames(NAME).length);
        }
        
        [Test]
        public function textureAtlasAsset():void
        {
            const NAME:String = "test_textureAtlas";
            var atlas:TextureAtlas = new TextureAtlas(null);
            
            manager.addTextureAtlas(NAME, atlas);
            assertStrictlyEquals(atlas, manager.getTextureAtlas(NAME));
            
            manager.removeTextureAtlas(NAME, false);// do not dispose, it holds no real texture
            assertNull(manager.getTextureAtlas(NAME));
        }
        
        [Test]
        public function soundAsset():void
        {
            const NAME:String = "test_sound";
            var sound:Sound = new Sound();
            
            manager.addSound(NAME, sound);
            assertStrictlyEquals(sound, manager.getSound(NAME));
            assertEquals(1, manager.getSoundNames(NAME).length);
            assertEquals(NAME, manager.getSoundNames(NAME)[0]);
            
            manager.removeSound(NAME);
            assertNull(manager.getSound(NAME));
            assertEquals(0, manager.getSoundNames(NAME).length);
        }
        
        [Test]
        public function playUndefinedSound():void
        {
            assertNull(manager.playSound("undefined"));
        }
        
        [Test]
        public function xmlAsset():void
        {
            const NAME:String = "test_xml";
            var xml:XML = new XML("<test/>");
            
            manager.addXml(NAME, xml);
            assertStrictlyEquals(xml, manager.getXml(NAME));
            assertEquals(1, manager.getXmlNames(NAME).length);
            assertEquals(NAME, manager.getXmlNames(NAME)[0]);
            
            manager.removeXml(NAME);
            assertNull(manager.getXml(NAME));
            assertEquals(0, manager.getXmlNames(NAME).length);
        }
        
        [Test]
        public function objectAsset():void
        {
            const NAME:String = "test_object";
            var object:Object = {};
            
            manager.addObject(NAME, object);
            assertStrictlyEquals(object, manager.getObject(NAME));
            assertEquals(1, manager.getObjectNames(NAME).length);
            assertEquals(NAME, manager.getObjectNames(NAME)[0]);
            
            manager.removeObject(NAME);
            assertNull(manager.getObject(NAME));
            assertEquals(0, manager.getObjectNames(NAME).length);
        }
        
        [Test]
        public function byteArrayAsset():void
        {
            const NAME:String = "test_bytearray";
            var bytes:ByteArray = new ByteArray();
            
            manager.addByteArray(NAME, bytes);
            assertStrictlyEquals(bytes, manager.getByteArray(NAME));
            assertEquals(1, manager.getByteArrayNames(NAME).length);
            assertEquals(NAME, manager.getByteArrayNames(NAME)[0]);
            
            manager.removeByteArray(NAME);
            assertNull(manager.getByteArray(NAME));
            assertEquals(0, manager.getByteArrayNames(NAME).length);
        }
        
        [Test]
        public function getNameForStringAsRawAsset():void
        {
            assertEquals("a", manager.__getName("a"));
            assertEquals("image", manager.__getName("image.png"));
            assertEquals("my image 2", manager.__getName("my%20image%202.png"));
        }
        
        [Test(expects="ArgumentError")]
        public function getNameForEmptyStringAsRawAsset():void
        {
            manager.__getName("");
        }
        
        [Test]
        public function getNameForFileReferenceAsRawAsset():void
        {
            assertEquals("a", manager.__getName(new FileReferenceMock("a")));
            assertEquals("image", manager.__getName(new FileReferenceMock("image.png")));
            assertEquals("my image 2", manager.__getName(new FileReferenceMock("my%20image%202.png")));
        }
        
        [Test(expects="ArgumentError")]
        public function getNameForUnsupportedTypeAsRawAsset():void
        {
            manager.__getName({});
        }
        
        [Test]
        public function getBasenameFromUrl():void
        {
            assertEquals("a", manager.__getBasenameFromUrl("a"));
            assertEquals("image", manager.__getBasenameFromUrl("image.png"));
            assertEquals("image", manager.__getBasenameFromUrl("http://example.com/dir/image.png"));
            assertNull(manager.__getBasenameFromUrl("http://example.com/dir/image/"));
        }
        
        [Test]
        public function getExtensionFromUrl():void
        {
            assertEquals("png", manager.__getExtensionFromUrl("image.png"));
            assertEquals("png", manager.__getExtensionFromUrl("http://example.com/dir/image.png"));
            assertNull(manager.__getExtensionFromUrl("http://example.com/dir/image/"));
        }
        
        [Test]
        public function enqueueWithName():void
        {
            manager.enqueueWithName("a", "b");
            assertEquals(1, manager.numQueuedAssets);
        }
        
        [Test]
        public function enqueueString():void
        {
            manager.enqueue("a");
            assertEquals(1, manager.numQueuedAssets);
        }
        
        [Test]
        public function enqueueArray():void
        {
            manager.enqueue(["a", "b"]);
            assertEquals(2, manager.numQueuedAssets);
        }
        
        [Test]
        public function enqueueClass():void
        {
            manager.enqueue(EmbeddedBitmap);
            assertEquals(1, manager.numQueuedAssets);
        }
        
        [Test]
        public function enqueueUnsupportedType():void
        {
            manager.enqueue({});
            assertEquals(0, manager.numQueuedAssets);
        }
        
    }
}

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

import starling.textures.Texture;

class TextureMock extends Texture
{
    public function TextureMock()
    {
        // do not call super()
    }
}

import flash.net.FileReference;

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