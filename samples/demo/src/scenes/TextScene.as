package scenes
{
    import starling.text.BitmapFont;
    import starling.text.TextField;
    import starling.text.TextFormat;
    import starling.utils.Align;
    import starling.utils.Color;

    public class TextScene extends Scene
    {
        public function TextScene()
        {
            init();
        }

        private function init():void
        {
            // TrueType fonts
            
            var offset:int = 10;
            var ttFont:String = "Ubuntu";
            var ttFontSize:int = 19;

            var colorTF:TextField = new TextField(300, 80, 
                "TextFields can have a border and a color. They can be aligned in different ways, ...");
            colorTF.format.setTo(ttFont, ttFontSize, 0x33399);
            colorTF.x = colorTF.y = offset;
            colorTF.border = true;
            addChild(colorTF);
            
            var leftTF:TextField = new TextField(145, 80, "... e.g.\ntop-left ...");
            leftTF.format.setTo(ttFont, ttFontSize, 0x993333);
            leftTF.format.horizontalAlign = Align.LEFT;
            leftTF.format.verticalAlign = Align.TOP;
            leftTF.x = offset;
            leftTF.y = colorTF.y + colorTF.height + offset;
            leftTF.border = true;
            addChild(leftTF);
            
            var rightTF:TextField = new TextField(145, 80, "... or\nbottom right ...");
            rightTF.format.setTo(ttFont, ttFontSize, 0x208020);
            rightTF.format.horizontalAlign = Align.RIGHT;
            rightTF.format.verticalAlign = Align.BOTTOM;
            rightTF.border = true;
            rightTF.x = 2 * offset + leftTF.width;
            rightTF.y = leftTF.y;
            addChild(rightTF);
            
            var fontTF:TextField = new TextField(300, 80,
                "... or centered. Embedded fonts are detected automatically and " +
                "<font color='#208080'>support</font> " +
                "<font color='#993333'>basic</font> " +
                "<font color='#333399'>HTML</font> " +
                "<font color='#208020'>formatting</font>.");
            fontTF.format.setTo(ttFont, ttFontSize);
            fontTF.x = offset;
            fontTF.y = leftTF.y + leftTF.height + offset;
            fontTF.border = true;
            fontTF.isHtmlText = true;
            addChild(fontTF);

            // Bitmap fonts!
            
            // First, you will need to create a bitmap font texture.
            //
            // E.g. with this tool: www.angelcode.com/products/bmfont/ or one that uses the same
            // data format. Export the font data as an XML file, and the texture as a png with
            // white (!) characters on a transparent background (32 bit).
            //
            // Then, you just have to register the font at the TextField class.
            // Look at the file "Assets.as" to see how this is done.
            // After that, you can use them just like a conventional TrueType font.
            
            var bmpFontTF:TextField = new TextField(300, 150, 
                    "It is very easy to use Bitmap fonts,\nas well!");
            bmpFontTF.format.font = "Desyrel";
            bmpFontTF.format.size = BitmapFont.NATIVE_SIZE; // native bitmap font size, no scaling
            bmpFontTF.format.color = Color.WHITE; // white will draw the texture as is (no tinting)
            bmpFontTF.x = offset;
            bmpFontTF.y = fontTF.y + fontTF.height + offset;
            addChild(bmpFontTF);

            // A tip: you can also add the font-texture to your standard texture atlas!
        }
    }
}