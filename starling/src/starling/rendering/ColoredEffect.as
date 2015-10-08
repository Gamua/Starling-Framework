// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2015 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.rendering
{
    import flash.display3D.Context3D;

    /** A concrete effect drawing a mesh of colored vertices. */
    public class ColoredEffect extends Effect
    {
        private static const FORMAT:VertexDataFormat =
                VertexDataFormat.fromString("position(float2), color(bytes4)");

        /** Creates a new ColoredEffect instance. */
        public function ColoredEffect()
        { }

        /** @private */
        override protected function createProgram():Program
        {
            var vertexShader:String =
                "m44 op, va0, vc0 \n" + // 4x4 matrix transform to output clipspace
                "mul v0, va1, vc4 \n";  // multiply alpha (vc4) with color (va1)

            var fragmentShader:String =
                "mov oc, v0       \n";  // output color

            return Program.fromSource(vertexShader, fragmentShader);
        }

        /** Activates the program, sets up two vertex program constants (<code>vc0-3</code> -
         *  MVP matrix, <code>vc4</code> - alpha) and two vertex buffer attributes
         *  (<code>va0</code> - position, <code>va1</code> - color). */
        override protected function beforeDraw(context:Context3D):void
        {
            super.beforeDraw(context);

            vertexFormat.setVertexBufferAttribute(vertexBuffer, 0, "position");
            vertexFormat.setVertexBufferAttribute(vertexBuffer, 1, "color");
        }

        /** Resets the vertex buffer attributes. */
        override protected function afterDraw(context:Context3D):void
        {
            context.setVertexBufferAt(0, null);
            context.setVertexBufferAt(1, null);

            super.afterDraw(context);
        }

        /** Returns the data format that this effect requires from the VertexData
         *  that it renders.
         *
         *  @return "position(float2), color(bytes4)" */
        override public function get vertexFormat():VertexDataFormat { return FORMAT; }
    }
}
