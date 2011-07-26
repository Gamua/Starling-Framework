package tests
{
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import org.flexunit.assertThat;
    import org.hamcrest.number.closeTo;

    internal class Helpers
    {
        public static function compareRectangles(rect1:Rectangle, rect2:Rectangle, 
                                                 e:Number=0.0001):void
        {
            assertThat(rect1.x, closeTo(rect2.x, e));
            assertThat(rect1.y, closeTo(rect2.y, e));
            assertThat(rect1.width, closeTo(rect2.width, e));
            assertThat(rect1.height, closeTo(rect2.height, e));
        }
        
        public static function comparePoints(point1:Point, point2:Point, e:Number=0.0001):void
        {
            assertThat(point1.x, closeTo(point2.x, e));
            assertThat(point1.y, closeTo(point2.y, e));
        }
    }
}