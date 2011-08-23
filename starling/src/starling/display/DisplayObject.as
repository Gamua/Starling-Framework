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
    
    [Event(name="added", type="starling.events.Event")]
    [Event(name="addedToStage", type="starling.events.Event")]
    [Event(name="removed", type="starling.events.Event")]
    [Event(name="removedFromStage", type="starling.events.Event")]
    [Event(name="enterFrame", type="starling.events.EnterFrameEvent")]
    [Event(name="touch", type="starling.events.TouchEvent")]
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
        
        private var mName:String;
        private var mLastTouchTimestamp:Number;
        private var mParent:DisplayObjectContainer;        
        
        // construction
        
        public function DisplayObject()
        {
            if (getQualifiedClassName(this) == "starling.display::DisplayObject")
                throw new AbstractClassError();
            
            mX = mY = mPivotX = mPivotY = mRotation = 0.0;
            mScaleX = mScaleY = mAlpha = 1.0;            
            mVisible = mTouchable = true;
            mLastTouchTimestamp = -1;
        }
        
        public function dispose():void
        {
            removeEventListeners();
        }
        
        // functions
        
        public function removeFromParent(dispose:Boolean=false):void
        {
            if (mParent) mParent.removeChild(this);
            if (dispose) this.dispose();
        }
        
        public function getTransformationMatrixToSpace(targetSpace:DisplayObject):Matrix
        {
            var rootMatrix:Matrix;
            var targetMatrix:Matrix;
            
            if (targetSpace == this)
            {
                return new Matrix();
            }
            else if (targetSpace == null)
            {
                // targetCoordinateSpace 'null' represents the target space of the root object.
                // -> move up from this to root
                rootMatrix = new Matrix();
                currentObject = this;
                while (currentObject)
                {
                    rootMatrix.concat(currentObject.transformationMatrix);
                    currentObject = currentObject.parent;
                }
                return rootMatrix;
            }
            else if (targetSpace.mParent == this) // optimization
            {
                targetMatrix = targetSpace.transformationMatrix;
                targetMatrix.invert();
                return targetMatrix;
            }
            else if (targetSpace == mParent) // optimization
            {
                return transformationMatrix;
            }
            
            // 1. find a common parent of this and the target space
            
            var ancestors:Vector.<DisplayObject> = new <DisplayObject>[];
            var commonParent:DisplayObject = null;
            var currentObject:DisplayObject = this;            
            while (currentObject)
            {
                ancestors.push(currentObject);
                currentObject = currentObject.parent;
            }
            
            currentObject = targetSpace;
            while (currentObject && ancestors.indexOf(currentObject) == -1)
                currentObject = currentObject.parent;
            
            if (currentObject == null)
                throw new ArgumentError("Object not connected to target");
            else
                commonParent = currentObject;
            
            // 2. move up from this to common parent
            
            rootMatrix = new Matrix();
            currentObject = this;
            
            while (currentObject != commonParent)
            {
                rootMatrix.concat(currentObject.transformationMatrix);
                currentObject = currentObject.parent;
            }
            
            // 3. now move up from target until we reach the common parent
            
            targetMatrix = new Matrix();
            currentObject = targetSpace;
            while (currentObject != commonParent)
            {
                targetMatrix.concat(currentObject.transformationMatrix);
                currentObject = currentObject.parent;
            }
            
            // 4. now combine the two matrices
            
            targetMatrix.invert();
            rootMatrix.concat(targetMatrix);
            
            return rootMatrix;            
        }        
        
        public function getBounds(targetSpace:DisplayObject):Rectangle
        {
            throw new AbstractMethodError("Method needs to be implemented in subclass");
            return null;
        }
        
        public function hitTestPoint(localPoint:Point, forTouch:Boolean=false):DisplayObject
        {
            // on a touch test, invisible or untouchable objects cause the test to fail
            if (forTouch && (!mVisible || !mTouchable)) return null;
            
            // otherwise, check bounding box
            if (getBounds(this).containsPoint(localPoint)) return this;             
            else return null;
        }
        
        public function localToGlobal(localPoint:Point):Point
        {
            // move up  until parent is null
            var transformationMatrix:Matrix = new Matrix();
            var currentObject:DisplayObject = this;
            while (currentObject)
            {
                transformationMatrix.concat(currentObject.transformationMatrix);
                currentObject = currentObject.parent;
            }            
            return transformationMatrix.transformPoint(localPoint);
        }
        
        public function globalToLocal(globalPoint:Point):Point
        {
            // move up until parent is null, then invert matrix
            var transformationMatrix:Matrix = new Matrix();
            var currentObject:DisplayObject = this;
            while (currentObject)
            {
                transformationMatrix.concat(currentObject.transformationMatrix);
                currentObject = currentObject.parent;
            }
            transformationMatrix.invert();
            return transformationMatrix.transformPoint(globalPoint);
        }
        
        public function render(support:RenderSupport, alpha:Number):void
        {
            // override in subclass
        }
        
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
        
        internal function setParent(value:DisplayObjectContainer):void 
        { 
            mParent = value; 
        }
        
        internal function dispatchEventOnChildren(event:Event):void 
        { 
            dispatchEvent(event); 
        }
        
        // properties
        
        public function get transformationMatrix():Matrix
        {
            var matrix:Matrix = new Matrix();
            
            if (mPivotX != 0.0 || mPivotY != 0.0) matrix.translate(-mPivotX, -mPivotY);
            if (mScaleX != 1.0 || mScaleY != 1.0) matrix.scale(mScaleX, mScaleY);
            if (mRotation != 0.0)                 matrix.rotate(mRotation);
            if (mX != 0.0 || mY != 0.0)           matrix.translate(mX, mY);
            
            return matrix;
        }
        
        public function get bounds():Rectangle
        {
            return getBounds(mParent);
        }
        
        public function get width():Number { return getBounds(mParent).width; }        
        public function set width(value:Number):void
        {
            // this method calls 'this.scaleX' instead of changing mScaleX directly.
            // that way, subclasses reacting on size changes need to override only the scaleX method.
            
            mScaleX = 1.0;
            var actualWidth:Number = width;
            if (actualWidth != 0.0) scaleX = value / actualWidth;
            else                    scaleX = 1.0;
        }
        
        public function get height():Number { return getBounds(mParent).height; }
        public function set height(value:Number):void
        {
            mScaleY = 1.0;
            var actualHeight:Number = height;
            if (actualHeight != 0.0) scaleY = value / actualHeight;
            else                     scaleY = 1.0;
        }
        
        public function get root():DisplayObject
        {
            var currentObject:DisplayObject = this;
            while (currentObject.parent) currentObject = currentObject.parent;
            return currentObject;
        }
        
        public function get x():Number { return mX; }
        public function set x(value:Number):void { mX = value; }
        
        public function get y():Number { return mY; }
        public function set y(value:Number):void { mY = value; }
        
        public function get pivotX():Number { return mPivotX; }
        public function set pivotX(value:Number):void { mPivotX = value; }
        
        public function get pivotY():Number { return mPivotY; }
        public function set pivotY(value:Number):void { mPivotY = value; }
        
        public function get scaleX():Number { return mScaleX; }
        public function set scaleX(value:Number):void { mScaleX = value; }
        
        public function get scaleY():Number { return mScaleY; }
        public function set scaleY(value:Number):void { mScaleY = value; }
        
        public function get rotation():Number { return mRotation; }
        public function set rotation(value:Number):void 
        { 
            // move into range [-180 deg, +180 deg]
            while (value < -Math.PI) value += Math.PI * 2.0;
            while (value >  Math.PI) value -= Math.PI * 2.0;
            mRotation = value;
        }
        
        public function get alpha():Number { return mAlpha; }
        public function set alpha(value:Number):void 
        { 
            mAlpha = Math.max(0.0, Math.min(1.0, value)); 
        }
        
        public function get visible():Boolean { return mVisible; }
        public function set visible(value:Boolean):void { mVisible = value; }
        
        public function get touchable():Boolean { return mTouchable; }
        public function set touchable(value:Boolean):void { mTouchable = value; }
        
        public function get name():String { return mName; }
        public function set name(value:String):void { mName = value; }        
        
        public function get parent():DisplayObjectContainer { return mParent; }
        public function get stage():Stage { return this.root as Stage; }
    }
}