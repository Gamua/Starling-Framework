package starling.unit
{
    import flash.display.BitmapData;

    /** The result of comparing two images pixel by pixel (see 'compare'). */
    public class ImageDiff
    {
        private var _numDiffPixels:int;
        private var _maxDelta:int;
        private var _image:BitmapData;

        public function ImageDiff(numDiffPixels:int, maxDelta:int, image:BitmapData)
        {
            _numDiffPixels = numDiffPixels;
            _maxDelta = maxDelta;
            _image = image;
        }

        /** Compares the images pixel by pixel. A pixel only counts as different if one of its
         *  channels differs by more than 'threshold'. Images must have the same size. */
        public static function compare(expected:BitmapData, actual:BitmapData, threshold:int):ImageDiff
        {
            var numDiffPixels:int = 0;
            var maxDelta:int = 0;
            var expectedPixels:Vector.<uint> = expected.getVector(expected.rect);
            var actualPixels:Vector.<uint> = actual.getVector(actual.rect);
            var diffPixels:Vector.<uint> = new Vector.<uint>(actualPixels.length);

            for (var i:int = 0; i < actualPixels.length; ++i)
            {
                var a:uint = expectedPixels[i];
                var b:uint = actualPixels[i];
                var delta:int = 0;

                for (var shift:int = 0; shift < 32; shift += 8)
                    delta = Math.max(delta, Math.abs(int((a >> shift) & 0xff) - int((b >> shift) & 0xff)));

                if (delta > maxDelta) maxDelta = delta;
                if (delta > threshold)
                {
                    numDiffPixels++;
                    diffPixels[i] = 0xffff0000;
                }
                else diffPixels[i] = b;
            }

            var image:BitmapData = new BitmapData(actual.width, actual.height, true, 0);
            image.setVector(actual.rect, diffPixels);
            return new ImageDiff(numDiffPixels, maxDelta, image);
        }

        /** The number of pixels with a channel delta above the threshold. */
        public function get numDiffPixels():int { return _numDiffPixels; }

        /** The biggest channel delta across all pixels. */
        public function get maxDelta():int { return _maxDelta; }

        /** The actual image, with the pixels that exceed the threshold marked in red. */
        public function get image():BitmapData { return _image; }
    }
}
