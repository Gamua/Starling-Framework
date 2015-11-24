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
    import flash.geom.Matrix;

    import starling.display.Mesh;
    import starling.display.MeshBatch;
    import starling.utils.MeshSubset;

    /** This class manages a list of mesh batches of different types;
     *  it acts as a "meta" MeshBatch that initiates all rendering.
     */
    public class BatchProcessor
    {
        private var _batches:Vector.<MeshBatch>;
        private var _batchPool:BatchPool;
        private var _currentBatch:MeshBatch;
        private var _currentStyleType:Class;
        private var _onBatchComplete:Function;
        private var _cacheToken:BatchToken;

        // helper objects
        private static var sCacheToken:BatchToken = new BatchToken();
        private static var sFullMeshSubset:MeshSubset = new MeshSubset();
        private static var sTempMeshSubset:MeshSubset = new MeshSubset();

        /** Creates a new batch processor. */
        public function BatchProcessor()
        {
            _batches = new <MeshBatch>[];
            _batchPool = new BatchPool();
            _cacheToken = new BatchToken();
        }

        /** Disposes all batches (including those in the reusable pool). */
        public function dispose():void
        {
            for each (var batch:MeshBatch in _batches)
                batch.dispose();

            _batches.length = 0;
            _batchPool.purge();
            _currentBatch = null;
        }

        /** Adds a mesh to the current batch, or to a new one if the current one does not support
         *  it. Whenever the batch changes, <code>onBatchComplete</code> is called for the previous
         *  one.
         *
         *  @param mesh       the mesh to add to the current (or new) batch.
         *  @param matrix     transform all vertex positions with a certain matrix. If this
         *                    parameter is omitted, <code>mesh.transformationMatrix</code>
         *                    will be used instead (except if the last parameter is enabled).
         *  @param alpha      will be multiplied with each vertex' alpha value.
         *  @param blendMode  if given, replaces the blend mode of the mesh instance.
         *  @param subset     the subset of the mesh you want to add, or <code>null</code> for
         *                    the complete mesh.
         *  @param ignoreTransformation  to copy the vertices without any transformation, pass
         *                    <code>null</code> as 'matrix' parameter and <code>true</code> for this
         *                    one.
         */
        public function addMesh(mesh:Mesh, matrix:Matrix=null, alpha:Number=1.0, blendMode:String=null,
                                subset:MeshSubset=null, ignoreTransformation:Boolean=false):void
        {
            if (subset == null) subset = sFullMeshSubset;

            if (_currentBatch == null || !_currentBatch.canAddMesh(mesh, blendMode))
            {
                finishBatch();

                _currentStyleType = mesh.style.type;
                _currentBatch = _batchPool.get(_currentStyleType);
                _cacheToken.setTo(_batches.length);
                _batches[_batches.length] = _currentBatch;
            }

            var numVertices:int = subset.numVertices;
            var numIndices:int  = subset.numIndices;

            if (numVertices < 0) numVertices = mesh.numVertices - subset.vertexID;
            if (numIndices  < 0) numIndices  = mesh.numIndices  - subset.indexID;

            _currentBatch.addMesh(mesh, matrix, alpha, blendMode, subset, ignoreTransformation);
            _cacheToken.vertexID += numVertices;
            _cacheToken.indexID  += numIndices;
        }

        /** Finishes the current batch, i.e. call the 'onComplete' callback on the batch and
         *  prepares initialization of a new one. */
        public function finishBatch():void
        {
            var meshBatch:MeshBatch = _currentBatch;

            if (meshBatch)
            {
                _currentBatch = null;
                _currentStyleType = null;

                if (_onBatchComplete != null)
                    _onBatchComplete(meshBatch);
            }
        }

        /** Clears all batches and adds them to a pool so they can be reused later. */
        public function clear():void
        {
            var numBatches:int = _batches.length;

            for (var i:int=0; i<numBatches; ++i)
                _batchPool.put(_batches[i]);

            _batches.length = 0;
            _currentBatch = null;
            _currentStyleType = null;
            _cacheToken.reset();
        }

        /** Disposes all batches that are currently unused. */
        public function trim():void
        {
            _batchPool.purge();
        }

        /** Sets all properties of the given token so that it describes the current position
         *  within this instance. */
        public function fillToken(token:BatchToken):BatchToken
        {
            token.batchID  = _cacheToken.batchID;
            token.vertexID = _cacheToken.vertexID;
            token.indexID  = _cacheToken.indexID;
            return token;
        }

        /** Adds the meshes from the given BatchProcessor to this instance.
         *
         *  @param batchProcessor  the object the meshes should be taken from.
         *  @param startToken      the position of the first vertex to be copied.
         *  @param endToken        the position of the last vertex to be copied.
         */
        public function addMeshesFrom(batchProcessor:BatchProcessor,
                                      startToken:BatchToken, endToken:BatchToken):void
        {
            var meshBatch:MeshBatch;
            var subset:MeshSubset;

            fillToken(sCacheToken);

            for (var i:int = startToken.batchID; i <= endToken.batchID; ++i)
            {
                subset = sTempMeshSubset;
                subset.setTo(); // resets subset

                if (i == startToken.batchID)
                {
                    subset.vertexID = startToken.vertexID;
                    subset.indexID  = startToken.indexID;
                }

                if (i == endToken.batchID)
                {
                    subset.numVertices = endToken.vertexID - subset.vertexID;
                    subset.numIndices  = endToken.indexID  - subset.indexID;
                }

                if (subset.numVertices != 0)
                {
                    meshBatch = batchProcessor._batches[i];
                    addMesh(meshBatch.mesh, null, 1.0, null, subset, true);
                }
            }

            fillToken(endToken);
            startToken.copyFrom(sCacheToken);
        }

        /** This callback is executed whenever a batch is finished and replaced by a new one.
         *  The finished MeshBatch is passed to the callback. Typically, this callback is used
         *  to actually render it. */
        public function get onBatchComplete():Function { return _onBatchComplete; }
        public function set onBatchComplete(value:Function):void { _onBatchComplete = value; }
    }
}

import flash.utils.Dictionary;

import starling.display.MeshBatch;

class BatchPool
{
    private var _batchLists:Dictionary;

    public function BatchPool()
    {
        _batchLists = new Dictionary();
    }

    public function purge():void
    {
        for each (var batchList:Vector.<MeshBatch> in _batchLists)
        {
            for (var i:int=0; i<batchList.length; ++i)
                batchList[i].dispose();

            batchList.length = 0;
        }
    }

    public function get(styleType:Class):MeshBatch
    {
        var batchList:Vector.<MeshBatch> = _batchLists[styleType];
        if (batchList == null)
        {
            batchList = new <MeshBatch>[];
            _batchLists[styleType] = batchList;
        }

        if (batchList.length > 0) return batchList.pop();
        else return new MeshBatch();
    }

    public function put(meshBatch:MeshBatch):void
    {
        var styleType:Class = meshBatch.style.type;
        var batchList:Vector.<MeshBatch> = _batchLists[styleType];
        if (batchList == null)
        {
            batchList = new <MeshBatch>[];
            _batchLists[styleType] = batchList;
        }

        meshBatch.clear();
        batchList[batchList.length] = meshBatch;
    }
}
