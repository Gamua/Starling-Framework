// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.events
{
    import flash.geom.Point;
    import flash.utils.getDefinitionByName;
    
    import starling.display.DisplayObject;
    import starling.display.Stage;

    /** The TouchProcessor is used to convert mouse and touch events of the conventional
     *  Flash stage to Starling's TouchEvents.
     *  
     *  <p>The Starling instance listens to mouse and touch events on the native stage. The
     *  attributes of those events are enqueued (right as they are happening) in the
     *  TouchProcessor.</p>
     *  
     *  <p>Once per frame, the "advanceTime" method is called. It analyzes the touch queue and
     *  figures out which touches are active at that moment; the properties of all touch objects
     *  are updated accordingly.</p>
     *  
     *  <p>Once the list of touches has been finalized, the "processTouches" method is called
     *  (that might happen several times in one "advanceTime" execution; no information is
     *  discarded). It's responsible for dispatching the actual touch events to the Starling
     *  display tree.</p>
     *  
     *  <strong>Subclassing TouchProcessor</strong>
     *  
     *  <p>You can extend the TouchProcessor if you need to have more control over touch and
     *  mouse input. For example, you could filter the touches by overriding the "processTouches"
     *  method, throwing away any touches you're not interested in and passing the rest to the
     *  super implementation.</p>
     *  
     *  <p>To use your custom TouchProcessor, assign it to the "Starling.touchProcessor"
     *  property.</p>
     *  
     *  <p>Note that you should not dispatch TouchEvents yourself, since they are
     *  much more complex to handle than conventional events (e.g. it must be made sure that an
     *  object receives a TouchEvent only once, even if it's manipulated with several fingers).
     *  Always use the base implementation of "processTouches" to let them be dispatched. That
     *  said: you can always dispatch your own custom events, of course.</p>
     */
    public class TouchProcessor
    {
        private var mStage:Stage;
        private var mRoot:DisplayObject;
        private var mElapsedTime:Number;
        private var mTouchMarker:TouchMarker;
        private var mLastTaps:Vector.<Touch>;
        private var mShiftDown:Boolean = false;
        private var mCtrlDown:Boolean  = false;
        private var mMultitapTime:Number = 0.3;
        private var mMultitapDistance:Number = 25;
        
        /** A vector of arrays with the arguments that were passed to the "enqueue"
         *  method (the oldest being at the end of the vector). */
        protected var mQueue:Vector.<Array>;
        
        /** The list of all currently active touches. */
        protected var mCurrentTouches:Vector.<Touch>;
        
        /** Helper objects. */
        private static var sUpdatedTouches:Vector.<Touch> = new <Touch>[];
        private static var sHoveringTouchData:Vector.<Object> = new <Object>[];
        private static var sHelperPoint:Point = new Point();
        
        /** Creates a new TouchProcessor that will dispatch events to the given stage. */
        public function TouchProcessor(stage:Stage)
        {
            mRoot = mStage = stage;
            mElapsedTime = 0.0;
            mCurrentTouches = new <Touch>[];
            mQueue = new <Array>[];
            mLastTaps = new <Touch>[];

            mStage.addEventListener(KeyboardEvent.KEY_DOWN, onKey);
            mStage.addEventListener(KeyboardEvent.KEY_UP,   onKey);
            monitorInterruptions(true);
        }

        /** Removes all event handlers on the stage and releases any acquired resources. */
        public function dispose():void
        {
            monitorInterruptions(false);
            mStage.removeEventListener(KeyboardEvent.KEY_DOWN, onKey);
            mStage.removeEventListener(KeyboardEvent.KEY_UP,   onKey);
            if (mTouchMarker) mTouchMarker.dispose();
        }
        
        /** Analyzes the current touch queue and processes the list of current touches, emptying
         *  the queue while doing so. This method is called by Starling once per frame. */
        public function advanceTime(passedTime:Number):void
        {
            var i:int;
            var touch:Touch;
            
            mElapsedTime += passedTime;
            
            // remove old taps
            if (mLastTaps.length > 0)
            {
                for (i=mLastTaps.length-1; i>=0; --i)
                    if (mElapsedTime - mLastTaps[i].timestamp > mMultitapTime)
                        mLastTaps.splice(i, 1);
            }
            
            while (mQueue.length > 0)
            {
                // Set touches that were new or moving to phase 'stationary'.
                for each (touch in mCurrentTouches)
                    if (touch.phase == TouchPhase.BEGAN || touch.phase == TouchPhase.MOVED)
                        touch.phase = TouchPhase.STATIONARY;

                // analyze new touches, but each ID only once
                while (mQueue.length > 0 &&
                      !containsTouchWithID(sUpdatedTouches, mQueue[mQueue.length-1][0]))
                {
                    var touchArgs:Array = mQueue.pop();
                    touch = createOrUpdateTouch(
                                touchArgs[0], touchArgs[1], touchArgs[2], touchArgs[3],
                                touchArgs[4], touchArgs[5], touchArgs[6]);
                    
                    sUpdatedTouches[sUpdatedTouches.length] = touch; // avoiding 'push'
                }

                // process the current set of touches (i.e. dispatch touch events)
                processTouches(sUpdatedTouches, mShiftDown, mCtrlDown);

                // remove ended touches
                for (i=mCurrentTouches.length-1; i>=0; --i)
                    if (mCurrentTouches[i].phase == TouchPhase.ENDED)
                        mCurrentTouches.splice(i, 1);
                
                sUpdatedTouches.length = 0;
            }
        }
        
        /** Dispatches TouchEvents to the display objects that are affected by the list of
         *  given touches. Called internally by "advanceTime". To calculate updated targets,
         *  the method will call "hitTest" on the "root" object.
         *  
         *  @param touches:   a list of all touches that have changed just now.
         *  @param shiftDown: indicates if the shift key was down when the touches occurred.
         *  @param CtrlDown:  indicates if the ctrl or cmd key was down when the touches occurred.
         */
        protected function processTouches(touches:Vector.<Touch>,
                                          shiftDown:Boolean, ctrlDown:Boolean):void
        {
            sHoveringTouchData.length = 0;
            
            // the same touch event will be dispatched to all targets;
            // the 'dispatch' method will make sure each bubble target is visited only once.
            var touchEvent:TouchEvent = new TouchEvent(TouchEvent.TOUCH, mCurrentTouches, shiftDown, ctrlDown);
            var touch:Touch;
            
            // hit test our updated touches
            for each (touch in touches)
            {
                // hovering touches need special handling (see below)
                if (touch.phase == TouchPhase.HOVER && touch.target)
                    sHoveringTouchData[sHoveringTouchData.length] = {
                        touch: touch,
                        target: touch.target,
                        bubbleChain: touch.bubbleChain
                    }; // avoiding 'push'
                
                if (touch.phase == TouchPhase.HOVER || touch.phase == TouchPhase.BEGAN)
                {
                    sHelperPoint.setTo(touch.globalX, touch.globalY);
                    touch.target = mRoot.hitTest(sHelperPoint, true);
                }
            }
            
            // if the target of a hovering touch changed, we dispatch the event to the previous
            // target to notify it that it's no longer being hovered over.
            for each (var touchData:Object in sHoveringTouchData)
                if (touchData.touch.target != touchData.target)
                    touchEvent.dispatch(touchData.bubbleChain);
            
            // dispatch events for the rest of our updated touches
            for each (touch in touches)
                touch.dispatchEvent(touchEvent);
        }
        
        /** Enqueues a new touch our mouse event with the given properties. */
        public function enqueue(touchID:int, phase:String, globalX:Number, globalY:Number,
                                pressure:Number=1.0, width:Number=1.0, height:Number=1.0):void
        {
            mQueue.unshift(arguments);
            
            // multitouch simulation (only with mouse)
            if (mCtrlDown && simulateMultitouch && touchID == 0) 
            {
                mTouchMarker.moveMarker(globalX, globalY, mShiftDown);
                mQueue.unshift([1, phase, mTouchMarker.mockX, mTouchMarker.mockY]);
            }
        }
        
        /** Enqueues an artificial touch that represents the mouse leaving the stage.
         *  
         *  <p>On OS X, we get mouse events from outside the stage; on Windows, we do not.
         *  This method enqueues an artificial hover point that is just outside the stage.
         *  That way, objects listening for HOVERs over them will get notified everywhere.</p>
         */
        public function enqueueMouseLeftStage():void
        {
            var mouse:Touch = getCurrentTouch(0);
            if (mouse == null || mouse.phase != TouchPhase.HOVER) return;
            
            var offset:int = 1;
            var exitX:Number = mouse.globalX;
            var exitY:Number = mouse.globalY;
            var distLeft:Number = mouse.globalX;
            var distRight:Number = mStage.stageWidth - distLeft;
            var distTop:Number = mouse.globalY;
            var distBottom:Number = mStage.stageHeight - distTop;
            var minDist:Number = Math.min(distLeft, distRight, distTop, distBottom);
            
            // the new hover point should be just outside the stage, near the point where
            // the mouse point was last to be seen.
            
            if (minDist == distLeft)       exitX = -offset;
            else if (minDist == distRight) exitX = mStage.stageWidth + offset;
            else if (minDist == distTop)   exitY = -offset;
            else                           exitY = mStage.stageHeight + offset;
            
            enqueue(0, TouchPhase.HOVER, exitX, exitY);
        }
        
        private function createOrUpdateTouch(touchID:int, phase:String,
                                             globalX:Number, globalY:Number,
                                             pressure:Number=1.0,
                                             width:Number=1.0, height:Number=1.0):Touch
        {
            var touch:Touch = getCurrentTouch(touchID);
            
            if (touch == null)
            {
                touch = new Touch(touchID);
                addCurrentTouch(touch);
            }
            
            touch.globalX = globalX;
            touch.globalY = globalY;
            touch.phase = phase;
            touch.timestamp = mElapsedTime;
            touch.pressure = pressure;
            touch.width  = width;
            touch.height = height;

            if (phase == TouchPhase.BEGAN)
                updateTapCount(touch);

            return touch;
        }
        
        private function updateTapCount(touch:Touch):void
        {
            var nearbyTap:Touch = null;
            var minSqDist:Number = mMultitapDistance * mMultitapDistance;
            
            for each (var tap:Touch in mLastTaps)
            {
                var sqDist:Number = Math.pow(tap.globalX - touch.globalX, 2) +
                                    Math.pow(tap.globalY - touch.globalY, 2);
                if (sqDist <= minSqDist)
                {
                    nearbyTap = tap;
                    break;
                }
            }
            
            if (nearbyTap)
            {
                touch.tapCount = nearbyTap.tapCount + 1;
                mLastTaps.splice(mLastTaps.indexOf(nearbyTap), 1);
            }
            else
            {
                touch.tapCount = 1;
            }
            
            mLastTaps.push(touch.clone());
        }
        
        private function addCurrentTouch(touch:Touch):void
        {
            for (var i:int=mCurrentTouches.length-1; i>=0; --i)
                if (mCurrentTouches[i].id == touch.id)
                    mCurrentTouches.splice(i, 1);
            
            mCurrentTouches.push(touch);
        }
        
        private function getCurrentTouch(touchID:int):Touch
        {
            for each (var touch:Touch in mCurrentTouches)
                if (touch.id == touchID) return touch;
            
            return null;
        }
        
        private function containsTouchWithID(touches:Vector.<Touch>, touchID:int):Boolean
        {
            for each (var touch:Touch in touches)
                if (touch.id == touchID) return true;
            
            return false;
        }
        
        /** Indicates if it multitouch simulation should be activated. When the user presses
         *  ctrl/cmd (and optionally shift), he'll see a second touch curser that mimics the first.
         *  That's an easy way to develop and test multitouch when there's only a mouse available.
         */
        public function get simulateMultitouch():Boolean { return mTouchMarker != null; }
        public function set simulateMultitouch(value:Boolean):void
        { 
            if (simulateMultitouch == value) return; // no change
            if (value)
            {
                mTouchMarker = new TouchMarker();
                mTouchMarker.visible = false;
                mStage.addChild(mTouchMarker);
            }
            else
            {                
                mTouchMarker.removeFromParent(true);
                mTouchMarker = null;
            }
        }
        
        /** The time period (in seconds) in which two touches must occur to be recognized as
         *  a multitap gesture. */
        public function get multitapTime():Number { return mMultitapTime; }
        public function set multitapTime(value:Number):void { mMultitapTime = value; }
        
        /** The distance (in points) describing how close two touches must be to each other to
         *  be recognized as a multitap gesture. */
        public function get multitapDistance():Number { return mMultitapDistance; }
        public function set multitapDistance(value:Number):void { mMultitapDistance = value; }

        /** The base object that will be used for hit testing. Per default, this reference points
         *  to the stage; however, you can limit touch processing to certain parts of your game
         *  by assigning a different object. */
        public function get root():DisplayObject { return mRoot; }
        public function set root(value:DisplayObject):void { mRoot = value; }
        
        /** The stage object to which the touch objects are (per default) dispatched. */
        public function get stage():Stage { return mStage; }
        
        // keyboard handling
        
        private function onKey(event:KeyboardEvent):void
        {
            if (event.keyCode == 17 || event.keyCode == 15) // ctrl or cmd key
            {
                var wasCtrlDown:Boolean = mCtrlDown;
                mCtrlDown = event.type == KeyboardEvent.KEY_DOWN;
                
                if (simulateMultitouch && wasCtrlDown != mCtrlDown)
                {
                    mTouchMarker.visible = mCtrlDown;
                    mTouchMarker.moveCenter(mStage.stageWidth/2, mStage.stageHeight/2);
                    
                    var mouseTouch:Touch = getCurrentTouch(0);
                    var mockedTouch:Touch = getCurrentTouch(1);
                    
                    if (mouseTouch)
                        mTouchMarker.moveMarker(mouseTouch.globalX, mouseTouch.globalY);
                    
                    if (wasCtrlDown && mockedTouch && mockedTouch.phase != TouchPhase.ENDED)
                    {
                        // end active touch ...
                        mQueue.unshift([1, TouchPhase.ENDED, mockedTouch.globalX, mockedTouch.globalY]);
                    }
                    else if (mCtrlDown && mouseTouch)
                    {
                        // ... or start new one
                        if (mouseTouch.phase == TouchPhase.HOVER || mouseTouch.phase == TouchPhase.ENDED)
                            mQueue.unshift([1, TouchPhase.HOVER, mTouchMarker.mockX, mTouchMarker.mockY]);
                        else
                            mQueue.unshift([1, TouchPhase.BEGAN, mTouchMarker.mockX, mTouchMarker.mockY]);
                    }
                }
            }
            else if (event.keyCode == 16) // shift key
            {
                mShiftDown = event.type == KeyboardEvent.KEY_DOWN;
            }
        }

        // interruption handling
        
        private function monitorInterruptions(enable:Boolean):void
        {
            // if the application moves into the background or is interrupted (e.g. through
            // an incoming phone call), we need to abort all touches.
            
            try
            {
                var nativeAppClass:Object = getDefinitionByName("flash.desktop::NativeApplication");
                var nativeApp:Object = nativeAppClass["nativeApplication"];
                
                if (enable)
                    nativeApp.addEventListener("deactivate", onInterruption, false, 0, true);
                else
                    nativeApp.removeEventListener("activate", onInterruption);
            }
            catch (e:Error) {} // we're not running in AIR
        }
        
        private function onInterruption(event:Object):void
        {
            if (mCurrentTouches.length > 0)
            {
                // abort touches
                for each (var touch:Touch in mCurrentTouches)
                {
                    if (touch.phase == TouchPhase.BEGAN || touch.phase == TouchPhase.MOVED ||
                        touch.phase == TouchPhase.STATIONARY)
                    {
                        touch.phase = TouchPhase.ENDED;
                    }
                }

                // dispatch events
                processTouches(mCurrentTouches, mShiftDown, mCtrlDown);
            }

            // purge touches
            mCurrentTouches.length = 0;
        }
    }
}
