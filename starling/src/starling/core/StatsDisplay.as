// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.core
{
    import flash.system.System;

    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.events.EnterFrameEvent;
    import starling.events.Event;
    import starling.rendering.Painter;
    import starling.styles.MeshStyle;
    import starling.text.BitmapFont;
    import starling.text.TextField;
    import starling.text.TextFormat;
    import starling.utils.Align;

    /** A small, lightweight box that displays the current framerate, memory consumption and
     *  the number of draw calls per frame. The display is updated automatically once per frame. */
    internal class StatsDisplay extends Sprite
    {
        private const UPDATE_INTERVAL:Number = 0.5;
        
        private var _background:Quad;
        private var _textField:TextField;
        
        private var _frameCount:int = 0;
        private var _totalTime:Number = 0;
        
        private var _fps:Number = 0;
        private var _memory:Number = 0;
        private var _drawCount:int = 0;
        private var _skipCount:int = 0;
        
        /** Creates a new Statistics Box. */
        public function StatsDisplay()
        {
            var format:TextFormat = new TextFormat(BitmapFont.MINI, BitmapFont.NATIVE_SIZE,
                    0xffffff, Align.LEFT, Align.TOP);

            _background = new Quad(50, 25, 0x0);
            _textField = new TextField(48, 25, "", format);
            _textField.x = 2;

            // make sure that rendering takes 2 draw calls
            if (_background.style.type != MeshStyle) _background.style = new MeshStyle();
            if ( _textField.style.type != MeshStyle) _textField.style  = new MeshStyle();

            addChild(_background);
            addChild(_textField);
            
            addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
        }
        
        private function onAddedToStage():void
        {
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
            _totalTime = _frameCount = _skipCount = 0;
            update();
        }
        
        private function onRemovedFromStage():void
        {
            removeEventListener(Event.ENTER_FRAME, onEnterFrame);
        }
        
        private function onEnterFrame(event:EnterFrameEvent):void
        {
            _totalTime += event.passedTime;
            _frameCount++;
            
            if (_totalTime > UPDATE_INTERVAL)
            {
                update();
                _frameCount = _skipCount = _totalTime = 0;
            }
        }
        
        /** Updates the displayed values. */
        public function update():void
        {
            _fps = _totalTime > 0 ? _frameCount / _totalTime : 0;
            _memory = System.totalMemory * 0.000000954; // 1.0 / (1024*1024) to convert to MB
            _background.color = _skipCount > _frameCount / 2 ? 0x003F00 : 0x0;
            _textField.text = "FPS: " + _fps.toFixed(_fps < 100 ? 1 : 0) +
                            "\nMEM: " + _memory.toFixed(_memory < 100 ? 1 : 0) +
                            "\nDRW: " + (_totalTime > 0 ? _drawCount-2 : _drawCount); // ignore self
        }

        /** Call this once in every frame that can skip rendering because nothing changed. */
        public function markFrameAsSkipped():void
        {
            _skipCount += 1;
        }
        
        public override function render(painter:Painter):void
        {
            // By calling 'finishQuadBatch' and 'excludeFromCache', we can make sure that the stats
            // display is always rendered with exactly two draw calls. That is taken into account
            // when showing the drawCount value (see 'ignore self' comment above)

            painter.excludeFromCache(this);
            painter.finishMeshBatch();
            super.render(painter);
        }
        
        /** The number of Stage3D draw calls per second. */
        public function get drawCount():int { return _drawCount; }
        public function set drawCount(value:int):void { _drawCount = value; }
        
        /** The current frames per second (updated twice per second). */
        public function get fps():Number { return _fps; }
        public function set fps(value:Number):void { _fps = value; }
        
        /** The currently required system memory in MB. */
        public function get memory():Number { return _memory; }
        public function set memory(value:Number):void { _memory = value; }
    }
}