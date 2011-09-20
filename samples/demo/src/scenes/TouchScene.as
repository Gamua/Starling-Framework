package scenes
{
    import starling.display.Image;
    import starling.text.TextField;
    import starling.utils.HAlign;
    import starling.utils.VAlign;
    
    import utils.TouchSheet;

    public class TouchScene extends Scene
    {
        public function TouchScene()
        {
            var description:String = 
                "- touch and drag to move the images \n" +
                "- pinch with 2 fingers to scale and rotate \n" +
                "- double tap brings an image to the front \n" +
                "- use Ctrl/Cmd & Shift to simulate multi-touch";
            
            var infoText:TextField = new TextField(300, 75, description);
            infoText.x = infoText.y = 10;
            infoText.vAlign = VAlign.TOP;
            infoText.hAlign = HAlign.LEFT;
            addChild(infoText);
            
            var eggClosed:Image = new Image(Assets.getTexture("EggClosed"));
            var eggOpened:Image = new Image(Assets.getTexture("EggOpened"));
            
            // to find out how to react to touch events have a look at the TouchSheet class! 
            // It's part of the demo.
            
            var sheet1:TouchSheet = new TouchSheet(eggClosed);
            sheet1.x = 130;
            sheet1.y = 200;
            
            var sheet2:TouchSheet = new TouchSheet(eggOpened);
            sheet2.x = 200;
            sheet2.y = 295;
            
            addChild(sheet1);
            addChild(sheet2);
        }
    }
}