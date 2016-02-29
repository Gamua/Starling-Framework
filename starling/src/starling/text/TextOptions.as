/**
 * Created by redge on 16.12.15.
 */
package starling.text
{
    import flash.display3D.Context3DTextureFormat;

    import starling.core.Starling;

    /** The TextOptions class contains data that describes how the letters of a text should
     *  be assembled on text composition.
     *
     *  <p>Note that not all properties are supported by all text compositors.</p>
     */
    public class TextOptions
    {
        private var _wordWrap:Boolean;
        private var _autoScale:Boolean;
        private var _isHtmlText:Boolean;
        private var _textureScale:Number;
        private var _textureFormat:String;

        /** Creates a new TextOptions instance with the given properties. */
        public function TextOptions(wordWrap:Boolean=true, autoScale:Boolean=false)
        {
            _wordWrap = wordWrap;
            _autoScale = autoScale;
            _textureScale = Starling.contentScaleFactor;
            _textureFormat = Context3DTextureFormat.BGR_PACKED;
            _isHtmlText = false;
        }

        /** Copies all properties from another TextOptions instance. */
        public function copyFrom(options:TextOptions):void
        {
            _wordWrap = options._wordWrap;
            _autoScale = options._autoScale;
            _isHtmlText = options._isHtmlText;
            _textureScale = options._textureScale;
            _textureFormat = options._textureFormat;
        }

        /** Creates a clone of this instance. */
        public function clone():TextOptions
        {
            var clone:TextOptions = new TextOptions();
            clone.copyFrom(this);
            return clone;
        }

        /** Indicates if the text should be wrapped at word boundaries if it does not fit into
         *  the TextField otherwise. @default true */
        public function get wordWrap():Boolean { return _wordWrap; }
        public function set wordWrap(value:Boolean):void { _wordWrap = value; }

        /** Indicates whether the font size is automatically reduced if the complete text does
         *  not fit into the TextField. @default false */
        public function get autoScale():Boolean { return _autoScale; }
        public function set autoScale(value:Boolean):void { _autoScale = value; }

        /** Indicates if text should be interpreted as HTML code. For a description
         *  of the supported HTML subset, refer to the classic Flash 'TextField' documentation.
         *  Beware: Only supported for TrueType fonts. @default false */
        public function get isHtmlText():Boolean { return _isHtmlText; }
        public function set isHtmlText(value:Boolean):void { _isHtmlText = value; }

        /** The scale factor of any textures that are created during text composition.
         *  @default Starling.contentScaleFactor */
        public function get textureScale():Number { return _textureScale; }
        public function set textureScale(value:Number):void { _textureScale = value; }

        /** The Context3DTextureFormat of any textures that are created during text composition.
         *  @default Context3DTextureFormat.BGRA_PACKED */
        public function get textureFormat():String { return _textureFormat; }
        public function set textureFormat(value:String):void { _textureFormat = value; }
    }
}
