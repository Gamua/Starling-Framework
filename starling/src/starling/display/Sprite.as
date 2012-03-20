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
    import flash.geom.Matrix3D;
    import flash.ui.Mouse;
    import flash.ui.MouseCursor;
    
    import starling.core.QuadBatch;
    import starling.core.RenderSupport;
    import starling.core.Starling;
    import starling.events.Event;
    import starling.events.TouchEvent;

    /** Dispatched on all children when the object is flattened. */
    [Event(name="flatten", type="starling.events.Event")]
    
    /** A Sprite is the most lightweight, non-abstract container class.
     *  <p>Use it as a simple means of grouping objects together in one coordinate system, or
     *  as the base class for custom display objects.</p>
     *
     *  <strong>Flattened Sprites</strong>
     * 
     *  <p>The <code>flatten</code>-method allows you to optimize the rendering of static parts of 
     *  your display list.</p>
     *
     *  <p>It analyzes the tree of children attached to the sprite and optimizes the rendering calls 
     *  in a way that makes rendering extremely fast. The speed-up comes at a price, though: you 
     *  will no longer see any changes in the properties of the children (position, rotation, 
     *  alpha, etc.). To update the object after changes have happened, simply call 
     *  <code>flatten</code> again, or <code>unflatten</code> the object.</p>
     * 
     *  @see DisplayObject
     *  @see DisplayObjectContainer
     */  
    public class Sprite extends DisplayObjectContainer
    {
        private var mFlattenedContents:Vector.<QuadBatch>;
        private var mUseHandCursor:Boolean;
        
        /** Creates an empty sprite. */
        public function Sprite()
        {
            super();
        }
        
        /** @inheritDoc */
        public override function dispose():void
        {
            unflatten();
            super.dispose();
        }
        
        /** Indicates if the mouse cursor should transform into a hand while it's over the sprite. 
         *  @default false */
        public function get useHandCursor():Boolean { return mUseHandCursor; }
        public function set useHandCursor(value:Boolean):void
        {
            if (value == mUseHandCursor) return;
            mUseHandCursor = value;
            
            if (mUseHandCursor)
                addEventListener(TouchEvent.TOUCH, onTouch);
            else
                removeEventListener(TouchEvent.TOUCH, onTouch);
        }
        
        private function onTouch(event:TouchEvent):void
        {
            Mouse.cursor = event.interactsWith(this) ? MouseCursor.BUTTON : MouseCursor.AUTO;
        }
        
        /** Optimizes the sprite for optimal rendering performance. Changes in the
         *  children of a flattened sprite will not be displayed any longer. For this to happen,
         *  either call <code>flatten</code> again, or <code>unflatten</code> the sprite. */
        public function flatten():void
        {
            dispatchEventOnChildren(new Event(Event.FLATTEN));
            
            if (mFlattenedContents == null)
            {
                mFlattenedContents = new <QuadBatch>[];
                Starling.current.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
            }
            
            QuadBatch.compile(this, mFlattenedContents);
        }
        
        /** Removes the rendering optimizations that were created when flattening the sprite.
         *  Changes to the sprite's children will become immediately visible again. */ 
        public function unflatten():void
        {
            if (mFlattenedContents)
            {
                Starling.current.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
                var numBatches:int = mFlattenedContents.length;
                
                for (var i:int=0; i<numBatches; ++i)
                    mFlattenedContents[i].dispose();
                
                mFlattenedContents = null;
            }
        }
        
        private function onContextCreated(event:Event):void
        {
            if (mFlattenedContents)
            {
                mFlattenedContents = new <QuadBatch>[];
                flatten();
            }
        }
        
        /** Indicates if the sprite was flattened. */
        public function get isFlattened():Boolean { return mFlattenedContents != null; }
        
        /** @inheritDoc */
        public override function render(support:RenderSupport, alpha:Number):void
        {
            if (mFlattenedContents)
            {
                support.finishQuadBatch();
                
                alpha *= this.alpha;
                var numBatches:int = mFlattenedContents.length;
                var mvpMatrix:Matrix3D = support.mvpMatrix;
                
                for (var i:int=0; i<numBatches; ++i)
                    mFlattenedContents[i].render(mvpMatrix, alpha);
            }
            else super.render(support, alpha);
        }
    }
}