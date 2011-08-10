package starling.text
{
    import flash.utils.Dictionary;
    
    import starling.display.Image;
    import starling.textures.Texture;

    public class BitmapChar
    {
        private var mTexture:Texture;
        private var mCharID:int;
        private var mXOffset:Number;
        private var mYOffset:Number;
        private var mXAdvance:Number;
        private var mKernings:Dictionary;
        
        public function BitmapChar(id:int, texture:Texture, 
                                   xOffset:Number, yOffset:Number, xAdvance:Number)
        {
            mCharID = id;
            mTexture = texture;
            mXOffset = xOffset;
            mYOffset = yOffset;
            mXAdvance = xAdvance;
            mKernings = null;
        }
        
        public function addKerning(charID:int, amount:Number):void
        {
            if (mKernings == null)
                mKernings = new Dictionary();
            
            mKernings[charID] = amount;
        }
        
        public function getKerning(charID:int):Number
        {
            if (mKernings[charID] == undefined) return 0.0;
            else return mKernings[charID];
        }
        
        public function createImage():Image
        {
            return new Image(mTexture);
        }
        
        public function get charID():int { return mCharID; }
        public function get xOffset():Number { return mXOffset; }
        public function get yOffset():Number { return mYOffset; }
        public function get xAdvance():Number { return mXAdvance; }
        public function get texture():Texture { return mTexture; }
    }
}