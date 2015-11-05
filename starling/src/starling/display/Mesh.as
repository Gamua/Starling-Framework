// =================================================================================================
//
//  Starling Framework
//  Copyright 2011-2015 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.display
{
    import flash.geom.Point;
    import flash.geom.Rectangle;

    import starling.rendering.IndexData;
    import starling.rendering.MeshEffect;
    import starling.rendering.Painter;
    import starling.rendering.VertexData;
    import starling.rendering.VertexDataFormat;
    import starling.textures.Texture;
    import starling.textures.TextureSmoothing;
    import starling.utils.GeometryUtil;

    /** The base class for all tangible (non-container) display objects, spawned up by a number
     *  of triangles.
     *
     *  <p>Since Starling uses Stage3D for rendering, all tangible (non-container) objects must be
     *  constructed from triangles. A mesh stores the information of its triangles through
     *  VertexData and IndexData structures. Each vertex may store a color value and (optionally)
     *  a texture coordinate, should there be a texture mapped onto it.</p>
     *
     *  <p>The rendering of a mesh is done by the "MeshBatch" class, which inherits from "Mesh"
     *  and adds batching and rendering mechanisms. Any custom display object should extend the
     *  mesh class, and may optionally provide its own rendering facility by implementing the
     *  "IMeshBatch" interface, as well.</p>
     *
     *  @see MeshBatch
     *  @see starling.rendering.VertexData
     *  @see starling.rendering.IndexData
     */
    public class Mesh extends DisplayObject
    {
        /** The vertex format expected by the Mesh (the same as found in the MeshEffect-class). */
        public static const VERTEX_FORMAT:VertexDataFormat = MeshEffect.VERTEX_FORMAT;

        private var _texture:Texture;
        private var _vertexData:VertexData;
        private var _indexData:IndexData;

        // helper objects
        private static var sPoint:Point = new Point();

        /** Creates a new mesh with the given vertices and indices. */
        public function Mesh(vertexData:VertexData, indexData:IndexData)
        {
            if (vertexData == null) throw new ArgumentError("VertexData must not be null");
            if (indexData == null)  throw new ArgumentError("IndexData must not be null");

            _vertexData = vertexData;
            _indexData = indexData;
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
            else return GeometryUtil.containsPoint(_vertexData, _indexData, localPoint) ? this : null;
        }

        /** @inheritDoc */
        override public function getBounds(targetSpace:DisplayObject, out:Rectangle=null):Rectangle
        {
            return GeometryUtil.calculateBounds(_vertexData, this, targetSpace, out);
        }

        /** Returns the alpha value of the vertex at the specified index. */
        public function getVertexAlpha(vertexID:int):Number
        {
            return _vertexData.getAlpha(vertexID);
        }

        /** Sets the alpha value of the vertex at the specified index to a certain value. */
        public function setVertexAlpha(vertexID:int, alpha:Number):void
        {
            _vertexData.setAlpha(vertexID, "color", alpha);
        }

        /** Returns the RGB color of the vertex at the specified index. */
        public function getVertexColor(vertexID:int):uint
        {
            return _vertexData.getColor(vertexID);
        }

        /** Sets the RGB color of the vertex at the specified index to a certain value. */
        public function setVertexColor(vertexID:int, color:uint):void
        {
            _vertexData.setColor(vertexID, "color", color);
        }

        /** Returns the texture coordinates of the vertex at the specified index. */
        public function getTexCoords(vertexID:int, out:Point = null):Point
        {
            if (_texture) return _texture.getTexCoords(_vertexData, vertexID, "texCoords", out);
            else return _vertexData.getPoint(vertexID, "texCoords", out);
        }

        /** Sets the texture coordinates of the vertex at the specified index to the given values. */
        public function setTexCoords(vertexID:int, u:Number, v:Number):void
        {
            if (_texture) _texture.setTexCoords(_vertexData, vertexID, "texCoords", u, v);
            else _vertexData.setPoint(vertexID, "texCoords", u, v);
        }

        /** @inheritDoc */
        public override function render(painter:Painter):void
        {
            painter.batchMesh(this, MeshBatch);
        }

        // properties

        /** Changes the color of all vertices to the same value. The getter simply returns the
         *  color of the first vertex. */
        public function get color():uint { return _vertexData.getColor(0); }
        public function set color(value:uint):void
        {
            var i:int;
            var numVertices:int = _vertexData.numVertices;

            for (i=0; i<numVertices; ++i)
                _vertexData.setColor(i, "color", value);
        }

        /** The texture mapped to the mesh. */
        public function get texture():Texture { return _texture; }
        public function set texture(value:Texture):void
        {
            if (_texture == value) return;

            var i:int;
            var numVertices:int = _vertexData.numVertices;

            for (i=0; i<numVertices; ++i)
            {
                getTexCoords(i, sPoint);
                if (value) value.setTexCoords(_vertexData, i, "texCoords", sPoint.x, sPoint.y);
            }

            _texture = value;
        }

        /** The texture smoothing used when sampling the texture. */
        public function get smoothing():String { return TextureSmoothing.BILINEAR; }
        public function set smoothing(value:String):void { /* FIXME */ }

        /** The vertex data describing all vertices of the mesh.
         *  Never change this object directly, except from subclasses;
         *  this property is solely provided for rendering. */
        public function get vertexData():VertexData { return _vertexData; }

        /** The index data describing how the vertices are interconnected.
         *  Never change this object directly, except from subclasses;
         *  this property is solely provided for rendering. */
        public function get indexData():IndexData { return _indexData; }
    }
}
