// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.filters
{
    import flash.geom.Point;

    import starling.core.Starling;
    import starling.rendering.FilterEffect;
    import starling.rendering.Painter;
    import starling.textures.Texture;

    /** The DisplacementMapFilter class uses the pixel values from the specified texture (called
     *  the map texture) to perform a displacement of an object. You can use this filter
     *  to apply a warped or mottled effect to any object that inherits from the DisplayObject
     *  class.
     *
     *  <p>The filter uses the following formula:</p>
     *  <listing>dstPixel[x, y] = srcPixel[x + ((componentX(x, y) - 128) &#42; scaleX) / 256,
     *                      y + ((componentY(x, y) - 128) &#42; scaleY) / 256]
     *  </listing>
     *
     *  <p>Where <code>componentX(x, y)</code> gets the componentX property color value from the
     *  map texture at <code>(x - mapPoint.x, y - mapPoint.y)</code>.</p>
     */
    public class DisplacementMapFilter extends FragmentFilter
    {
        /** Creates a new displacement map filter that uses the provided map texture. */
        public function DisplacementMapFilter(mapTexture:Texture, mapPoint:Point=null,
                                              componentX:uint=0, componentY:uint=0,
                                              scaleX:Number=0.0, scaleY:Number=0.0)
        {
            this.mapTexture = mapTexture;
            this.mapPoint = mapPoint;
            this.componentX = componentX;
            this.componentY = componentY;
            this.scaleX = scaleX;
            this.scaleY = scaleY;
        }

        /** @private */
        override public function process(painter:Painter, pool:ITexturePool,
                                         input0:Texture = null, input1:Texture = null,
                                         input2:Texture = null, input3:Texture = null):Texture
        {
            updateVertexData(input0, mapTexture);
            return super.process(painter, pool, input0);
        }

        /** @private */
        override protected function createEffect():FilterEffect
        {
            return new DisplacementMapEffect();
        }

        private function updateVertexData(inputTexture:Texture, mapTexture:Texture):void
        {
            // The size of input texture and map texture may be different. We need to calculate
            // the right values for the texture coordinates at the filter vertices.

            var scale:Number = Starling.contentScaleFactor;
            var mapX:Number = (dispEffect.mapPoint.x + padding.left) / mapTexture.width;
            var mapY:Number = (dispEffect.mapPoint.y + padding.top)  / mapTexture.height;
            var maxU:Number = inputTexture.root.nativeWidth  / (mapTexture.width  * scale);
            var maxV:Number = inputTexture.root.nativeHeight / (mapTexture.height * scale);

            mapTexture.setTexCoords(vertexData, 0, "mapTexCoords", -mapX, -mapY);
            mapTexture.setTexCoords(vertexData, 1, "mapTexCoords", -mapX + maxU, -mapY);
            mapTexture.setTexCoords(vertexData, 2, "mapTexCoords", -mapX, -mapY + maxV);
            mapTexture.setTexCoords(vertexData, 3, "mapTexCoords", -mapX + maxU, -mapY + maxV);
        }

        private function updatePadding():void
        {
            var paddingX:Number = Math.ceil(Math.abs(dispEffect.scaleX) / 2);
            var paddingY:Number = Math.ceil(Math.abs(dispEffect.scaleY) / 2);

            padding.setTo(paddingX, paddingX, paddingY, paddingY);
        }

        // properties

        /** Describes which color channel to use in the map image to displace the x result.
         *  Possible values are constants from the BitmapDataChannel class. */
        public function get componentX():uint { return dispEffect.componentX; }
        public function set componentX(value:uint):void
        {
            if (dispEffect.componentX != value)
            {
                dispEffect.componentX = value;
                setRequiresRedraw();
            }
        }

        /** Describes which color channel to use in the map image to displace the y result.
         *  Possible values are constants from the BitmapDataChannel class. */
        public function get componentY():uint { return dispEffect.componentY; }
        public function set componentY(value:uint):void
        {
            if (dispEffect.componentY != value)
            {
                dispEffect.componentY = value;
                setRequiresRedraw();
            }
        }

        /** The multiplier used to scale the x displacement result from the map calculation. */
        public function get scaleX():Number { return dispEffect.scaleX; }
        public function set scaleX(value:Number):void
        {
            if (dispEffect.scaleX != value)
            {
                dispEffect.scaleX = value;
                updatePadding();
            }
        }

        /** The multiplier used to scale the y displacement result from the map calculation. */
        public function get scaleY():Number { return dispEffect.scaleY; }
        public function set scaleY(value:Number):void
        {
            if (dispEffect.scaleY != value)
            {
                dispEffect.scaleY = value;
                updatePadding();
            }
        }

        /** The texture that will be used to calculate displacement. */
        public function get mapTexture():Texture { return dispEffect.mapTexture; }
        public function set mapTexture(value:Texture):void
        {
            if (dispEffect.mapTexture != value)
            {
                dispEffect.mapTexture = value;
                setRequiresRedraw();
            }
        }

        /** A value that contains the offset of the upper-left corner of the target display
         *  object from the upper-left corner of the map image. */
        public function get mapPoint():Point { return dispEffect.mapPoint; }
        public function set mapPoint(value:Point):void
        {
            dispEffect.mapPoint = value;
            setRequiresRedraw();
        }

        /** Indicates how the pixels of the map texture will be wrapped at the edge. */
        public function get mapRepeat():Boolean { return dispEffect.mapRepeat; }
        public function set mapRepeat(value:Boolean):void
        {
            if (dispEffect.mapRepeat != value)
            {
                dispEffect.mapRepeat = value;
                setRequiresRedraw();
            }
        }

        private function get dispEffect():DisplacementMapEffect
        {
            return this.effect as DisplacementMapEffect;
        }
    }
}

