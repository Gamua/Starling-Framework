// =================================================================================================
//
//	Starling Framework
//	Copyright 2012 Gamua OG. All Rights Reserved.
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
    import flash.errors.IllegalOperationError;
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.events.TouchEvent;
    import flash.geom.Rectangle;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.ui.Mouse;
    import flash.ui.Multitouch;
    import flash.ui.MultitouchInputMode;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;
    import flash.utils.getTimer;
    
    import starling.animation.Juggler;
    import starling.display.DisplayObject;
    import starling.display.Stage;
    import starling.events.EventDispatcher;
    import starling.events.ResizeEvent;
    import starling.events.TouchPhase;
    
    /** Dispatched when a new render context is created. */
    [Event(name="context3DCreate", type="starling.events.Event")]
    
    /** Dispatched when the root class has been created. */
    [Event(name="rootCreated", type="starling.events.Event")]
    
    /** The Starling class represents the core of the Starling framework.
     *
     *  <p>The Starling framework makes it possible to create 2D applications and games that make
     *  use of the Stage3D architecture introduced in Flash Player 11. It implements a display tree
     *  system that is very similar to that of conventional Flash, while leveraging modern GPUs
     *  to speed up rendering.</p>
     *  
     *  <p>The Starling class represents the link between the conventional Flash display tree and
     *  the Starling display tree. To create a Starling-powered application, you have to create
     *  an instance of the Starling class:</p>
     *  
     *  <pre>var starling:Starling = new Starling(Game, stage);</pre>
     *  
     *  <p>The first parameter has to be a Starling display object class, e.g. a subclass of 
     *  <code>starling.display.Sprite</code>. In the sample above, the class "Game" is the
     *  application root. An instance of "Game" will be created as soon as Starling is initialized.
     *  The second parameter is the conventional (Flash) stage object. Per default, Starling will
     *  display its contents directly below the stage.</p>
     *  
     *  <p>It is recommended to store the Starling instance as a member variable, to make sure
     *  that the Garbage Collector does not destroy it. After creating the Starling object, you 
     *  have to start it up like this:</p>
     * 
     *  <pre>starling.start();</pre>
     * 
     *  <p>It will now render the contents of the "Game" class in the frame rate that is set up for
     *  the application (as defined in the Flash stage).</p> 
     *  
     *  <strong>Accessing the Starling object</strong>
     * 
     *  <p>From within your application, you can access the current Starling object anytime
     *  through the static method <code>Starling.current</code>. It will return the active Starling
     *  instance (most applications will only have one Starling object, anyway).</p> 
     * 
     *  <strong>Viewport</strong>
     * 
     *  <p>The area the Starling content is rendered into is, per default, the complete size of the 
     *  stage. You can, however, use the "viewPort" property to change it. This can be  useful 
     *  when you want to render only into a part of the screen, or if the player size changes. For
     *  the latter, you can listen to the RESIZE-event dispatched by the Starling
     *  stage.</p>
     * 
     *  <strong>Native overlay</strong>
     *  
     *  <p>Sometimes you will want to display native Flash content on top of Starling. That's what the
     *  <code>nativeOverlay</code> property is for. It returns a Flash Sprite lying directly
     *  on top of the Starling content. You can add conventional Flash objects to that overlay.</p>
     *  
     *  <p>Beware, though, that conventional Flash content on top of 3D content can lead to
     *  performance penalties on some (mobile) platforms. For that reason, always remove all child
     *  objects from the overlay when you don't need them any longer. Starling will remove the 
     *  overlay from the display list when it's empty.</p>
     *  
     *  <strong>Multitouch</strong>
     *  
     *  <p>Starling supports multitouch input on devices that provide it. During development, 
     *  where most of us are working with a conventional mouse and keyboard, Starling can simulate 
     *  multitouch events with the help of the "Shift" and "Ctrl" (Mac: "Cmd") keys. Activate
     *  this feature by enabling the <code>simulateMultitouch</code> property.</p>
     *  
     *  <strong>Handling a lost render context</strong>
     *  
     *  <p>On some operating systems and under certain conditions (e.g. returning from system
     *  sleep), Starling's stage3D render context may be lost. Starling can recover from a lost
     *  context if the class property "handleLostContext" is set to "true". Keep in mind, however, 
     *  that this comes at the price of increased memory consumption; Starling will cache textures 
     *  in RAM to be able to restore them when the context is lost.</p> 
     *  
     *  <p>In case you want to react to a context loss, Starling dispatches an event with
     *  the type "Event.CONTEXT3D_CREATE" when the context is restored. You can recreate any 
     *  invalid resources in a corresponding event listener.</p>
	 * 
     */ 
    public class Starling extends EventDispatcher
    {
        /** The version of the Starling framework. */
        public static const VERSION:String = "1.1";
        
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
        private var mLeftMouseDown:Boolean;
        private var mStatsDisplay:StatsDisplay;
        
        private var mNativeStage:flash.display.Stage;
        private var mNativeOverlay:flash.display.Sprite;
        
        private var mContext:Context3D;
        private var mPrograms:Dictionary;
        
        private static var sCurrent:Starling;
        private static var sHandleLostContext:Boolean;
        
        // construction
        
        /** Creates a new Starling instance. 
         *  @param rootClass  A subclass of a Starling display object. It will be created as soon as
         *                    initialization is finished and will become the first child of the
         *                    Starling stage.
         *  @param stage      The Flash (2D) stage.
         *  @param viewPort   A rectangle describing the area into which the content will be 
         *                    rendered. @default stage size
         *  @param stage3D    The Stage3D object into which the content will be rendered.
         *                    @default the first available Stage3D.
         *  @param renderMode Use this parameter to force "software" rendering. 
         */
        public function Starling(rootClass:Class, stage:flash.display.Stage, 
                                 viewPort:Rectangle=null, stage3D:Stage3D=null,
                                 renderMode:String="auto") 
        {
            if (stage == null) throw new ArgumentError("Stage must not be null");
            if (rootClass == null) throw new ArgumentError("Root class must not be null");
            if (viewPort == null) viewPort = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
            if (stage3D == null) stage3D = stage.stage3Ds[0];
            
            makeCurrent();
            
            mRootClass = rootClass;
            mViewPort = viewPort;
            mStage3D = stage3D;
            mStage = new Stage(viewPort.width, viewPort.height, stage.color);
            mNativeStage = stage;
            mNativeOverlay = new Sprite();
            mTouchProcessor = new TouchProcessor(mStage);
            mJuggler = new Juggler();
            mAntiAliasing = 0;
            mSimulateMultitouch = false;
            mEnableErrorChecking = false;
            mLastFrameTimestamp = getTimer() / 1000.0;
            mPrograms = new Dictionary();
            mSupport  = new RenderSupport();
            
            // register touch/mouse event handlers            
            for each (var touchEventType:String in touchEventTypes)
                stage.addEventListener(touchEventType, onTouch, false, 0, true);
            
            // register other event handlers
            stage.addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);
            stage.addEventListener(KeyboardEvent.KEY_DOWN, onKey, false, 0, true);
            stage.addEventListener(KeyboardEvent.KEY_UP, onKey, false, 0, true);
            stage.addEventListener(Event.RESIZE, onResize, false, 0, true);
            
            mStage3D.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated, false, 1, true);
            mStage3D.addEventListener(ErrorEvent.ERROR, onStage3DError, false, 1, true);
            
            try { mStage3D.requestContext3D(renderMode); } 
            catch (e:Error) { showFatalError("Context3D error: " + e.message); }
        }
        
        /** Disposes Shader programs and render context. */
        public function dispose():void
        {
            mNativeStage.removeEventListener(Event.ENTER_FRAME, onEnterFrame, false);
            mNativeStage.removeEventListener(KeyboardEvent.KEY_DOWN, onKey, false);
            mNativeStage.removeEventListener(KeyboardEvent.KEY_UP, onKey, false);
            mNativeStage.removeEventListener(Event.RESIZE, onResize, false);
            
            mStage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated, false);
            mStage3D.removeEventListener(ErrorEvent.ERROR, onStage3DError, false);
            
            for each (var touchEventType:String in touchEventTypes)
                mNativeStage.removeEventListener(touchEventType, onTouch, false);
            
            for each (var program:Program3D in mPrograms)
                program.dispose();
            
            if (mContext) mContext.dispose();
            if (mTouchProcessor) mTouchProcessor.dispose();
            if (mSupport) mSupport.dispose();
            if (sCurrent == this) sCurrent = null;
        }
        
        // functions
        
        private function initializeGraphicsAPI():void
        {
            mContext = mStage3D.context3D;
            mContext.enableErrorChecking = mEnableErrorChecking;
            mPrograms = new Dictionary();
            
            updateViewPort();
            
            trace("[Starling] Initialization complete.");
            trace("[Starling] Display Driver:" + mContext.driverInfo);
        }
        
        private function initializeRoot():void
        {
            if (mStage.numChildren > 0) return;
            
            var rootObject:DisplayObject = new mRootClass();
            if (rootObject == null) throw new Error("Invalid root class: " + mRootClass);
            mStage.addChildAt(rootObject, 0);
        }
        
        private function updateViewPort():void
        {
            if (mContext)
                mContext.configureBackBuffer(mViewPort.width, mViewPort.height, mAntiAliasing, false);
            
            mStage3D.x = mViewPort.x;
            mStage3D.y = mViewPort.y;
        }
        
        private function advanceTime():void
        {
            var now:Number = getTimer() / 1000.0;
            var passedTime:Number = now - mLastFrameTimestamp;
            mLastFrameTimestamp = now;
            
            mStage.advanceTime(passedTime);
            mJuggler.advanceTime(passedTime);
            mTouchProcessor.advanceTime(passedTime);
        }
        
        private function render():void
        {
            if (mContext == null || mContext.driverInfo == "Disposed")
                return;
            
            RenderSupport.clear(mStage.color, 1.0);
            mSupport.setOrthographicProjection(mStage.stageWidth, mStage.stageHeight);
            
            mStage.render(mSupport, 1.0);

            mSupport.finishQuadBatch();
            mSupport.nextFrame();
            
            mContext.present();
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
        
        /** Make this Starling instance the <code>current</code> one. */
        public function makeCurrent():void
        {
            sCurrent = this;
        }
        
        /** Starts rendering and dispatching of <code>ENTER_FRAME</code> events. */
        public function start():void 
        { 
            mStarted = true; 
            mLastFrameTimestamp = getTimer() / 1000.0; 
        }
        
        /** Stops rendering. */
        public function stop():void 
        { 
            mStarted = false; 
        }
        
        // event handlers
        
        private function onStage3DError(event:ErrorEvent):void
        {
            showFatalError("This application is not correctly embedded (wrong wmode value)");
        }
        
        private function onContextCreated(event:Event):void
        {
            if (!Starling.handleLostContext && mContext)
            {
                showFatalError("Fatal error: The application lost the device context!");
                stop();
                return;
            }
            
            makeCurrent();
            
            initializeGraphicsAPI();
            dispatchEvent(new starling.events.Event(starling.events.Event.CONTEXT3D_CREATE));
            
            initializeRoot();
            dispatchEvent(new starling.events.Event(starling.events.Event.ROOT_CREATED));
            
            mTouchProcessor.simulateMultitouch = mSimulateMultitouch;
            mLastFrameTimestamp = getTimer() / 1000.0;
        }
        
        private function onEnterFrame(event:Event):void
        {
            makeCurrent();
            updateNativeOverlay();
            
            // When there's a native overlay, we have to call 'render' even if Starling is 
            // paused -- because the native stage is only updated on calls to 'context.present()'.
            
            if (mStarted) advanceTime();
            if (mStarted || mNativeOverlay.parent) render();
        }
        
        private function onKey(event:KeyboardEvent):void
        {
            if (!mStarted) return;
            
            makeCurrent();
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
            if (!mStarted) return;
            
            var globalX:Number;
            var globalY:Number;
            var touchID:int;
            var phase:String;
            
            // figure out general touch properties
            if (event is MouseEvent)
            {
                var mouseEvent:MouseEvent = event as MouseEvent;
                globalX = mouseEvent.stageX;
                globalY = mouseEvent.stageY;
                touchID = 0;
                
                // MouseEvent.buttonDown returns true for both left and right button (AIR supports
                // the right mouse button). We only want to react on the left button for now,
                // so we have to save the state for the left button manually.
                if (event.type == MouseEvent.MOUSE_DOWN)    mLeftMouseDown = true;
                else if (event.type == MouseEvent.MOUSE_UP) mLeftMouseDown = false;
            }
            else
            {
                var touchEvent:TouchEvent = event as TouchEvent;
                globalX = touchEvent.stageX;
                globalY = touchEvent.stageY;
                touchID = touchEvent.touchPointID;
            }
            
            // figure out touch phase
            switch (event.type)
            {
                case TouchEvent.TOUCH_BEGIN: phase = TouchPhase.BEGAN; break;
                case TouchEvent.TOUCH_MOVE:  phase = TouchPhase.MOVED; break;
                case TouchEvent.TOUCH_END:   phase = TouchPhase.ENDED; break;
                case MouseEvent.MOUSE_DOWN:  phase = TouchPhase.BEGAN; break;
                case MouseEvent.MOUSE_UP:    phase = TouchPhase.ENDED; break;
                case MouseEvent.MOUSE_MOVE: 
                    phase = (mLeftMouseDown ? TouchPhase.MOVED : TouchPhase.HOVER); break;
            }
            
            // move position into viewport bounds
            globalX = mStage.stageWidth  * (globalX - mViewPort.x) / mViewPort.width;
            globalY = mStage.stageHeight * (globalY - mViewPort.y) / mViewPort.height;
            
            // enqueue touch in touch processor
            mTouchProcessor.enqueue(touchID, phase, globalX, globalY);
        }
        
        private function get touchEventTypes():Array
        {
            return Mouse.supportsCursor || !multitouchEnabled ?
                [ MouseEvent.MOUSE_DOWN,  MouseEvent.MOUSE_MOVE, MouseEvent.MOUSE_UP ] :
                [ TouchEvent.TOUCH_BEGIN, TouchEvent.TOUCH_MOVE, TouchEvent.TOUCH_END ];  
        }
        
        // program management
        
        /** Registers a vertex- and fragment-program under a certain name. */
        public function registerProgram(name:String, vertexProgram:ByteArray, fragmentProgram:ByteArray):void
        {
            if (name in mPrograms)
                throw new Error("Another program with this name is already registered");
            
            var program:Program3D = mContext.createProgram();
            program.upload(vertexProgram, fragmentProgram);            
            mPrograms[name] = program;
        }
        
        /** Deletes the vertex- and fragment-programs of a certain name. */
        public function deleteProgram(name:String):void
        {
            var program:Program3D = getProgram(name);            
            if (program)
            {                
                program.dispose();
                delete mPrograms[name];
            }
        }
        
        /** Returns the vertex- and fragment-programs registered under a certain name. */
        public function getProgram(name:String):Program3D
        {
            return mPrograms[name] as Program3D;
        }
        
        /** Indicates if a set of vertex- and fragment-programs is registered under a certain name. */
        public function hasProgram(name:String):Boolean
        {
            return name in mPrograms;
        }
        
        // properties
        
        /** Indicates if this Starling instance is started. */
        public function get isStarted():Boolean { return mStarted; }
        
        /** The default juggler of this instance. Will be advanced once per frame. */
        public function get juggler():Juggler { return mJuggler; }
        
        /** The render context of this instance. */
        public function get context():Context3D { return mContext; }
        
        /** Indicates if multitouch simulation with "Shift" and "Ctrl"/"Cmd"-keys is enabled. 
         *  @default false */
        public function get simulateMultitouch():Boolean { return mSimulateMultitouch; }
        public function set simulateMultitouch(value:Boolean):void
        {
            mSimulateMultitouch = value;
            if (mContext) mTouchProcessor.simulateMultitouch = value;
        }
        
        /** Indicates if Stage3D render methods will report errors. Activate only when needed,
         *  as this has a negative impact on performance. @default false */
        public function get enableErrorChecking():Boolean { return mEnableErrorChecking; }
        public function set enableErrorChecking(value:Boolean):void 
        { 
            mEnableErrorChecking = value;
            if (mContext) mContext.enableErrorChecking = value; 
        }
        
        /** The antialiasing level. 0 - no antialasing, 16 - maximum antialiasing. @default 0 */
        public function get antiAliasing():int { return mAntiAliasing; }
        public function set antiAliasing(value:int):void
        {
            mAntiAliasing = value;
            updateViewPort();
        }
        
        /** The viewport into which Starling contents will be rendered. */
        public function get viewPort():Rectangle { return mViewPort.clone(); }
        public function set viewPort(value:Rectangle):void
        {
            mViewPort = value.clone();
            updateViewPort();
        }
        
        /** The ratio between viewPort width and stage width. Useful for choosing a different
         *  set of textures depending on the display resolution. */
        public function get contentScaleFactor():Number
        {
            return mViewPort.width / mStage.stageWidth;
        }
        
        /** A Flash Sprite placed directly on top of the Starling content. Use it to display native
         *  Flash components. */ 
        public function get nativeOverlay():Sprite { return mNativeOverlay; }
        
        /** Indicates if a small statistics box (with FPS and memory usage) is displayed. */
        public function get showStats():Boolean { return mStatsDisplay != null; }
        public function set showStats(value:Boolean):void
        {
            if (mContext == null)
            {
                // Starling is not yet ready - we postpone this until it's initialized.
                addEventListener(starling.events.Event.ROOT_CREATED, onRootCreated);
            }
            else
            {
                if (value && mStatsDisplay == null)
                {
                    mStatsDisplay = new StatsDisplay();
                    mStatsDisplay.touchable = false;
                    mStatsDisplay.scaleX = mStatsDisplay.scaleY = 1.0 / contentScaleFactor;
                    mStage.addChild(mStatsDisplay);
                }
                else if (!value && mStatsDisplay)
                {
                    mStatsDisplay.removeFromParent(true);
                    mStatsDisplay = null;
                }
            }
            
            function onRootCreated(event:Object):void
            {
                showStats = value;
                removeEventListener(starling.events.Event.ROOT_CREATED, onRootCreated);
            }
        }
        
        /** The Starling stage object, which is the root of the display tree that is rendered. */
        public function get stage():Stage
        {
            return mStage;
        }

        /** The Flash Stage3D object Starling renders into. */
        public function get stage3D():Stage3D
        {
            return mStage3D;
        }
        
        /** The Flash (2D) stage object Starling renders beneath. */
        public function get nativeStage():flash.display.Stage
        {
            return mNativeStage;
        }
        
        // static properties
        
        /** The currently active Starling instance. */
        public static function get current():Starling { return sCurrent; }
        
        /** The render context of the currently active Starling instance. */
        public static function get context():Context3D { return sCurrent ? sCurrent.context : null; }
        
        /** The default juggler of the currently active Starling instance. */
        public static function get juggler():Juggler { return sCurrent ? sCurrent.juggler : null; }
        
        /** The contentScaleFactor of the currently active Starling instance. */
        public static function get contentScaleFactor():Number 
        {
            return sCurrent ? sCurrent.contentScaleFactor : 1.0;
        }
        
        /** Indicates if multitouch input should be supported. */
        public static function get multitouchEnabled():Boolean 
        { 
            return Multitouch.inputMode == MultitouchInputMode.TOUCH_POINT;
        }
        
        public static function set multitouchEnabled(value:Boolean):void
        {            
            Multitouch.inputMode = value ? MultitouchInputMode.TOUCH_POINT :
                                           MultitouchInputMode.NONE;
        }
        
        /** Indicates if Starling should automatically recover from a lost device context.
         *  On some systems, an upcoming screensaver or entering sleep mode may invalidate the
         *  render context. This setting indicates if Starling should recover from such incidents.
         *  Beware that this has a huge impact on memory consumption! @default false */
        public static function get handleLostContext():Boolean { return sHandleLostContext; }
        public static function set handleLostContext(value:Boolean):void 
        {
            if (sCurrent != null) throw new IllegalOperationError(
                "Setting must be changed before Starling instance is created");
            else
                sHandleLostContext = value;
        }
    }
}