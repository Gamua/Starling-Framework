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

    /** This class manages a list of mesh batches of different types;
     *  it acts as a "meta" MeshBatch that initiates all rendering.
     */
    public class BatchProcessor
    {
        private var _batches:Vector.<MeshBatch>;
        private var _batchPool:BatchPool;
        private var _currentBatch:MeshBatch;
        private var _currentBatchClass:Class;
        private var _onBatchComplete:Function;

        /** Creates a new batch processor. */
        public function BatchProcessor()
        {
            _batches = new <MeshBatch>[];
            _batchPool = new BatchPool();
        }

        /** Disposes all batches (including those in the reusable pool). */
        public function dispose():void
        {
            for each (var batch:MeshBatch in _batches)
                batch.dispose();

            _batches.length = 0;
            _batchPool.purge();
            _currentBatch = null;
            _currentBatchClass = null;
        }

        /** Adds a mesh to the current batch, or to a new one if the current one does not support
         *  it. Whenever the batch changes, <code>onBatchComplete</code> is called for the previous
         *  one.
         *
         *  @param mesh        the mesh to add to the current (or new) batch.
         *  @param batchClass  the class that should be used to batch/render the mesh;
         *                     must implement <code>IMeshBatch</code>.
         *  @param matrix      transforms the mesh with a certain matrix before adding it.
         *  @param alpha       will be multiplied with each vertex' alpha value.
         *  @param blendMode   will replace the blend mode of the mesh instance.         */
        public function addMesh(mesh:Mesh, batchClass:Class,
                                matrix:Matrix=null, alpha:Number=1.0, blendMode:String=null):void
        {
            var canAdd:Boolean = _currentBatch != null && _currentBatchClass == batchClass &&
                                 _currentBatch.canAddMesh(mesh, blendMode);
            if (!canAdd)
            {
                finishBatch();

                _currentBatch = _batchPool.get(batchClass);
                _currentBatchClass = batchClass;
                _batches[_batches.length] = _currentBatch;
            }

            _currentBatch.addMesh(mesh, matrix, alpha, blendMode);
        }

        /** Finishes the current batch, i.e. call the 'onComplete' callback on the batch and
         *  prepares initialization of a new one. */
        public function finishBatch():void
        {
            var meshBatch:MeshBatch = _currentBatch;

            if (meshBatch)
            {
                _currentBatch = null;
                _currentBatchClass = null;

                if (_onBatchComplete)
                    _onBatchComplete(meshBatch);
            }
        }

        /** Clears all batches and adds them to a pool so they can be reused later. */
        public function clear():void
        {
            var numBatches:int = _batches.length;
            var batch:MeshBatch;

            for (var i:int=0; i<numBatches; ++i)
                _batchPool.put(_batches[i]);

            _batches.length = 0;
            _currentBatch = null;
            _currentBatchClass = null;
        }

        /** Disposes all batches that are currently unused. */
        public function trim():void
        {
            _batchPool.purge();
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

    public function get(batchClass:Class):MeshBatch
    {
        var batchList:Vector.<MeshBatch> = _batchLists[batchClass];
        if (batchList == null)
        {
            batchList = new <MeshBatch>[];
            _batchLists[batchClass] = batchList;
        }

        if (batchList.length > 0) return batchList.pop();
        else return new batchClass();
    }

    public function put(meshBatch:MeshBatch):void
    {
        meshBatch.clear();
        var batchClass:Class = Object(meshBatch).constructor as Class;
        var batchList:Vector.<MeshBatch> = _batchLists[batchClass];
        batchList[batchList.length] = meshBatch;
    }
}