import flash.display.BitmapDataChannel;
import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import flash.geom.Matrix3D;
import flash.geom.Point;

import starling.core.Starling;
import starling.rendering.FilterEffect;
import starling.rendering.Program;
import starling.rendering.VertexDataFormat;
import starling.textures.Texture;
import starling.utils.RenderUtil;

class DisplacementMapEffect extends FilterEffect
{
    public static const VERTEX_FORMAT:VertexDataFormat =
        VertexDataFormat.fromString("position:float2, texCoords:float2, mapTexCoords:float2");

    private var _mapTexture:Texture;
    private var _mapPoint:Point;
    private var _mapRepeat:Boolean;
    private var _componentX:uint;
    private var _componentY:uint;
    private var _scaleX:Number;
    private var _scaleY:Number;

    // helper objects
    private static var sOneHalf:Vector.<Number> = new <Number>[0.5, 0.5, 0.5, 0.5];
    private static var sMatrix:Matrix3D = new Matrix3D();
    private static var sMatrixData:Vector.<Number> =
        new <Number>[0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0];

    public function DisplacementMapEffect()
    {
        _mapPoint = new Point();
        _componentX = _componentY = 0;
        _scaleX = _scaleY = 0;
    }

    override protected function createProgram():Program
    {
        if (_mapTexture)
        {
            // vc0-3: mvpMatrix
            // va0:   vertex position
            // va1:   input texture coords
            // va2:   map texture coords

            var vertexShader:String = [
                "m44  op, va0, vc0", // 4x4 matrix transform to output space
                "mov  v0, va1",      // pass input texture coordinates to fragment program
                "mov  v1, va2"       // pass map texture coordinates to fragment program
            ].join("\n");

            // v0:    input texCoords
            // v1:    map texCoords
            // fc0:   OneHalf
            // fc1-4: matrix

            var fragmentShader:String = [
                tex("ft0", "v1", 1, _mapTexture, false), // read map texture
                "sub ft1, ft0, fc0", // subtract 0.5 -> range [-0.5, 0.5]
                "m44 ft2, ft1, fc1", // multiply matrix with displacement values
                "add ft3,  v0, ft2", // add displacement values to texture coords
                tex("oc", "ft3", 0, texture)  // read input texture at displaced coords
            ].join("\n");

            return Program.fromSource(vertexShader, fragmentShader);
        }
        else return super.createProgram();
    }

