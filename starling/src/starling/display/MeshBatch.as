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

    import starling.rendering.IndexData;
    import starling.rendering.MeshEffect;
    import starling.rendering.MeshStyle;
    import starling.rendering.Painter;
    import starling.rendering.VertexData;
    import starling.utils.MeshSubset;

    /** Combines a number of meshes to one display object and renders them efficiently.
     *
     *  <p>The most basic tangible (non-container) display object in Starling is the Mesh.
     *  However, a mesh typically does not render itself; it just holds the data describing its
     *  geometry. Rendering is orchestrated by the "MeshBatch" class. As its name suggests, it
     *  acts as a batch for an arbitrary number of Mesh instances; add meshes to a batch and they
     *  are all rendered together, in one draw call.</p>
     *
     *  <p>You can only batch meshes that share similar properties, e.g. they need to have the
     *  same texture and the same blend mode. The first object you add to a batch will decide
     *  this state; call <code>canAddMesh</code> to find out if a new mesh shares that state.
     *  To reset the current state, you can call <code>clear</code>; this will also remove all
     *  geometry that has been added thus far.</p>
     *
     *  <p>Starling will use MeshBatch instances (or compatible objects) for all rendering.
     *  However, you can also instantiate MeshBatch instances yourself and add them to the display
     *  tree. That makes sense for an object containing a large number of meshes; that way, that
     *  object can be created once and then rendered very efficiently, without having to copy its
     *  vertices and indices between buffers and GPU memory.</p>
     *
     *  @see Mesh
     *  @see Sprite
     */
    public class MeshBatch extends Mesh
    {
        private static const MAX_NUM_VERTICES:int = 65535;

        private var _effect:MeshEffect;
        private var _batchable:Boolean;
        private var _vertexSyncRequired:Boolean;
        private var _indexSyncRequired:Boolean;

        // helper object
        private static var sFullMeshSubset:MeshSubset = new MeshSubset();

        /** Creates a new, empty MeshBatch instance. */
        public function MeshBatch()
        {
            var vertexData:VertexData = new VertexData(MeshStyle.VERTEX_FORMAT);
            var indexData:IndexData = new IndexData();

            super(vertexData, indexData);

            // per default, 'batchable' is false -> no render cache
            updateSupportsRenderCache();
        }

        // display object overrides

        /** @inheritDoc */
        override public function dispose():void
        {
            if (_effect) _effect.dispose();
            super.dispose();
        }

        /** @inheritDoc */
        override protected function get supportsRenderCache():Boolean
        {
            return _batchable && super.supportsRenderCache;
        }

        private function setVertexAndIndexDataChanged():void
        {
            _vertexSyncRequired = _indexSyncRequired = true;
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
            _vertexData.numVertices = 0;
            _indexData.numIndices   = 0;
            _vertexSyncRequired = true;
            _indexSyncRequired  = true;
        }

        /** Adds a mesh to the batch.
         *
         *  @param mesh      the mesh to add to the batch.
         *  @param matrix    transform all vertex positions with a certain matrix. If this
         *                   parameter is omitted, <code>mesh.transformationMatrix</code>
         *                   will be used instead (except if the last parameter is enabled).
         *  @param alpha     will be multiplied with each vertex' alpha value.
         *  @param blendMode if given, replaces the blend mode of the mesh instance.
         *  @param subset    the subset of the mesh you want to add, or <code>null</code> for
         *                   the complete mesh.
         *  @param ignoreTransformation  to copy the vertices without any transformation, pass
         *                   <code>null</code> as 'matrix' parameter and <code>true</code> for this
         *                   one.
         */
        public function addMesh(mesh:Mesh, matrix:Matrix=null, alpha:Number=1.0, blendMode:String=null,
                                subset:MeshSubset=null, ignoreTransformation:Boolean=false):void
        {
            if (matrix == null && !ignoreTransformation) matrix = mesh.transformationMatrix;
            if (blendMode == null) blendMode = mesh.blendMode;
            if (subset == null) subset = sFullMeshSubset;

            var targetVertexID:int = _vertexData.numVertices;
            var targetIndexID:int  = _indexData.numIndices;
            var meshStyle:MeshStyle = mesh._style;

            if (targetVertexID == 0)
            {
                var meshStyleType:Class = meshStyle.type;

                if (_style.type != meshStyleType)
                {
                    if (_effect)
                    {
                        _effect.dispose();
                        _effect = null;
                    }

                    setStyle(new meshStyleType() as MeshStyle, false);
                }

                if (_effect == null)
                {
                    _effect = _style.createEffect();
                    _effect.onRestore = setVertexAndIndexDataChanged;
                }

                _style.copyFrom(meshStyle);
                this.blendMode = blendMode;
            }

            meshStyle.copyVertexDataTo(_vertexData, targetVertexID, matrix, subset.vertexID, subset.numVertices);
            meshStyle.copyIndexDataTo(_indexData, targetIndexID, targetVertexID - subset.vertexID,
                subset.indexID, subset.numIndices);

            if (alpha != 1.0) _vertexData.scaleAlphas("color", alpha, targetVertexID);
            if (_batchable) setRequiresRedraw();

            _indexSyncRequired = _vertexSyncRequired = true;
        }

        /** Indicates if the given mesh instance fits to the current state of the batch.
         *  Will always return <code>true</code> for the first added object; later calls
         *  will check if style or blend mode differ in any way.
         *
         *  @param mesh         the mesh to add to the batch.
         *  @param blendMode    if <code>null</code>, <code>mesh.blendMode</code> will be used
         *  @param numVertices  if <code>-1</code>, <code>mesh.numVertices</code> will be used
         *  @return
         */
        public function canAddMesh(mesh:Mesh, blendMode:String=null, numVertices:int=-1):Boolean
        {
            if (numVertices < 0) numVertices = _vertexData.numVertices;
            if (numVertices == 0) return true;
            if (numVertices + mesh.numVertices > MAX_NUM_VERTICES) return false;
            if (blendMode == null) blendMode = mesh.blendMode;

            return _style.canBatchWith(mesh._style) && this.blendMode == blendMode;
        }

        /** If the <code>batchable</code> property is enabled, this method will add the batch
         *  to the painter's current batch. Otherwise, this will actually do the drawing. */
        override public function render(painter:Painter):void
        {
            if (_vertexData.numVertices == 0)
            {
                // nothing to do =)
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

                _style.updateEffect(_effect, painter.state);
                _effect.render(0, _indexData.numTriangles);
            }
        }

        /** Indicates if this object will be added to the painter's batch on rendering,
         *  or if it will draw itself right away. */
        public function get batchable():Boolean { return _batchable; }
        public function set batchable(value:Boolean):void
        {
            if (value != _batchable) // self-rendering must disrupt the render cache
            {
                _batchable = value;
                updateSupportsRenderCache();
            }
        }
    }
}
