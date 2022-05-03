// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.utils
{
    import starling.errors.AbstractClassError;

    /** A utility class containing predefined colors and methods converting between different
     *  color representations.
     *
     *  <p>The HSL and HSV calculations conform to theory and implementation found on
     *  <a href="https://en.wikipedia.org/wiki/HSL_and_HSV">Wikipedia</a> and
     *  <a href="https://www.rapidtables.com/convert/color/">rapidtables.com</a>.</p>
     */
    public class Color
    {
        public static const WHITE:uint   = 0xffffff;
        public static const SILVER:uint  = 0xc0c0c0;
        public static const GRAY:uint    = 0x808080;
        public static const BLACK:uint   = 0x000000;
        public static const RED:uint     = 0xff0000;
        public static const MAROON:uint  = 0x800000;
        public static const YELLOW:uint  = 0xffff00;
        public static const OLIVE:uint   = 0x808000;
        public static const LIME:uint    = 0x00ff00;
        public static const GREEN:uint   = 0x008000;
        public static const AQUA:uint    = 0x00ffff;
        public static const TEAL:uint    = 0x008080;
        public static const BLUE:uint    = 0x0000ff;
        public static const NAVY:uint    = 0x000080;
        public static const FUCHSIA:uint = 0xff00ff;
        public static const PURPLE:uint  = 0x800080;

        /** Returns the alpha part of an ARGB color (0 - 255). */
        public static function getAlpha(color:uint):int { return (color >> 24) & 0xff; }

        /** Returns the red part of an (A)RGB color (0 - 255). */
        public static function getRed(color:uint):int   { return (color >> 16) & 0xff; }

        /** Returns the green part of an (A)RGB color (0 - 255). */
        public static function getGreen(color:uint):int { return (color >>  8) & 0xff; }

        /** Returns the blue part of an (A)RGB color (0 - 255). */
        public static function getBlue(color:uint):int  { return  color        & 0xff; }

        /** Sets the alpha part of an ARGB color (0 - 255). */
        public static function setAlpha(color:uint, alpha:int):uint
        {
            return (color & 0x00ffffff) | (alpha & 0xff) << 24;
        }

        /** Sets the red part of an (A)RGB color (0 - 255). */
        public static function setRed(color:uint, red:int):uint
        {
            return (color & 0xff00ffff) | (red & 0xff) << 16;
        }

        /** Sets the green part of an (A)RGB color (0 - 255). */
        public static function setGreen(color:uint, green:int):uint
        {
            return (color & 0xffff00ff) | (green & 0xff) << 8;
        }

        /** Sets the blue part of an (A)RGB color (0 - 255). */
        public static function setBlue(color:uint, blue:int):uint
        {
            return (color & 0xffffff00) | (blue & 0xff);
        }

        /** Creates an RGB color, stored in an unsigned integer. Channels are expected
         *  in the range 0 - 255. */
        public static function rgb(red:int, green:int, blue:int):uint
        {
            return (red << 16) | (green << 8) | blue;
        }

        /** Creates an ARGB color, stored in an unsigned integer. Channels are expected
         *  in the range 0 - 255. */
        public static function argb(alpha:int, red:int, green:int, blue:int):uint
        {
            return (alpha << 24) | (red << 16) | (green << 8) | blue;
        }

        /** Creates an RGB color from hue, saturation and value (brightness).
         *  Assumes hue, saturation, and value are contained in the range [0, 1].
         */
        public static function hsv(hue:Number, saturation:Number, value:Number):uint
        {
            var r:Number, g:Number, b:Number;
            var i:Number = Math.floor(hue * 6);
            var f:Number = hue * 6 - i;
            var p:Number = value * (1 - saturation);
            var q:Number = value * (1 - f * saturation);
            var t:Number = value * (1 - (1 - f) * saturation);

            switch (int(i % 6))
            {
                case 0: r = value; g = t; b = p; break;
                case 1: r = q; g = value; b = p; break;
                case 2: r = p; g = value; b = t; break;
                case 3: r = p; g = q; b = value; break;
                case 4: r = t; g = p; b = value; break;
                case 5: r = value; g = p; b = q; break;
            }

            return rgb(Math.ceil(r * 255), Math.ceil(g * 255), Math.ceil(b * 255));
        }

        /** Creates an RGB color from hue, saturation and lightness.
         *  Assumes hue, saturation, and lightness are contained in the range [0, 1].
         */
         public static function hsl(hue:Number, saturation:Number, lightness:Number):uint
        {
            var r:Number, g:Number, b:Number;
            var c:Number = (1.0 - Math.abs(2.0 * lightness - 1.0)) * saturation;
            var h2:Number = hue * 6.0;
            var x:Number = c * (1.0 - Math.abs(h2 % 2 - 1.0));
            var m:Number = lightness - c / 2.0;

            switch (int(h2 % 6))
            {
                case 0: r = c + m; g = x + m; b = m; break;
                case 1: r = x + m; g = c + m; b = m; break;
                case 2: r = m; g = c + m; b = x + m; break;
                case 3: r = m; g = x + m; b = c + m; break;
                case 4: r = x + m; g = m; b = c + m; break;
                case 5: r = c + m; g = m; b = x + m; break;
            }

            return rgb(Math.ceil(r * 255), Math.ceil(g * 255), Math.ceil(b * 255));
        }

        /** Converts an RGB color into a vector with HSV components.
         *
         *  @param rgb  the standard RGB color
         *  @param hsv  a vector to be used for the result; passing null will create a new one.
         *  @return     a vector containing hue, saturation, and value, in this order. Range: [0..1]
         */
        public static function rgbToHsv(rgb:uint, hsv:Vector.<Number>=null):Vector.<Number>
        {
            if (hsv == null) hsv = new Vector.<Number>(3, true);

            var r:Number = Color.getRed(rgb)   / 255.0;
            var g:Number = Color.getGreen(rgb) / 255.0;
            var b:Number = Color.getBlue(rgb)  / 255.0;
            var cMax:Number = Math.max(r, g, b);
            var cMin:Number = Math.min(r, g, b);
            var delta:Number = cMax - cMin;

            // hue
            if (delta == 0)     hsv[0] = 0;
            else if (cMax == r) hsv[0] = (((g - b) / delta) % 6) / 6.0;
            else if (cMax == g) hsv[0] = ((b - r) / delta + 2) / 6.0;
            else if (cMax == b) hsv[0] = ((r - g) / delta + 4) / 6.0;

            // normalize [0..1]
            while (hsv[0] <  0.0) hsv[0] += 1.0;
            while (hsv[0] >= 1.0) hsv[0] -= 1.0;

            // value / brightness
            hsv[2] = cMax;

            // saturation
            hsv[1] = cMax == 0 ? 0 : delta / cMax;

            return hsv;
        }

        /** Converts an RGB color into a vector with HSV components.
         *
         *  @param rgb  the standard RGB color
         *  @param hsl  a vector to be used for the result; passing null will create a new one.
         *  @return     a vector containing hue, saturation, and lightness, in this order. Range: [0..1]
         */
        public static function rgbToHsl(rgb:uint, hsl:Vector.<Number>=null):Vector.<Number>
        {
            if (hsl == null) hsl = new Vector.<Number>(3, true);

            var r:Number = Color.getRed(rgb)   / 255.0;
            var g:Number = Color.getGreen(rgb) / 255.0;
            var b:Number = Color.getBlue(rgb)  / 255.0;
            var cMax:Number = Math.max(r, g, b);
            var cMin:Number = Math.min(r, g, b);
            var delta:Number = cMax - cMin;

            // hue
            if (delta == 0)     hsl[0] = 0;
            else if (cMax == r) hsl[0] = (((g - b) / delta) % 6) / 6.0;
            else if (cMax == g) hsl[0] = ((b - r) / delta + 2) / 6.0;
            else if (cMax == b) hsl[0] = ((r - g) / delta + 4) / 6.0;

            // normalize [0..1]
            while (hsl[0] <  0.0) hsl[0] += 1.0;
            while (hsl[0] >= 1.0) hsl[0] -= 1.0;

            // lightness
            hsl[2] = (cMax + cMin) * 0.5;

            // saturation
            hsl[1] = delta == 0 ? 0 : delta / (1.0 - Math.abs(2.0 * hsl[2] - 1.0));

            return hsl;
        }

        /** Converts a color to a vector containing the RGBA components (in this order) scaled
         *  between 0 and 1. */
        public static function toVector(color:uint, out:Vector.<Number>=null):Vector.<Number>
        {
            if (out == null) out = new Vector.<Number>(4, true);

            out[0] = ((color >> 16) & 0xff) / 255.0;
            out[1] = ((color >>  8) & 0xff) / 255.0;
            out[2] = ( color        & 0xff) / 255.0;
            out[3] = ((color >> 24) & 0xff) / 255.0;

            return out;
        }

        /** Multiplies all channels of an (A)RGB color with a certain factor. */
        public static function multiply(color:uint, factor:Number):uint
        {
            if (factor == 0.0) return 0x0;

            var alpha:uint = ((color >> 24) & 0xff) * factor;
            var red:uint   = ((color >> 16) & 0xff) * factor;
            var green:uint = ((color >>  8) & 0xff) * factor;
            var blue:uint  = ( color        & 0xff) * factor;

            if (alpha > 255) alpha = 255;
            if (red   > 255) red   = 255;
            if (green > 255) green = 255;
            if (blue  > 255) blue  = 255;

            return argb(alpha, red, green, blue);
        }

        /** Calculates a smooth transition between one color to the next.
         *  <code>ratio</code> is expected between 0 and 1. */
        public static function interpolate(startColor:uint, endColor:uint, ratio:Number):uint
        {
            var startA:uint = (startColor >> 24) & 0xff;
            var startR:uint = (startColor >> 16) & 0xff;
            var startG:uint = (startColor >>  8) & 0xff;
            var startB:uint = (startColor      ) & 0xff;

            var endA:uint = (endColor >> 24) & 0xff;
            var endR:uint = (endColor >> 16) & 0xff;
            var endG:uint = (endColor >>  8) & 0xff;
            var endB:uint = (endColor      ) & 0xff;

            var newA:uint = startA + (endA - startA) * ratio;
            var newR:uint = startR + (endR - startR) * ratio;
            var newG:uint = startG + (endG - startG) * ratio;
            var newB:uint = startB + (endB - startB) * ratio;

            return (newA << 24) | (newR << 16) | (newG << 8) | newB;
        }

        /** @private */
        public function Color() { throw new AbstractClassError(); }
    }
}