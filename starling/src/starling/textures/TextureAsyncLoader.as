package starling.textures {
 
	import starling.core.Starling;
	import starling.errors.MissingContextError;
 
	import flash.display3D.Context3D;
	import flash.display3D.textures.Texture;
	import flash.events.Event;
	import flash.utils.ByteArray;
 
	public class TextureAsyncLoader extends starling.textures.Texture {
 
		private var _ready : Function = null;
 
		private var _nativeTexture : flash.display3D.textures.Texture;
		private var _atfData : AtfData;
		private var _concreteTexture : ConcreteTexture;
 
		public function TextureAsyncLoader() {
			super();
		}
 
		public function loadAsyncATF(data : ByteArray, ready : Function) : void {
 
			var context : Context3D = Starling.context;
			if (context == null) throw new MissingContextError();
 
 			_ready = ready;
 
			_atfData = new AtfData(data);
			_nativeTexture = context.createTexture(_atfData.width, _atfData.height, _atfData.format, false);
 
			_nativeTexture.addEventListener("textureReady", _onTextureReady);
			_nativeTexture.uploadCompressedTextureFromByteArray(data, 0, true);
		}
 
		private function _onTextureReady(event : Event) : void {
			_nativeTexture.removeEventListener("textureReady", _onTextureReady);
 
 			if ( _ready ) {
	 			//_atfData.numTextures > 1
				_concreteTexture = new ConcreteTexture(_nativeTexture, _atfData.format, _atfData.width, _atfData.height, false, false); //, false, Starling.contentScaleFactor);
	 
				if (Starling.handleLostContext)
					_concreteTexture.restoreOnLostContext(_atfData);
				 _ready(_concreteTexture);
			}
			else {
				// No more listener, dispose the texture immediately
				_nativeTexture.dispose();
			}
			
			_nativeTexture = null;
			_concreteTexture = null;
			_atfData = null;
			_ready = null;
		}
 
		public function close() : void {
			_ready = null;
		}
 
	}
}