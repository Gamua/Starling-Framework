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

    import starling.rendering.IndexData;
    import starling.rendering.MeshStyle;
    import starling.rendering.VertexData;
    import starling.textures.Texture;
    import starling.utils.RectangleUtil;

    /** A Quad represents a colored and/or textured rectangle.
     *
     *  <p>You can set one color per vertex. The colors will smoothly fade into each other over the
     *  area of the quad. To display a simple linear color gradient, assign one color to vertices
     *  0 and 1 and another color to vertices 2 and 3.</p>
     *
     *  <p>When assigning a texture, the colors of the vertices will "tint" the texture, i.e. the
     *  vertex color will be multiplied with the color of the texture at the same position. That's
     *  why the default color of a quad is pure white: tinting with white does not change the
     *  texture color (that's a multiplication with one).</p>
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
    public class Quad extends Mesh
    {
        private var _bounds:Rectangle;

        // helper objects
        private static var sPoint3D:Vector3D = new Vector3D();
        private static var sMatrix:Matrix = new Matrix();
        private static var sMatrix3D:Matrix3D = new Matrix3D();

        /** Creates a quad with a certain size and color. */
        public function Quad(width:Number, height:Number, color:uint=0xffffff)
        {
            _bounds = new Rectangle(0, 0, width, height);

            var vertexData:VertexData = new VertexData(MeshStyle.VERTEX_FORMAT, 4);
            var indexData:IndexData = new IndexData(6);

            setupVertexPositions(vertexData, _bounds);
            setupTextureCoordinates(vertexData);
            indexData.appendQuad(0, 1, 2, 3);

            super(vertexData, indexData);

            if (width == 0.0 || height == 0.0)
                throw new ArgumentError("Invalid size: width and height must not be zero");

            this.color = color;
        }

        private function setupVertexPositions(vertexData:VertexData, bounds:Rectangle):void
        {
            vertexData.setPoint(0, "position", bounds.left,  bounds.top);
            vertexData.setPoint(1, "position", bounds.right, bounds.top);
            vertexData.setPoint(2, "position", bounds.left,  bounds.bottom);
            vertexData.setPoint(3, "position", bounds.right, bounds.bottom);
        }

        private function setupTextureCoordinates(vertexData:VertexData):void
        {
            vertexData.setPoint(0, "texCoords", 0.0, 0.0);
            vertexData.setPoint(1, "texCoords", 1.0, 0.0);
            vertexData.setPoint(2, "texCoords", 0.0, 1.0);
            vertexData.setPoint(3, "texCoords", 1.0, 1.0);
        }

        /** @inheritDoc */
        public override function getBounds(targetSpace:DisplayObject, out:Rectangle=null):Rectangle
        {
            if (out == null) out = new Rectangle();
            
            if (targetSpace == this) // optimization
            {
                out.copyFrom(_bounds);
            }
            else if (targetSpace == parent && rotation == 0.0) // optimization
            {
                var scaleX:Number = this.scaleX;
                var scaleY:Number = this.scaleY;

                out.setTo(   x - pivotX * scaleX,     y - pivotY * scaleY,
                          _bounds.width * scaleX, _bounds.height * scaleY);

                if (scaleX < 0) { out.width  *= -1; out.x -= out.width;  }
                if (scaleY < 0) { out.height *= -1; out.y -= out.height; }
            }
            else if (is3D && stage)
            {
                stage.getCameraPosition(targetSpace, sPoint3D);
                getTransformationMatrix3D(targetSpace, sMatrix3D);
                RectangleUtil.getBoundsProjected(_bounds, sMatrix3D, sPoint3D, out);
            }
            else
            {
                getTransformationMatrix(targetSpace, sMatrix);
                RectangleUtil.getBounds(_bounds, sMatrix, out);
            }

            return out;
        }

        /** @inheritDoc */
        override public function hitTest(localPoint:Point):DisplayObject
        {
            if (!visible || !touchable || !hitTestMask(localPoint)) return null;
            else if (_bounds.containsPoint(localPoint)) return this;
            else return null;
        }

        /** Readjusts the dimensions of the quad according to its current texture. Call this method
         *  to synchronize quad and texture size after assigning a texture with a different size.*/
        public function readjustSize():void
        {
            var texture:Texture = style.texture;

            if (texture)
            {
                _bounds.setTo(0, 0, texture.frameWidth, texture.frameHeight);
                texture.setupVertexPositions(vertexData);
            }
        }

        /** Creates a quad from the given texture.
         *  The quad will have the same size as the texture. */
        public static function fromTexture(texture:Texture):Quad
        {
            var quad:Quad = new Quad(100, 100);
            quad.texture = texture;
            quad.readjustSize();
            return quad;
        }

        /** The texture that is mapped to the quad (or <code>null</code>, if there is none).
         *  Per default, it is mapped to the complete quad, i.e. to the complete area between the
         *  top left and bottom right vertices. This can be changed with the
         *  <code>setTexCoords</code>-method.
         *
         *  <p>Note that the size of the quad will not change when you assign a texture, which
         *  means that the texture might be distorted at first. Call <code>readjustSize</code> to
         *  synchronize quad and texture size.</p>
         *
         *  <p>You could also set the texture via the <code>style.texture</code> property.
         *  That way, however, the texture frame won't be taken into account. Since only rectangular
         *  objects can make use of a texture frame, only a property on the Quad class can do that.
         *  </p>
         */
        override public function set texture(value:Texture):void
        {
            if (value == texture) return;

            if (value) value.setupVertexPositions(vertexData, 0, "position", _bounds);
            else setupVertexPositions(vertexData, _bounds);

            super.texture = value;
        }
    }
}