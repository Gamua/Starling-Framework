// =================================================================================================
//
//    Starling Framework
//    Copyright 2011 Gamua OG. All Rights Reserved.
//
//    This program is free software. You can redistribute and/or modify it
//    in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.core
{
    import flash.utils.getDefinitionByName;

    import starling.display.Stage;
    import starling.events.KeyboardEvent;
    import starling.events.Touch;
    import starling.events.TouchDispatcher;
    import starling.events.TouchHandler;
    import starling.events.TouchPhase;

    use namespace starling_internal;

    /** @private
     *  The TouchProcessor is used internally to convert mouse and touch events of the conventional
     *  Flash stage to Starling's TouchEvents. */
    internal class TouchProcessor
    {
        private static const MULTITAP_TIME:Number = 0.3;
        private static const MULTITAP_DISTANCE:Number = 25;

        private var mStage:Stage;
        private var mElapsedTime:Number;
        private var mTouchMarker:TouchMarker;

        private var mTouchHandler:TouchHandler;

        private var mCurrentTouches:Vector.<Touch>;
        private var mQueue:Vector.<Array>;
        private var mLastTaps:Vector.<Touch>;

        private var mShiftDown:Boolean = false;
        private var mCtrlDown:Boolean = false;

        /** Helper objects. */
        private static var sProcessedTouchIDs:Vector.<int> = new <int>[];

        public function TouchProcessor(stage:Stage)
        {
            mStage = stage;
            mElapsedTime = 0.0;
            mCurrentTouches = new <Touch>[];
            mQueue = new <Array>[];
            mLastTaps = new <Touch>[];

            // install the default touch handler
            mTouchHandler = new TouchDispatcher(stage);

            mStage.addEventListener(KeyboardEvent.KEY_DOWN, onKey);
            mStage.addEventListener(KeyboardEvent.KEY_UP,   onKey);
            monitorInterruptions(true);
        }

        public function dispose():void
        {
            monitorInterruptions(false);
            mStage.removeEventListener(KeyboardEvent.KEY_DOWN, onKey);
            mStage.removeEventListener(KeyboardEvent.KEY_UP,   onKey);
            if (mTouchMarker) mTouchMarker.dispose();
            if (mTouchHandler) mTouchHandler.dispose();
        }

        public function advanceTime(passedTime:Number):void
        {
            var i:int;
            var touchID:int;
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

                // process new touches, but each ID only once
                while (mQueue.length > 0 &&
                    sProcessedTouchIDs.indexOf(mQueue[mQueue.length-1][0]) == -1)
                {
                    var touchArgs:Array = mQueue.pop();
                    touch = processTouch.apply(this, touchArgs);
                    sProcessedTouchIDs.push(touch.id);
                    touch.setUpdated(true);
                }

                // hand the newly-processed touches to the touch handler
                if (mTouchHandler)
                    mTouchHandler.handleTouches(mCurrentTouches);

                // remove ended touches
                for (i=mCurrentTouches.length-1; i>=0; --i)
                    if (mCurrentTouches[i].phase == TouchPhase.ENDED)
                        mCurrentTouches.splice(i, 1);
            }
        }

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

        private function processTouch(touchID:int, phase:String, globalX:Number, globalY:Number,
                                      pressure:Number=1.0, width:Number=1.0, height:Number=1.0):Touch
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
                processTap(touch);

            return touch;
        }

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

        private function processTap(touch:Touch):void
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

        public function get touchHandler():TouchHandler { return mTouchHandler; }
        public function set touchHandler(value:TouchHandler):void { mTouchHandler = value; }

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
            if (mCurrentTouches.length > 0 && mTouchHandler != null)
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

                // update the touch handler
                mTouchHandler.handleTouches(mCurrentTouches);
            }

            // purge touches
            mCurrentTouches.length = 0;
        }
    }
}
