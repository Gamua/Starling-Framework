package scenes
{
    import flash.geom.Point;
    
    import starling.display.Image;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    import starling.events.TouchPhase;
    import starling.textures.RenderTexture;

    public class RenderTextureScene extends Scene
    {
        private var mRenderTexture:RenderTexture;
        private var mBrush:Image;
        
        public function RenderTextureScene()
        {
            mBrush = new Image(Assets.getTexture("EggOpened"));
            mBrush.pivotX = mBrush.width / 2;
            mBrush.pivotY = mBrush.height / 2;
            mBrush.scaleX = mBrush.scaleY = 0.5;
            
            mRenderTexture = new RenderTexture(320, 435); 
            
            var canvas:Image = new Image(mRenderTexture);
            canvas.addEventListener(TouchEvent.TOUCH, onTouch);
            addChild(canvas);
        }
        
        private function onTouch(event:TouchEvent):void
        {
            var touches:Vector.<Touch> = event.getTouches(this);
            
            for each (var touch:Touch in touches)
            {
                if (touch.phase == TouchPhase.HOVER || touch.phase == TouchPhase.ENDED)
                    continue;
                
                var location:Point = touch.getLocation(this);
                mBrush.x = location.x;
                mBrush.y = location.y;
                
                mRenderTexture.draw(mBrush);
            }
        }
        
        public override function dispose():void
        {
            mRenderTexture.dispose();
            super.dispose();
        }
    }
}