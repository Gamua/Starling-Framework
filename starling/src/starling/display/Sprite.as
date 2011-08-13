// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.display
{
    import starling.core.RenderSupport;
    import starling.events.Event;

    public class Sprite extends DisplayObjectContainer
    {
        private var mFrozenContents:Vector.<QuadGroup>;
        
        public function Sprite()
        {
            super();
        }
        
        public override function dispose():void
        {
            unfreeze();
            super.dispose();
        }
        
        public function freeze():void
        {
            unfreeze();
            dispatchEventOnChildren(new Event(Event.FREEZE));
            mFrozenContents = QuadGroup.compile(this);
        }
        
        public function unfreeze():void
        {
            for each (var quadGroup:QuadGroup in mFrozenContents)
                quadGroup.dispose();
            mFrozenContents = null;
        }
        
        public function get isFrozen():Boolean { return mFrozenContents != null; }
        
        public override function render(support:RenderSupport, alpha:Number):void
        {
            if (mFrozenContents)
            {
                for each (var quadGroup:QuadGroup in mFrozenContents)
                    quadGroup.render(support, this.alpha * alpha);
            }
            else super.render(support, alpha);
        }
    }
}