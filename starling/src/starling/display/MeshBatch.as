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
    import flash.geom.Point;
    import flash.geom.Rectangle;

    import starling.rendering.IndexData;
    import starling.rendering.MeshEffect;
    import starling.rendering.Painter;
    import starling.rendering.VertexData;
    import starling.textures.Texture;
    import starling.utils.GeometryUtil;

    /** Combines a number of meshes to one display object and renders them efficiently.
     *
     *  <p>The most basic tangible display object in Starling is the Mesh. However, a mesh cannot
     *  render itself; it just holds the data describing its geometry. Rendering is done by the
     *  "MeshBatch" class. As its name suggests, it acts as a batch for an arbitrary number
     *  of Mesh instances; add meshes to a batch and they are all rendered together,
     *  in one draw call.</p>
     *
     *  <p>You can only batch meshes that share similar properties, e.g. they need to have the
     *  same texture and the same blend mode. The first object you add to a batch will decide
     *  this state; call <code>canAddMesh</code> to find out if a new mesh shares that state.
     *  To reset the current state, you can call <code>clear</code>; this will also remove all
     *  geometry that has been added thus far.</p>
     *
     *  <p>Starling will use MeshBatch instances (or compatible objects) for all rendering.
     *  You can also use MeshBatch instances yourself, though, as they are also display objects.
     *  That makes sense for an object containing a large number of meshes; that way, that object
     *  can be created once and then rendered very efficiently, without having to copy its vertices
     *  and indices between buffers and GPU memory.</p>
     *
     *  @see Mesh
     *  @see Sprite
     */
    public class MeshBatch extends DisplayObject
    {
        public static const MAX_NUM_VERTICES:int = 65535;

        /** The Effect that is used to render the mesh. */
        protected var _effect:MeshEffect;

        /** The aggregate mesh, which is a combination of all added meshes. */
        protected var _mesh:Mesh;

        private var _vertexSyncRequired:Boolean;
        private var _indexSyncRequired:Boolean;
        private var _batchable:Boolean;

        private var _texture:Texture;
        private var _vertexData:VertexData;
        private var _indexData:IndexData;

        /** Creates a new, empty MeshBatch instance. */
        public function MeshBatch()
        {
            _mesh = createMesh();
            _effect = createEffect();
            _effect.onRestore = setVertexAndIndexDataChanged;

            // direct access for better performance
            _vertexData = _mesh.vertexData;
            _indexData = _mesh.indexData;
        }

        /** Override this method in subclasses to customize the aggregate mesh. */
        protected function createMesh():Mesh
        {
            var vertexData:VertexData = new VertexData(Mesh.VERTEX_FORMAT);
            var indexData:IndexData = new IndexData();
            return new Mesh(vertexData, indexData);
        }

        /** Override this method in subclasses to provide a custom effect for rendering. */
        protected function createEffect():MeshEffect
        {
            return new MeshEffect();
        }

        // display object overrides

        /** @inheritDoc */
        override public function dispose():void
        {
            _effect.dispose();
            _mesh.dispose();
            super.dispose();
        }

        /** @inheritDoc */
        override public function hitTest(localPoint:Point):DisplayObject
        {
            return _mesh.hitTest(localPoint);
        }

        /** @inheritDoc */
        override public function getBounds(targetSpace:DisplayObject, out:Rectangle=null):Rectangle
        {
            return GeometryUtil.calculateBounds(_vertexData, this, targetSpace, out);
        }

        /** To call when the vertex data was changed. */
        protected function setVertexDataChanged():void
        {
            _vertexSyncRequired = true;
        }

        /** To call when the index data was changed. */
        protected function setIndexDataChanged():void
        {
            _indexSyncRequired = true;
        }

        /** To call when both vertex- and index-data were changed.
         *  Calls the other two <code>dataChanged</code>-methods internally. */
        protected function setVertexAndIndexDataChanged():void
        {
            setVertexDataChanged();
            setIndexDataChanged();
        }

        private function syncVertexBuffer():void
        {
            _effect.uploadVertexData(_vertexData);
            _vertexSyncRequired = false;
        }

        private function syncIndexBuffer():void
        {
            _effect.uploadIndexData(_indexData);
            _indexSyncRequired = false;
        }

        /** Removes all geometry. */
        public function clear():void
        {
            _texture = null;
            _vertexData.numVertices = 0;
            _indexData.numIndices   = 0;
            _vertexSyncRequired = true;
            _indexSyncRequired  = true;
        }

        /** Adds a mesh to the batch.
         *
         *  @param mesh      the mesh to add to the batch.
         *  @param matrix    transforms the mesh with a certain matrix before adding it.
         *  @param alpha     will be multiplied with each vertex' alpha value.
         *  @param blendMode will replace the blend mode of the mesh instance.
         */
        public function addMesh(mesh:Mesh, matrix:Matrix=null,
                                alpha:Number=1.0, blendMode:String=null):void
        {
            if (matrix == null) matrix = mesh.transformationMatrix;
            if (blendMode == null) blendMode = mesh.blendMode;

            var vertexID:int = _vertexData.numVertices;
            var indexID:int  = _indexData.numIndices;

            if (vertexID == 0)
            {
                _texture = _mesh.texture = mesh.texture;
                this.blendMode = blendMode;
            }

            mesh.indexData.copyTo(_indexData, indexID, vertexID);
            mesh.vertexData.copyTo(_vertexData, vertexID, matrix);

            if (alpha != 1.0)
                _vertexData.scaleAlphas("color", alpha, vertexID);

            _indexSyncRequired = _vertexSyncRequired = true;
        }

        /** Indicates if the given mesh instance fits to the current state of the batch.
         *  Will always return <code>true</code> for the first added object; later calls
         *  will check if the texture, smoothing or blend mode differ in any way. */
        public function canAddMesh(mesh:Mesh, blendMode:String):Boolean
        {
            // TODO check texture smoothing

            var numVertices:int = _vertexData.numVertices;
            if (numVertices == 0) return true;
            if (numVertices + mesh.vertexData.numVertices > MAX_NUM_VERTICES) return false;

            var newTexture:Texture = mesh.texture;

            if (_texture == null && newTexture == null)
                return this.blendMode == blendMode;
            else if (_texture && newTexture)
                return _texture.base == newTexture.base &&
                    this.blendMode == blendMode;
            else return false;
        }

        /** If the <code>batchable</code> property is enabled, this method will add the batch
         *  to the painter's current batch. Otherwise, this will actually do the drawing. */
        override public function render(painter:Painter):void
        {
            if (_vertexData.numVertices == 0)
            {
                // nothing to do
            }
            else if (_batchable)
            {
                painter.batchMesh(_mesh, MeshBatch);
            }
            else
            {
                painter.finishMeshBatch();
                painter.drawCount += 1;
                painter.prepareToDraw();

                if (_vertexSyncRequired) syncVertexBuffer();
                if (_indexSyncRequired)  syncIndexBuffer();

                _effect.mvpMatrix = painter.state.mvpMatrix3D;
                _effect.alpha = painter.state.alpha;
                _effect.texture = _texture;
                _effect.render(0, _indexData.numTriangles);
            }
        }

        /** Indicates if this object will be added to the painter's batch on rendering,
         *  or if it will draw itself right away. */
        public function get batchable():Boolean { return _batchable; }
        public function set batchable(value:Boolean):void { _batchable = value; }

        /** The aggregate mesh, which is a combination of all added meshes. */
        public function get mesh():Mesh { return _mesh; }
    }
}
