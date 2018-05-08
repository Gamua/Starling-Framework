package starling.utils
{
    import flash.utils.ByteArray;

    import starling.errors.AbstractClassError;

    public class ByteArrayUtil
    {
        /** @private */
        public function ByteArrayUtil() { throw new AbstractClassError(); }

        /** Figures out if a byte array starts with the UTF bytes of a certain string. If the
         *  array starts with a 'BOM', it is ignored; so are leading zeros and whitespace. */
        public static function startsWithString(bytes:ByteArray, string:String):Boolean
        {
            var start:int = 0;
            var length:int = bytes.length;

            var wantedBytes:ByteArray = new ByteArray();
            wantedBytes.writeUTFBytes(string);

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

            for (var i:int=start; i<length; ++i)
            {
                var byte:int = bytes[i];
                if (byte != 0 && byte != 10 && byte != 13 && byte != 32) // null, \n, \r, space
                    return compareByteArrays(bytes, i, wantedBytes, 0, wantedBytes.length)
            }

            return false;
        }

        /** Compares the range of bytes within two byte arrays. */
        public static function compareByteArrays(a:ByteArray, indexA:int,
                                                 b:ByteArray, indexB:int,
                                                 numBytes:int=-1):Boolean
        {
            if (numBytes < 0) numBytes = MathUtil.min(a.length - indexA, b.length - indexB);
            else if (indexA + numBytes > a.length || indexB + numBytes > b.length)
                throw new RangeError();

            for (var i:int=0; i<numBytes; ++i)
                if (a[indexA + i] != b[indexB + i]) return false;

            return true;
        }
    }
}
