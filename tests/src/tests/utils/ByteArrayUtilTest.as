package tests.utils
{
    import flash.utils.ByteArray;

    import org.flexunit.asserts.assertFalse;

    import org.flexunit.asserts.assertTrue;

    import starling.utils.ByteArrayUtil;

    public class ByteArrayUtilTest
    {
        public function ByteArrayUtilTest()
        { }

        [Test]
        public function testStartsWith():void
        {
            var byteArray:ByteArray = new ByteArray();
            byteArray.writeUTFBytes("  \n<Hello World/>");

            assertTrue(ByteArrayUtil.startsWithString(byteArray, "<Hello"));
            assertFalse(ByteArrayUtil.startsWithString(byteArray, "<Holla"));
        }

        [Test]
        public function testCompare():void
        {
            var a:ByteArray = new ByteArray();
            var b:ByteArray = new ByteArray();
            var c:ByteArray = new ByteArray();

            a.writeUTFBytes("Hello World");
            b.writeUTFBytes("Hello Starling");
            c.writeUTFBytes("Good-bye World");

            assertFalse(ByteArrayUtil.compareByteArrays(a, 0, b, 0));
            assertTrue(ByteArrayUtil.compareByteArrays(a, 0, b, 0, 6));
            assertTrue(ByteArrayUtil.compareByteArrays(a, 0, a, 0));
            assertTrue(ByteArrayUtil.compareByteArrays(a, 5, c, 8));
        }
    }
}
