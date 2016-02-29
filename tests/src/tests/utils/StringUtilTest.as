/**
 * Created by redge on 23.07.15.
 */
package tests.utils
{
    import org.flexunit.asserts.assertEquals;

    import starling.utils.StringUtil;

    public class StringUtilTest
    {
        [Test]
        public function testFormatString():void
        {
            assertEquals("This is a test.", StringUtil.format("This is {0} test.", "a"));
            assertEquals("aba{2}", StringUtil.format("{0}{1}{0}{2}", "a", "b"));
            assertEquals("1{2}21", StringUtil.format("{0}{2}{1}{0}", 1, 2));
        }

        [Test]
        public function testCleanMasterString():void
        {
            assertEquals("a", StringUtil.clean("a"));
        }

        [Test]
        public function testTrimStart():void
        {
            assertEquals("hugo ", StringUtil.trimStart("   hugo "));
            assertEquals("hugo ", StringUtil.trimStart("\n hugo "));
            assertEquals("hugo ", StringUtil.trimStart("\r hugo "));
            assertEquals("", StringUtil.trimStart("\r\n "));
        }

        [Test]
        public function testTrimEnd():void
        {
            assertEquals(" hugo", StringUtil.trimEnd(" hugo   "));
            assertEquals(" hugo", StringUtil.trimEnd(" hugo\n "));
            assertEquals(" hugo", StringUtil.trimEnd(" hugo\r "));
            assertEquals("", StringUtil.trimEnd("\r\n "));
        }

        [Test]
        public function testTrim():void
        {
            assertEquals("hugo", StringUtil.trim("   hugo   "));
            assertEquals("hugo", StringUtil.trim(" \nhugo\r "));
            assertEquals("hugo", StringUtil.trim(" \nhugo\r "));
            assertEquals("", StringUtil.trim(" \r \n "));
        }
    }
}
