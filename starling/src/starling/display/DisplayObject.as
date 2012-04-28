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
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.getQualifiedClassName;
    
    import starling.core.RenderSupport;
    import starling.errors.AbstractClassError;
    import starling.errors.AbstractMethodError;
    import starling.events.Event;
    import starling.events.EventDispatcher;
    import starling.events.TouchEvent;
    
    /** Dispatched when an object is added to a parent. */
    [Event(name="added", type="starling.events.Event")]
    /** Dispatched when an object is connected to the stage (directly or indirectly). */
    [Event(name="addedToStage", type="starling.events.Event")]
    /** Dispatched when an object is removed from its parent. */
    [Event(name="removed", type="starling.events.Event")]
    /** Dispatched when an object is removed from the stage and won't be rendered any longer. */ 
    [Event(name="removedFromStage", type="starling.events.Event")]
    /** Dispatched once every frame on every object that is connected to the stage. */ 
    [Event(name="enterFrame", type="starling.events.EnterFrameEvent")]
    /** Dispatched when an object is touched. Bubbles. */
    [Event(name="touch", type="starling.events.TouchEvent")]
    
    /**
     *  The DisplayObject class is the base class for all objects that are rendered on the 
     *  screen.
     *  
     *  <p><strong>The Display Tree</strong></p> 
     *  
     *  <p>In Starling, all displayable objects are organized in a display tree. Only objects that
     *  are part of the display tree will be displayed (rendered).</p> 
     *   
     *  <p>The display tree consists of leaf nodes (Image, Quad) that will be rendered directly to
     *  the screen, and of container nodes (subclasses of "DisplayObjectContainer", like "Sprite").
     *  A container is simply a display object that has child nodes - which can, again, be either
     *  leaf nodes or other containers.</p> 
     *  
     *  <p>At the root of the display tree, there is the Stage, which is a container, too. To create
     *  a Starling application, you create a custom Sprite subclass, and Starling will add an
     *  instance of this class to the stage.</p>
     *  
     *  <p>A display object has properties that define its position in relation to its parent
     *  (x, y), as well as its rotation and scaling factors (scaleX, scaleY). Use the 
     *  <code>alpha</code> and <code>visible</code> properties to make an object translucent or 
     *  invisible.</p>
     *  
     *  <p>Every display object may be the target of touch events. If you don't want an object to be
     *  touchable, you can disable the "touchable" property. When it's disabled, neither the object
     *  nor its children will receive any more touch events.</p>
     *    
     *  <strong>Transforming coordinates</strong>
     *  
     *  <p>Within the display tree, each object has its own local coordinate system. If you rotate
     *  a container, you rotate that coordinate system - and thus all the children of the 
     *  container.</p>
     *  
     *  <p>Sometimes you need to know where a certain point lies relative to another coordinate 
     *  system. That's the purpose of the method <code>getTransformationMatrix</code>. It will  
     *  create a matrix that represents the transformation of a point in one coordinate system to 
     *  another.</p> 
     *  
     *  <strong>Subclassing</strong>
     *  
     *  <p>Since DisplayObject is an abstract class, you cannot instantiate it directly, but have 
     *  to use one of its subclasses instead. There are already a lot of them available, and most 
     *  of the time they will suffice.</p> 
     *  
     *  <p>However, you can create custom subclasses as well. That way, you can create an object
     *  with a custom render function. You will need to implement the following methods when you 
     *  subclass DisplayObject:</p>
     *  
     *  <ul>
     *    <li><code>function render(support:RenderSupport, parentAlpha:Number):void</code></li>
     *    <li><code>function getBounds(targetSpace:DisplayObject, 
     *                                 resultRect:Rectangle=null):Rectangle</code></li>
     *  </ul>
     *  
     *  <p>Have a look at the Quad class for a sample implementation of the 'getBounds' method.
     *  For a sample on how to write a custom render function, you can have a look at the
     *  <a href="https://github.com/PrimaryFeather/Starling-Extension-Particle-System">particle
     *  system extension</a>.</p> 
     * 
     *  <p>When you override the render method, it is important that you call the method
     *  'finishQuadBatch' of the support object. This forces Starling to render all quads that 
     *  were accumulated before by different render methods (for performance reasons). Otherwise, 
     *  the z-ordering will be incorrect.</p> 
     * 
     *  @see DisplayObjectContainer
     *  @see Sprite
     *  @see Stage 
     */
    public class DisplayObject extends EventDispatcher
    {
        // members
        
        private var mX:Number;
        private var mY:Number;
        private var mPivotX:Number;
        private var mPivotY:Number;
        private var mScaleX:Number;
        private var mScaleY:Number;
        private var mRotation:Number;
        private var mAlpha:Number;
        private var mVisible:Boolean;
        private var mTouchable:Boolean;
        private var mBlendMode:String;
        private var mName:String;
        private var mLastTouchTimestamp:Number;
        private var mParent:DisplayObjectContainer;        
        
        /** Helper objects. */
        private static var sAncestors:Vector.<DisplayObject> = new <DisplayObject>[];
        private static var sHelperRect:Rectangle = new Rectangle();
        private static var sHelperMatrix:Matrix  = new Matrix();
        private static var sTargetMatrix:Matrix  = new Matrix();
        
        /** @private */ 
        public function DisplayObject()
        {
            if (getQualifiedClassName(this) == "starling.display::DisplayObject")
                throw new AbstractClassError();
            
            mX = mY = mPivotX = mPivotY = mRotation = 0.0;
            mScaleX = mScaleY = mAlpha = 1.0;            
            mVisible = mTouchable = true;
            mLastTouchTimestamp = -1;
            mBlendMode = BlendMode.AUTO;
        }
        
        /** Disposes all resources of the display object. 
          * GPU buffers are released, event listeners are removed. */
        public function dispose():void
        {
            removeEventListeners();
        }
        
        /** Removes the object from its parent, if it has one. */
        public function removeFromParent(dispose:Boolean=false):void
        {
            if (mParent) mParent.removeChild(this);
            if (dispose) this.dispose();
        }
        
        /** Creates a matrix that represents the transformation from the local coordinate system 
         *  to another. If you pass a 'resultMatrix', the result will be stored in this matrix
         *  instead of creating a new object. */ 
        public function getTransformationMatrix(targetSpace:DisplayObject, 
                                                resultMatrix:Matrix=null):Matrix
        {
            if (resultMatrix) resultMatrix.identity();
            else resultMatrix = new Matrix();
            
            if (targetSpace == this)
            {
                return resultMatrix;
            }
            else if (targetSpace == mParent || (targetSpace == null && mParent == null))
            {
                if (mPivotX != 0.0 || mPivotY != 0.0) resultMatrix.translate(-mPivotX, -mPivotY);
                if (mScaleX != 1.0 || mScaleY != 1.0) resultMatrix.scale(mScaleX, mScaleY);
                if (mRotation != 0.0)                 resultMatrix.rotate(mRotation);
                if (mX != 0.0 || mY != 0.0)           resultMatrix.translate(mX, mY);
                
                return resultMatrix;
            }
            else if (targetSpace == null)
            {
                // targetCoordinateSpace 'null' represents the target space of the root object.
                // -> move up from this to root
                
                currentObject = this;
                while (currentObject)
                {
                    currentObject.getTransformationMatrix(currentObject.mParent, sHelperMatrix);
                    resultMatrix.concat(sHelperMatrix);
                    currentObject = currentObject.mParent;
                }
                
                return resultMatrix;
            }
            else if (targetSpace.mParent == this) // optimization
            {
                targetSpace.getTransformationMatrix(this, resultMatrix);
                resultMatrix.invert();
                
                return resultMatrix;
            }
            
            // 1. find a common parent of this and the target space
            
            sAncestors.length = 0;
            
            var commonParent:DisplayObject = null;
            var currentObject:DisplayObject = this;            
            while (currentObject)
            {
                sAncestors.push(currentObject);
                currentObject = currentObject.mParent;
            }
            
            currentObject = targetSpace;
            while (currentObject && sAncestors.indexOf(currentObject) == -1)
                currentObject = currentObject.mParent;
            
            if (currentObject == null)
                throw new ArgumentError("Object not connected to target");
            else
                commonParent = currentObject;
            
            // 2. move up from this to common parent
            
            currentObject = this;
            
            while (currentObject != commonParent)
            {
                currentObject.getTransformationMatrix(currentObject.mParent, sHelperMatrix);
                resultMatrix.concat(sHelperMatrix);
                currentObject = currentObject.mParent;
            }
            
            // 3. now move up from target until we reach the common parent
            
            sTargetMatrix.identity();
            currentObject = targetSpace;
            while (currentObject != commonParent)
            {
                currentObject.getTransformationMatrix(currentObject.mParent, sHelperMatrix);
                sTargetMatrix.concat(sHelperMatrix);
                currentObject = currentObject.mParent;
            }
            
            // 4. now combine the two matrices
            
            sTargetMatrix.invert();
            resultMatrix.concat(sTargetMatrix);
            
            return resultMatrix;
        }        
        
        /** Returns a rectangle that completely encloses the object as it appears in another 
         *  coordinate system. If you pass a 'resultRectangle', the result will be stored in this 
         *  rectangle instead of creating a new object. */ 
        public function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
        {
            throw new AbstractMethodError("Method needs to be implemented in subclass");
            return null;
        }
        
        /** Returns the object that is found topmost beneath a point in local coordinates, or nil if 
         *  the test fails. If "forTouch" is true, untouchable and invisible objects will cause
         *  the test to fail. */
        public function hitTest(localPoint:Point, forTouch:Boolean=false):DisplayObject
        {
            // on a touch test, invisible or untouchable objects cause the test to fail
            if (forTouch && (!mVisible || !mTouchable)) return null;
            
            // otherwise, check bounding box
            if (getBounds(this, sHelperRect).containsPoint(localPoint)) return this;
            else return null;
        }
        
        /** Transforms a point from the local coordinate system to global (stage) coordinates. */
        public function localToGlobal(localPoint:Point):Point
        {
            // move up  until parent is null
            sTargetMatrix.identity();
            var currentObject:DisplayObject = this;
            while (currentObject)
            {
                currentObject.getTransformationMatrix(currentObject.mParent, sHelperMatrix);
                sTargetMatrix.concat(sHelperMatrix);
                currentObject = currentObject.mParent;
            }            
            return sTargetMatrix.transformPoint(localPoint);
        }
        
        /** Transforms a point from global (stage) coordinates to the local coordinate system. */
        public function globalToLocal(globalPoint:Point):Point
        {
            // move up until parent is null, then invert matrix
            sTargetMatrix.identity();
            var currentObject:DisplayObject = this;
            while (currentObject)
            {
                currentObject.getTransformationMatrix(currentObject.mParent, sHelperMatrix);
                sTargetMatrix.concat(sHelperMatrix);
                currentObject = currentObject.mParent;
            }
            sTargetMatrix.invert();
            return sTargetMatrix.transformPoint(globalPoint);
        }
        
        /** Renders the display object with the help of a support object. Never call this method
         *  directly, except from within another render method.
         *  @param support Provides utility functions for rendering.
         *  @param parentAlpha The accumulated alpha value from the object's parent up to the stage. */
        public function render(support:RenderSupport, parentAlpha:Number):void
        {
            throw new AbstractMethodError("Method needs to be implemented in subclass");
        }
        
        /** @inheritDoc */
        public override function dispatchEvent(event:Event):void
        {
            // on one given moment, there is only one set of touches -- thus, 
            // we process only one touch event with a certain timestamp per frame
            if (event is TouchEvent)
            {
                var touchEvent:TouchEvent = event as TouchEvent;
                if (touchEvent.timestamp == mLastTouchTimestamp) return;
                else mLastTouchTimestamp = touchEvent.timestamp;
            }
            
            super.dispatchEvent(event);
        }
        
        // internal methods
        
        /** @private */
        internal function setParent(value:DisplayObjectContainer):void 
        {
            // check for a recursion
            var ancestor:DisplayObject = value;
            while (ancestor != this && ancestor != null)
                ancestor = ancestor.mParent;
            
            if (ancestor == this)
                throw new ArgumentError("An object cannot be added as a child to itself or one " +
                                        "of its children (or children's children, etc.)");
            else
                mParent = value; 
        }
        
        /** @private */
        internal function dispatchEventOnChildren(event:Event):void 
        { 
            dispatchEvent(event); 
        }
        
        // properties
        
        /** The transformation matrix of the object relative to its parent. */
        public function get transformationMatrix():Matrix
        {
            return getTransformationMatrix(mParent); 
        }
        
        /** The bounds of the object relative to the local coordinates of the parent. */
        public function get bounds():Rectangle
        {
            return getBounds(mParent);
        }
        
        /** The width of the object in pixels. */
        public function get width():Number { return getBounds(mParent, sHelperRect).width; }
        public function set width(value:Number):void
        {
            // this method calls 'this.scaleX' instead of changing mScaleX directly.
            // that way, subclasses reacting on size changes need to override only the scaleX method.
            
            mScaleX = 1.0;
            var actualWidth:Number = width;
            if (actualWidth != 0.0) scaleX = value / actualWidth;
            else                    scaleX = 1.0;
        }
        
        /** The height of the object in pixels. */
        public function get height():Number { return getBounds(mParent, sHelperRect).height; }
        public function set height(value:Number):void
        {
            mScaleY = 1.0;
            var actualHeight:Number = height;
            if (actualHeight != 0.0) scaleY = value / actualHeight;
            else                     scaleY = 1.0;
        }
        
        /** The topmost object in the display tree the object is part of. */
        public function get root():DisplayObject
        {
            var currentObject:DisplayObject = this;
            while (currentObject.mParent) currentObject = currentObject.mParent;
            return currentObject;
        }
        
        /** The x coordinate of the object relative to the local coordinates of the parent. */
        public function get x():Number { return mX; }
        public function set x(value:Number):void { mX = value; }
        
        /** The y coordinate of the object relative to the local coordinates of the parent. */
        public function get y():Number { return mY; }
        public function set y(value:Number):void { mY = value; }
        
        /** The x coordinate of the object's origin in its own coordinate space (default: 0). */
        public function get pivotX():Number { return mPivotX; }
        public function set pivotX(value:Number):void { mPivotX = value; }
        
        /** The y coordinate of the object's origin in its own coordinate space (default: 0). */
        public function get pivotY():Number { return mPivotY; }
        public function set pivotY(value:Number):void { mPivotY = value; }
        
        /** The horizontal scale factor. '1' means no scale, negative values flip the object. */
        public function get scaleX():Number { return mScaleX; }
        public function set scaleX(value:Number):void { mScaleX = value; }
        
        /** The vertical scale factor. '1' means no scale, negative values flip the object. */
        public function get scaleY():Number { return mScaleY; }
        public function set scaleY(value:Number):void { mScaleY = value; }
        
        /** The rotation of the object in radians. (In Starling, all angles are measured 
         *  in radians.) */
        public function get rotation():Number { return mRotation; }
        public function set rotation(value:Number):void 
        { 
            // move into range [-180 deg, +180 deg]
            while (value < -Math.PI) value += Math.PI * 2.0;
            while (value >  Math.PI) value -= Math.PI * 2.0;
            mRotation = value;
        }
        
        /** The opacity of the object. 0 = transparent, 1 = opaque. */
        public function get alpha():Number { return mAlpha; }
        public function set alpha(value:Number):void 
        { 
            mAlpha = value < 0.0 ? 0.0 : (value > 1.0 ? 1.0 : value); 
        }
        
        /** The visibility of the object. An invisible object will be untouchable. */
        public function get visible():Boolean { return mVisible; }
        public function set visible(value:Boolean):void { mVisible = value; }
        
        /** Indicates if this object (and its children) will receive touch events. */
        public function get touchable():Boolean { return mTouchable; }
        public function set touchable(value:Boolean):void { mTouchable = value; }
        
        /** The blend mode determines how the object is blended with the objects underneath. 
         *   @default auto
         *   @see starling.display.BlendMode */ 
        public function get blendMode():String { return mBlendMode; }
        public function set blendMode(value:String):void { mBlendMode = value; }
        
        /** The name of the display object (default: null). Used by 'getChildByName()' of 
         *  display object containers. */
        public function get name():String { return mName; }
        public function set name(value:String):void { mName = value; }        
        
        /** The display object container that contains this display object. */
        public function get parent():DisplayObjectContainer { return mParent; }
        
        /** The stage the display object is connected to, or null if it is not connected 
         *  to a stage. */
        public function get stage():Stage { return this.root as Stage; }
    }
}