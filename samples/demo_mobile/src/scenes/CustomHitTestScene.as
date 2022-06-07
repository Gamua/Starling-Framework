package scenes
{
    import starling.events.Event;
    import starling.text.BitmapFont;
    import starling.text.TextField;
    import starling.utils.Align;
    import starling.utils.Color;

    import utils.RoundButton;
    import utils.TextButton;

    public class CustomHitTestScene extends Scene
    {
        public function CustomHitTestScene()
        {
            addInfoTextField(
                "Pushing the bird only works when the touch occurs within a circle." + 
                "This can be accomplished by overriding the method 'hitTest'.", 15);

            // 'RoundButton' is a helper class of the Demo, not a part of Starling!
            // Have a look at its code to understand this example.
            
            var roundButton:RoundButton = new RoundButton(Game.assets.getTexture("starling_round"));
            roundButton.x = Constants.CenterX - int(roundButton.width / 2);
            roundButton.y = 85;
            addChild(roundButton);

            addInfoTextField(
                "The object below is created by combining a 'TextField' with a " +
                "'ButtonBehavior'. It acts just a like normal button, i.e. allowing " +
                "to abort a tap by moving away.", 270);

            // 'TextButton' is a helper class of the Demo, not a part of Starling!
            // Have a look at its code to understand this example.

            const texts:Array = [
                "Hold me!",
                "Thrill me.",
                "Kiss me!",
                "Kill me."
            ];

            var textButton:TextButton = new TextButton(115, 85, texts[0]);
            textButton.format.setTo("Desyrel", BitmapFont.NATIVE_SIZE, Color.WHITE);
            textButton.format.leading = -10;
            textButton.x = Constants.CenterX - int(textButton.width / 2);
            textButton.y = 340;
            addChild(textButton);

            var hitCount:int = 0;
            textButton.addEventListener(Event.TRIGGERED, function():void
            {
                textButton.text = texts[++hitCount % texts.length];
            });
        }

        private function addInfoTextField(text:String, y:Number):void
        {
            var infoText:TextField = new TextField(300, 100, text);
            infoText.x = 10;
            infoText.y = y;
            infoText.format.verticalAlign = Align.TOP;
            infoText.format.horizontalAlign = Align.CENTER;
            addChild(infoText);
        }
    }
}