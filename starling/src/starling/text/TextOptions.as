// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.text
{
    import flash.text.StyleSheet;

    import starling.core.Starling;
    import starling.events.Event;
    import starling.events.EventDispatcher;

    /** Dispatched when any property of the instance changes. */
    [Event(name="change", type="starling.events.Event")]

    /** The TextOptions class contains data that describes how the letters of a text should
     *  be assembled on text composition.
     *
     *  <p>Note that not all properties are supported by all text compositors.</p>
     */
    public class TextOptions extends EventDispatcher
    {
        private var _wordWrap:Boolean;
        private var _autoScale:Boolean;
        private var _autoSize:String;
        private var _isHtmlText:Boolean;
        private var _textureScale:Number;
        private var _textureFormat:String;
        private var _styleSheet:StyleSheet;
        private var _padding:Number;

        /** Creates a new TextOptions instance with the given properties. */
        public function TextOptions(wordWrap:Boolean=true, autoScale:Boolean=false)
        {
            _wordWrap = wordWrap;
            _autoScale = autoScale;
            _autoSize = TextFieldAutoSize.NONE;
            _textureScale = Starling.contentScaleFactor;
            _textureFormat = TextField.defaultTextureFormat;
            _isHtmlText = false;
            _padding = 0.0;
        }

        /** Copies all properties from another TextOptions instance. */
        public function copyFrom(options:TextOptions):void
        {
            _wordWrap = options._wordWrap;
            _autoScale = options._autoScale;
            _autoSize = options._autoSize;
            _isHtmlText = options._isHtmlText;
            _textureScale = options._textureScale;
            _textureFormat = options._textureFormat;
            _styleSheet = options._styleSheet;
            _padding = options._padding;

            dispatchEventWith(Event.CHANGE);
        }

        /** Creates a clone of this instance. */
        public function clone():TextOptions
        {
            var actualClass:Class = Object(this).constructor as Class;
            var clone:TextOptions = new actualClass() as TextOptions;
            clone.copyFrom(this);
            return clone;
        }

        /** Indicates if the text should be wrapped at word boundaries if it does not fit into
         *  the TextField otherwise. @default true */
        public function get wordWrap():Boolean { return _wordWrap; }
        public function set wordWrap(value:Boolean):void
        {
            if (_wordWrap != value)
            {
                _wordWrap = value;
                dispatchEventWith(Event.CHANGE);
            }
        }

        /** Specifies the type of auto-sizing set on the TextField. Custom text compositors may
         *  take this into account, though the basic implementation (done by the TextField itself)
         *  is often sufficient: it passes a very big size to the <code>fillMeshBatch</code>
         *  method and then trims the result to the actually used area. @default none */
        public function get autoSize():String { return _autoSize; }
        public function set autoSize(value:String):void
        {
            if (_autoSize != value)
            {
                _autoSize = value;
                dispatchEventWith(Event.CHANGE);
            }
        }

        /** Indicates whether the font size is automatically reduced if the complete text does
         *  not fit into the TextField. @default false */
        public function get autoScale():Boolean { return _autoScale; }
        public function set autoScale(value:Boolean):void
        {
            if (_autoScale != value)
            {
                _autoScale = value;
                dispatchEventWith(Event.CHANGE);
            }
        }

        /** Indicates if text should be interpreted as HTML code. For a description
         *  of the supported HTML subset, refer to the classic Flash 'TextField' documentation.
         *  Beware: Only supported for TrueType fonts. @default false */
        public function get isHtmlText():Boolean { return _isHtmlText; }
        public function set isHtmlText(value:Boolean):void
        {
            if (_isHtmlText != value)
            {
                _isHtmlText = value;
                dispatchEventWith(Event.CHANGE);
            }
        }

        /** An optional style sheet to be used for HTML text. @default null */
        public function get styleSheet():StyleSheet { return _styleSheet; }
        public function set styleSheet(value:StyleSheet):void
        {
            _styleSheet = value;
            dispatchEventWith(Event.CHANGE);
        }

        /** The scale factor of any textures that are created during text composition.
         *  The optimal value for this property is determined directly before rendering;
         *  manual changes will be ignored.
         *
         *  <p>Note that this property does NOT dispatch <code>CHANGE</code> events.</p>
         */
        public function get textureScale():Number { return _textureScale; }
        public function set textureScale(value:Number):void { _textureScale = value; }

        /** The Context3DTextureFormat of any textures that are created during text composition.
         *  @default Context3DTextureFormat.BGRA_PACKED */
        public function get textureFormat():String { return _textureFormat; }
        public function set textureFormat(value:String):void
        {
            if (_textureFormat != value)
            {
                _textureFormat = value;
                dispatchEventWith(Event.CHANGE);
            }
        }

        /** The padding (in points) that's added to the sides of text that's rendered to a Bitmap.
         *  If your text is truncated on the sides (which may happen if the font returns incorrect
         *  bounds), padding can make up for that. Value must be positive. @default 0.0 */
        public function get padding():Number { return _padding; }
        public function set padding(value:Number):void
        {
            if (value < 0) value = 0;
            if (_padding != value)
            {
                _padding = value;
                dispatchEventWith(Event.CHANGE);
            }
        }
    }
}
