package starling.assets
{
    import starling.textures.TextureOptions;

    public class AssetReference
    {
        private var _name:String;
        private var _url:String;
        private var _data:Object;
        private var _mimeType:String;
        private var _extension:String;
        private var _textureOptions:TextureOptions;
        private var _nameFromUrl:Function;
        private var _extensionFromUrl:Function;

        public function AssetReference(data:Object, name:String=null)
        {
            _data = data;
            _name = name;
            _textureOptions = new TextureOptions();

            if (data is String) _url = data as String;
            else if ("url" in data) _url = data["url"] as String;
        }

        public function get name():String { return _name || _nameFromUrl(_url); }
        public function set name(value:String):void { _name = value; }

        public function get url():String { return _url; }
        public function set url(value:String):void { _url = value; }

        public function get data():Object { return _data; }
        public function set data(value:Object):void { _data = value; }

        public function get mimeType():String { return _mimeType; }
        public function set mimeType(value:String):void { _mimeType = value; }

        public function get extension():String { return _extension || _extensionFromUrl(_url); }
        public function set extension(value:String):void { _extension = value; }

        public function get textureOptions():TextureOptions { return _textureOptions; }
        public function set textureOptions(value:TextureOptions):void
        {
            _textureOptions.copyFrom(value);
        }

        internal function get filename():String
        {
            var filename:String = this.name;
            var extension:String = this.extension;
            if (extension) filename += "." + extension;
            return filename;
        }

        internal function setCallbacks(nameFromUrl:Function, extensionFromUrl:Function):void
        {
            _nameFromUrl = nameFromUrl;
            _extensionFromUrl = extensionFromUrl;
        }
    }
}
