package scenes
{
    import starling.core.Starling;
    import starling.display.Button;
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.events.EnterFrameEvent;
    import starling.events.Event;
    import starling.text.BitmapFont;
    import starling.text.TextField;
    import starling.textures.Texture;
    import starling.utils.formatString;

    public class BenchmarkScene extends Scene
    {
        private static const FRAME_TIME_WINDOW_SIZE:int = 10;
        private static const MAX_FAIL_COUNT:int = 100;

        private var mStartButton:Button;
        private var mResultText:TextField;
        private var mStatusText:TextField;
        private var mContainer:Sprite;
        private var mObjectPool:Vector.<DisplayObject>;
        private var mObjectTexture:Texture;

        private var mFrameCount:int;
        private var mFailCount:int;
        private var mStarted:Boolean;
        private var mFrameTimes:Vector.<Number>;
        private var mTargetFps:int;

        private var mPhase:int;

        public function BenchmarkScene()
        {
            super();

            // the container will hold all test objects
            mContainer = new Sprite();
            mContainer.x = Constants.CenterX;
            mContainer.y = Constants.CenterY;
            mContainer.touchable = false; // we do not need touch events on the test objects --
                                          // thus, it is more efficient to disable them.
            addChildAt(mContainer, 0);

            mStatusText = new TextField(Constants.GameWidth - 40, 30, "",
                    BitmapFont.MINI, BitmapFont.NATIVE_SIZE * 2);
            mStatusText.x = 20;
            mStatusText.y = 10;
            addChild(mStatusText);

            mStartButton = new Button(Game.assets.getTexture("button_normal"), "Start benchmark");
            mStartButton.addEventListener(Event.TRIGGERED, onStartButtonTriggered);
            mStartButton.x = Constants.CenterX - int(mStartButton.width / 2);
            mStartButton.y = 20;
            addChild(mStartButton);
            
            mStarted = false;
            mFrameTimes = new <Number>[];
            mObjectPool = new <DisplayObject>[];
            mObjectTexture = Game.assets.getTexture("benchmark_object");

            addEventListener(Event.ENTER_FRAME, onEnterFrame);
        }
        
        public override function dispose():void
        {
            removeEventListener(Event.ENTER_FRAME, onEnterFrame);
            mStartButton.removeEventListener(Event.TRIGGERED, onStartButtonTriggered);

            for each (var object:DisplayObject in mObjectPool)
                object.dispose();

            super.dispose();
        }

        private function onStartButtonTriggered():void
        {
            trace("Starting benchmark");

            mStartButton.visible = false;
            mStarted = true;
            mTargetFps = Starling.current.nativeStage.frameRate;
            mFrameCount = 0;
            mFailCount = 0;
            mPhase = 0;

            for (var i:int=0; i<FRAME_TIME_WINDOW_SIZE; ++i)
                mFrameTimes[i] = 1.0 / mTargetFps;

            if (mResultText)
            {
                mResultText.removeFromParent(true);
                mResultText = null;
            }
        }

        private function onEnterFrame(event:EnterFrameEvent, passedTime:Number):void
        {
            if (!mStarted) return;

            mFrameCount++;
            mContainer.rotation += event.passedTime * 0.5;
            mFrameTimes[FRAME_TIME_WINDOW_SIZE] = 0.0;

            for (var i:int=0; i<FRAME_TIME_WINDOW_SIZE; ++i)
                mFrameTimes[i] += passedTime;

            const measuredFps:Number = FRAME_TIME_WINDOW_SIZE / mFrameTimes.shift();

            if (mPhase == 0)
            {
                if (measuredFps < 0.985 * mTargetFps)
                {
                    mFailCount++;

                    if (mFailCount == MAX_FAIL_COUNT)
                        mPhase = 1;
                }
                else
                {
                    addTestObjects(16);
                    mContainer.scale *= 0.99;
                    mFailCount = 0;
                }
            }
            if (mPhase == 1)
            {
                if (measuredFps > 0.99 * mTargetFps)
                {
                    mFailCount--;

                    if (mFailCount == 0)
                        benchmarkComplete();
                }
                else
                {
                    removeTestObjects(1);
                    mContainer.scale /= 0.9993720513; // 0.99 ^ (1/16)
                }
            }

            if (mFrameCount % int(mTargetFps / 4) == 0)
                mStatusText.text = mContainer.numChildren.toString() + " objects";
        }

        private function addTestObjects(count:int):void
        {
            var scale:Number = 1.0 / mContainer.scale;

            for (var i:int = 0; i<count; ++i)
            {
                var egg:DisplayObject = getObjectFromPool();
                var distance:Number = (100 + Math.random() * 100) * scale;
                var angle:Number = Math.random() * Math.PI * 2.0;

                egg.x = Math.cos(angle) * distance;
                egg.y = Math.sin(angle) * distance;
                egg.rotation = angle + Math.PI / 2.0;
                egg.scale = scale;

                mContainer.addChild(egg);
            }
        }

        private function removeTestObjects(count:int):void
        {
            var numChildren:int = mContainer.numChildren;

            if (count >= numChildren)
                count  = numChildren;

            for (var i:int=0; i<count; ++i)
                putObjectToPool(mContainer.removeChildAt(mContainer.numChildren-1));
        }

        private function getObjectFromPool():DisplayObject
        {
            // we pool mainly to avoid any garbage collection while the benchmark is running

            if (mObjectPool.length == 0)
            {
                var image:Image = new Image(mObjectTexture);
                image.alignPivot();
                return image;
            }
            else
                return mObjectPool.pop();
        }

        private function putObjectToPool(object:DisplayObject):void
        {
            mObjectPool[mObjectPool.length] = object;
        }

        private function benchmarkComplete():void
        {
            mStarted = false;
            mStartButton.visible = true;
            
            var fps:int = Starling.current.nativeStage.frameRate;
            var numChildren:int = mContainer.numChildren;
            var resultString:String = formatString("Result:\n{0} objects\nwith {1} fps",
                                                   numChildren, fps);
            trace(resultString.replace(/\n/g, " "));

            mResultText = new TextField(240, 200, resultString);
            mResultText.fontSize = 30;
            mResultText.x = Constants.CenterX - mResultText.width / 2;
            mResultText.y = Constants.CenterY - mResultText.height / 2;
            
            addChild(mResultText);

            mContainer.scale = 1.0;
            mFrameTimes.length = 0;
            mStatusText.text = "";

            for (var i:int=numChildren-1; i>=0; --i)
                putObjectToPool(mContainer.removeChildAt(i));
        }
    }
}