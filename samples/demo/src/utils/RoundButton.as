package utils
{
    import flash.geom.Point;
    import flash.geom.Rectangle;

    import starling.display.Button;
    import starling.display.DisplayObject;
    import starling.textures.Texture;

    public class RoundButton extends Button
    {
        public function RoundButton(upState:Texture, text:String="", downState:Texture=null)
        {
            super(upState, text, downState);
        }
        
        public override function hitTest(localPoint:Point):DisplayObject
        {
            // When the user touches the screen, this method is used to find out if an object was 
            // hit. By default, this method uses the bounding box, but by overriding it, 
            // we can change the box (rectangle) to a circle (or whatever necessary).
            
            // these are the cases in which a hit test must always fail
            if (!visible || !touchable || !hitTestMask(localPoint)) return null;
            
            // get center of button
            var bounds:Rectangle = this.bounds;
            var centerX:Number = bounds.width / 2;
            var centerY:Number = bounds.height / 2;
            
            // calculate distance of localPoint to center. 
            // we keep it squared, since we want to avoid the 'sqrt()'-call.
            var sqDist:Number = Math.pow(localPoint.x - centerX, 2) + 
                                Math.pow(localPoint.y - centerY, 2);
            
            // when the squared distance is smaller than the squared radius, 
            // the point is inside the circle
            var radius:Number = bounds.width / 2 - 8;
            if (sqDist < Math.pow(radius, 2)) return this;
            else return null;
        }
    }
}