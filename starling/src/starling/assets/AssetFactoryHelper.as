package starling.assets
{
    import flash.utils.ByteArray;

    import starling.utils.SystemUtil;

    public class AssetFactoryHelper
    {
        private var _urlLoader:UrlLoader;
        private var _getNameFromUrlFunc:Function;
        private var _getExtensionFromUrlFunc:Function;
        private var _addPostProcessorFunc:Function;
        private var _onRestoreFunc:Function;
        private var _logFunc:Function;

        public function AssetFactoryHelper()
        { }

        public function getNameFromUrl(url:String):String
        {
            if (_getNameFromUrlFunc) return _getNameFromUrlFunc(url);
            else return "";
        }

        public function getExtensionFromUrl(url:String):String
        {
            if (_getExtensionFromUrlFunc) return _getExtensionFromUrlFunc(url);
            else return "";
        }

        public function loadDataFromUrl(url:Object, onComplete:Function, onError:Function):void
        {
            if (_urlLoader) _urlLoader.load(url, onComplete, onError);
        }

        public function addPostProcessor(processor:Function, priority:int=0):void
        {
            if (_addPostProcessorFunc) _addPostProcessorFunc(processor, priority);
        }

        public function onBeginRestore():void
        {
            if (_onRestoreFunc) _onRestoreFunc(false);
        }

        public function onEndRestore():void
        {
            if (_onRestoreFunc) _onRestoreFunc(true);
        }

        public function log(message:String):void
        {
            if (_logFunc) _logFunc(message);
        }

        public function executeWhenContextReady(call:Function, ...args):void
        {
            // On mobile, it is not allowed / endorsed to make stage3D calls while the app
            // is in the background. Thus, we pause execution if that's the case.

            if (SystemUtil.isDesktop) call.apply(this, args);
            else
            {
                args.unshift(call);
                SystemUtil.executeWhenApplicationIsActive.apply(this, args);
            }
        }

        internal function set getNameFromUrlFunc(value:Function):void { _getNameFromUrlFunc = value; }
        internal function get getNameFromUrlFunc():Function { return _getNameFromUrlFunc; }

        internal function set getExtensionFromUrlFunc(value:Function):void { _getExtensionFromUrlFunc = value; }
        internal function get getExtensionFromUrlFunc():Function { return _getExtensionFromUrlFunc; }

        internal function set urlLoader(value:UrlLoader):void { _urlLoader = value; }
        internal function get urlLoader():UrlLoader { return _urlLoader; }

        internal function set logFunc(value:Function):void { _logFunc = value; }
        internal function get logFunc():Function { return _logFunc; }

        internal function set onRestoreFunc(value:Function):void { _onRestoreFunc = value; }
        internal function get onRestoreFunc():Function { return _onRestoreFunc; }

        internal function set addPostProcessorFunc(value:Function):void { _addPostProcessorFunc = value; }
        internal function get addPostProcessorFunc():Function { return _addPostProcessorFunc; }
    }
}
