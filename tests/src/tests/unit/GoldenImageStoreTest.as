// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.unit
{
    import flash.display.BitmapData;
    import flash.filesystem.File;

    import starling.unit.GoldenImageStore;
    import starling.unit.ImageDiff;
    import starling.unit.UnitTest;

    public class GoldenImageStoreTest extends UnitTest
    {
        private var _tempDir:File;
        private var _goldenImageStore:GoldenImageStore;

        override public function setUp():void
        {
            super.setUp();
            _tempDir = File.createTempDirectory();
            _goldenImageStore = new GoldenImageStore(
                _tempDir.resolvePath("golden"), _tempDir.resolvePath("failures"));
        }

        override public function tearDown():void
        {
            _tempDir.deleteDirectory(true);
            super.tearDown();
        }

        public function testSaveAndLoad(onComplete:Function):void
        {
            var image:BitmapData = new BitmapData(4, 4, true, 0xff336699);
            image.setPixel32(0, 0, 0xffff0000);
            _goldenImageStore.save("test", image);

            _goldenImageStore.load("test", function(loaded:BitmapData):void
            {
                assertNotNull(loaded);
                if (loaded) assertEqual(0, ImageDiff.compare(image, loaded, 0).numDiffPixels);
                onComplete();
            });
        }

        public function testLoadMissingImage(onComplete:Function):void
        {
            _goldenImageStore.load("missing", function(loaded:BitmapData):void
            {
                assertNull(loaded);
                onComplete();
            });
        }

        public function testSaveFailure():void
        {
            var image:BitmapData = new BitmapData(4, 4);
            _goldenImageStore.saveFailure("test", image, image);

            assertTrue(_tempDir.resolvePath("failures/test.png").exists);
            assertTrue(_tempDir.resolvePath("failures/test-diff.png").exists);
            assertFalse(_tempDir.resolvePath("golden/test.png").exists);
        }
    }
}
