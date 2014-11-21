package scenes
{
    import starling.text.BitmapFont;
    import starling.text.TextField;
    import starling.utils.Color;
    import starling.utils.HAlign;
    import starling.utils.VAlign;

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
                "TextFields can have a border and a color. They can be aligned in different ways, ...", 
                ttFont, ttFontSize);
            colorTF.x = colorTF.y = offset;
            colorTF.border = true;
            colorTF.color = 0x333399;
            addChild(colorTF);
            
            var leftTF:TextField = new TextField(145, 80,
                "... e.g.\ntop-left ...", ttFont, ttFontSize);
            leftTF.x = offset;
            leftTF.y = colorTF.y + colorTF.height + offset;
            leftTF.hAlign = HAlign.LEFT;
            leftTF.vAlign = VAlign.TOP;
            leftTF.border = true;
            leftTF.color = 0x993333;
            addChild(leftTF);
            
            var rightTF:TextField = new TextField(145, 80,
                "... or\nbottom right ...", ttFont, ttFontSize);
            rightTF.x = 2*offset + leftTF.width;
            rightTF.y = leftTF.y;
            rightTF.hAlign = HAlign.RIGHT;
            rightTF.vAlign = VAlign.BOTTOM;
            rightTF.color = 0x208020;
            rightTF.border = true;
            addChild(rightTF);
            
            var fontTF:TextField = new TextField(300, 80,
                "... or centered. Embedded fonts are detected automatically and " +
                "<font color='#208080'>support</font> " +
                "<font color='#993333'>basic</font> " +
                "<font color='#333399'>HTML</font> " +
                "<font color='#208020'>formatting</font>.",
                ttFont, ttFontSize, 0x0, true);
            fontTF.x = offset;
            fontTF.y = leftTF.y + leftTF.height + offset;
            fontTF.border = true;
            fontTF.isHtmlText = true;
            addChild(fontTF);

            // Bitmap fonts!
            
            // First, you will need to create a bitmap font texture.
            //
            // E.g. with this tool: www.angelcode.com/products/bmfont/ or one that uses the same
            // data format. Export the font data as an XML file, and the texture as a png with white
            // characters on a transparent background (32 bit).
            //
            // Then, you just have to register the font at the TextField class.    
            // Look at the file "Assets.as" to see how this is done.
            // After that, you can use them just like a conventional TrueType font.
            
            var bmpFontTF:TextField = new TextField(300, 150, 
                "It is very easy to use Bitmap fonts,\nas well!", "Desyrel");
            
            bmpFontTF.fontSize = BitmapFont.NATIVE_SIZE; // the native bitmap font size, no scaling
            bmpFontTF.color = Color.WHITE; // use white to use the texture as it is (no tinting)
            bmpFontTF.x = offset;
            bmpFontTF.y = fontTF.y + fontTF.height + offset;
            addChild(bmpFontTF);
            
            // A tip: you can add the font-texture to your standard texture atlas and reference 
            // it from there. That way, you save texture space and avoid another texture-switch.
        }
    }
}