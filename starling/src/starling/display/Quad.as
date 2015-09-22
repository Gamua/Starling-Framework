// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2015 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.display
{
    import flash.geom.Matrix;
    import flash.geom.Matrix3D;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.geom.Vector3D;

    import starling.core.Painter;
    import starling.utils.VertexData;

    /** A Quad represents a rectangle with a uniform color or a color gradient.
     *  
     *  <p>You can set one color per vertex. The colors will smoothly fade into each other over the area
     *  of the quad. To display a simple linear color gradient, assign one color to vertices 0 and 1 and 
     *  another color to vertices 2 and 3. </p> 
     *
     *  <p>The indices of the vertices are arranged like this:</p>
     *  
     *  <pre>
     *  0 - 1
     *  | / |
     *  2 - 3
     *  </pre>
     * 
     *  @see Image
     */
    public class Quad extends DisplayObject
    {
        private var mTinted:Boolean;

        /** The raw vertex data of the quad. */
        protected var mVertexData:VertexData;
        
        /** Helper objects. */
        private static var sHelperPoint:Point = new Point();
        private static var sHelperPoint3D:Vector3D = new Vector3D();
        private static var sHelperMatrix:Matrix = new Matrix();
        private static var sHelperMatrix3D:Matrix3D = new Matrix3D();
        
        /** Creates a quad with a certain size and color. The last parameter controls if the 
         *  alpha value should be premultiplied into the color values on rendering, which can
         *  influence blending output. You can use the default value in most cases.  */
        public function Quad(width:Number, height:Number, color:uint=0xffffff,
                             premultipliedAlpha:Boolean=true)
        {
            if (width == 0.0 || height == 0.0)
                throw new ArgumentError("Invalid size: width and height must not be zero");

            mTinted = color != 0xffffff;

            mVertexData = new VertexData("position(float2), color(bytes4), texCoords(float2)", 4);
            mVertexData.setPremultipliedAlpha("color", premultipliedAlpha, false);
            mVertexData.setUniformColorAndAlpha("color", color, 1.0);
            mVertexData.setPoint(0, "position", 0.0, 0.0);
            mVertexData.setPoint(1, "position", width, 0.0);
            mVertexData.setPoint(2, "position", 0.0, height);
            mVertexData.setPoint(3, "position", width, height);

            onVertexDataChanged();
        }
        
        /** Call this method after manually changing the contents of 'mVertexData'. */
        protected function onVertexDataChanged():void
        {
            // override in subclasses, if necessary
        }
        
        /** @inheritDoc */
        public override function getBounds(targetSpace:DisplayObject, out:Rectangle=null):Rectangle
        {
            if (out == null) out = new Rectangle();
            
            if (targetSpace == this) // optimization
            {
                mVertexData.getPoint(3, "position", sHelperPoint);
                out.setTo(0.0, 0.0, sHelperPoint.x, sHelperPoint.y);
            }
            else if (targetSpace == parent && rotation == 0.0) // optimization
            {
                var scaleX:Number = this.scaleX;
                var scaleY:Number = this.scaleY;
                mVertexData.getPoint(3, "position", sHelperPoint);
                out.setTo(x - pivotX * scaleX, y - pivotY * scaleY,
                          sHelperPoint.x * scaleX, sHelperPoint.y * scaleY);
                if (scaleX < 0) { out.width  *= -1; out.x -= out.width;  }
                if (scaleY < 0) { out.height *= -1; out.y -= out.height; }
            }
            else if (is3D && stage)
            {
                stage.getCameraPosition(targetSpace, sHelperPoint3D);
                getTransformationMatrix3D(targetSpace, sHelperMatrix3D);
                mVertexData.getBoundsProjected("position", sHelperMatrix3D, sHelperPoint3D, 0, 4, out);
            }
            else
            {
                getTransformationMatrix(targetSpace, sHelperMatrix);
                mVertexData.getBounds("position", sHelperMatrix, 0, 4, out);
            }
            
            return out;
        }
        
        /** Returns the color of a vertex at a certain index. */
        public function getVertexColor(vertexID:int):uint
        {
            return mVertexData.getColor(vertexID, "color");
        }
        
        /** Sets the color of a vertex at a certain index. */
        public function setVertexColor(vertexID:int, color:uint):void
        {
            mVertexData.setColor(vertexID, "color", color);
            onVertexDataChanged();

            if (color != 0xffffff) mTinted = true;
            else mTinted = mVertexData.isTinted();
        }
        
        /** Returns the alpha value of a vertex at a certain index. */
        public function getVertexAlpha(vertexID:int):Number
        {
            return mVertexData.getAlpha(vertexID, "color");
        }
        
        /** Sets the alpha value of a vertex at a certain index. */
        public function setVertexAlpha(vertexID:int, alpha:Number):void
        {
            mVertexData.setAlpha(vertexID, "color", alpha);
            onVertexDataChanged();

            if (alpha != 1.0) mTinted = true;
            else mTinted = mVertexData.isTinted();
        }
        
        /** Returns the color of the quad, or of vertex 0 if vertices have different colors. */
        public function get color():uint 
        { 
            return mVertexData.getColor(0, "color");
        }
        
        /** Sets the colors of all vertices to a certain value. */
        public function set color(value:uint):void 
        {
            mVertexData.setUniformColorAndAlpha("color", value, 1.0);
            onVertexDataChanged();

            if (value != 0xffffff || alpha != 1.0) mTinted = true;
            else mTinted = mVertexData.isTinted();
        }
        
        /** @inheritDoc **/
        public override function set alpha(value:Number):void
        {
            super.alpha = value;
            
            if (value < 1.0) mTinted = true;
            else mTinted = mVertexData.isTinted();
        }
        
        /** Copies the raw vertex data to a VertexData instance. */
        public function copyVertexDataTo(targetData:VertexData, targetVertexID:int=0):void
        {
            mVertexData.copyTo(targetData, targetVertexID, 0, 4);
        }
        
        /** Transforms the vertex positions of the raw vertex data by a certain matrix and
         *  copies the result to another VertexData instance. */
        public function copyVertexDataTransformedTo(targetData:VertexData, targetVertexID:int=0,
                                                    matrix:Matrix=null):void
        {
            mVertexData.copyToTransformed(targetData, targetVertexID, matrix, 0, 4);
        }
        
        /** @inheritDoc */
        public override function render(painter:Painter):void
        {
            painter.batchQuad(this);
        }
        
        /** Returns true if the quad (or any of its vertices) is non-white or non-opaque. */
        public function get tinted():Boolean { return mTinted; }
        
        /** Indicates if the rgb values are stored premultiplied with the alpha value; this can
         *  affect the rendering. (Most of the time, you don't have to care, though.) */
        public function get premultipliedAlpha():Boolean
        {
            return mVertexData.getPremultipliedAlpha();
        }
    }
}