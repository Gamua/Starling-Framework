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
    import flash.display.BitmapData;
    import flash.errors.IllegalOperationError;
    import flash.geom.Matrix3D;
    import flash.geom.Point;
    import flash.geom.Vector3D;
    
    import starling.core.RenderSupport;
    import starling.core.Starling;
    import starling.core.starling_internal;
    import starling.events.EnterFrameEvent;
    import starling.events.Event;
    import starling.filters.FragmentFilter;
    import starling.utils.MatrixUtil;
    
    use namespace starling_internal;
    
    /** Dispatched when the Flash container is resized. */
    [Event(name="resize", type="starling.events.ResizeEvent")]
    
    /** A Stage represents the root of the display tree.  
     *  Only objects that are direct or indirect children of the stage will be rendered.
     * 
     *  <p>This class represents the Starling version of the stage. Don't confuse it with its 
     *  Flash equivalent: while the latter contains objects of the type 
     *  <code>flash.display.DisplayObject</code>, the Starling stage contains only objects of the
     *  type <code>starling.display.DisplayObject</code>. Those classes are not compatible, and 
     *  you cannot exchange one type with the other.</p>
     * 
     *  <p>A stage object is created automatically by the <code>Starling</code> class. Don't
     *  create a Stage instance manually.</p>
     * 
     *  <strong>Keyboard Events</strong>
     * 
     *  <p>In Starling, keyboard events are only dispatched at the stage. Add an event listener
     *  directly to the stage to be notified of keyboard events.</p>
     * 
     *  <strong>Resize Events</strong>
     * 
     *  <p>When the Flash player is resized, the stage dispatches a <code>ResizeEvent</code>. The 
     *  event contains properties containing the updated width and height of the Flash player.</p>
     *
     *  @see starling.events.KeyboardEvent
     *  @see starling.events.ResizeEvent  
     * 
     */
    public class Stage extends DisplayObjectContainer
    {
        private var mWidth:int;
        private var mHeight:int;
        private var mColor:uint;
        private var mFieldOfView:Number;
        private var mProjectionOffset:Point;
        private var mCameraPosition:Vector3D;
        private var mEnterFrameEvent:EnterFrameEvent;
        private var mEnterFrameListeners:Vector.<DisplayObject>;
        
        /** Helper objects. */
        private static var sHelperMatrix:Matrix3D = new Matrix3D();

        /** @private */
        public function Stage(width:int, height:int, color:uint=0)
        {
            mWidth = width;
            mHeight = height;
            mColor = color;
            mFieldOfView = 1.0;
            mProjectionOffset = new Point();
            mCameraPosition = new Vector3D();
            mEnterFrameEvent = new EnterFrameEvent(Event.ENTER_FRAME, 0.0);
            mEnterFrameListeners = new <DisplayObject>[];
        }
        
        /** @inheritDoc */
        public function advanceTime(passedTime:Number):void
        {
            mEnterFrameEvent.reset(Event.ENTER_FRAME, false, passedTime);
            broadcastEvent(mEnterFrameEvent);
        }

        /** Returns the object that is found topmost beneath a point in stage coordinates, or  
         *  the stage itself if nothing else is found. */
        public override function hitTest(localPoint:Point, forTouch:Boolean=false):DisplayObject
        {
            if (forTouch && (!visible || !touchable))
                return null;
            
            // locations outside of the stage area shouldn't be accepted
            if (localPoint.x < 0 || localPoint.x > mWidth ||
                localPoint.y < 0 || localPoint.y > mHeight)
                return null;
            
            // if nothing else is hit, the stage returns itself as target
            var target:DisplayObject = super.hitTest(localPoint, forTouch);
            if (target == null) target = this;
            return target;
        }
        
        /** Draws the complete stage into a BitmapData object.
         *
         *  <p>If you encounter problems with transparency, start Starling in BASELINE profile
         *  (or higher). BASELINE_CONSTRAINED might not support transparency on all platforms.
         *  </p>
         *
         *  @param destination  If you pass null, the object will be created for you.
         *                      If you pass a BitmapData object, it should have the size of the
         *                      back buffer (which is accessible via the respective properties
         *                      on the Starling instance).
         *  @param transparent  If enabled, empty areas will appear transparent; otherwise, they
         *                      will be filled with the stage color.
         */
        public function drawToBitmapData(destination:BitmapData=null,
                                         transparent:Boolean=true):BitmapData
        {
            var support:RenderSupport = new RenderSupport();
            var star:Starling = Starling.current;

            if (destination == null)
            {
                var width:int  = star.backBufferWidth  * star.backBufferPixelsPerPoint;
                var height:int = star.backBufferHeight * star.backBufferPixelsPerPoint;
                destination = new BitmapData(width, height, transparent);
            }
            
            support.renderTarget = null;
            support.setProjectionMatrix(0, 0, mWidth, mHeight, mWidth, mHeight, cameraPosition);
            
            if (transparent) support.clear();
            else             support.clear(mColor, 1);
            
            render(support, 1.0);
            support.finishQuadBatch();
            support.dispose();
            
            Starling.current.context.drawToBitmapData(destination);
            Starling.current.context.present(); // required on some platforms to avoid flickering
            
            return destination;
        }
        
        // camera positioning

        /** Returns the position of the camera within the local coordinate system of a certain
         *  display object. If you do not pass a space, the method returns the global position.
         *  To change the position of the camera, you can modify the properties 'fieldOfView',
         *  'focalDistance' and 'projectionOffset'.
         */
        public function getCameraPosition(space:DisplayObject=null, result:Vector3D=null):Vector3D
        {
            getTransformationMatrix3D(space, sHelperMatrix);

            return MatrixUtil.transformCoords3D(sHelperMatrix,
                mWidth / 2 + mProjectionOffset.x, mHeight / 2 + mProjectionOffset.y,
               -focalLength, result);
        }

        // enter frame event optimization
        
        /** @private */
        internal function addEnterFrameListener(listener:DisplayObject):void
        {
            mEnterFrameListeners.push(listener);
        }
        
        /** @private */
        internal function removeEnterFrameListener(listener:DisplayObject):void
        {
            var index:int = mEnterFrameListeners.indexOf(listener);
            if (index >= 0) mEnterFrameListeners.splice(index, 1); 
        }
        
        /** @private */
        internal override function getChildEventListeners(object:DisplayObject, eventType:String, 
                                                          listeners:Vector.<DisplayObject>):void
        {
            if (eventType == Event.ENTER_FRAME && object == this)
            {
                for (var i:int=0, length:int=mEnterFrameListeners.length; i<length; ++i)
                    listeners[listeners.length] = mEnterFrameListeners[i]; // avoiding 'push' 
            }
            else
                super.getChildEventListeners(object, eventType, listeners);
        }
        
        // properties
        
        /** @private */
        public override function set width(value:Number):void 
        { 
            throw new IllegalOperationError("Cannot set width of stage");
        }
        
        /** @private */
        public override function set height(value:Number):void
        {
            throw new IllegalOperationError("Cannot set height of stage");
        }
        
        /** @private */
        public override function set x(value:Number):void
        {
            throw new IllegalOperationError("Cannot set x-coordinate of stage");
        }
        
        /** @private */
        public override function set y(value:Number):void
        {
            throw new IllegalOperationError("Cannot set y-coordinate of stage");
        }
        
        /** @private */
        public override function set scaleX(value:Number):void
        {
            throw new IllegalOperationError("Cannot scale stage");
        }

        /** @private */
        public override function set scaleY(value:Number):void
        {
            throw new IllegalOperationError("Cannot scale stage");
        }
        
        /** @private */
        public override function set rotation(value:Number):void
        {
            throw new IllegalOperationError("Cannot rotate stage");
        }
        
        /** @private */
        public override function set skewX(value:Number):void
        {
            throw new IllegalOperationError("Cannot skew stage");
        }
        
        /** @private */
        public override function set skewY(value:Number):void
        {
            throw new IllegalOperationError("Cannot skew stage");
        }
        
        /** @private */
        public override function set filter(value:FragmentFilter):void
        {
            throw new IllegalOperationError("Cannot add filter to stage. Add it to 'root' instead!");
        }
        
        /** The background color of the stage. */
        public function get color():uint { return mColor; }
        public function set color(value:uint):void { mColor = value; }
        
        /** The width of the stage coordinate system. Change it to scale its contents relative
         *  to the <code>viewPort</code> property of the Starling object. */ 
        public function get stageWidth():int { return mWidth; }
        public function set stageWidth(value:int):void { mWidth = value; }
        
        /** The height of the stage coordinate system. Change it to scale its contents relative
         *  to the <code>viewPort</code> property of the Starling object. */
        public function get stageHeight():int { return mHeight; }
        public function set stageHeight(value:int):void { mHeight = value; }

        /** The distance between the stage and the camera. Changing this value will update the
         *  field of view accordingly. */
        public function get focalLength():Number
        {
            return mWidth / (2 * Math.tan(mFieldOfView/2));
        }

        public function set focalLength(value:Number):void
        {
            mFieldOfView = 2 * Math.atan(stageWidth / (2*value));
        }

        /** Specifies an angle (radian, between zero and PI) for the field of view. This value
         *  determines how strong the perspective transformation and distortion apply to a Sprite3D
         *  object.
         *
         *  <p>A value close to zero will look similar to an orthographic projection; a value
         *  close to PI results in a fisheye lens effect. If the field of view is set to 0 or PI,
         *  nothing is seen on the screen.</p>
         *
         *  @default 1.0
         */
        public function get fieldOfView():Number { return mFieldOfView; }
        public function set fieldOfView(value:Number):void { mFieldOfView = value; }

        /** A vector that moves the camera away from its default position in the center of the
         *  stage. Use this property to change the center of projection, i.e. the vanishing
         *  point for 3D display objects. <p>CAUTION: not a copy, but the actual object!</p>
         */
        public function get projectionOffset():Point { return mProjectionOffset; }
        public function set projectionOffset(value:Point):void
        {
            mProjectionOffset.setTo(value.x, value.y);
        }

        /** The global position of the camera. This property can only be used to find out the
         *  current position, but not to modify it. For that, use the 'projectionOffset',
         *  'fieldOfView' and 'focalLength' properties. If you need the camera position in
         *  a certain coordinate space, use 'getCameraPosition' instead.
         *
         *  <p>CAUTION: not a copy, but the actual object!</p>
         */
        public function get cameraPosition():Vector3D
        {
            return getCameraPosition(null, mCameraPosition);
        }
    }
}