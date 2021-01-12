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
    import flash.geom.Rectangle;
    import flash.system.System;

    import starling.display.DisplayObject;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.events.EnterFrameEvent;
    import starling.events.Event;
    import starling.rendering.Painter;
    import starling.styles.MeshStyle;
    import starling.text.BitmapFont;
    import starling.text.TextField;
    import starling.utils.Align;

    /** A small, lightweight box that displays the current framerate, memory consumption and
     *  the number of draw calls per frame. The display is updated automatically once per frame. */
    internal class StatsDisplay extends Sprite
    {
        private static const UPDATE_INTERVAL:Number = 0.5;
        private static const B_TO_MB:Number = 1.0 / (1024 * 1024); // convert from bytes to MB

        private var _background:Quad;
        private var _labels:TextField;
        private var _values:TextField;

        private var _frameCount:int = 0;
        private var _totalTime:Number = 0;

        private var _fps:Number = 0;
        private var _memory:Number = 0;
        private var _gpuMemory:Number = 0;
        private var _drawCount:int = 0;
        private var _skipCount:int = 0;
        private var _showSkipped:Boolean = false;

        /** Creates a new Statistics Box. */
        public function StatsDisplay()
        {
            const fontName:String = BitmapFont.MINI;
            const fontSize:Number = BitmapFont.NATIVE_SIZE;
            const fontColor:uint  = 0xffffff;
            const width:Number    = 90;
            const height:Number   = 45;

            _labels = new TextField(width, height);
            _labels.format.setTo(fontName, fontSize, fontColor, Align.LEFT, Align.TOP);
            _labels.batchable = true;
            _labels.x = 2;

            _values = new TextField(width - 1, height, "");
            _values.format.setTo(fontName, fontSize, fontColor, Align.RIGHT, Align.TOP);
            _values.batchable = true;

            _background = new Quad(width, height, 0x0);
            updateLabels();

            // make sure that rendering takes 2 draw calls
            if (_background.style.type != MeshStyle) _background.style = new MeshStyle();
            if (_labels.style.type     != MeshStyle) _labels.style     = new MeshStyle();
            if (_values.style.type     != MeshStyle) _values.style     = new MeshStyle();

            addChild(_background);
            addChild(_labels);
            addChild(_values);

            addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
        }

        private function onAddedToStage():void
        {
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
            Starling.current.addEventListener(Event.SKIP_FRAME, onSkipFrame);
            _totalTime = _frameCount = _skipCount = 0;
            update();
        }

        private function onRemovedFromStage():void
        {
            removeEventListener(Event.ENTER_FRAME, onEnterFrame);
            Starling.current.removeEventListener(Event.SKIP_FRAME, onSkipFrame);
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

        private function onSkipFrame():void
        {
            _skipCount += 1;
        }

        /** Updates the displayed values. */
        public function update():void
        {
            _background.color = _skipCount > _frameCount / 2 ? 0x003F00 : 0x0;
            _fps = _totalTime > 0 ? _frameCount / _totalTime : 0;
            _memory = System.totalMemory * B_TO_MB;
            _gpuMemory = supportsGpuMem ? Starling.context['totalGPUMemory'] * B_TO_MB : -1;

            var skippedPerSec:Number = _totalTime > 0 ? _skipCount / _totalTime : 0;
            var skippedText:String = _showSkipped ? skippedPerSec.toFixed(skippedPerSec < 100 ? 1 : 0) : "";
            var fpsText:String = _fps.toFixed(_fps < 100 ? 1 : 0);
            var memText:String = _memory.toFixed(_memory < 100 ? 1 : 0);
            var gpuMemText:String = _gpuMemory.toFixed(_gpuMemory < 100 ? 1 : 0);
            var drwText:String = (_totalTime > 0 ? _drawCount-2 : _drawCount).toString(); // ignore self

            _values.text = fpsText + "\n" + (_showSkipped ? skippedText + "\n" : "") +
                memText + "\n" + (_gpuMemory >= 0 ? gpuMemText + "\n" : "") + drwText;
        }

        private function updateLabels():void
        {
            var labels:Array = ["frames/sec:"];
            if (_showSkipped) labels.insertAt(labels.length, "skipped/sec:");
            labels.insertAt(labels.length, "std memory:");
            if (supportsGpuMem) labels.insertAt(labels.length, "gpu memory:");
            labels.insertAt(labels.length, "draw calls:");

            _labels.text = labels.join("\n");
            _background.height = _labels.textBounds.height + 4;
        }

        /** @private */
        public override function render(painter:Painter):void
        {
            // By calling 'finishQuadBatch' and 'excludeFromCache', we can make sure that the stats
            // display is always rendered with exactly two draw calls. That is taken into account
            // when showing the drawCount value (see 'ignore self' comment above)

            painter.excludeFromCache(this);
            painter.finishMeshBatch();
            super.render(painter);
        }

        /** @private */
        override public function getBounds(targetSpace:DisplayObject, out:Rectangle = null):Rectangle
        {
            return _background.getBounds(targetSpace, out);
        }

        /** Indicates if the current runtime supports the 'totalGPUMemory' API. */
        private function get supportsGpuMem():Boolean
        {
            return "totalGPUMemory" in Starling.context;
        }
        
        /** The number of Stage3D draw calls per second. */
        public function get drawCount():int { return _drawCount; }
        public function set drawCount(value:int):void { _drawCount = value; }
        
        /** The current frames per second (updated twice per second). */
        public function get fps():Number { return _fps; }
        public function set fps(value:Number):void { _fps = value; }
        
        /** The currently used system memory in MB. */
        public function get memory():Number { return _memory; }
        public function set memory(value:Number):void { _memory = value; }

        /** The currently used graphics memory in MB. */
        public function get gpuMemory():Number { return _gpuMemory; }
        public function set gpuMemory(value:Number):void { _gpuMemory = value; }

        /** Indicates if the number of skipped frames should be shown. */
        public function get showSkipped():Boolean { return _showSkipped; }
        public function set showSkipped(value:Boolean):void
        {
            _showSkipped = value;
            updateLabels();
            update();
        }
    }
}