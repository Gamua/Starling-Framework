package utils
{
    import flash.geom.Point;
    
    import starling.display.DisplayObject;
    import starling.display.Sprite;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    import starling.events.TouchPhase;
    
    public class TouchSheet extends Sprite
    {
        public function TouchSheet(contents:DisplayObject=null)
        {
            addEventListener(TouchEvent.TOUCH, onTouch);
            
            if (contents)
            {
                contents.x = contents.width / -2;
                contents.y = contents.height / -2;
                addChild(contents);
            }
        }
        
        private function onTouch(event:TouchEvent):void
        {
            var touches:Vector.<Touch> = event.getTouches(this, TouchPhase.MOVED);
            
            if (touches.length == 1)
            {
                var touch:Touch = touches[0];
                var currentPos:Point = touch.getLocationInSpace(parent);
                var previousPos:Point = touch.getPreviousLocationInSpace(parent);
                var delta:Point = currentPos.subtract(previousPos);
                
                x += delta.x;
                y += delta.y;
            }            
            else if (touches.length == 2)
            {
                var touchA:Touch = touches[0];
                var touchB:Touch = touches[1];
                
                var currentPosA:Point  = touchA.getLocationInSpace(parent);
                var previousPosA:Point = touchA.getPreviousLocationInSpace(parent);
                var currentPosB:Point  = touchB.getLocationInSpace(parent);
                var previousPosB:Point = touchB.getPreviousLocationInSpace(parent);
                
                var currentVector:Point  = currentPosA.subtract(currentPosB);
                var previousVector:Point = previousPosA.subtract(previousPosB);
                
                var currentAngle:Number  = Math.atan2(currentVector.y, currentVector.x);
                var previousAngle:Number = Math.atan2(previousVector.y, previousVector.x);
                var deltaAngle:Number = currentAngle - previousAngle;
                
                // rotate
                rotation += deltaAngle;

                // scale
                var sizeDiff:Number = currentVector.length / previousVector.length;
                scaleX *= sizeDiff;
                scaleY *= sizeDiff;
            }
            
            touch = event.getTouch(this, TouchPhase.ENDED);
            
            if (touch && touch.tapCount == 2)
                parent.addChild(this); // bring self to front
            
            // enable this code to see when you're hovering over the object
            // touch = event.getTouch(this, TouchPhase.HOVER);            
            // alpha = touch ? 0.8 : 1.0;
        }
        
        public override function dispose():void
        {
            removeEventListener(TouchEvent.TOUCH, onTouch);
            super.dispose();
        }
    }
}