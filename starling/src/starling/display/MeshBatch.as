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

    import starling.core.starling_internal;
    import starling.rendering.IMeshBatch;
    import starling.rendering.IndexData;
    import starling.rendering.MeshEffect;
    import starling.rendering.Painter;
    import starling.rendering.VertexData;
    import starling.textures.Texture;

    use namespace starling_internal;
    
    /** Combines a number of meshes to one display object and renders them efficiently.
     *
     *  <p>The most basic tangible display object in Starling is the Mesh. However, a mesh cannot
     *  render itself; it just holds the data describing its geometry. Rendering is done by the
     *  "MeshBatch" class. As its name suggests, it also acts as a batch for an arbitrary number
     *  of Mesh instances; add meshes to a batch and they are all rendered together,
     *  in one draw call.</p>
     *
     *  <p>You can only batch meshes that share similar properties, e.g. they need to have the
     *  same texture and the same blend mode. The first object you add to a batch will decide
     *  this state; call <code>canBatchMesh</code> to find out if another mesh shares that state.
     *  You may also clear the batch, which will reset that state and remove all geometry that
     *  has been added thus far.</p>
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
    public class MeshBatch extends Mesh implements IMeshBatch
    {
        public static const MAX_NUM_VERTICES:int = 65535;

        private var _effect:MeshEffect;
        private var _vertexSyncRequired:Boolean;
        private var _indexSyncRequired:Boolean;
        private var _batchable:Boolean;

        /** Creates a new, empty MeshBatch instance. */
        public function MeshBatch()
        {
            var vertexData:VertexData = new VertexData(Mesh.VERTEX_FORMAT);
            var indexData:IndexData = new IndexData();

            super(vertexData, indexData);

            _effect = new MeshEffect();
            _effect.onRestore = setVertexAndIndexDataChanged;
        }

        /** @inheritDoc */
        override public function dispose():void
        {
            _effect.dispose();
            super.dispose();
        }

        /** @inheritDoc */
        override protected function setVertexDataChanged():void
        {
            _vertexSyncRequired = true;
        }

        /** @inheritDoc */
        override protected function setIndexDataChanged():void
        {
            _indexSyncRequired = true;
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

        /** Removes all geometry, sets the texture to <code>null</code>. */
        public function clear():void
        {
            _texture = null;
            _vertexData.numVertices = 0;
            _indexData.numIndices = 0;
            _vertexSyncRequired = true;
            _indexSyncRequired = true;
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
                _texture = mesh.texture;
                this.blendMode = blendMode;
            }

            mesh.copyIndexDataTo(_indexData, indexID, vertexID);
            mesh.copyVertexDataTo(_vertexData, vertexID, matrix);

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
            if (numVertices + mesh.numVertices > MAX_NUM_VERTICES) return false;

            var meshTexture:Texture = mesh.texture;

            if (_texture == null && meshTexture == null)
                return this.blendMode == blendMode;
            else if (_texture && meshTexture)
                return _texture.base == meshTexture.base &&
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
                painter.batchMesh(this);
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
                _effect.render(0, numTriangles);
            }
        }

        /** Indicates if this object will be added to the painter's batch on rendering,
         *  or if it will draw itself right away. */
        public function get batchable():Boolean { return _batchable; }
        public function set batchable(value:Boolean):void { _batchable = value; }
    }
}
