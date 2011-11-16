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
    import com.adobe.utils.AGALMiniAssembler;
    
    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DVertexBufferFormat;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.VertexBuffer3D;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.geom.Vector3D;
    
    import starling.core.RenderSupport;
    import starling.core.Starling;
    import starling.errors.MissingContextError;
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
        /** The name of the shader program used when a quad is rendered. The program is registered
         *  under this name at the Starling object. */
        public static const PROGRAM_NAME:String = "quad";
        
        /** The raw vertex data of the quad. */
        protected var mVertexData:VertexData;
        
        /** The vertex buffer object containing the vertex data of the quad. */
        protected var mVertexBuffer:VertexBuffer3D;
        
        /** The index buffer object used to render the quad. */
        protected var mIndexBuffer:IndexBuffer3D;
        
        /** A helper object for the render method. **/
        protected static var sRenderAlpha:Vector.<Number> = new Vector.<Number>(4, true);
        
        /** Creates a quad with a certain size and color. */
        public function Quad(width:Number, height:Number, color:uint=0xffffff)
        {
            mVertexData = new VertexData(4, true);
            mVertexData.setPosition(0, 0.0, 0.0);
            mVertexData.setPosition(1, width, 0.0);
            mVertexData.setPosition(2, 0.0, height);
            mVertexData.setPosition(3, width, height);            
            mVertexData.setUniformColor(color);
        }
        
        /** Disposes vertex- and index-buffer of the quad. */
        public override function dispose():void
        {
            if (mVertexBuffer) mVertexBuffer.dispose();
            if (mIndexBuffer)  mIndexBuffer.dispose();
            
            super.dispose();
        }
        
        /** @inheritDoc */
        public override function getBounds(targetSpace:DisplayObject):Rectangle
        {
            var minX:Number = Number.MAX_VALUE, maxX:Number = -Number.MAX_VALUE;
            var minY:Number = Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE;
            var position:Vector3D;
            var i:int;
            
            if (targetSpace == this) // optimization
            {
                for (i=0; i<4; ++i)
                {
                    position = mVertexData.getPosition(i);
                    minX = Math.min(minX, position.x);
                    maxX = Math.max(maxX, position.x);
                    minY = Math.min(minY, position.y);
                    maxY = Math.max(maxY, position.y);
                }
            }
            else
            {
                var transformationMatrix:Matrix = getTransformationMatrix(targetSpace);
                var point:Point = new Point();
                
                for (i=0; i<4; ++i)
                {
                    position = mVertexData.getPosition(i);
                    point.x = position.x;
                    point.y = position.y;
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
            if (mVertexBuffer) createVertexBuffer();
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
            if (mVertexBuffer) createVertexBuffer();
        }
        
        /** Returns the color of the quad, or of vertex 0 if vertices have different colors. */
        public function get color():uint 
        { 
            return mVertexData.getColor(0); 
        }
        
        /** Sets the colors of all vertices to a certain value. */
        public function set color(value:uint):void 
        {
            mVertexData.setUniformColor(value);
            if (mVertexBuffer) createVertexBuffer();
        }
        
        /** Returns a clone of the raw vertex data. */
        public function get vertexData():VertexData 
        { 
            return mVertexData.clone(); 
        }
        
        /** @inheritDoc */
        public override function render(support:RenderSupport, alpha:Number):void
        {
            alpha *= this.alpha;
            sRenderAlpha[0] = sRenderAlpha[1] = sRenderAlpha[2] = sRenderAlpha[3] = alpha;
            
            var context:Context3D = Starling.context;
            
            if (context == null) throw new MissingContextError();
            if (mVertexBuffer == null) createVertexBuffer();
            if (mIndexBuffer  == null) createIndexBuffer();
            
            support.setDefaultBlendFactors(true);
            
            context.setProgram(Starling.current.getProgram(PROGRAM_NAME));
            context.setVertexBufferAt(0, mVertexBuffer, VertexData.POSITION_OFFSET, Context3DVertexBufferFormat.FLOAT_3); 
            context.setVertexBufferAt(1, mVertexBuffer, VertexData.COLOR_OFFSET,    Context3DVertexBufferFormat.FLOAT_4);
            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, support.mvpMatrix, true);            
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, sRenderAlpha, 1);
            context.drawTriangles(mIndexBuffer, 0, 2);
            
            context.setVertexBufferAt(0, null);
            context.setVertexBufferAt(1, null);
        }
        
        /** Creates the vertex buffer from the raw vertex data at the current render context. */
        protected function createVertexBuffer():void
        {
            if (mVertexBuffer == null) 
                mVertexBuffer = Starling.context.createVertexBuffer(4, VertexData.ELEMENTS_PER_VERTEX);
                
            mVertexBuffer.uploadFromVector(vertexData.data, 0, 4);
        }
        
        /** Creates the index buffer at the current render context. */
        protected function createIndexBuffer():void
        {
            if (mIndexBuffer == null) 
                mIndexBuffer = Starling.context.createIndexBuffer(6);
            
            mIndexBuffer.uploadFromVector(Vector.<uint>([0, 1, 2, 1, 3, 2]), 0, 6);
        }
        
        /** Registers the vertex and fragment program required in the 'render' method at a 
         *  Starling object. You don't have to call this method manually. */
        public static function registerPrograms(target:Starling):void
        {
            // create a vertex and fragment program - from assembly
            var vertexProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler();
            vertexProgramAssembler.assemble(Context3DProgramType.VERTEX, 
                "m44 op, va0, vc0  \n" +  // 4x4 matrix transform to output clipspace
                "mov v0, va1       \n"    // pass color to fragment program 
            );
            
            var fragmentProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler(); 
            fragmentProgramAssembler.assemble(Context3DProgramType.FRAGMENT,
                "mul ft0, v0, fc0  \n" +  // multiply alpha (fc0) by color (v0)
                "mov oc, ft0       \n"    // output color
            );
            
            target.registerProgram(PROGRAM_NAME, vertexProgramAssembler.agalcode,
                                               fragmentProgramAssembler.agalcode);
        }
    }
}