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
    }
}
