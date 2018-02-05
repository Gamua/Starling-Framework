package starling.assets
{
    import flash.events.Event;
    import flash.events.HTTPStatusEvent;
    import flash.events.IOErrorEvent;
    import flash.events.ProgressEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.FileReference;
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;
    import flash.utils.ByteArray;

    import starling.utils.execute;

    internal class UrlLoader
    {
        // This HTTPStatusEvent is only available in AIR
        private static const HTTP_RESPONSE_STATUS:String = "httpResponseStatus";

        public function UrlLoader()
        { }

        public function load(url:Object, onComplete:Function,
                             onError:Function, onProgress:Function=null):void
        {
            if ("url" in url && !(url is URLRequest))
                url = url["url"];

            var message:String;
            var mimeType:String = null;
            var request:URLRequest = url as URLRequest || new URLRequest(url as String);
            var loader:URLLoader = new URLLoader();
            loader.dataFormat = URLLoaderDataFormat.BINARY;
            loader.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
            loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
            loader.addEventListener(HTTP_RESPONSE_STATUS, onHttpResponseStatus);
            loader.addEventListener(ProgressEvent.PROGRESS, onLoadProgress);
            loader.addEventListener(Event.COMPLETE, onUrlLoaderComplete);
            loader.load(request);

            function onIoError(event:IOErrorEvent):void
            {
                cleanup();
                message = "IO error when loading from '" + request.url + "'. " + event.text;
                execute(onError, message);
            }

            function onSecurityError(event:SecurityErrorEvent):void
            {
                cleanup();
                message = "Security error when loading from '" + request.url + "'. " + event.text;
                execute(onError, message);
            }

            function onHttpResponseStatus(event:HTTPStatusEvent):void
            {
                mimeType = getHttpHeader(event["responseHeaders"], "Content-Type");
            }

            function onLoadProgress(event:ProgressEvent):void
            {
                if (onProgress != null && event.bytesTotal > 0)
                    onProgress(event.bytesLoaded / event.bytesTotal);
            }

            function onUrlLoaderComplete(event:Object):void
            {
                complete(loader.data as ByteArray);
            }

            function complete(asset:ByteArray):void
            {
                cleanup();
                execute(onComplete, asset, mimeType);
            }

            function cleanup():void
            {
                loader.removeEventListener(IOErrorEvent.IO_ERROR, onIoError);
                loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
                loader.removeEventListener(HTTP_RESPONSE_STATUS, onHttpResponseStatus);
                loader.removeEventListener(ProgressEvent.PROGRESS, onLoadProgress);
                loader.removeEventListener(Event.COMPLETE, onUrlLoaderComplete);
            }
        }

        private static function getHttpHeader(headers:Array, headerName:String):String
        {
            if (headers)
            {
                for each (var header:Object in headers)
                    if (header.name == headerName) return header.value;
            }
            return null;
        }
    }
}
