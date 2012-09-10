package scenes
{
    import starling.display.Button;
    import starling.display.Image;
    import starling.events.Event;
    import starling.filters.BlurFilter;
    import starling.filters.ColorMatrixFilter;
    import starling.filters.GrayscaleFilter;
    import starling.filters.InverseFilter;
    import starling.text.TextField;

    public class FilterScene extends Scene
    {
        private var mButton:Button;
        private var mImage:Image;
        private var mInfoText:TextField;
        
        private var mFilterInfos:Array = [
            ["Identity", new ColorMatrixFilter()],
            ["Inverse", new InverseFilter()],
            ["Grayscale", new GrayscaleFilter()],
            ["Blur", new BlurFilter()],
            ["Drop Shadow", BlurFilter.createDropShadow()],
            ["Glow", BlurFilter.createGlow()]
        ];
        
        public function FilterScene()
        {
            mButton = new Button(Assets.getTexture("ButtonNormal"), "Switch Filter");
            mButton.x = int(Constants.CenterX - mButton.width / 2);
            mButton.y = 15;
            mButton.addEventListener(Event.TRIGGERED, onButtonTriggered);
            addChild(mButton);
            
            mImage = new Image(Assets.getTexture("StarlingRocket"));
            mImage.x = int(Constants.CenterX - mImage.width / 2);
            mImage.y = 170;
            addChild(mImage);
            
            mInfoText = new TextField(300, 32, "", "Verdana", 19);
            mInfoText.x = 10;
            mInfoText.y = 330;
            addChild(mInfoText);
            
            onButtonTriggered();
        }
        
        private function onButtonTriggered():void
        {
            var filterInfo:Array = mFilterInfos.shift() as Array;
            mFilterInfos.push(filterInfo);
            
            mInfoText.text = filterInfo[0] + " Filter";
            mImage.filter = filterInfo[1];
        }
    }
}