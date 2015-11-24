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

    import starling.events.Event;
    import starling.rendering.IndexData;
    import starling.rendering.MeshEffect;
    import starling.rendering.MeshStyle;
    import starling.rendering.Painter;
    import starling.rendering.VertexData;
    import starling.utils.MeshSubset;
    import starling.utils.MeshUtil;

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
    public class MeshBatch extends DisplayObject
    {
        private static const MAX_NUM_VERTICES:int = 65535;

        private var _effect:MeshEffect;
        private var _style:MeshStyle;
        private var _mesh:Mesh;

        private var _vertexSyncRequired:Boolean;
        private var _indexSyncRequired:Boolean;
        private var _batchable:Boolean;

        private var _vertexData:VertexData;
        private var _indexData:IndexData;

        // helper object
        private static var sFullMeshSubset:MeshSubset = new MeshSubset();

        /** Creates a new, empty MeshBatch instance. */
        public function MeshBatch()
        {
            _vertexData = new VertexData(MeshStyle.VERTEX_FORMAT);
            _indexData = new IndexData();
            _mesh = new Mesh(_vertexData, _indexData);
            _style = _mesh.style;

            // as long as 'batchable' is false, batches disrupt the render cache
            addEventListener(Event.ENTER_FRAME, onEnterFrameWhileNotBatchable);
        }

        private function onEnterFrameWhileNotBatchable():void
        {
            // we need to wrap 'setRequiresRedraw' with this method, otherwise we'd run into
            // problems when subclasses want to disable the render cache, as well.

            setRequiresRedraw();
        }

        // display object overrides

        /** @inheritDoc */
        override public function dispose():void
        {
            // the ownership of vertex- and index-data is on the mesh;
            // thus, the mesh will dispose them.

            if (_effect) _effect.dispose();
            if (_mesh)   _mesh.dispose();

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
            return MeshUtil.calculateBounds(_vertexData, this, targetSpace, out);
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

            if (targetVertexID == 0)
            {
                var styleType:Class = mesh.style.type;

                if (_style.type != styleType)
                {
                    if (_effect)
                    {
                        _effect.dispose();
                        _effect = null;
                    }

                    _style = new styleType() as MeshStyle;
                    _mesh.style = _style;
                }

                if (_effect == null)
                {
                    _effect = _style.createEffect();
                    _effect.onRestore = setVertexAndIndexDataChanged;
                }

                _style.copyFrom(mesh.style);
                _mesh.blendMode = this.blendMode = blendMode;
            }

            mesh.copyVertexDataTo(_vertexData, targetVertexID, matrix, subset.vertexID, subset.numVertices);
            mesh.copyIndexDataTo(_indexData, targetIndexID, targetVertexID - subset.vertexID,
                subset.indexID, subset.numIndices);

            if (alpha != 1.0) _vertexData.scaleAlphas("color", alpha, targetVertexID);
            if (_batchable) setRequiresRedraw();

            _indexSyncRequired = _vertexSyncRequired = true;
        }

        /** Indicates if the given mesh instance fits to the current state of the batch.
         *  Will always return <code>true</code> for the first added object; later calls
         *  will check if style or blend mode differ in any way. */
        public function canAddMesh(mesh:Mesh, blendMode:String=null):Boolean
        {
            var numVertices:int = _vertexData.numVertices;

            if (numVertices == 0) return true;
            if (numVertices + mesh.numVertices > MAX_NUM_VERTICES) return false;
            if (blendMode == null) blendMode = mesh.blendMode;

            return _style.canBatchWith(mesh.style) && this.blendMode == blendMode;
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
                painter.batchMesh(_mesh);
            }
            else
            {
                painter.finishMeshBatch();
                painter.drawCount += 1;
                painter.prepareToDraw();

                if (_vertexSyncRequired) syncVertexBuffer();
                if (_indexSyncRequired)  syncIndexBuffer();

                _style.updateEffect(_effect);
                _effect.mvpMatrix = painter.state.mvpMatrix3D;
                _effect.alpha = painter.state.alpha;
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

                if (value) removeEventListener(Event.ENTER_FRAME, onEnterFrameWhileNotBatchable);
                else       addEventListener(Event.ENTER_FRAME, onEnterFrameWhileNotBatchable);
            }
        }

        /** The aggregate mesh, which is a combination of all added meshes. */
        public function get mesh():Mesh
        {
            // TODO when BatchProcessor becomes a display object, make this property internal.
            //      It's not used anywhere else right now.
            return _mesh;
        }

        /** The style of the aggregate mesh. */
        public function get style():MeshStyle { return _style; }
        public function set style(value:MeshStyle):void
        {
            _style = _mesh.style = value;
        }
    }
}
