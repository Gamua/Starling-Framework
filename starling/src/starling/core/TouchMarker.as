// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.core
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Shape;
    import flash.geom.Point;
    
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.textures.Texture;
    
    /** The TouchMarker is used internally to mark touches created through "simulateMultitouch". */
    internal class TouchMarker extends Sprite
    {
        private var mCenter:Point;
        private var mTexture:Texture;
        
        public function TouchMarker()
        {
            mCenter = new Point();
            mTexture = createTexture();
            
            for (var i:int=0; i<2; ++i)
            {
                var marker:Image = new Image(mTexture);
                marker.pivotX = mTexture.width / 2;
                marker.pivotY = mTexture.height / 2;
                marker.touchable = false;
                addChild(marker);
            }
        }
        
        public override function dispose():void
        {
            mTexture.dispose();
            super.dispose();
        }
        
        public function moveMarker(x:Number, y:Number, withCenter:Boolean=false):void
        {
            if (withCenter)
            {
                mCenter.x += x - realMarker.x;
                mCenter.y += y - realMarker.y;
            }
            
            realMarker.x = x;
            realMarker.y = y;
            mockMarker.x = 2*mCenter.x - x;
            mockMarker.y = 2*mCenter.y - y;
        }
        
        public function moveCenter(x:Number, y:Number):void
        {
            mCenter.x = x;
            mCenter.y = y;
            moveMarker(realX, realY); // reset mock position
        }
        
        private function createTexture():Texture
        {
            var scale:Number = Starling.contentScaleFactor;
            var radius:Number = 12 * scale;
            var width:int = 32 * scale;
            var height:int = 32 * scale;
            var thickness:Number = 1.5 * scale;
            var shape:Shape = new Shape();
            
            // draw dark outline
            shape.graphics.lineStyle(thickness, 0x0, 0.3);
            shape.graphics.drawCircle(width/2, height/2, radius + thickness);
            
            // draw white inner circle
            shape.graphics.beginFill(0xffffff, 0.4);
            shape.graphics.lineStyle(thickness, 0xffffff);
            shape.graphics.drawCircle(width/2, height/2, radius);
            shape.graphics.endFill();
            
            var bmpData:BitmapData = new BitmapData(width, height, true, 0x0);
            bmpData.draw(shape);
            
            return Texture.fromBitmapData(bmpData, false, false, scale);
        }
        
        private function get realMarker():Image { return getChildAt(0) as Image; }
        private function get mockMarker():Image { return getChildAt(1) as Image; }
        
        public function get realX():Number { return realMarker.x; }
        public function get realY():Number { return realMarker.y; }
        
        public function get mockX():Number { return mockMarker.x; }
        public function get mockY():Number { return mockMarker.y; }
    }        
}