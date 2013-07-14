// =================================================================================================
//
//	Starling Framework
//	Copyright 2013 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.filters
{
    import flash.display.BitmapDataChannel;
    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DTextureFormat;
    import flash.display3D.Program3D;
    import flash.geom.Matrix3D;
    import flash.geom.Point;
    
    import starling.core.RenderSupport;
    import starling.textures.Texture;
    
    /** The DisplacementMapFilter class uses the pixel values from the specified texture (called
     *  the displacement map) to perform a displacement of an object. You can use this filter 
     *  to apply a warped or mottled effect to any object that inherits from the DisplayObject 
     *  class. 
     * 
     *  <p>TODO: Extend documentation. For now, please check out the documentation of the same
     *  class in the AS3 API reference.</p>
     */ 
    public class DisplacementMapFilter extends FragmentFilter
    {
        private var mMapTexture:Texture;
        private var mMapPoint:Point;
        private var mComponentX:uint;
        private var mComponentY:uint;
        private var mScaleX:Number;
        private var mScaleY:Number;
        private var mRepeat:Boolean;
        
        private var mShaderProgram:Program3D;
        
        private static var sOneHalf:Vector.<Number> = new <Number>[0.5, 0.5, 0.5, 0.5];
        private static var sMapPoint:Vector.<Number>   = new <Number>[0, 0, 0, 0];
        private static var sMapUVScale:Vector.<Number> = new <Number>[1, 1, 1, 1]; 
        private static var sMatrix:Matrix3D = new Matrix3D();
        private static var sMatrixData:Vector.<Number> = 
            new <Number>[0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0];
        
        /** Creates a new displacement map filter that uses the provided texture. */
        public function DisplacementMapFilter(mapTexture:Texture, mapPoint:Point=null, 
                                              componentX:uint=0, componentY:uint=0, 
                                              scaleX:Number=0.0, scaleY:Number=0.0,
                                              repeat:Boolean=false)
        {
            mMapTexture = mapTexture;
            mMapPoint = new Point();
            mComponentX = componentX;
            mComponentY = componentY;
            mScaleX = scaleX;
            mScaleY = scaleY;
            this.mapPoint = mapPoint;
            
            super();
        }
        
        /** @private */
        public override function dispose():void
        {
            if (mShaderProgram) mShaderProgram.dispose();
            super.dispose();
        }
        
        /** @private */
        protected override function createPrograms():void
        {
            // vc0-3: mvpMatrix
            // vc4:   conversion factor between input texCoords and map texCoords
            // vc5:   map point
            
            var vertexShaderString:String = [
                "m44  op, va0, vc0", // 4x4 matrix transform to output space
                "mov  v0, va1",      // pass input texture coordinates to fragment program
                "mul vt0, va1, vc4", // scale map texture coordinates
                "sub  v1, vt0, vc5"  // move map texture coordinates by map point, pass to fp
            ].join("\n");
            
            // v0:    input texCoords
            // v1:    map texCoords
            // fc0:   OneHalf
            // fc1-4: matrix
            
            var mapFlags:String = RenderSupport.getTextureLookupFlags(mapTexture.format,
                                      mapTexture.mipMapping, mapTexture.repeat);
            var inputFlags:String = RenderSupport.getTextureLookupFlags(
                                        Context3DTextureFormat.BGRA, false, mRepeat);
            
            var fragmentShaderString:String = [
                "tex ft0, v1, fs1 " + mapFlags, // read map texture
                "sub ft1, ft0, fc0", // subtract 0.5 -> range [-0.5, 0.5]
                "m44 ft2, ft1, fc1", // multiply matrix with displacement values
                "add ft3, v0, ft2",  // add displacement values to texture coords
                "tex oc, ft3, fs0 " + inputFlags // read input texture at displaced coords
            ].join("\n");
            
            mShaderProgram = assembleAgal(fragmentShaderString, vertexShaderString);
        }
        
        /** @private */
        protected override function activate(pass:int, context:Context3D, texture:Texture):void
        {
            // already set by super class:
            //
            // vertex constants 0-3: mvpMatrix (3D)
            // vertex attribute 0:   vertex position (FLOAT_2)
            // vertex attribute 1:   texture coordinates (FLOAT_2)
            // texture 0:            input texture

            updateParameters(texture.nativeWidth, texture.nativeHeight);
            
            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, sMapUVScale);
            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 5, sMapPoint);
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, sOneHalf);
            context.setProgramConstantsFromMatrix(Context3DProgramType.FRAGMENT, 1, sMatrix, true);
            context.setTextureAt(1, mMapTexture.base);
            context.setProgram(mShaderProgram);
        }
        
        /** @private */
        override protected function deactivate(pass:int, context:Context3D, texture:Texture):void
        {
            context.setTextureAt(1, null);
        }
        
        private function updateParameters(textureWidth:int, textureHeight:int):void
        {
            // matrix:
            // Maps RGBA values of map texture to UV-offsets in input texture.
            
            var columnX:int, columnY:int;
            
            for (var i:int=0; i<16; ++i)
                sMatrixData[i] = 0;
            
            if      (mComponentX == BitmapDataChannel.RED)   columnX = 0;
            else if (mComponentX == BitmapDataChannel.GREEN) columnX = 1;
            else if (mComponentX == BitmapDataChannel.BLUE)  columnX = 2;
            else                                             columnX = 3;
            
            if      (mComponentY == BitmapDataChannel.RED)   columnY = 0;
            else if (mComponentY == BitmapDataChannel.GREEN) columnY = 1;
            else if (mComponentY == BitmapDataChannel.BLUE)  columnY = 2;
            else                                             columnY = 3;
            
            sMatrixData[int(columnX * 4    )] = mScaleX / textureWidth;
            sMatrixData[int(columnY * 4 + 1)] = mScaleY / textureHeight;
            
            sMatrix.copyRawDataFrom(sMatrixData);
            
            // map texture coordinate scaling:
            // The map texture may have a different size than the input texture. The vertex shader
            // will use this scale factor to create the texture coordinates of the map texture.
            
            sMapUVScale[0] = textureWidth  / mapTexture.root.nativeWidth;
            sMapUVScale[1] = textureHeight / mapTexture.root.nativeHeight;
            
            // map point offset
            // the offset needs to be converted from pixels to [0-1] range.
            
            sMapPoint[0] = mMapPoint.x / mapTexture.root.nativeWidth;
            sMapPoint[1] = mMapPoint.y / mapTexture.root.nativeHeight;
        }
        
        // properties

        /** Describes which color channel to use in the map image to displace the x result. 
         *  Possible values are constants from the BitmapDataChannel class. */
        public function get componentX():uint { return mComponentX; }
        public function set componentX(value:uint):void { mComponentX = value; }

        /** Describes which color channel to use in the map image to displace the y result. 
         *  Possible values are constants from the BitmapDataChannel class. */
        public function get componentY():uint { return mComponentY; }
        public function set componentY(value:uint):void { mComponentY = value; }

        /** The multiplier to use to scale the x displacement result from the map calculation. */
        public function get scaleX():Number { return mScaleX; }
        public function set scaleX(value:Number):void { mScaleX = value; }

        /** The multiplier to use to scale the y displacement result from the map calculation. */
        public function get scaleY():Number { return mScaleY; }
        public function set scaleY(value:Number):void { mScaleY = value; }
        
        /** The texture that will be used to calculate displacement. */
        public function get mapTexture():Texture { return mMapTexture; }
        public function set mapTexture(value:Texture):void { mMapTexture = value; }
        
        /** A value that contains the offset of the upper-left corner of the target display 
         *  object from the upper-left corner of the map image. */   
        public function get mapPoint():Point { return mMapPoint; }
        public function set mapPoint(value:Point):void
        {
            if (value) mMapPoint.setTo(value.x, value.y);
            else mMapPoint.setTo(0, 0);
        }
        
        /** Indicates how the pixels at the edge of the input image (the filtered object) will
         *  be wrapped at the edge. */ 
        public function get repeat():Boolean { return mRepeat; }
        public function set repeat(value:Boolean):void { mRepeat = value; }
    }
}