// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.textures
{
    import flash.display.BitmapData;
    import flash.display3D.textures.RectangleTexture;
    import flash.display3D.textures.TextureBase;
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.utils.setTimeout;

    import starling.core.Starling;
    import starling.utils.execute;

    /** @private
     *
     *  A concrete texture that wraps a <code>RectangleTexture</code> base.
     *  For internal use only. */
    internal class ConcreteRectangleTexture extends ConcreteTexture
    {
        private var _textureReadyCallback:Function;

        private static var sAsyncUploadEnabled:Boolean = false;

        /** Creates a new instance with the given parameters. */
        public function ConcreteRectangleTexture(base:RectangleTexture, format:String,
                                                 width:int, height:int, premultipliedAlpha:Boolean,
                                                 optimizedForRenderTexture:Boolean=false,
                                                 scale:Number=1)
        {
            super(base, format, width, height, false, premultipliedAlpha,
                  optimizedForRenderTexture, scale);
        }

        /** @inheritDoc */
        override public function uploadBitmapData(data:BitmapData, async:*=null):void
        {
            if (async is Function)
                _textureReadyCallback = async as Function;

            upload(data, async != null);
            setDataUploaded();
        }

        /** @inheritDoc */
        override protected function createBase():TextureBase
        {
            return Starling.context.createRectangleTexture(
                    nativeWidth, nativeHeight, format, optimizedForRenderTexture);
        }

        private function get rectBase():RectangleTexture
        {
            return base as RectangleTexture;
        }

        // async upload

        private function upload(source:BitmapData, isAsync:Boolean):void
        {
            if (isAsync)
            {
                uploadAsync(source);
                base.addEventListener(Event.TEXTURE_READY, onTextureReady);
                base.addEventListener(ErrorEvent.ERROR, onTextureReady);
            }
            else
            {
                rectBase.uploadFromBitmapData(source);
            }
        }

        private function uploadAsync(source:BitmapData):void
        {
            if (sAsyncUploadEnabled)
            {
                try { base["uploadFromBitmapDataAsync"](source); }
                catch (error:Error)
                {
                    if (error.errorID == 3708 || error.errorID == 1069)
                        sAsyncUploadEnabled = false; // feature or method not available
                    else
                        throw error;
                }
            }

            if (!sAsyncUploadEnabled)
            {
                setTimeout(base.dispatchEvent, 1, new Event(Event.TEXTURE_READY));
                rectBase.uploadFromBitmapData(source);
            }
        }

        private function onTextureReady(event:Event):void
        {
            base.removeEventListener(Event.TEXTURE_READY, onTextureReady);
            base.removeEventListener(ErrorEvent.ERROR, onTextureReady);

            execute(_textureReadyCallback, this, event as ErrorEvent);
            _textureReadyCallback = null;
        }

        /** @private */
        internal static function get asyncUploadEnabled():Boolean { return sAsyncUploadEnabled; }
        internal static function set asyncUploadEnabled(value:Boolean):void { sAsyncUploadEnabled = value; }
    }
}
