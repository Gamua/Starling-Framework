// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.text
{
    import flash.geom.Matrix;
    import flash.text.AntiAliasType;
    import flash.text.TextField;

    import starling.display.MeshBatch;
    import starling.display.Quad;
    import starling.styles.MeshStyle;
    import starling.textures.Texture;
    import starling.utils.Align;
    import starling.utils.MathUtil;
    import starling.utils.SystemUtil;

    /** This text compositor uses a Flash TextField to render system- or embedded fonts into
     *  a texture.
     *
     *  <p>You typically don't have to instantiate this class. It will be used internally by
     *  Starling's text fields.</p>
     */
    public class TrueTypeCompositor implements ITextCompositor
    {
        // helpers
        private static var sHelperMatrix:Matrix = new Matrix();
        private static var sHelperQuad:Quad = new Quad(100, 100);
        private static var sNativeTextField:flash.text.TextField = new flash.text.TextField();
        private static var sNativeFormat:flash.text.TextFormat = new flash.text.TextFormat();

        /** Creates a new TrueTypeCompositor instance. */
        public function TrueTypeCompositor()
        {}

        /** @inheritDoc */
        public function dispose():void
        {}

        /** @inheritDoc */
        public function fillMeshBatch(meshBatch:MeshBatch, width:Number, height:Number, text:String,
                                      format:TextFormat, options:TextOptions=null):void
        {
            if (text == null || text == "") return;

            var texture:Texture;
            var textureFormat:String = options.textureFormat;
            var bitmapData:BitmapDataEx = renderText(width, height, text, format, options);

            texture = Texture.fromBitmapData(bitmapData, false, false, bitmapData.scale, textureFormat);
            texture.root.onRestore = function():void
            {
                bitmapData = renderText(width, height, text, format, options);
                texture.root.uploadBitmapData(bitmapData);
                bitmapData.dispose();
                bitmapData = null;
            };

            bitmapData.dispose();
            bitmapData = null;

            sHelperQuad.texture = texture;
            sHelperQuad.readjustSize();

            if (format.horizontalAlign == Align.LEFT) sHelperQuad.x = 0;
            else if (format.horizontalAlign == Align.CENTER) sHelperQuad.x = (width - texture.width) / 2.0;
            else sHelperQuad.x = width - texture.width;

            if (format.verticalAlign == Align.TOP) sHelperQuad.y = 0;
            else if (format.verticalAlign == Align.CENTER) sHelperQuad.y = (height - texture.height) / 2.0;
            else sHelperQuad.y = height - texture.height;

            sHelperQuad.x = snapToPixels(sHelperQuad.x, options.textureScale);
            sHelperQuad.y = snapToPixels(sHelperQuad.y, options.textureScale);

            meshBatch.addMesh(sHelperQuad);

            sHelperQuad.texture = null;
        }

        /** @inheritDoc */
        public function clearMeshBatch(meshBatch:MeshBatch):void
        {
            meshBatch.clear();
            if (meshBatch.texture)
            {
                meshBatch.texture.dispose();
                meshBatch.texture = null;
            }
        }

        /** @private */
        public function getDefaultMeshStyle(previousStyle:MeshStyle,
                                            format:TextFormat, options:TextOptions):MeshStyle
        {
            return null;
        }

        private function renderText(width:Number, height:Number, text:String,
                                    format:TextFormat, options:TextOptions):BitmapDataEx
        {
            var scale:Number = options.textureScale;
            var scaledWidth:Number  = width  * scale;
            var scaledHeight:Number = height * scale;
            var hAlign:String = format.horizontalAlign;

            format.toNativeFormat(sNativeFormat);

            sNativeFormat.size = Number(sNativeFormat.size) * scale;
            sNativeTextField.embedFonts = SystemUtil.isEmbeddedFont(format.font, format.bold, format.italic);
            sNativeTextField.styleSheet = null; // only to make sure 'defaultTextFormat' is assignable
            sNativeTextField.defaultTextFormat = sNativeFormat;
            sNativeTextField.styleSheet = options.styleSheet;
            sNativeTextField.width  = scaledWidth;
            sNativeTextField.height = scaledHeight;
            sNativeTextField.antiAliasType = AntiAliasType.ADVANCED;
            sNativeTextField.selectable = false;
            sNativeTextField.multiline = true;
            sNativeTextField.wordWrap = options.wordWrap;

            if (options.isHtmlText) sNativeTextField.htmlText = text;
            else                    sNativeTextField.text     = text;

            if (options.autoScale)
                autoScaleNativeTextField(sNativeTextField, text, options.isHtmlText);

            var minTextureSize:int = 1;
            var maxTextureSize:int = Texture.getMaxSize(options.textureFormat);
            var paddingX:Number = options.padding * scale;
            var paddingY:Number = options.padding * scale;
            var textWidth:Number  = sNativeTextField.textWidth  + 4;
            var textHeight:Number = sNativeTextField.textHeight + 4;
            var bitmapWidth:int   = Math.ceil(textWidth)  + 2 * paddingX;
            var bitmapHeight:int  = Math.ceil(textHeight) + 2 * paddingY;

            // if text + padding doesn't fit into the bitmap, reduce padding & cap bitmap size.
            if (bitmapWidth > scaledWidth)
            {
                paddingX = MathUtil.max(0, (scaledWidth - textWidth) / 2);
                bitmapWidth = Math.ceil(scaledWidth);
            }
            if (bitmapHeight > scaledHeight)
            {
                paddingY = MathUtil.max(0, (scaledHeight - textHeight) / 2);
                bitmapHeight = Math.ceil(scaledHeight);
            }

            // HTML text may have its own alignment -> use the complete width
            if (options.isHtmlText) textWidth = bitmapWidth = scaledWidth;

            // check for invalid texture sizes
            if (bitmapWidth  < minTextureSize) bitmapWidth  = 1;
            if (bitmapHeight < minTextureSize) bitmapHeight = 1;
            if (bitmapHeight > maxTextureSize || bitmapWidth > maxTextureSize)
            {
                options.textureScale *= maxTextureSize / Math.max(bitmapWidth, bitmapHeight);
                return renderText(width, height, text, format, options);
            }
            else
            {
                var offsetX:Number = -paddingX;
                var offsetY:Number = -paddingY;

                if (!options.isHtmlText)
                {
                    if      (hAlign == Align.RIGHT)  offsetX =  scaledWidth - textWidth - paddingX;
                    else if (hAlign == Align.CENTER) offsetX = (scaledWidth - textWidth) / 2.0 - paddingX;
                }

                // finally: draw TextField to bitmap data
                var bitmapData:BitmapDataEx = new BitmapDataEx(bitmapWidth, bitmapHeight);
                sHelperMatrix.setTo(1, 0, 0, 1, -offsetX, -offsetY);
                bitmapData.draw(sNativeTextField, sHelperMatrix);
                bitmapData.scale = scale;
                sNativeTextField.text = "";
                return bitmapData;
            }
        }

        private static function autoScaleNativeTextField(textField:flash.text.TextField,
                                                         text:String, isHtmlText:Boolean):void
        {
            var textFormat:flash.text.TextFormat = textField.defaultTextFormat;
            var maxTextWidth:int  = textField.width  - 4;
            var maxTextHeight:int = textField.height - 4;
            var size:Number = Number(textFormat.size);

            while (textField.textWidth > maxTextWidth || textField.textHeight > maxTextHeight)
            {
                if (size <= 4) break;

                textFormat.size = size--;
                textField.defaultTextFormat = textFormat;

                if (isHtmlText) textField.htmlText = text;
                else            textField.text     = text;
            }
        }

        private static function snapToPixels(coordinate:Number, scaleFactor:Number):Number
        {
            if (coordinate == 0.0 || scaleFactor == 0.0) return coordinate;
            else
            {
                var pixelSize:Number = 1.0 / scaleFactor;
                return Math.round(coordinate / pixelSize) * pixelSize;
            }
        }
    }
}

import flash.display.BitmapData;

class BitmapDataEx extends BitmapData
{
    private var _scale:Number = 1.0;

    function BitmapDataEx(width:int, height:int, transparent:Boolean=true, fillColor:uint=0x0)
    {
        super(width, height, transparent, fillColor);
    }

    public function get scale():Number { return _scale; }
    public function set scale(value:Number):void { _scale = value; }
}
