// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.display
{
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.geom.Vector3D;
    
    import starling.core.RenderSupport;
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
        /** The raw vertex data of the quad. */
        protected var mVertexData:VertexData;
        
        /** Helper object. */
        private static var sPosition:Vector3D = new Vector3D();
        
        /** Creates a quad with a certain size and color. The last parameter controls if the 
         *  alpha value should be premultiplied into the color values on rendering, which can
         *  influence blending output. You can use the default value in most cases.  */
        public function Quad(width:Number, height:Number, color:uint=0xffffff,
                             premultipliedAlpha:Boolean=true)
        {
            mVertexData = new VertexData(4, premultipliedAlpha);
            updateVertexData(width, height, color, premultipliedAlpha);    
        }
        
        /** Updates the vertex data with specific values for dimensions and color. */
        protected function updateVertexData(width:Number, height:Number, color:uint,
                                            premultipliedAlpha:Boolean):void
        {
            mVertexData.setPremultipliedAlpha(premultipliedAlpha);
            mVertexData.setPosition(0, 0.0, 0.0);
            mVertexData.setPosition(1, width, 0.0);
            mVertexData.setPosition(2, 0.0, height);
            mVertexData.setPosition(3, width, height);            
            mVertexData.setUniformColor(color);
        }
        
        /** @inheritDoc */
        public override function getBounds(targetSpace:DisplayObject):Rectangle
        {
            var minX:Number = Number.MAX_VALUE, maxX:Number = -Number.MAX_VALUE;
            var minY:Number = Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE;
            var i:int;
            
            if (targetSpace == this) // optimization
            {
                for (i=0; i<4; ++i)
                {
                    mVertexData.getPosition(i, sPosition);
                    minX = Math.min(minX, sPosition.x);
                    maxX = Math.max(maxX, sPosition.x);
                    minY = Math.min(minY, sPosition.y);
                    maxY = Math.max(maxY, sPosition.y);
                }
            }
            else
            {
                var transformationMatrix:Matrix = getTransformationMatrix(targetSpace);
                var point:Point = new Point();
                
                for (i=0; i<4; ++i)
                {
                    mVertexData.getPosition(i, sPosition);
                    point.x = sPosition.x;
                    point.y = sPosition.y;
                    var transformedPoint:Point = transformationMatrix.transformPoint(point);
                    minX = Math.min(minX, transformedPoint.x);
                    maxX = Math.max(maxX, transformedPoint.x);
                    minY = Math.min(minY, transformedPoint.y);
                    maxY = Math.max(maxY, transformedPoint.y);                    
                }
            }
            
            return new Rectangle(minX, minY, maxX-minX, maxY-minY);
        }
        
        /** Returns the color of a vertex at a certain index. */
        public function getVertexColor(vertexID:int):uint
        {
            return mVertexData.getColor(vertexID);
        }
        
        /** Sets the color of a vertex at a certain index. */
        public function setVertexColor(vertexID:int, color:uint):void
        {
            mVertexData.setColor(vertexID, color);
        }
        
        /** Returns the alpha value of a vertex at a certain index. */
        public function getVertexAlpha(vertexID:int):Number
        {
            return mVertexData.getAlpha(vertexID);
        }
        
        /** Sets the alpha value of a vertex at a certain index. */
        public function setVertexAlpha(vertexID:int, alpha:Number):void
        {
            mVertexData.setAlpha(vertexID, alpha);
        }
        
        /** Returns the color of the quad, or of vertex 0 if vertices have different colors. */
        public function get color():uint 
        { 
            return mVertexData.getColor(0); 
        }
        
        /** Sets the colors of all vertices to a certain value. */
        public function set color(value:uint):void 
        {
            for (var i:int=0; i<4; ++i)
                setVertexColor(i, value);
        }
        
        /** Copies the raw vertex data to a VertexData instance. */
        public function copyVertexDataTo(targetData:VertexData, targetVertexID:int=0):void
        {
            mVertexData.copyTo(targetData, targetVertexID);
        }
        
        /** @inheritDoc */
        public override function render(support:RenderSupport, alpha:Number):void
        {
            support.batchQuad(this, alpha);
        }
    }
}