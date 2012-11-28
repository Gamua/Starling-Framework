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
            useHandCursor = true;
            
            if (contents)
            {
                contents.x = int(contents.width / -2);
                contents.y = int(contents.height / -2);
                addChild(contents);
            }
        }
        
        private function onTouch(event:TouchEvent):void
        {
            var touches:Vector.<Touch> = event.getTouches(this, TouchPhase.MOVED);
            
            if (touches.length == 1)
            {
                // one finger touching -> move
                var delta:Point = touches[0].getMovement(parent);
                x += delta.x;
                y += delta.y;
            }            
            else if (touches.length == 2)
            {
                // two fingers touching -> rotate and scale
                var touchA:Touch = touches[0];
                var touchB:Touch = touches[1];
                
                var currentPosA:Point  = touchA.getLocation(parent);
                var previousPosA:Point = touchA.getPreviousLocation(parent);
                var currentPosB:Point  = touchB.getLocation(parent);
                var previousPosB:Point = touchB.getPreviousLocation(parent);
                
                var currentVector:Point  = currentPosA.subtract(currentPosB);
                var previousVector:Point = previousPosA.subtract(previousPosB);
                
                var currentAngle:Number  = Math.atan2(currentVector.y, currentVector.x);
                var previousAngle:Number = Math.atan2(previousVector.y, previousVector.x);
                var deltaAngle:Number = currentAngle - previousAngle;
                
				// update pivot point based on previous center
				var previousLocalA:Point  = touchA.getPreviousLocation(this);
				var previousLocalB:Point  = touchB.getPreviousLocation(this);
				pivotX = (previousLocalA.x + previousLocalB.x) * 0.5;
				pivotY = (previousLocalA.y + previousLocalB.y) * 0.5;
				
				// update location based on the current center
				x = (currentPosA.x + currentPosB.x) * 0.5;
				y = (currentPosA.y + currentPosB.y) * 0.5;
				
				// rotate
                rotation += deltaAngle;

                // scale
                var sizeDiff:Number = currentVector.length / previousVector.length;
                scaleX *= sizeDiff;
                scaleY *= sizeDiff;
            }
            
            var touch:Touch = event.getTouch(this, TouchPhase.ENDED);
            
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