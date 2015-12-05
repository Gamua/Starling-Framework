package scenes
{
    import flash.display.BitmapData;
    import flash.display.BitmapDataChannel;
    
    import starling.core.Starling;
    import starling.display.Button;
    import starling.display.Image;
    import starling.events.Event;
    import starling.filters.BlurFilter;
    import starling.filters.ColorMatrixFilter;
    import starling.filters.DisplacementMapFilter;
    import starling.text.TextField;
    import starling.textures.Texture;

    public class FilterScene extends Scene
    {
        private var _button:Button;
        private var _image:Image;
        private var _infoText:TextField;
        private var _filterInfos:Array;
        
        public function FilterScene()
        {
            _button = new Button(Game.assets.getTexture("button_normal"), "Switch Filter");
            _button.x = int(Constants.CenterX - _button.width / 2);
            _button.y = 15;
            _button.addEventListener(Event.TRIGGERED, onButtonTriggered);
            addChild(_button);
            
            _image = new Image(Game.assets.getTexture("starling_rocket"));
            _image.x = int(Constants.CenterX - _image.width / 2);
            _image.y = 170;
            addChild(_image);
            
            _infoText = new TextField(300, 32, "", "Verdana", 19);
            _infoText.x = 10;
            _infoText.y = 330;
            addChild(_infoText);
            
            initFilters();
            onButtonTriggered();
        }
        
        private function onButtonTriggered():void
        {
            var filterInfo:Array = _filterInfos.shift() as Array;
            _filterInfos.push(filterInfo);
            
            _infoText.text = filterInfo[0];
            _image.filter  = filterInfo[1];
        }
        
        private function initFilters():void
        {
            _filterInfos = [
                ["Identity", new ColorMatrixFilter()],
                ["Blur", new BlurFilter()],
                ["Drop Shadow", BlurFilter.createDropShadow()],
                ["Glow", BlurFilter.createGlow()]
            ];
            
            var displacementFilter:DisplacementMapFilter = new DisplacementMapFilter(
                createDisplacementMap(_image.width, _image.height), null,
                BitmapDataChannel.RED, BitmapDataChannel.GREEN, 25, 25);
            _filterInfos.push(["Displacement Map", displacementFilter]);
            
            var invertFilter:ColorMatrixFilter = new ColorMatrixFilter();
            invertFilter.invert();
            _filterInfos.push(["Invert", invertFilter]);
            
            var grayscaleFilter:ColorMatrixFilter = new ColorMatrixFilter();
            grayscaleFilter.adjustSaturation(-1);
            _filterInfos.push(["Grayscale", grayscaleFilter]);
            
            var saturationFilter:ColorMatrixFilter = new ColorMatrixFilter();
            saturationFilter.adjustSaturation(1);
            _filterInfos.push(["Saturation", saturationFilter]);
            
            var contrastFilter:ColorMatrixFilter = new ColorMatrixFilter();
            contrastFilter.adjustContrast(0.75);
            _filterInfos.push(["Contrast", contrastFilter]);

            var brightnessFilter:ColorMatrixFilter = new ColorMatrixFilter();
            brightnessFilter.adjustBrightness(-0.25);
            _filterInfos.push(["Brightness", brightnessFilter]);

            var hueFilter:ColorMatrixFilter = new ColorMatrixFilter();
            hueFilter.adjustHue(1);
            _filterInfos.push(["Hue", hueFilter]);
        }
        
        private function createDisplacementMap(width:Number, height:Number):Texture
        {
            var scale:Number = Starling.contentScaleFactor;
            var map:BitmapData = new BitmapData(width*scale, height*scale, false);
            map.perlinNoise(20*scale, 20*scale, 3, 5, false, true);
            var texture:Texture = Texture.fromBitmapData(map, false, false, scale);
            return texture;
        }
    }
}