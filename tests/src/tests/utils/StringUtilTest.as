/**
 * Created by redge on 23.07.15.
 */
package tests.utils
{
    import starling.unit.UnitTest;
    import starling.utils.StringUtil;

    public class StringUtilTest extends UnitTest
    {
        public function testFormatString():void
        {
            assertEqual("This is a test.", StringUtil.format("This is {0} test.", "a"));
            assertEqual("aba{2}", StringUtil.format("{0}{1}{0}{2}", "a", "b"));
            assertEqual("1{2}21", StringUtil.format("{0}{2}{1}{0}", 1, 2));
        }

        public function testCleanMasterString():void
        {
            assertEqual("a", StringUtil.clean("a"));
        }

        public function testTrimStart():void
        {
            assertEqual("hugo ", StringUtil.trimStart("   hugo "));
            assertEqual("hugo ", StringUtil.trimStart("\n hugo "));
            assertEqual("hugo ", StringUtil.trimStart("\r hugo "));
            assertEqual("", StringUtil.trimStart("\r\n "));
        }

        public function testTrimEnd():void
        {
            assertEqual(" hugo", StringUtil.trimEnd(" hugo   "));
            assertEqual(" hugo", StringUtil.trimEnd(" hugo\n "));
            assertEqual(" hugo", StringUtil.trimEnd(" hugo\r "));
            assertEqual("", StringUtil.trimEnd("\r\n "));
        }

        public function testTrim():void
        {
            assertEqual("hugo", StringUtil.trim("   hugo   "));
            assertEqual("hugo", StringUtil.trim(" \nhugo\r "));
            assertEqual("hugo", StringUtil.trim(" \nhugo\r "));
            assertEqual("", StringUtil.trim(" \r \n "));
        }

        public function testParseBool():void
        {
            assertTrue(StringUtil.parseBoolean("TRUE"));
            assertTrue(StringUtil.parseBoolean("True"));
            assertTrue(StringUtil.parseBoolean("true"));
            assertTrue(StringUtil.parseBoolean("1"));
            assertFalse(StringUtil.parseBoolean("false"));
            assertFalse(StringUtil.parseBoolean("abc"));
            assertFalse(StringUtil.parseBoolean("0"));
            assertFalse(StringUtil.parseBoolean(""));
        }
    }
}
