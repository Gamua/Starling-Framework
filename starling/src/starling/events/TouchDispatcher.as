// =================================================================================================
//
//    Starling Framework
//    Copyright 2011 Gamua OG. All Rights Reserved.
//
//    This program is free software. You can redistribute and/or modify it
//    in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.events
{
    import flash.geom.Point;

    import starling.core.starling_internal;
    import starling.display.DisplayObjectContainer;
    import starling.display.Stage;

    use namespace starling_internal;

    public class TouchDispatcher implements TouchHandler
    {
        private var mRoot:DisplayObjectContainer;
        private var mStage:Stage;

        private var mShiftDown:Boolean = false;
        private var mCtrlDown:Boolean = false;

        /** Helper object */
        private static var sHoveringTouchData:Vector.<Object> = new <Object>[];

        public function TouchDispatcher(root:DisplayObjectContainer)
        {
            mRoot = root;
            mStage = root.stage;
            if (mStage == null)
                throw new ArgumentError("root must be added to the stage");

            mStage.addEventListener(KeyboardEvent.KEY_DOWN, onKey);
            mStage.addEventListener(KeyboardEvent.KEY_UP,   onKey);
        }

        public function dispose():void
        {
            mStage.removeEventListener(KeyboardEvent.KEY_DOWN, onKey);
            mStage.removeEventListener(KeyboardEvent.KEY_UP,   onKey);
        }

        public function handleTouches(touches:Vector.<Touch>):void
        {
            sHoveringTouchData.length = 0;
            var touch:Touch;

            // the same touch event will be dispatched to all targets;
            // the 'dispatch' method will make sure each bubble target is visited only once.
            var touchEvent:TouchEvent = new TouchEvent(TouchEvent.TOUCH, touches, mShiftDown, mCtrlDown);

            // hit test our updated touches
            for each (touch in touches)
            {
                if (!touch.updated) continue;

                // hovering touches need special handling (see below)
                if (touch.phase == TouchPhase.HOVER && touch.target)
                    sHoveringTouchData.push({
                        touch: touch,
                        target: touch.target,
                        bubbleChain: touch.bubbleChain
                    });

                if (touch.phase == TouchPhase.HOVER || touch.phase == TouchPhase.BEGAN)
                    touch.setTarget(mRoot.hitTest(new Point(touch.globalX, touch.globalY), true));
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

        private function onKey(event:KeyboardEvent):void
        {
            if (event.keyCode == 17 || event.keyCode == 15) // ctrl or cmd key
                mCtrlDown = event.type == KeyboardEvent.KEY_DOWN;
            else if (event.keyCode == 16)
               mShiftDown = event.type == KeyboardEvent.KEY_DOWN;
        }
    }
}
