package starling.textures
{
    import flash.display3D.textures.TextureBase;

    public class ConcreteTexture extends Texture
    {
        private var mWidth:int;
        private var mHeight:int;
        private var mBase:TextureBase;
        
        public function ConcreteTexture(base:TextureBase, width:int, height:int)
        {
            mBase = base;
            mWidth = width;
            mHeight = height;
        }
        
        public override function dispose():void
        {
            mBase.dispose();
        }
        
        public override function get width():Number  { return mWidth;  }
        public override function get height():Number { return mHeight; }
        public override function get nativeTexture():TextureBase { return mBase; }
    }
}