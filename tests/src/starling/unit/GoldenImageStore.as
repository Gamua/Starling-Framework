package starling.unit
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Loader;
    import flash.display.PNGEncoderOptions;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.utils.ByteArray;

    /** Loads and saves the reference images used by 'UnitTest.assertMatchesGolden'. */
    public class GoldenImageStore
    {
        private var _directory:File;
        private var _failureDirectory:File;

        /** @param directory         where the golden images are stored.
         *  @param failureDirectory  where actual and diff images are saved on a mismatch. */
        public function GoldenImageStore(directory:File, failureDirectory:File)
        {
            _directory = directory;
            _failureDirectory = failureDirectory;
        }

        /** Loads the golden image with the given name and passes it to 'onComplete', or
         *  null if it does not exist. */
        public function load(name:String, onComplete:Function):void
        {
            var file:File = _directory.resolvePath(name + ".png");
            if (!file.exists) { onComplete(null); return; }

            var bytes:ByteArray = new ByteArray();
            var stream:FileStream = new FileStream();
            stream.open(file, FileMode.READ);
            stream.readBytes(bytes);
            stream.close();

            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function():void
            {
                onComplete((loader.content as Bitmap).bitmapData);
            });
            loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function():void
            {
                onComplete(null);
            });
            loader.loadBytes(bytes);
        }

        public function save(name:String, image:BitmapData):void
        {
            write(_directory.resolvePath(name + ".png"), image);
        }

        /** Saves the actual and diff images next to each other, so they can be inspected. */
        public function saveFailure(name:String, actual:BitmapData, diff:BitmapData):void
        {
            write(_failureDirectory.resolvePath(name + ".png"), actual);
            if (diff) write(_failureDirectory.resolvePath(name + "-diff.png"), diff);
        }

        private function write(file:File, image:BitmapData):void
        {
            var stream:FileStream = new FileStream();
            file.parent.createDirectory();
            stream.open(file, FileMode.WRITE);
            stream.writeBytes(image.encode(image.rect, new PNGEncoderOptions()));
            stream.close();
        }
    }
}
