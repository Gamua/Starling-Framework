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
        
        /** Optimizes the sprite for optimal rendering performance. Changes in the
         *  children of a flattened sprite will not be displayed any longer. For this to happen,
         *  either call <code>flatten</code> again, or <code>unflatten</code> the sprite. */
        public function flatten():void
        {
            broadcastEventWith(Event.FLATTEN);
            
            if (mFlattenedContents == null)
                mFlattenedContents = new <QuadBatch>[];
            
            QuadBatch.compile(this, mFlattenedContents);
        }
        
        /** Removes the rendering optimizations that were created when flattening the sprite.
         *  Changes to the sprite's children will become immediately visible again. */ 
        public function unflatten():void
        {
            if (mFlattenedContents)
            {
                var numBatches:int = mFlattenedContents.length;
                
                for (var i:int=0; i<numBatches; ++i)
                    mFlattenedContents[i].dispose();
                
                mFlattenedContents = null;
            }
        }
        
        /** Indicates if the sprite was flattened. */
        public function get isFlattened():Boolean { return mFlattenedContents != null; }
        
        /** @inheritDoc */
        public override function render(support:RenderSupport, parentAlpha:Number):void
        {
            if (mFlattenedContents)
            {
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