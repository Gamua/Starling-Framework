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
    import flash.geom.Matrix;
    
    import starling.core.RenderSupport;
    import starling.events.Event;

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
        private var mFlattenRequested:Boolean;
        
        /** Creates an empty sprite. */
        public function Sprite()
        {
            super();
        }
        
        /** @inheritDoc */
        public override function dispose():void
        {
            disposeFlattenedContents();
            super.dispose();
        }
        
        private function disposeFlattenedContents():void
        {
            if (mFlattenedContents)
            {
                for (var i:int=0, max:int=mFlattenedContents.length; i<max; ++i)
                    mFlattenedContents[i].dispose();
                
                mFlattenedContents = null;
            }
        }
        
        /** Optimizes the sprite for optimal rendering performance. Changes in the
         *  children of a flattened sprite will not be displayed any longer. For this to happen,
         *  either call <code>flatten</code> again, or <code>unflatten</code> the sprite. 
         *  Beware that the actual flattening will not happen right away, but right before the
         *  next rendering. */
        public function flatten():void
        {
            mFlattenRequested = true;
            broadcastEventWith(Event.FLATTEN);
        }
        
        /** Removes the rendering optimizations that were created when flattening the sprite.
         *  Changes to the sprite's children will immediately become visible again. */ 
        public function unflatten():void
        {
            mFlattenRequested = false;
            disposeFlattenedContents();
        }
        
        /** Indicates if the sprite was flattened. */
        public function get isFlattened():Boolean 
        { 
            return mFlattenedContents || mFlattenRequested; 
        }
        
        /** @inheritDoc */
        public override function render(support:RenderSupport, parentAlpha:Number):void
        {
            if (mFlattenedContents || mFlattenRequested)
            {
                if (mFlattenedContents == null)
                    mFlattenedContents = new <QuadBatch>[];
                
                if (mFlattenRequested)
                {
                    QuadBatch.compile(this, mFlattenedContents);
                    mFlattenRequested = false;
                }
                
                var alpha:Number = parentAlpha * this.alpha;
                var numBatches:int = mFlattenedContents.length;
                var mvpMatrix:Matrix = support.mvpMatrix;
                
                support.finishQuadBatch();
                support.raiseDrawCount(numBatches);
                
                for (var i:int=0; i<numBatches; ++i)
                {
                    var quadBatch:QuadBatch = mFlattenedContents[i];
                    var blendMode:String = quadBatch.blendMode == BlendMode.AUTO ?
                        support.blendMode : quadBatch.blendMode;
                    quadBatch.renderCustom(mvpMatrix, alpha, blendMode);
                }
            }
            else super.render(support, parentAlpha);
        }
    }
}