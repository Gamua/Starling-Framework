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
     *  <p>You can extend the TouchProcessor class if you want to handle touch and mouse input
     *  manually. You'll probably want to override the "processTouches" method; that way,
     *  input analysis will be done automatically and you're just responsible for dispatching
     *  your own events. If you need more control, you can override the "advanceTime" method,
     *  as well.</p>
     *  
     *  <p>Pass an instance of your subclass to "Starling.touchProcessor".</p>
     */
    public class TouchProcessor
    {
        private static const MULTITAP_TIME:Number = 0.3;
        private static const MULTITAP_DISTANCE:Number = 25;
        
        private var mStage:Stage;
        private var mElapsedTime:Number;
        private var mTouchMarker:TouchMarker;
        
        private var mCurrentTouches:Vector.<Touch>;
        private var mQueue:Vector.<Array>;
        private var mLastTaps:Vector.<Touch>;
        
        private var mShiftDown:Boolean = false;
        private var mCtrlDown:Boolean = false;
        
        /** Helper objects. */
        private static var sProcessedTouchIDs:Vector.<int> = new <int>[];
        private static var sHoveringTouchData:Vector.<Object> = new <Object>[];
        private static var sHelperPoint:Point = new Point();
        
        /** Creates a new TouchProcessor that will dispatch events to the given stage. */
        public function TouchProcessor(stage:Stage)
        {
            mStage = stage;
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
                    if (mElapsedTime - mLastTaps[i].timestamp > MULTITAP_TIME)
                        mLastTaps.splice(i, 1);
            }
            
            while (mQueue.length > 0)
            {
                sProcessedTouchIDs.length = 0;

                // Set touches that were new or moving to phase 'stationary'.
                // Moving into the STATIONARY state doesn't generate touch events, so we don't
                // set the 'updated' flag on these touches.
                for each (touch in mCurrentTouches)
                {
                    touch.setUpdated(false);
                    if (touch.phase == TouchPhase.BEGAN || touch.phase == TouchPhase.MOVED)
                        touch.setPhase(TouchPhase.STATIONARY);
                }

                // analyze new touches, but each ID only once
                while (mQueue.length > 0 && 
                    sProcessedTouchIDs.indexOf(mQueue[mQueue.length-1][0]) == -1)
                {
                    var touchArgs:Array = mQueue.pop();
                    touch = createOrUpdateTouch(
                                touchArgs[0], touchArgs[1], touchArgs[2], touchArgs[3],
                                touchArgs[4], touchArgs[5], touchArgs[6]);
                    
                    sProcessedTouchIDs[sProcessedTouchIDs.length] = touch.id; // avoiding 'push'
                    touch.setUpdated(true);
                }

                // process the current set of touches (i.e. dispatch touch events)
                processTouches(mCurrentTouches, mShiftDown, mCtrlDown);

                // remove ended touches
                for (i=mCurrentTouches.length-1; i>=0; --i)
                    if (mCurrentTouches[i].phase == TouchPhase.ENDED)
                        mCurrentTouches.splice(i, 1);
            }
        }
        
        /** Dispatches TouchEvents to the display objects that are affected by the list of
         *  given touches. Called internally by "advanceTime".
         *  
         *  @param touches:   a list of <em>all</em> current touches. Touches that were just
         *                    created or updated as a result of new input will have their "updated"
         *                    properties set to true.
         *  @param shiftDown: indicates if the shift key was down when the touches occurred.
         *  @param CtrlDown:  indicates if the ctrl or cmd key was down when the touches occurred.
         */
        protected function processTouches(touches:Vector.<Touch>,
                                          shiftDown:Boolean, ctrlDown:Boolean):void
        {
            sHoveringTouchData.length = 0;
            
            // the same touch event will be dispatched to all targets;
            // the 'dispatch' method will make sure each bubble target is visited only once.
            var touchEvent:TouchEvent = new TouchEvent(TouchEvent.TOUCH, touches, shiftDown, ctrlDown);
            var touch:Touch;
            
            // hit test our updated touches
            for each (touch in touches)
            {
                if (!touch.updated) continue;
                
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
                    touch.setTarget(mStage.hitTest(sHelperPoint, true));
                }
            }
            
            // if the target of a hovering touch changed, we dispatch the event to the previous
            // target to notify it that it's no longer being hovered over.
            for each (var touchData:Object in sHoveringTouchData)
                if (touchData.touch.target != touchData.target)
                    touchEvent.dispatch(touchData.bubbleChain);
            
            // dispatch events for the rest of our updated touches
            for each (touch in touches)
                if (touch.updated)
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
         *  That way, objects listening for HOVERs over them will get notified everywhere.
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
                touch = new Touch(touchID, globalX, globalY, phase);
                addCurrentTouch(touch);
            }
            
            touch.setPosition(globalX, globalY);
            touch.setPhase(phase);
            touch.setTimestamp(mElapsedTime);
            touch.setPressure(pressure);
            touch.setSize(width, height);

            if (phase == TouchPhase.BEGAN)
                updateTapCount(touch);

            return touch;
        }
        
        private function updateTapCount(touch:Touch):void
        {
            var nearbyTap:Touch = null;
            var minSqDist:Number = MULTITAP_DISTANCE * MULTITAP_DISTANCE;
            
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
                touch.setTapCount(nearbyTap.tapCount + 1);
                mLastTaps.splice(mLastTaps.indexOf(nearbyTap), 1);
            }
            else
            {
                touch.setTapCount(1);
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

        /** The stage object to which the touch events will be dispatched. */
        public function get stage():Stage { return mStage; }
        
        /** Contains a vector of arrays with the arguments that were passed to the "enqueue"
         *  method (the oldest being at the end of the vector). */
        protected function get queue():Vector.<Array> { return mQueue; }
        
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
                    
                    // end active touch ...
                    if (wasCtrlDown && mockedTouch && mockedTouch.phase != TouchPhase.ENDED)
                        mQueue.unshift([1, TouchPhase.ENDED, mockedTouch.globalX, mockedTouch.globalY]);
                        // ... or start new one
                    else if (mCtrlDown && mouseTouch)
                    {
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
                        touch.setPhase(TouchPhase.ENDED);
                        touch.setUpdated(true);
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
