package tests
{
    import flexunit.framework.Assert;
    
    import starling.utils.Color;

    public class ColorTest
    {		
        [Test]
        public function testGetElement():void
        {
            var color:uint = 0xaabbcc;
            Assert.assertEquals(0xaa, Color.getRed(color));
            Assert.assertEquals(0xbb, Color.getGreen(color));
            Assert.assertEquals(0xcc, Color.getBlue(color));
        }
        
        [Test]
        public function testCreate():void
        {
            var color:uint = Color.create(0xaa, 0xbb, 0xcc);
            Assert.assertEquals(0xaabbcc, color);
        }
    }
}