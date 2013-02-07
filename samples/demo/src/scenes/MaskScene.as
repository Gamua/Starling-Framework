package scenes
{
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import starling.core.Starling;
    import starling.display.Image;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    import starling.events.TouchPhase;
    import starling.filters.ColorMatrixFilter;
    import starling.text.TextField;

    public class MaskScene extends Scene
    {
        private var mContents:Sprite;
        private var mClipQuad:Quad;
        
        public function MaskScene()
        {
            mContents = new Sprite();
            addChild(mContents);
            
            var stageWidth:Number  = Starling.current.stage.stageWidth;
            var stageHeight:Number = Starling.current.stage.stageHeight;
            
            var touchQuad:Quad = new Quad(stageWidth, stageHeight);
            touchQuad.alpha = 0; // only used to get touch events
            addChildAt(touchQuad, 0);
            
            var image:Image = new Image(Game.assets.getTexture("flight_00"));
            image.x = (stageWidth - image.width) / 2;
            image.y = 80;
            mContents.addChild(image);
            
            // just to prove it works, use a filter on the image.
            var cm:ColorMatrixFilter = new ColorMatrixFilter();
            cm.adjustHue(-0.5);
            image.filter = cm;
            
            var scissorText:TextField = new TextField(256, 128, 
                "Move the mouse (or a finger) over the screen to move the clipping rectangle.");
            scissorText.x = (stageWidth - scissorText.width) / 2;
            scissorText.y = 240;
            mContents.addChild(scissorText);
            
            var maskText:TextField = new TextField(256, 128, 
                "Currently, Starling supports only stage-aligned clipping; more complex masks " +
                "will be supported in future versions.");
            maskText.x = scissorText.x;
            maskText.y = 290;
            mContents.addChild(maskText);
            
            var scissorRect:Rectangle = new Rectangle(0, 0, 150, 150); 
            scissorRect.x = (stageWidth  - scissorRect.width)  / 2;
            scissorRect.y = (stageHeight - scissorRect.height) / 2 + 5;
            mContents.clipRect = scissorRect;
            
            mClipQuad = new Quad(scissorRect.width, scissorRect.height, 0xff0000);
            mClipQuad.x = scissorRect.x;
            mClipQuad.y = scissorRect.y;
            mClipQuad.alpha = 0.1;
            mClipQuad.touchable = false;
            addChild(mClipQuad);
            
            addEventListener(TouchEvent.TOUCH, onTouch);
        }
        
        private function onTouch(event:TouchEvent):void
        {
            var touch:Touch = event.getTouch(this, TouchPhase.HOVER) ||
                              event.getTouch(this, TouchPhase.BEGAN) ||
                              event.getTouch(this, TouchPhase.MOVED);

            if (touch)
            {
                var localPos:Point = touch.getLocation(this);
                var clipRect:Rectangle = mContents.clipRect;
                clipRect.x = localPos.x - clipRect.width  / 2;
                clipRect.y = localPos.y - clipRect.height / 2;
                
                mClipQuad.x = clipRect.x;
                mClipQuad.y = clipRect.y;
            }
        }
    }
}