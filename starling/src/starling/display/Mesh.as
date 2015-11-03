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
    import flash.geom.Matrix;
    import flash.geom.Matrix3D;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.geom.Vector3D;

    import starling.rendering.IndexData;
    import starling.rendering.MeshEffect;
    import starling.rendering.Painter;
    import starling.rendering.VertexData;
    import starling.rendering.VertexDataFormat;
    import starling.textures.Texture;
    import starling.textures.TextureSmoothing;
    import starling.utils.MathUtil;
    import starling.utils.Pool;

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
     *  @see starling.rendering.IMeshBatch
     *  @see starling.rendering.VertexData
     *  @see starling.rendering.IndexData
     */
    public class Mesh extends DisplayObject
    {
        /** The vertex format expected by the Mesh (the same as found in the MeshEffect-class). */
        public static const VERTEX_FORMAT:VertexDataFormat = MeshEffect.VERTEX_FORMAT;

        /** The texture mapped to the mesh. */
        protected var _texture:Texture;

        /** The vertex data describing all vertices of the mesh. */
        protected var _vertexData:VertexData;

        /** The index data describing how the vertices are interconnected. */
        protected var _indexData:IndexData;

        // helper objects
        private static var sPoint:Point = new Point();
        private static var sPoint3D:Vector3D = new Vector3D();
        private static var sMatrix:Matrix = new Matrix();
        private static var sMatrix3D:Matrix3D = new Matrix3D();

        /** Creates a new mesh with the given vertices and indices. */
        public function Mesh(vertexData:VertexData, indexData:IndexData)
        {
            if (vertexData == null) throw new ArgumentError("VertexData must not be null");
            if (indexData == null)  throw new ArgumentError("IndexData must not be null");

            _vertexData = vertexData;
            _indexData = indexData;

            setVertexDataChanged();
            setIndexDataChanged();
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

            var i:int;
            var result:DisplayObject = null;
            var numIndices:int = _indexData.numIndices;
            var p0:Point = Pool.getPoint();
            var p1:Point = Pool.getPoint();
            var p2:Point = Pool.getPoint();

            for (i=0; i<numIndices; i+=3)
            {
                _vertexData.getPoint(_indexData.getIndex(i  ), "position", p0);
                _vertexData.getPoint(_indexData.getIndex(i+1), "position", p1);
                _vertexData.getPoint(_indexData.getIndex(i+2), "position", p2);

                if (MathUtil.isPointInTriangle(localPoint, p0, p1, p2))
                {
                    result = this;
                    break;
                }
            }

            Pool.putPoint(p0);
            Pool.putPoint(p1);
            Pool.putPoint(p2);

            return result;
        }

        /** @inheritDoc */
        override public function getBounds(targetSpace:DisplayObject, out:Rectangle=null):Rectangle
        {
            if (out == null) out = new Rectangle();

            // TODO find some optimizations

            if (is3D && stage)
            {
                stage.getCameraPosition(targetSpace, sPoint3D);
                getTransformationMatrix3D(targetSpace, sMatrix3D);
                _vertexData.getBoundsProjected("position", sMatrix3D, sPoint3D, 0, -1, out);
            }
            else
            {
                getTransformationMatrix(targetSpace, sMatrix);
                _vertexData.getBounds("position", sMatrix, 0, -1, out);
            }

            return out;
        }

        /** Copies the vertex data of the mesh to the target, optionally transforming all
         *  "position" attributes with the given matrix. */
        public function copyVertexDataTo(targetData:VertexData, targetVertexID:int=0,
                                         matrix:Matrix=null):void
        {
            _vertexData.copyTo(targetData, targetVertexID, matrix);
        }

        /** Copies the index data of the mesh to the target, optionally adding a certain
         *  offset to each value. */
        public function copyIndexDataTo(targetData:IndexData, targetIndexID:int=0,
                                        offset:int=0):void
        {
            _indexData.copyTo(targetData, targetIndexID, offset);
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
            setVertexDataChanged();
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
            setVertexDataChanged();
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

            setVertexDataChanged();
        }

        /** This method needs to be called when the vertex data changes in any way.
         *  Override it to get notified of such a change. */
        protected function setVertexDataChanged():void
        {
            // override in subclasses, if necessary
        }

        /** This method needs to be called when the index data changes in any way.
         *  Override it to get notified of such a change. */
        protected function setIndexDataChanged():void
        {
            // override in subclasses, if necessary
        }

        /** To call when both vertex- and index-data have changed. Calls the other
         *  two <code>dataChanged</code>-methods internally. */
        protected function setVertexAndIndexDataChanged():void
        {
            setVertexDataChanged();
            setIndexDataChanged();
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

            setVertexDataChanged();
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
            setVertexDataChanged();
        }

        /** The texture smoothing used when sampling the texture. */
        public function get smoothing():String { return TextureSmoothing.BILINEAR; }
        public function set smoothing(value:String):void { /* FIXME */ }

        /** The total number of vertices of the mesh. */
        public function get numVertices():int { return _vertexData.numVertices; }

        /** The total number of triangles spawning up the mesh. */
        public function get numTriangles():int { return _indexData.numTriangles; }

        /** The format of the internal vertex data. */
        public function get vertexFormat():VertexDataFormat { return _vertexData.format; }
    }
}
