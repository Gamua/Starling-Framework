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

    import starling.events.Event;
    import starling.textures.TextureAtlas;
    import starling.unit.UnitTest;
    import utils.MockTexture;

    public class AssetManagerTest extends UnitTest
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

        public function testLoadEmptyQueue(onComplete:Function):void
        {
            _manager.loadQueue(function():void
            {
                assert(true);
                onComplete();
            });
        }

        public function testLoadBitmapFromPngFile(onComplete:Function):void
        {
            _manager.enqueue("../fixtures/image.png");
            _manager.loadQueue(function():void
            {
                assertEqual(1, _manager.getTextures("image").length);
                onComplete();
            });
        }

        public function testLoadBitmapFromJpgFile(onComplete:Function):void
        {
            _manager.enqueue("../fixtures/image.jpg");
            _manager.loadQueue(function():void
            {
                assertEqual(1, _manager.getTextures("image").length);
                onComplete();
            });
        }

        public function testLoadBitmapFromGifFile(onComplete:Function):void
        {
            _manager.enqueue("../fixtures/image.gif");
            _manager.loadQueue(function():void
            {
                assertEqual(1, _manager.getTextures("image").length);
                onComplete();
            });
        }

        public function testLoadXmlFromFile(onComplete:Function):void
        {
            _manager.enqueue("../fixtures/xml.xml");
            _manager.loadQueue(function():void
            {
                assertEqual(1, _manager.getXmlNames("xml").length);
                onComplete();
            });
        }

        public function testLoadInvalidXmlFromFile(onComplete:Function):void
        {
            var errorCount:int = 0;

            _manager.enqueue("../fixtures/invalid.xml");
            _manager.loadQueue(onSuccess, onError);

            function onSuccess():void
            {
                assertEqual(1, errorCount);
                onComplete();
            }

            function onError(error:String):void { ++errorCount; }
        }

        public function testLoadJsonFromFile(onComplete:Function):void
        {
            _manager.enqueue("../fixtures/json.json");
            _manager.loadQueue(function():void
            {
                assertEqual(1, _manager.getObjectNames("json").length);
                onComplete();
            });
        }

        public function testLoadInvalidJsonFromFile(onComplete:Function):void
        {
            var errorCount:int=0;

            _manager.enqueue("../fixtures/invalid.json");
            _manager.loadQueue(onSuccess, onError);

            function onSuccess():void
            {
                assertEqual(1, errorCount);
                onComplete();
            }

            function onError(error:String):void { ++errorCount; }
        }

        public function testLoadSoundFromMp3File(onComplete:Function):void
        {
            _manager.enqueue("../fixtures/audio.mp3");
            _manager.loadQueue(function():void
            {
                assertEqual(1, _manager.getSoundNames("audio").length);
                onComplete();
            });
        }

        public function testLoadTextureAtlasFromFile(onComplete:Function):void
        {
            _manager.enqueue("../fixtures/atlas.xml");
            _manager.enqueueSingle("../fixtures/image.png", "atlas");
            _manager.loadQueue(function():void
            {
                assertEqual(1, _manager.getTextureAtlasNames("atlas").length);
                onComplete();
            });
        }

        public function testLoadFontFromFile(onComplete:Function):void
        {
            _manager.enqueue("../fixtures/font.xml");
            _manager.enqueueSingle("../fixtures/image.png", "font");
            _manager.loadQueue(function():void
            {
                assertEqual(1, _manager.getBitmapFontNames().length);
                onComplete();
            });
        }

        public function testLoadByteArrayFromFile(onComplete:Function):void
        {
            _manager.enqueue("../fixtures/data.txt");
            _manager.loadQueue(function():void
            {
                var bytes:ByteArray = _manager.getByteArray("data");
                assertNotNull(bytes);
                assertEqual("data", bytes.readUTFBytes(bytes.length));
                onComplete();
            });
        }

        public function testLoadXmlFromByteArray(onComplete:Function):void
        {
            _manager.verbose = true;
            _manager.enqueue(EmbeddedXml);
            _manager.loadQueue(function():void
            {
                assertEqual(1, _manager.getXmlNames("Data").length);
                onComplete();
            });
        }

        public function testLoadJsonFromByteArray(onComplete:Function):void
        {
            _manager.verbose = true;
            _manager.enqueue(EmbeddedJson);
            _manager.loadQueue(function():void
            {
                assertEqual(1, _manager.getObjectNames("Data").length);
                onComplete();
            });
        }

        public function testLoadAtfFromByteArray(onComplete:Function):void
        {
            _manager.enqueue("../fixtures/image.atf");
            _manager.loadQueue(function():void
            {
                assertEqual(1, _manager.getTextures("image").length);
                onComplete();
            });
        }

        public function testPurgeQueue():void
        {
            var cancelCount:int = 0;
            function onCanceled (e:Event):void { cancelCount += 1;  }

            _manager.addEventListener(Event.CANCEL, onCanceled);
            _manager.purgeQueue();
            assertEqual(0, _manager.numQueuedAssets);
            assertEqual(cancelCount, 1);
            _manager.removeEventListener(Event.CANCEL, onCanceled);
        }

        public function testTextureAsset():void
        {
            const NAME:String = "test_texture";
            var texture:MockTexture = new MockTexture();

            _manager.addAsset(NAME, texture);
            assertEqual(texture, _manager.getTexture(NAME));
            assertEqual(1, _manager.getTextures(NAME).length);
            assertEqual(1, _manager.getTextureNames(NAME).length);
            assertEqual(NAME, _manager.getTextureNames(NAME)[0]);

            _manager.removeTexture(NAME);
            assertNull(_manager.getTexture(NAME));
            assertEqual(0, _manager.getTextures(NAME).length);
            assertEqual(0, _manager.getTextureNames(NAME).length);
        }

        public function testTextureAtlasAsset():void
        {
            const NAME:String = "test_textureAtlas";
            var atlas:TextureAtlas = new TextureAtlas(null);

            _manager.addAsset(NAME, atlas);
            assertEqual(atlas, _manager.getTextureAtlas(NAME));
            assertEqual(1, _manager.getTextureAtlasNames(NAME).length);
            assertEqual(NAME, _manager.getTextureAtlasNames(NAME)[0]);

            _manager.removeTextureAtlas(NAME, false);// do not dispose, it holds no real texture
            assertNull(_manager.getTextureAtlas(NAME));
            assertEqual(0, _manager.getTextureAtlasNames(NAME).length);
        }

        public function testSoundAsset():void
        {
            const NAME:String = "test_sound";
            var sound:Sound = new Sound();

            _manager.addAsset(NAME, sound);
            assertEqual(sound, _manager.getSound(NAME));
            assertEqual(1, _manager.getSoundNames(NAME).length);
            assertEqual(NAME, _manager.getSoundNames(NAME)[0]);

            _manager.removeSound(NAME);
            assertNull(_manager.getSound(NAME));
            assertEqual(0, _manager.getSoundNames(NAME).length);
        }

        public function testPlayUndefinedSound():void
        {
            assertNull(_manager.playSound("undefined"));
        }

        public function testXmlAsset():void
        {
            const NAME:String = "test_xml";
            var xml:XML = new XML("<test/>");

            _manager.addAsset(NAME, xml);
            assertEqual(xml, _manager.getXml(NAME));
            assertEqual(1, _manager.getXmlNames(NAME).length);
            assertEqual(NAME, _manager.getXmlNames(NAME)[0]);

            _manager.removeXml(NAME);
            assertNull(_manager.getXml(NAME));
            assertEqual(0, _manager.getXmlNames(NAME).length);
        }

        public function testObjectAsset():void
        {
            const NAME:String = "test_object";
            var object:Object = {};

            _manager.addAsset(NAME, object);
            assertEqual(object, _manager.getObject(NAME));
            assertEqual(1, _manager.getObjectNames(NAME).length);
            assertEqual(NAME, _manager.getObjectNames(NAME)[0]);

            _manager.removeObject(NAME);
            assertNull(_manager.getObject(NAME));
            assertEqual(0, _manager.getObjectNames(NAME).length);
        }

        public function testByteArrayAsset():void
        {
            const NAME:String = "test_bytearray";
            var bytes:ByteArray = new ByteArray();

            _manager.addAsset(NAME, bytes);
            assertEqual(bytes, _manager.getByteArray(NAME));
            assertEqual(1, _manager.getByteArrayNames(NAME).length);
            assertEqual(NAME, _manager.getByteArrayNames(NAME)[0]);

            _manager.removeByteArray(NAME);
            assertNull(_manager.getByteArray(NAME));
            assertEqual(0, _manager.getByteArrayNames(NAME).length);
        }

        public function testGetBasenameFromUrl():void
        {
            assertEqual("a", _manager.__getNameFromUrl("a"));
            assertEqual("image", _manager.__getNameFromUrl("image.png"));
            assertEqual("image", _manager.__getNameFromUrl("http://example.com/dir/image.png"));
            assertEqual(null, _manager.__getNameFromUrl("http://example.com/dir/image/"));
        }

        public function testGetExtensionFromUrl():void
        {
            assertEqual("png", _manager.__getExtensionFromUrl("image.png"));
            assertEqual("png", _manager.__getExtensionFromUrl("http://example.com/dir/image.png"));
            assertEqual("", _manager.__getExtensionFromUrl("http://example.com/dir/image/"));
        }

        public function testEnqueueWithName():void
        {
            _manager.enqueueSingle("a", "b");
            assertEqual(1, _manager.numQueuedAssets);
        }

        public function testEnqueueString():void
        {
            _manager.enqueue("a");
            assertEqual(1, _manager.numQueuedAssets);
        }

        public function testEnqueueArray():void
        {
            _manager.enqueue(["a", "b"]);
            assertEqual(2, _manager.numQueuedAssets);
        }

        public function testEnqueueClass():void
        {
            _manager.enqueue(EmbeddedBitmap);
            assertEqual(1, _manager.numQueuedAssets);
        }

        public function testEnqueueUnsupportedType():void
        {
            _manager.enqueue({});
            assertEqual(0, _manager.numQueuedAssets);
        }

        public function testAddSameTextureTwice():void
        {
            var texture:MockTexture = new MockTexture();
            var name:String = "mock";

            _manager.addAsset(name, texture);
            _manager.addAsset(name, texture);

            assertFalse(texture.isDisposed);
        }

        public function testDequeueAsset(onComplete:Function):void
        {
            _manager.enqueue("../fixtures/image.png");
            _manager.enqueue("../fixtures/json.json");
            _manager.enqueue("../fixtures/data.txt");
            _manager.enqueue("../fixtures/xml.xml");
            _manager.dequeue("data", "xml");
            _manager.loadQueue(function():void
            {
                assertNotNull(_manager.getTextures("image"));
                assertNull(_manager.getByteArray("data"));
                assertNotNull(_manager.getObject("json"));
                assertNull(_manager.getObject("xml"));
                onComplete();
            });
        }
    }
}

import starling.assets.AssetManager;

class TestAssetManager extends AssetManager
{
    public function __getNameFromUrl(url:String):String
    {
        return getNameFromUrl(url);
    }

    public function __getExtensionFromUrl(url:String):String
    {
        return getExtensionFromUrl(url);
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
