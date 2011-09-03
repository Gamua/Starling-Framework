// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.core
{
    import flash.display.Sprite;
    import flash.display.Stage3D;
    import flash.display3D.Context3D;
    import flash.display3D.Program3D;
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.events.TouchEvent;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.ui.Multitouch;
    import flash.ui.MultitouchInputMode;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;
    import flash.utils.getTimer;
    
    import starling.animation.Juggler;
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.display.Quad;
    import starling.display.Stage;
    import starling.events.ResizeEvent;
    import starling.events.TouchPhase;
    import starling.events.TouchProcessor;
    
    public class Starling
    {
        // members
        
        private var mStage3D:Stage3D;
        private var mStage:Stage; // starling.display.stage!
        private var mRootClass:Class;
        private var mJuggler:Juggler;
        private var mStarted:Boolean;        
        private var mSupport:RenderSupport;
        private var mTouchProcessor:TouchProcessor;
        private var mAntiAliasing:int;
        private var mSimulateMultitouch:Boolean;
        private var mEnableErrorChecking:Boolean;
        private var mLastFrameTimestamp:Number;
        private var mViewPort:Rectangle;
        
        private var mNativeStage:flash.display.Stage;
        private var mNativeOverlay:flash.display.Sprite;
        
        private var mContext:Context3D;
        private var mPrograms:Dictionary;
        
        private static var sCurrent:Starling;
        
        // construction
        
        public function Starling(rootClass:Class, stage:flash.display.Stage, 
                                 viewPort:Rectangle=null, stage3D:Stage3D=null,
                                 renderMode:String="auto") 
        {
            if (stage == null) throw new ArgumentError("Stage must not be null");
            if (rootClass == null) throw new ArgumentError("Root class must not be null");
            if (viewPort == null) viewPort = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
            if (stage3D == null) stage3D = stage.stage3Ds[0];
            
            mRootClass = rootClass;
            mViewPort = viewPort;
            mStage3D = stage3D;
            mStage = new Stage(viewPort.width, viewPort.height, stage.color);
            mNativeStage = stage;
            mTouchProcessor = new TouchProcessor(mStage);
            mJuggler = new Juggler();
            mAntiAliasing = 0;
            mSimulateMultitouch = false;
            mEnableErrorChecking = false;
            mLastFrameTimestamp = getTimer() / 1000.0;
            mPrograms = new Dictionary();
            mSupport = new RenderSupport();
            
            if (sCurrent == null)
                makeCurrent();
            
            // register touch/mouse event handlers            
            var touchEventTypes:Array = Multitouch.supportsTouchEvents ?
                [ TouchEvent.TOUCH_BEGIN, TouchEvent.TOUCH_MOVE, TouchEvent.TOUCH_END ] :
                [ MouseEvent.MOUSE_DOWN, MouseEvent.MOUSE_MOVE, MouseEvent.MOUSE_UP ];            
            
            for each (var touchEventType:String in touchEventTypes)
                stage.addEventListener(touchEventType, onTouch, false, 0, true);
            
            // register other event handlers
            stage.addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);
            stage.addEventListener(KeyboardEvent.KEY_DOWN, onKey, false, 0, true);
            stage.addEventListener(KeyboardEvent.KEY_UP, onKey, false, 0, true);
            stage.addEventListener(Event.RESIZE, onResize, false, 0, true);
            
            mStage3D.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated, false, 0, true);
            mStage3D.addEventListener(ErrorEvent.ERROR, onStage3DError, false, 0, true);
            
            try { mStage3D.requestContext3D(renderMode); } 
            catch (e:Error) { showFatalError("Context3D error: " + e.message); }
        }
        
        public function dispose():void
        {
            for each (var program:Program3D in mPrograms)
                program.dispose();
            
            if (mContext) mContext.dispose();
            if (mTouchProcessor) mTouchProcessor.dispose();
        }
        
        // functions
        
        private function initializeGraphicsAPI():void
        {
            if (mContext) return;            
            
            mContext = mStage3D.context3D;
            mContext.enableErrorChecking = mEnableErrorChecking;
            updateViewPort();
            
            trace("[Starling] Initialization complete.");
            trace("[Starling] Display Driver:" + mContext.driverInfo);
        }
        
        private function initializePrograms():void
        {
            Quad.registerPrograms(this);
            Image.registerPrograms(this);
        }
        
        private function initializeRoot():void
        {
            if (mStage.numChildren > 0) return;
            
            var rootObject:DisplayObject = new mRootClass();
            if (rootObject == null) throw new Error("Invalid root class: " + mRootClass);
            mStage.addChild(rootObject);
        }
        
        private function updateViewPort():void
        {
            if (mContext)
                mContext.configureBackBuffer(mViewPort.width, mViewPort.height, mAntiAliasing, false);
            
            mStage3D.x = mViewPort.x;
            mStage3D.y = mViewPort.y;
        }
        
        private function render():void
        {
            if (mContext == null) return;
            
            var now:Number = getTimer() / 1000.0;
            var passedTime:Number = now - mLastFrameTimestamp;
            mLastFrameTimestamp = now;
            
            mStage.advanceTime(passedTime);
            mJuggler.advanceTime(passedTime);
            mTouchProcessor.advanceTime(passedTime);
            
            mSupport.setOrthographicProjection(mStage.stageWidth, mStage.stageHeight);
            mSupport.setDefaultBlendFactors(true);
            mSupport.clear(mStage.color, 1.0);
            
            mStage.render(mSupport, 1.0);
            mContext.present();
            
            mSupport.resetMatrix();
        }
        
        private function updateNativeOverlay():void
        {
            mNativeOverlay.x = mViewPort.x;
            mNativeOverlay.y = mViewPort.y;
            mNativeOverlay.scaleX = mViewPort.width / mStage.stageWidth;
            mNativeOverlay.scaleY = mViewPort.height / mStage.stageHeight;
            
            // Having a native overlay on top of Stage3D content can cause a performance hit on
            // some environments. For that reason, we add it only to the stage while it's not empty.
            
            var numChildren:int = mNativeOverlay.numChildren;
            var parent:flash.display.DisplayObject = mNativeOverlay.parent;
            
            if (numChildren != 0 && parent == null) 
                mNativeStage.addChild(mNativeOverlay);
            else if (numChildren == 0 && parent)
                mNativeStage.removeChild(mNativeOverlay);
        }
        
        private function showFatalError(message:String):void
        {
            var textField:TextField = new TextField();
            var textFormat:TextFormat = new TextFormat("Verdana", 12, 0xFFFFFF);
            textFormat.align = TextFormatAlign.CENTER;
            textField.defaultTextFormat = textFormat;
            textField.wordWrap = true;
            textField.width = mStage.stageWidth * 0.75;
            textField.autoSize = TextFieldAutoSize.CENTER;
            textField.text = message;
            textField.x = (mStage.stageWidth - textField.width) / 2;
            textField.y = (mStage.stageHeight - textField.height) / 2;
            textField.background = true;
            textField.backgroundColor = 0x440000;
            nativeOverlay.addChild(textField);
        }
        
        public function makeCurrent():void
        {
            sCurrent = this;
        }
        
        public function start():void { mStarted = true; }
        public function stop():void { mStarted = false; }
        
        // event handlers
        
        private function onStage3DError(event:ErrorEvent):void
        {
            showFatalError("This application is not correctly embedded (wrong wmode value)");
        }
        
        private function onContextCreated(event:Event):void
        {            
            initializeGraphicsAPI();
            initializePrograms();
            initializeRoot();
            
            mTouchProcessor.simulateMultitouch = mSimulateMultitouch;
        }
        
        private function onEnterFrame(event:Event):void
        {
            if (mNativeOverlay) updateNativeOverlay();
            if (mStarted) render();           
        }
        
        private function onKey(event:KeyboardEvent):void
        {
            mStage.dispatchEvent(new starling.events.KeyboardEvent(
                event.type, event.charCode, event.keyCode, event.keyLocation, 
                event.ctrlKey, event.altKey, event.shiftKey));
        }
        
        private function onResize(event:flash.events.Event):void
        {
            var stage:flash.display.Stage = event.target as flash.display.Stage; 
            mStage.dispatchEvent(new ResizeEvent(Event.RESIZE, stage.stageWidth, stage.stageHeight));
        }

        private function onTouch(event:Event):void
        {
            var position:Point;
            var phase:String;
            var touchID:int;
            
            if (event is MouseEvent)
            {
                var mouseEvent:MouseEvent = event as MouseEvent;
                position = convertPosition(new Point(mouseEvent.stageX, mouseEvent.stageY));
                phase = getPhaseFromMouseEvent(mouseEvent);
                touchID = 0;
            }
            else
            {
                var touchEvent:TouchEvent = event as TouchEvent;
                position = convertPosition(new Point(touchEvent.stageX, touchEvent.stageY));
                phase = getPhaseFromTouchEvent(touchEvent);
                touchID = touchEvent.touchPointID;
            }
            
            mTouchProcessor.enqueue(touchID, phase, position.x, position.y);
            
            function convertPosition(globalPos:Point):Point
            {
                return new Point(
                    (globalPos.x - mViewPort.x) + (mViewPort.width  / mStage.stageWidth),
                    (globalPos.y - mViewPort.y) + (mViewPort.height / mStage.stageHeight));
            }
            
            function getPhaseFromMouseEvent(event:MouseEvent):String
            {
                switch (event.type)
                {
                    case MouseEvent.MOUSE_DOWN: return TouchPhase.BEGAN; break;
                    case MouseEvent.MOUSE_UP:   return TouchPhase.ENDED; break;
                    case MouseEvent.MOUSE_MOVE: 
                        return mouseEvent.buttonDown ? TouchPhase.MOVED : TouchPhase.HOVER; 
                        break;
                    default: return null;
                }
            }
             
            function getPhaseFromTouchEvent(event:TouchEvent):String
            {
                switch (event.type)
                {
                    case TouchEvent.TOUCH_BEGIN: return TouchPhase.BEGAN; break;
                    case TouchEvent.TOUCH_MOVE:  return TouchPhase.MOVED; break;
                    case TouchEvent.TOUCH_END:   return TouchPhase.ENDED; break;
                    default: return null;
                }
            }
        }
        
        // program management
        
        public function registerProgram(name:String, vertexProgram:ByteArray, fragmentProgram:ByteArray):void
        {
            if (mPrograms.hasOwnProperty(name))
                throw new Error("Another program with this name is already registered");
            
            var program:Program3D = mContext.createProgram();
            program.upload(vertexProgram, fragmentProgram);            
            mPrograms[name] = program;
        }
        
        public function deleteProgram(name:String):void
        {
            var program:Program3D = getProgram(name);            
            if (program)
            {                
                program.dispose();
                delete mPrograms[name];
            }
        }
        
        public function getProgram(name:String):Program3D
        {
            return mPrograms[name] as Program3D;
        }
        
        // properties
        
        public function get isStarted():Boolean { return mStarted; }
        
        public function get juggler():Juggler { return mJuggler; }
        public function get context():Context3D { return mContext; }
        
        public function get simulateMultitouch():Boolean { return mSimulateMultitouch; }
        public function set simulateMultitouch(value:Boolean):void
        {
            mSimulateMultitouch = value;
            if (mContext) mTouchProcessor.simulateMultitouch = value;
        }
        
        public function get enableErrorChecking():Boolean { return mEnableErrorChecking; }
        public function set enableErrorChecking(value:Boolean):void 
        { 
            mEnableErrorChecking = value;
            if (mContext) mContext.enableErrorChecking = value; 
        }
        
        public function get antiAliasing():int { return mAntiAliasing; }
        public function set antiAliasing(value:int):void
        {
            mAntiAliasing = value;
            updateViewPort();
        }
        
        public function get viewPort():Rectangle { return mViewPort.clone(); }
        public function set viewPort(value:Rectangle):void
        {
            mViewPort = value.clone();
            updateViewPort();
        }
        
        public function get nativeOverlay():Sprite
        {
            if (mNativeOverlay == null)
            {
                mNativeOverlay = new Sprite();
                mNativeStage.addChild(mNativeOverlay);
                updateNativeOverlay();
            }
            
            return mNativeOverlay;
        }
        
        // static properties
        
        public static function get current():Starling { return sCurrent; }
        
        public static function get context():Context3D { return sCurrent.context; }
        public static function get juggler():Juggler { return sCurrent.juggler; }
        
        public static function get multitouchEnabled():Boolean 
        { 
            return Multitouch.inputMode == MultitouchInputMode.TOUCH_POINT;
        }
        
        public static function set multitouchEnabled(value:Boolean):void
        {            
            Multitouch.inputMode = value ? MultitouchInputMode.TOUCH_POINT :
                                           MultitouchInputMode.NONE;
        }
    }
}