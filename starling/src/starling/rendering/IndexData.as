// =================================================================================================
//
//  Starling Framework
//  Copyright 2011-2015 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.rendering
{
    import flash.display3D.Context3D;
    import flash.display3D.IndexBuffer3D;
    import flash.utils.ByteArray;
    import flash.utils.Endian;

    import starling.core.Starling;
    import starling.errors.MissingContextError;
    import starling.utils.StringUtil;

    /** The IndexData class manages a raw list of vertex indices, allowing direct upload
     *  to Stage3D index buffers. <em>You only have to work with this class if you're writing
     *  your own rendering code (e.g. if you create custom display objects).</em>
     *
     *  <p>To render objects with Stage3D, you have to organize vertices and indices in so-called
     *  vertex- and index buffers. Vertex buffers store the coordinates of the vertices that make
     *  up an object; index buffers reference those vertices to determine which vertices spawn
     *  up triangles. Those buffers reside in graphics memory and can be accessed very
     *  efficiently by the GPU.</p>
     *
     *  <p>Before you can move data into the buffers, you have to set it up in conventional
     *  memory - that is, in a Vector or a ByteArray. Since it's quite cumbersome to manually
     *  create and manipulate those data structures, the IndexData and VertexData classes provide
     *  a simple way to do just that. The data is stored in a ByteArray (one index or vertex after
     *  the other) that can easily be uploaded to a buffer.</p>
     *
     *  @see VertexData
     */
    public class IndexData
    {
        /** The number of bytes per index element. */
        private static const INDEX_SIZE:int = 2;

        private var _rawData:ByteArray;
        private var _numIndices:int;

        // helper objects
        private static var sVector:Vector.<uint> = new <uint>[];
        private static var sBytes:ByteArray = new ByteArray();

        /** Creates an empty IndexData instance with the given capacity (in indices).
         *
         *  @param initialCapacity
         *
         *  The initial capacity affects just the way the internal ByteArray is allocated, not the
         *  <code>numIndices</code> value, which will always be zero when the constructor returns.
         *  The reason for this behavior is the peculiar way in which ByteArrays organize their
         *  memory:
         *
         *  <p>The first time you set the length of a ByteArray, it will adhere to that:
         *  a ByteArray with length 20 will take up 20 bytes (plus some overhead). When you change
         *  it to a smaller length, it will stick to the original value, e.g. with a length of 10
         *  it will still take up 20 bytes. However, now comes the weird part: change it to
         *  anything above the original length, and it will allocate 4096 bytes!</p>
         *
         *  <p>Thus, be sure to always make a generous educated guess, depending on the planned
         *  usage of your VertexData instances.</p>
         *
         */
        public function IndexData(initialCapacity:int=48)
        {
            _numIndices = 0;
            _rawData = new ByteArray();
            _rawData.endian = Endian.LITTLE_ENDIAN;
            _rawData.length = initialCapacity * INDEX_SIZE; // just for the initial allocation
            _rawData.length = 0;                            // changes length, but not memory!
        }

        /** Explicitly frees up the memory used by the ByteArray. */
        public function clear():void
        {
            _rawData.clear();
            _numIndices = 0;
        }

        /** Creates a duplicate of either the complete IndexData object, or of a subset.
         *  To clone all indices, call the method without any arguments. */
        public function clone(indexID:int=0, numIndices:int=-1):IndexData
        {
            if (numIndices < 0 || indexID + numIndices > _numIndices)
                numIndices = _numIndices - indexID;

            var clone:IndexData = new IndexData(numIndices);
            clone._rawData.writeBytes(_rawData, indexID * INDEX_SIZE, numIndices * INDEX_SIZE);
            clone._numIndices = numIndices;

            return clone;
        }

        /** Copies the index data (or a range of it, defined by 'indexID' and 'numIndices')
         *  of this instance to another IndexData object, starting at a certain target index.
         *  If the target is not big enough, it will be resized to fit all the new indices.
         *
         *  <p>By passing a non-zero <code>offset</code>, you can raise all copied indices
         *  by that value in the target object.</p> */
        public function copyTo(target:IndexData, targetIndexID:int=0, offset:int=0,
                               indexID:int=0, numIndices:int=-1):void
        {
            if (numIndices < 0 || indexID + numIndices > _numIndices)
                numIndices = _numIndices - indexID;

            if (target._numIndices < targetIndexID + numIndices)
                target._numIndices = targetIndexID + numIndices;

            var targetRawData:ByteArray = target._rawData;
            targetRawData.position = targetIndexID * INDEX_SIZE;

            if (offset == 0)
                targetRawData.writeBytes(_rawData, indexID * INDEX_SIZE, numIndices * INDEX_SIZE);
            else
            {
                _rawData.position = indexID * INDEX_SIZE;

                // by reading junks of 32 instead of 16 bits, we can spare half the time
                while (numIndices > 1)
                {
                    var indexAB:uint = _rawData.readUnsignedInt();
                    var indexA:uint  = ((indexAB & 0xffff0000) >> 16) + offset;
                    var indexB:uint  = ((indexAB & 0x0000ffff)      ) + offset;
                    targetRawData.writeUnsignedInt(indexA << 16 | indexB);
                    numIndices -= 2;
                }

                if (numIndices)
                    targetRawData.writeShort(_rawData.readUnsignedShort() + offset);
            }
        }

        /** Sets an index at the specified position. */
        public function setIndex(indexID:int, index:uint):void
        {
            if (_numIndices < indexID + 1)
                 numIndices = indexID + 1;

            _rawData.position = indexID * INDEX_SIZE;
            _rawData.writeShort(index);
        }

        /** Reads the index from the specified position. */
        public function getIndex(indexID:int):int
        {
            _rawData.position = indexID * INDEX_SIZE;
            return _rawData.readUnsignedShort();
        }

        /** Adds an offset to all indices in the specified range. */
        public function offsetIndices(offset:int, indexID:int=0, numIndices:int=-1):void
        {
            if (numIndices < 0 || indexID + numIndices > _numIndices)
                numIndices = _numIndices - indexID;

            var endIndex:int = indexID + numIndices;

            for (var i:int=indexID; i<endIndex; ++i)
                setIndex(i, getIndex(i) + offset);
        }

        /** Appends three indices representing a triangle. Reference the vertices clockwise,
         *  as this defines the front side of the triangle. */
        public function appendTriangle(a:uint, b:uint, c:uint):void
        {
            _rawData.position = _numIndices * INDEX_SIZE;
            _rawData.writeShort(a);
            _rawData.writeShort(b);
            _rawData.writeShort(c);
            _numIndices += 3;
        }

        /** Appends two triangles spawning up the quad with the given indices.
         *  The indices of the vertices are arranged like this:
         *
         *  <pre>
         *  a - b
         *  | / |
         *  c - d
         *  </pre>
         */
        public function appendQuad(a:uint, b:uint, c:uint, d:uint):void
        {
            _rawData.position = _numIndices * INDEX_SIZE;
            _rawData.writeShort(a);
            _rawData.writeShort(b);
            _rawData.writeShort(c);
            _rawData.writeShort(b);
            _rawData.writeShort(d);
            _rawData.writeShort(c);
            _numIndices += 6;
        }

        /** Creates a vector containing all indices. If you pass an existing vector to the method,
         *  its contents will be overwritten. */
        public function toVector(out:Vector.<uint>=null):Vector.<uint>
        {
            if (out == null) out = new Vector.<uint>(_numIndices);
            else out.length = _numIndices;

            _rawData.position = 0;

            for (var i:int=0; i<_numIndices; ++i)
                out[i] = _rawData.readUnsignedShort();

            return out;
        }

        /** Returns a string representation of the IndexData object,
         *  including a comma-separated list of all indices. */
        public function toString():String
        {
            var string:String = StringUtil.format("[IndexData numIndices={0} indices=\"{1}\"]",
                _numIndices, toVector(sVector).join());

            sVector.length = 0;
            return string;
        }

        // IndexBuffer helpers

        /** Creates an index buffer object with the right size to fit the complete data.
         *  Optionally, the current data is uploaded right away. */
        public function createIndexBuffer(upload:Boolean=false,
                                          bufferUsage:String="staticDraw"):IndexBuffer3D
        {
            var context:Context3D = Starling.context;
            if (context == null) throw new MissingContextError();

            var buffer:IndexBuffer3D = context.createIndexBuffer(_numIndices, bufferUsage);

            if (upload) uploadToIndexBuffer(buffer);
            return buffer;
        }

        /** Uploads the complete data (or a section of it) to the given index buffer. */
        public function uploadToIndexBuffer(buffer:IndexBuffer3D, indexID:int=0, numIndices:int=-1):void
        {
            if (numIndices < 0 || indexID + numIndices > _numIndices)
                numIndices = _numIndices - indexID;

            buffer.uploadFromByteArray(_rawData, 0, indexID, numIndices);
        }

        /** Optimizes the ByteArray so that it has exactly the required capacity, without
         *  wasting any memory. If your IndexData object grows larger than the initial capacity
         *  you passed to the constructor, call this method to avoid the 4k memory problem. */
        public function trim():void
        {
            sBytes.length = _rawData.length;
            sBytes.position = 0;
            sBytes.writeBytes(_rawData);

            _rawData.clear();
            _rawData.length = sBytes.length;
            _rawData.writeBytes(sBytes);

            sBytes.clear();
        }

        // properties

        /** The total number of indices. If you make the object bigger, it will be filled up with
         *  indices set to zero. */
        public function get numIndices():int { return _numIndices; }
        public function set numIndices(value:int):void
        {
            if (value != _numIndices)
            {
                _rawData.length = value * INDEX_SIZE;
                _numIndices = value;
            }
        }

        /** The number of triangles that can be spawned up with the contained indices.
         *  (In other words: the number of indices divided by three.) */
        public function get numTriangles():int { return _numIndices / 3; }
        public function set numTriangles(value:int):void { numIndices = value * 3; }

        /** The number of bytes required for each index value. */
        public function get indexSizeInBytes():int { return INDEX_SIZE; }

        /** The raw index data; not a copy! */
        public function get rawData():ByteArray { return _rawData; }
    }
}
