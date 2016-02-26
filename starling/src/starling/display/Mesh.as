// =================================================================================================
//
//  Starling Framework
//  Copyright Gamua GmbH. All Rights Reserved.
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

    import starling.core.starling_internal;
    import starling.rendering.IndexData;
    import starling.rendering.MeshStyle;
    import starling.rendering.Painter;
    import starling.rendering.VertexData;
    import starling.rendering.VertexDataFormat;
    import starling.textures.Texture;
    import starling.utils.MeshUtil;

    use namespace starling_internal;

    /** The base class for all tangible (non-container) display objects, spawned up by a number
     *  of triangles.
     *
     *  <p>Since Starling uses Stage3D for rendering, all rendered objects must be constructed
     *  from triangles. A mesh stores the information of its triangles through VertexData and
     *  IndexData structures. The default format stores position, color and texture coordinates
     *  for each vertex.</p>
     *
     *  <p>How a mesh is rendered depends on its style. Per default, this is an instance
     *  of the <code>MeshStyle</code> base class; however, subclasses may extend its behavior
     *  to add support for color transformations, normal mapping, etc.</p>
     *
     *  @see MeshBatch
     *  @see starling.rendering.MeshStyle
     *  @see starling.rendering.VertexData
     *  @see starling.rendering.IndexData
     */
    public class Mesh extends DisplayObject
    {
        /** @private */ internal var _style:MeshStyle;
        /** @private */ internal var _vertexData:VertexData;
        /** @private */ internal var _indexData:IndexData;

        private var _pixelSnapping:Boolean;
        private static var sDefaultStyle:Class = MeshStyle;

        /** Creates a new mesh with the given vertices and indices.
         *  If you don't pass a style, an instance of <code>MeshStyle</code> will be created
         *  for you. Note that the format of the vertex data will be matched to the
         *  given style right away. */
        public function Mesh(vertexData:VertexData, indexData:IndexData, style:MeshStyle=null)
        {
            if (vertexData == null) throw new ArgumentError("VertexData must not be null");
            if (indexData == null)  throw new ArgumentError("IndexData must not be null");

            _vertexData = vertexData;
            _indexData = indexData;
            _pixelSnapping = true;

            setStyle(style, false);
        }

        /** @inheritDoc */
        override public function dispose():void
        {
            _vertexData.clear();
            _indexData.clear();

            super.dispose();
        }

        /** @inheritDoc */
        override public function hitTest(localPoint:Point):DisplayObject
        {
            if (!visible || !touchable || !hitTestMask(localPoint)) return null;
            else return MeshUtil.containsPoint(_vertexData, _indexData, localPoint) ? this : null;
        }

        /** @inheritDoc */
        override public function getBounds(targetSpace:DisplayObject, out:Rectangle=null):Rectangle
        {
            return MeshUtil.calculateBounds(_vertexData, this, targetSpace, out);
        }

        /** @inheritDoc */
        override public function render(painter:Painter):void
        {
            if (_pixelSnapping)
                snapToPixels(painter.state.modelviewMatrix, painter.pixelSize);

            painter.batchMesh(this);
        }

        private function snapToPixels(matrix:Matrix, pixelSize:Number):void
        {
            // Snapping only makes sense if the object is unscaled and rotated only by
            // multiples of 90 degrees. If that's the case can be found out by looking
            // at the modelview matrix.

            const E:Number = 0.0001;

            var doSnap:Boolean = false;
            var aSq:Number, bSq:Number, cSq:Number, dSq:Number;

            if (matrix.b + E > 0 && matrix.b - E < 0 && matrix.c + E > 0 && matrix.c - E < 0)
            {
                // what we actually want is 'Math.abs(matrix.a)', but squaring
                // the value works just as well for our needs & is faster.

                aSq = matrix.a * matrix.a;
                dSq = matrix.d * matrix.d;
                doSnap = aSq + E > 1 && aSq - E < 1 && dSq + E > 1 && dSq - E < 1;
            }
            else if (matrix.a + E > 0 && matrix.a - E < 0 && matrix.d + E > 0 && matrix.d - E < 0)
            {
                bSq = matrix.b * matrix.b;
                cSq = matrix.c * matrix.c;
                doSnap = bSq + E > 1 && bSq - E < 1 && cSq + E > 1 && cSq - E < 1;
            }

            if (doSnap)
            {
                matrix.tx = Math.round(matrix.tx / pixelSize) * pixelSize;
                matrix.ty = Math.round(matrix.ty / pixelSize) * pixelSize;
            }
        }

        /** Sets the style that is used to render the mesh. Styles (which are always subclasses of
         *  <code>MeshStyle</code>) provide a means to completely modify the way a mesh is rendered.
         *  For example, they may add support for color transformations or normal mapping.
         *
         *  <p>When assigning a new style, the vertex format will be changed to fit it.
         *  Do not use the same style instance on multiple objects! Instead, make use of
         *  <code>style.clone()</code> to assign an identical style to multiple meshes.</p>
         *
         *  @param meshStyle             the style to assign. If <code>null</code>, an instance of
         *                               a standard <code>MeshStyle</code> will be created.
         *  @param mergeWithPredecessor  if enabled, all attributes of the previous style will be
         *                               be copied to the new one, if possible.
         */
        public function setStyle(meshStyle:MeshStyle=null, mergeWithPredecessor:Boolean=true):void
        {
            if (meshStyle == null) meshStyle = new sDefaultStyle() as MeshStyle;
            else if (meshStyle == _style) return;
            else if (meshStyle.target) meshStyle.target.setStyle();

            if (_style)
            {
                if (mergeWithPredecessor) meshStyle.copyFrom(_style);
                _style.setTarget(null);
            }

            _style = meshStyle;
            _style.setTarget(this, _vertexData, _indexData);
        }

        // vertex manipulation

        /** Returns the alpha value of the vertex at the specified index. */
        public function getVertexAlpha(vertexID:int):Number
        {
            return _style.getVertexAlpha(vertexID);
        }

        /** Sets the alpha value of the vertex at the specified index to a certain value. */
        public function setVertexAlpha(vertexID:int, alpha:Number):void
        {
            _style.setVertexAlpha(vertexID, alpha);
        }

        /** Returns the RGB color of the vertex at the specified index. */
        public function getVertexColor(vertexID:int):uint
        {
            return _style.getVertexColor(vertexID);
        }

        /** Sets the RGB color of the vertex at the specified index to a certain value. */
        public function setVertexColor(vertexID:int, color:uint):void
        {
            _style.setVertexColor(vertexID, color);
        }

        /** Returns the texture coordinates of the vertex at the specified index. */
        public function getTexCoords(vertexID:int, out:Point = null):Point
        {
            return _style.getTexCoords(vertexID, out);
        }

        /** Sets the texture coordinates of the vertex at the specified index to the given values. */
        public function setTexCoords(vertexID:int, u:Number, v:Number):void
        {
            _style.setTexCoords(vertexID, u, v);
        }

        // properties

        /** The vertex data describing all vertices of the mesh.
         *  Any change requires a call to <code>setRequiresRedraw</code>. */
        protected function get vertexData():VertexData { return _vertexData; }

        /** The index data describing how the vertices are interconnected.
         *  Any change requires a call to <code>setRequiresRedraw</code>. */
        protected function get indexData():IndexData { return _indexData; }

        /** The style that is used to render the mesh. Styles (which are always subclasses of
         *  <code>MeshStyle</code>) provide a means to completely modify the way a mesh is rendered.
         *  For example, they may add support for color transformations or normal mapping.
         *
         *  <p>The setter will simply forward the assignee to <code>setStyle(value)</code>.</p>
         *
         *  @default MeshStyle
         */
        public function get style():MeshStyle { return _style; }
        public function set style(value:MeshStyle):void
        {
            setStyle(value);
        }

        /** The texture that is mapped to the mesh (or <code>null</code>, if there is none). */
        public function get texture():Texture { return _style.texture; }
        public function set texture(value:Texture):void { _style.texture = value; }

        /** Changes the color of all vertices to the same value.
         *  The getter simply returns the color of the first vertex. */
        public function get color():uint { return _style.color; }
        public function set color(value:uint):void { _style.color = value; }

        /** The smoothing filter that is used for the texture.
         *  @default bilinear */
        public function get textureSmoothing():String { return _style.textureSmoothing; }
        public function set textureSmoothing(value:String):void { _style.textureSmoothing = value; }

        /** Controls whether or not the mesh object is snapped to the nearest pixel. This
         *  can prevent the object from looking blurry when it's not exactly aligned with the
         *  pixels of the screen. For this to work, the object must be unscaled and may only
         *  be rotated by multiples of 90 degrees. @default true */
        public function get pixelSnapping():Boolean { return _pixelSnapping; }
        public function set pixelSnapping(value:Boolean):void { _pixelSnapping = value; }

        /** The total number of vertices in the mesh. */
        public function get numVertices():int { return _vertexData.numVertices; }

        /** The total number of indices referencing vertices. */
        public function get numIndices():int { return _indexData.numIndices; }

        /** The total number of triangles in this mesh.
         *  (In other words: the number of indices divided by three.) */
        public function get numTriangles():int { return _indexData.numTriangles; }

        /** The format used to store the vertices. */
        public function get vertexFormat():VertexDataFormat { return _style.vertexFormat; }

        // static properties

        /** The default style used for meshes if no specific style is provided. The default is
         *  <code>starling.rendering.MeshStyle</code>, and any assigned class must be a subclass
         *  of the same. */
        public static function get defaultStyle():Class { return sDefaultStyle; }
        public static function set defaultStyle(value:Class):void
        {
            sDefaultStyle = value;
        }
    }
}
