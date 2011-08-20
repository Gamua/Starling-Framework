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
        private var mFlattenedContents:Vector.<QuadGroup>;
        
        public function Sprite()
        {
            super();
        }
        
        public override function dispose():void
        {
            unflatten();
            super.dispose();
        }
        
        public function flatten():void
        {
            unflatten();
            dispatchEventOnChildren(new Event(Event.FLATTEN));
            mFlattenedContents = QuadGroup.compile(this);
        }
        
        public function unflatten():void
        {
            for each (var quadGroup:QuadGroup in mFlattenedContents)
                quadGroup.dispose();
            mFlattenedContents = null;
        }
        
        public function get isFlattened():Boolean { return mFlattenedContents != null; }
        
        public override function render(support:RenderSupport, alpha:Number):void
        {
            if (mFlattenedContents)
            {
                for each (var quadGroup:QuadGroup in mFlattenedContents)
                    quadGroup.render(support, this.alpha * alpha);
            }
            else super.render(support, alpha);
        }
    }
}