    override protected function beforeDraw(context:Context3D):void
    {
        super.beforeDraw(context);

        if (_mapTexture)
        {
            // already set by super class:
            //
            // vertex constants 0-3: mvpMatrix (3D)
            // vertex attribute 0:   vertex position (FLOAT_2)
            // vertex attribute 1:   texture coordinates (FLOAT_2)
            // texture 0:            input texture

            getMapMatrix(sMatrix);

            vertexFormat.setVertexBufferAt(2, vertexBuffer, "mapTexCoords");
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, sOneHalf);
            context.setProgramConstantsFromMatrix(Context3DProgramType.FRAGMENT, 1, sMatrix, true);
            RenderUtil.setSamplerStateAt(1, _mapTexture.mipMapping, textureSmoothing, _mapRepeat);
            context.setTextureAt(1, _mapTexture.base);
        }
    }

    override protected function afterDraw(context:Context3D):void
    {
        if (_mapTexture)
        {
            context.setVertexBufferAt(2, null);
            context.setTextureAt(1, null);
        }

        super.afterDraw(context);
    }

    override public function get vertexFormat():VertexDataFormat
    {
        return VERTEX_FORMAT;
    }

    /** This matrix maps RGBA values of the map texture to UV-offsets in the input texture. */
    private function getMapMatrix(out:Matrix3D):Matrix3D
    {
        if (out == null) out = new Matrix3D();

        var columnX:int, columnY:int;
        var scale:Number = Starling.contentScaleFactor;
        var textureWidth:Number  = texture.root.nativeWidth;
        var textureHeight:Number = texture.root.nativeHeight;

        for (var i:int=0; i<16; ++i)
            sMatrixData[i] = 0;

        if      (_componentX == BitmapDataChannel.RED)   columnX = 0;
        else if (_componentX == BitmapDataChannel.GREEN) columnX = 1;
        else if (_componentX == BitmapDataChannel.BLUE)  columnX = 2;
        else                                             columnX = 3;

        if      (_componentY == BitmapDataChannel.RED)   columnY = 0;
        else if (_componentY == BitmapDataChannel.GREEN) columnY = 1;
        else if (_componentY == BitmapDataChannel.BLUE)  columnY = 2;
        else                                             columnY = 3;

        sMatrixData[int(columnX * 4    )] = _scaleX * scale / textureWidth;
        sMatrixData[int(columnY * 4 + 1)] = _scaleY * scale / textureHeight;

        out.copyRawDataFrom(sMatrixData);

        return out;
    }

    private static function tex(resultReg:String, uvReg:String, sampler:int, texture:Texture,
                                convertToPmaIfRequired:Boolean=true):String
    {
        return RenderUtil.createAGALTexOperation(resultReg, uvReg, sampler, texture,
            convertToPmaIfRequired);
    }

    // properties

    public function get componentX():uint { return _componentX; }
    public function set componentX(value:uint):void { _componentX = value; }

    public function get componentY():uint { return _componentY; }
    public function set componentY(value:uint):void { _componentY = value; }

    public function get scaleX():Number { return _scaleX; }
    public function set scaleX(value:Number):void { _scaleX = value; }

    public function get scaleY():Number { return _scaleY; }
    public function set scaleY(value:Number):void { _scaleY = value; }

    public function get mapTexture():Texture { return _mapTexture; }
    public function set mapTexture(value:Texture):void { _mapTexture = value; }

    public function get mapPoint():Point { return _mapPoint; }
    public function set mapPoint(value:Point):void
    {
        if (value) _mapPoint.setTo(value.x, value.y);
        else _mapPoint.setTo(0, 0);
    }

    public function get mapRepeat():Boolean { return _mapRepeat; }
    public function set mapRepeat(value:Boolean):void { _mapRepeat = value; }
}
