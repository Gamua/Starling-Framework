// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.display
{
    import flash.geom.Matrix;
    import flash.geom.Matrix3D;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import starling.core.RenderSupport;
    import starling.events.Event;
    import starling.utils.MatrixUtil;
    import starling.utils.RectangleUtil;

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
     *  <strong>Clipping Rectangle</strong>
     * 
     *  <p>The <code>clipRect</code> property allows you to clip the visible area of the sprite
     *  to a rectangular region. Only pixels inside the rectangle will be displayed. This is a very
     *  fast way to mask objects. However, there is one limitation: the <code>clipRect</code>
     *  only works with stage-aligned rectangles, i.e. you cannot rotate or skew the rectangle.
     *  This limitation is inherited from the underlying "scissoring" technique that is used
     *  internally.</p>
     *  
     *  @see DisplayObject
     *  @see DisplayObjectContainer
     */
    public class Sprite extends DisplayObjectContainer
    {
        private var mFlattenedContents:Vector.<QuadBatch>;
        private var mFlattenRequested:Boolean;
        private var mFlattenOptimized:Boolean;
        private var mClipRect:Rectangle;
        
        /** Helper objects. */
        private static var sHelperMatrix:Matrix = new Matrix();
        private static var sHelperPoint:Point = new Point();
        private static var sHelperRect:Rectangle = new Rectangle();
        
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
         *  next rendering. 
         * 
         *  <p>When you flatten a sprite, the result of all matrix operations that are otherwise
         *  executed during rendering are cached. For this reason, a flattened sprite can be
         *  rendered with much less strain on the CPU. However, a flattened sprite will always
         *  produce at least one draw call; if it were merged together with other objects, this
         *  would cause additional matrix operations, and the optimization would have been in vain.
         *  Thus, don't just blindly flatten all your sprites, but reserve flattening for sprites
         *  with a big number of children.</p>
         *
         *  <p>Beware that while you can add a 'mask' or 'clipRect' to a flattened sprite, any
         *  such property will be ignored on its children. Furthermore, while a 'Sprite3D' may
         *  contain a flattened sprite, a flattened sprite must not contain a 'Sprite3D'.</p>
         *
         *  @param ignoreChildOrder If the child order is not important, you can further optimize
         *           the number of draw calls. Naturally, this is not an option for all use-cases.
         */
        public function flatten(ignoreChildOrder:Boolean=false):void
        {
            mFlattenRequested = true;
            mFlattenOptimized = ignoreChildOrder;
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
            return (mFlattenedContents != null) || mFlattenRequested; 
        }
        
        /** The object's clipping rectangle in its local coordinate system.
         *  Only pixels within that rectangle will be drawn. 
         *  <strong>Note:</strong> clipping rectangles are axis aligned with the screen, so they
         *  will not be rotated or skewed if the Sprite is. */
        public function get clipRect():Rectangle { return mClipRect; }
        public function set clipRect(value:Rectangle):void 
        {
            if (mClipRect && value) mClipRect.copyFrom(value);
            else mClipRect = (value ? value.clone() : null);
        }

        /** Returns the bounds of the container's clipping rectangle in the given coordinate space,
         *  or null if the sprite does not have one. */
        public function getClipRect(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
        {
            if (mClipRect == null) return null;
            if (resultRect == null) resultRect = new Rectangle();
            
            var x:Number, y:Number;
            var minX:Number =  Number.MAX_VALUE;
            var maxX:Number = -Number.MAX_VALUE;
            var minY:Number =  Number.MAX_VALUE;
            var maxY:Number = -Number.MAX_VALUE;
            var transMatrix:Matrix = getTransformationMatrix(targetSpace, sHelperMatrix);
            
            for (var i:int=0; i<4; ++i)
            {
                switch(i)
                {
                    case 0: x = mClipRect.left;  y = mClipRect.top;    break;
                    case 1: x = mClipRect.left;  y = mClipRect.bottom; break;
                    case 2: x = mClipRect.right; y = mClipRect.top;    break;
                    case 3: x = mClipRect.right; y = mClipRect.bottom; break;
                }
                var transformedPoint:Point = MatrixUtil.transformCoords(transMatrix, x, y, sHelperPoint);
                
                if (minX > transformedPoint.x) minX = transformedPoint.x;
                if (maxX < transformedPoint.x) maxX = transformedPoint.x;
                if (minY > transformedPoint.y) minY = transformedPoint.y;
                if (maxY < transformedPoint.y) maxY = transformedPoint.y;
            }
            
            resultRect.setTo(minX, minY, maxX-minX, maxY-minY);
            return resultRect;
        }
        
        /** @inheritDoc */ 
        public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
        {
            var bounds:Rectangle = super.getBounds(targetSpace, resultRect);
            
            // if we have a scissor rect, intersect it with our bounds
            if (mClipRect)
                RectangleUtil.intersect(bounds, getClipRect(targetSpace, sHelperRect), 
                                        bounds);
            
            return bounds;
        }
        
        /** @inheritDoc */
        public override function hitTest(localPoint:Point, forTouch:Boolean=false):DisplayObject
        {
            if (mClipRect != null && !mClipRect.containsPoint(localPoint))
                return null;
            else
                return super.hitTest(localPoint, forTouch);
        }
        
        /** @inheritDoc */
        public override function render(support:RenderSupport, parentAlpha:Number):void
        {
            if (mClipRect)
            {
                var clipRect:Rectangle = support.pushClipRect(getClipRect(stage, sHelperRect));
                if (clipRect.isEmpty())
                {
                    // empty clipping bounds - no need to render children.
                    support.popClipRect();
                    return;
                }
            }
            
            if (mFlattenedContents || mFlattenRequested)
            {
                if (mFlattenedContents == null)
                    mFlattenedContents = new <QuadBatch>[];
                
                if (mFlattenRequested)
                {
                    QuadBatch.compile(this, mFlattenedContents);
                    if (mFlattenOptimized) QuadBatch.optimize(mFlattenedContents);

                    support.applyClipRect(); // compiling filters might change scissor rect. :-\
                    mFlattenRequested = false;
                }
                
                var alpha:Number = parentAlpha * this.alpha;
                var numBatches:int = mFlattenedContents.length;
                var mvpMatrix:Matrix3D = support.mvpMatrix3D;
                
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
            
            if (mClipRect)
                support.popClipRect();
        }
    }
}