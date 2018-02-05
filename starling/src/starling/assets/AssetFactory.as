package starling.assets
{
    import flash.utils.ByteArray;

    public class AssetFactory
    {
        private var _priority:int;
        private var _mimeTypes:Vector.<String>;
        private var _extensions:Vector.<String>;

        public function AssetFactory()
        {
            _mimeTypes = new <String>[];
            _extensions = new <String>[];
        }

        public function canHandle(reference:AssetReference):Boolean
        {
            var mimeType:String = reference.mimeType;
            var extension:String = reference.extension;

            return reference.data is ByteArray && (
                (mimeType && _mimeTypes.indexOf(reference.mimeType.toLowerCase()) != -1) ||
                (extension && _extensions.indexOf(reference.extension.toLowerCase()) != -1));
        }

        public function create(reference:AssetReference, helper:AssetFactoryHelper,
                               onComplete:Function, onError:Function):void
        {
            // to be implemented by subclasses
        }

        public function addMimeTypes(...args):void
        {
            for each (var mimeType:String in args)
            {
                mimeType = mimeType.toLowerCase();

                if (_mimeTypes.indexOf(mimeType) == -1)
                    _mimeTypes[_mimeTypes.length] = mimeType;
            }
        }

        public function addExtensions(...args):void
        {
            for each (var extension:String in args)
            {
                extension = extension.toLowerCase();

                if (_extensions.indexOf(extension) == -1)
                    _extensions[_extensions.length] = extension;
            }
        }

        public function getMimeTypes(out:Vector.<String>=null):Vector.<String>
        {
            out ||= new <String>[];

            for (var i:int=0; i<_mimeTypes.length; ++i)
                out[i] = _mimeTypes[i];

            return out;
        }

        public function getExtensions(out:Vector.<String>=null):Vector.<String>
        {
            out ||= new <String>[];

            for (var i:int=0; i<_extensions.length; ++i)
                out[i] = _extensions[i];

            return out;
        }

        internal function get priority():int { return _priority; }
        internal function set priority(value:int):void { _priority = value; }
    }
}
