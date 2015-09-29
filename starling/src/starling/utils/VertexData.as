// =================================================================================================
//
//  Starling Framework
//  Copyright 2011-2015 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.utils
{
    import flash.display3D.Context3D;
    import flash.display3D.VertexBuffer3D;
    import flash.errors.IllegalOperationError;
    import flash.geom.Matrix;
    import flash.geom.Matrix3D;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.geom.Vector3D;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;
    import flash.utils.Endian;

    import starling.core.Starling;
    import starling.errors.MissingContextError;

    /** The VertexData class manages a raw list of vertex information, allowing direct upload
     *  to Stage3D vertex buffers. <em>You only have to work with this class if you're writing
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
     *  <strong>Vertex Format</strong>
     *
     *  <p>The VertexData class requires a custom format string on initialization. With that
     *  string, you tell the class the attributes of each vertex. Here's an example:</p>
     *
     *  <pre>
     *  var vertexData:VertexData = new VertexData("position(float2), color(bytes4)");
     *  vertexData.setPoint(0, "position", 320, 480);
     *  vertexData.setColor(0, "color", 0xff00ff);
     *  </pre>
     *
     *  <p>This instance is set up with two attributes: "position" and "color". The keywords
     *  in parentheses depict the format and size of the data that each property uses; in this
     *  case, we store two floats for the position (taking up the x- and y-coordinates) and four
     *  bytes for the color. (The available formats are the same as those defined in the
     *  <code>Context3DVertexBufferFormat</code> class:
     *  <code>float1, float2, float3, float4, bytes4</code>.)</p>
     *
     *  <p>The attribute names are then used to read and write data to the respective positions
     *  inside a vertex. Furthermore, they come in handy when copying data from one VertexData
     *  instance to another: attributes with equal name and data format may be transferred between
     *  different VertexData objects, even when they contain different sets of attributes or have
     *  a different layout.</p>
     *
     *  <strong>Colors</strong>
     *
     *  <p>Always use the format <code>bytes4</code> for color data. The color access methods
     *  expect that format, since it's the most efficient way to store color data. Furthermore,
     *  you should always include the string "color" (or "Color") in the name of color data;
     *  that way, it will be recognized as such and will always have its alpha value pre-filled
     *  with the value "1.0".</p>
     *
     *  <strong>Premultiplied Alpha</strong>
     *
     *  <p>The color values of the "BitmapData" object contain premultiplied alpha values, which
     *  means that the <code>rgb</code> values were multiplied with the <code>alpha</code> value
     *  before saving them. Since textures are often created from bitmap data, they contain the
     *  values in the same style. On rendering, it makes a difference in which way the alpha value
     *  is saved; for that reason, the VertexData class mimics this behavior. You can choose how
     *  the alpha values should be handled per attribute via the
     *  <code>get/setPremultipliedAlpha()</code> methods.</p>
     *
     *  @see IndexData
     */
    public class VertexData
    {
        private var _rawData:ByteArray;
        private var _format:String;
        private var _formatID:int;
        private var _attributes:Vector.<Attribute>;
        private var _numAttributes:int;
        private var _posOffset:int;  // in bytes
        private var _vertexSize:int; // in bytes
        private var _numVertices:int;

        private static var sFormats:Vector.<String> = new <String>[];  // fast format comparison
        private static var sFormatCache:Dictionary = new Dictionary(); // avoid multiple parsing

        // helper objects
        private static var sHelperPoint:Point = new Point();
        private static var sHelperPoint3D:Vector3D = new Vector3D();
        private static var sBytes:ByteArray = new ByteArray();

        /** Creates an empty VertexData object with the given format and initial capacity.
         *
         *  @param format
         *
         *  Describes the attributes of each vertex, consisting of a comma-separated
         *  list of attribute names and their format, e.g.:
         *
         *  <pre>"position(float2), color(bytes4), texCoords(float2)"</pre>
         *
         *  <p>This set of attributes will be allocated for each vertex, and they will be
         *  stored in exactly the given order.</p>
         *
         *  <ul>
         *    <li>Names are used to access the specific attributes of a vertex. They are
         *        completely arbitrary.</li>
         *    <li>The available formats can be found in the <code>Context3DVertexBufferFormat</code>
         *        class in the <code>flash.display3D</code> package.</li>
         *    <li>Both names and format strings are case-sensitive.</li>
         *    <li>Always use <code>bytes4</code> for color data that you want to access with the
         *        respective methods.</li>
         *    <li>Furthermore, the attribute names of colors should include the string "color"
         *        (or the camelcase variant). If that's the case, the "alpha" value of the color
         *        will automatically be initialized with "1.0" when the VertexData object is
         *        created or resized.</li>
         *  </ul>
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
         */
        public function VertexData(format:String, initialCapacity:int=32)
        {
            parseFormat(format);

            _numVertices = 0;
            _rawData = new ByteArray();
            _rawData.endian = Endian.LITTLE_ENDIAN;
            _rawData.length = initialCapacity * _vertexSize; // just for the initial allocation
            _rawData.length = 0;                             // changes length, but not memory!
        }

        /** Explicitly frees up the memory used by the ByteArray. */
        public function clear():void
        {
            _rawData.clear();
            _numVertices = 0;
        }

        /** Creates a duplicate of either the complete vertex data object, or of a subset.
         *  To clone all vertices, call the method without any arguments. */
        public function clone(vertexID:int=0, numVertices:int=-1):VertexData
        {
            if (numVertices < 0 || vertexID + numVertices > _numVertices)
                numVertices = _numVertices - vertexID;

            var clone:VertexData = new VertexData(_format, numVertices);
            clone._rawData.writeBytes(_rawData, vertexID * _vertexSize, numVertices * _vertexSize);
            clone._numVertices = numVertices;

            for (var i:int=0; i<_numAttributes; ++i)
                clone._attributes[i].pma = _attributes[i].pma;

            return clone;
        }

        /** Copies the vertex data (or a range of it, defined by 'vertexID' and 'numVertices')
         *  of this instance to another vertex data object, starting at a certain index. If the
         *  target is not big enough, it will be resized to fit all the new vertices.
         *
         *  <p>Source and target do not need to have the exact same format. Only properties that
         *  exist in the target will be copied; others will be ignored. If a property with the
         *  same name but a different format exists in the target, an exception will be raised.
         *  Copying will be faster, though, if the two formats are identical.</p>
         */
        public function copyTo(target:VertexData, targetVertexID:int=0,
                               vertexID:int=0, numVertices:int=-1):void
        {
            copyToTransformed(target, targetVertexID, null, vertexID, numVertices);
        }

        /** Copies the vertex data (or a range of it, defined by 'vertexID' and 'numVertices')
         *  of this instance to another vertex data object, starting at a certain index.
         *  At the same time, the 2D position of each vertex will be transformed via a matrix-
         *  multiplication. If the target is not big enough, it will be resized to fit all the
         *  new vertices.
         *
         *  <p>The position of a vertex is either an attribute with the name "position", or (if
         *  such an attribute is not found) the first attribute of each vertex. It must consist
         *  of two float values containing the x- and y-coordinates of the vertex.</p>
         *
         *  <p>Source and target do not need to have the exact same format. Only properties that
         *  exist in the target will be copied; others will be ignored. If a property with the
         *  same name but a different format exists in the target, an exception will be raised.
         *  Beware, though, that the copy-operation becomes much more expensive when the formats
         *  differ.</p>
         */
        public function copyToTransformed(target:VertexData, targetVertexID:int, matrix:Matrix,
                                          vertexID:int=0, numVertices:int=-1):void
        {
            if (numVertices < 0 || vertexID + numVertices > _numVertices)
                numVertices = _numVertices - vertexID;

            if (_formatID == target._formatID)
            {
                if (target._numVertices < targetVertexID + numVertices)
                    target._numVertices = targetVertexID + numVertices;

                // In this case, it's fastest to copy the complete range in one call
                // and then overwrite only the transformed positions.

                var targetRawData:ByteArray = target._rawData;
                targetRawData.position = targetVertexID * _vertexSize;
                targetRawData.writeBytes(_rawData, vertexID * _vertexSize, numVertices * _vertexSize);

                if (matrix)
                {
                    var x:Number, y:Number;
                    var position:int = targetVertexID * _vertexSize + _posOffset;
                    var endPosition:int = position + (numVertices * _vertexSize);

                    while (position < endPosition)
                    {
                        targetRawData.position = position;
                        x = targetRawData.readFloat();
                        y = targetRawData.readFloat();

                        targetRawData.position = position;
                        targetRawData.writeFloat(matrix.a * x + matrix.c * y + matrix.tx);
                        targetRawData.writeFloat(matrix.d * y + matrix.b * x + matrix.ty);

                        position += _vertexSize;
                    }
                }
            }
            else
            {
                if (target._numVertices < targetVertexID + numVertices)
                    target.numVertices  = targetVertexID + numVertices; // ensure correct alphas!

                for (var i:int=0; i<_numAttributes; ++i)
                {
                    var srcAttr:Attribute = _attributes[i];
                    var tgtAttr:Attribute = target.getAttribute(srcAttr.name);

                    if (tgtAttr) // only copy attributes that exist in the target, as well
                    {
                        if (srcAttr.offset == _posOffset)
                            copyAttributeToTransformed_internal(target, targetVertexID, matrix,
                                    srcAttr, tgtAttr, vertexID, numVertices);
                        else
                            copyAttributeToTransformed_internal(target, targetVertexID, null,
                                    srcAttr, tgtAttr, vertexID, numVertices);
                    }
                }
            }
        }

        /** Copies a specific attribute of a range of vertices to another VertexData instance.
         *  Beware that both name and format must be identical in the target VertexData object.
         *  If the target is not big enough, it will be resized to fit all the new vertices.
         */
        public function copyAttributeTo(target:VertexData, targetVertexID:int, attrName:String,
                                        vertexID:int=0, numVertices:int=-1):void
        {
            copyAttributeToTransformed(target, targetVertexID, null, attrName, vertexID, numVertices);
        }

        /** Copies a specific attribute of a range of vertices to another VertexData instance.
         *  Beware that both name and format must be identical in the target VertexData object.
         *  At the same time, a specific attribute (which should point to a 2D Point) is transformed
         *  via multiplication with a matrix. If the target is not big enough, it will be resized
         *  to fit all the new vertices.
         */
        public function copyAttributeToTransformed(target:VertexData, targetVertexID:int,
                                                   matrix:Matrix, attrName:String="position",
                                                   vertexID:int=0, numVertices:int=-1):void
        {
            var sourceAttribute:Attribute = getAttribute(attrName);
            var targetAttribute:Attribute = target.getAttribute(attrName);

            if (sourceAttribute == null)
                throw new ArgumentError("Attribute '" + attrName + "' not found in source data");

            if (targetAttribute == null)
                throw new ArgumentError("Attribute '" + attrName + "' not found in target data");

            copyAttributeToTransformed_internal(target, targetVertexID, matrix,
                    sourceAttribute, targetAttribute, vertexID, numVertices);
        }

        private function copyAttributeToTransformed_internal(
                target:VertexData, targetVertexID:int, matrix:Matrix,
                sourceAttribute:Attribute, targetAttribute:Attribute,
                vertexID:int, numVertices:int):void
        {
            if (sourceAttribute.format != targetAttribute.format)
                throw new IllegalOperationError("Attribute formats differ between source and target");

            if (numVertices < 0 || vertexID + numVertices > _numVertices)
                numVertices = _numVertices - vertexID;

            if (target._numVertices < targetVertexID + numVertices)
                target._numVertices = targetVertexID + numVertices;

            var i:int, j:int, x:Number, y:Number;
            var sourceData:ByteArray = _rawData;
            var targetData:ByteArray = target._rawData;
            var sourceDelta:int = _vertexSize - sourceAttribute.size;
            var targetDelta:int = target._vertexSize - targetAttribute.size;
            var attributeSizeIn32Bits:int = sourceAttribute.size / 4;

            sourceData.position = vertexID * _vertexSize + sourceAttribute.offset;
            targetData.position = targetVertexID * target._vertexSize + targetAttribute.offset;

            if (matrix)
            {
                for (i=0; i<numVertices; ++i)
                {
                    x = sourceData.readFloat();
                    y = sourceData.readFloat();

                    targetData.writeFloat(matrix.a * x + matrix.c * y + matrix.tx);
                    targetData.writeFloat(matrix.d * y + matrix.b * x + matrix.ty);

                    sourceData.position += sourceDelta;
                    targetData.position += targetDelta;
                }
            }
            else
            {
                for (i=0; i<numVertices; ++i)
                {
                    for (j=0; j<attributeSizeIn32Bits; ++j)
                        targetData.writeUnsignedInt(sourceData.readUnsignedInt());

                    sourceData.position += sourceDelta;
                    targetData.position += targetDelta;
                }
            }
        }

        /** Optimizes the ByteArray so that it has exactly the required capacity, without
         *  wasting any memory. If your VertexData object grows larger than the initial capacity
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

        // read / write attributes

        /** Reads a float value from the specified vertex and attribute. */
        public function getFloat(vertexID:int, attrName:String):Number
        {
            _rawData.position = vertexID * _vertexSize + getAttribute(attrName).offset;
            return _rawData.readFloat();
        }

        /** Writes a float value to the specified vertex and attribute. */
        public function setFloat(vertexID:int, attrName:String, value:Number):void
        {
            if (_numVertices < vertexID + 1)
                 numVertices = vertexID + 1;

            _rawData.position = vertexID * _vertexSize + getAttribute(attrName).offset;
            _rawData.writeFloat(value);
        }

        /** Reads a Point from the specified vertex and attribute. */
        public function getPoint(vertexID:int, attrName:String, out:Point=null):Point
        {
            if (out == null) out = new Point();

            _rawData.position = vertexID * _vertexSize + getAttribute(attrName).offset;
            out.x = _rawData.readFloat();
            out.y = _rawData.readFloat();

            return out;
        }

        /** Writes the given coordinates to the specified vertex and attribute. */
        public function setPoint(vertexID:int, attrName:String, x:Number, y:Number):void
        {
            if (_numVertices < vertexID + 1)
                 numVertices = vertexID + 1;

            _rawData.position = vertexID * _vertexSize + getAttribute(attrName).offset;
            _rawData.writeFloat(x);
            _rawData.writeFloat(y);
        }

        /** Reads a Vector3D from the specified vertex and attribute.
         *  The 'w' property of the Vector3D is ignored. */
        public function getPoint3D(vertexID:int, attrName:String, out:Vector3D=null):Vector3D
        {
            if (out == null) out = new Vector3D();

            _rawData.position = vertexID * _vertexSize + getAttribute(attrName).offset;
            out.x = _rawData.readFloat();
            out.y = _rawData.readFloat();
            out.z = _rawData.readFloat();

            return out;
        }

        /** Writes the given coordinates to the specified vertex and attribute. */
        public function setPoint3D(vertexID:int, attrName:String, x:Number, y:Number, z:Number):void
        {
            if (_numVertices < vertexID + 1)
                 numVertices = vertexID + 1;

            _rawData.position = vertexID * _vertexSize + getAttribute(attrName).offset;
            _rawData.writeFloat(x);
            _rawData.writeFloat(y);
            _rawData.writeFloat(z);
        }

        /** Reads a Vector3D from the specified vertex and attribute, including the fourth
         *  coordinate ('w'). */
        public function getPoint4D(vertexID:int, attrName:String, out:Vector3D=null):Vector3D
        {
            if (out == null) out = new Vector3D();

            _rawData.position = vertexID * _vertexSize + getAttribute(attrName).offset;
            out.x = _rawData.readFloat();
            out.y = _rawData.readFloat();
            out.z = _rawData.readFloat();
            out.w = _rawData.readFloat();

            return out;
        }

        /** Writes the given coordinates to the specified vertex and attribute. */
        public function setPoint4D(vertexID:int, attrName:String,
                                   x:Number, y:Number, z:Number, w:Number=1.0):void
        {
            if (_numVertices < vertexID + 1)
                 numVertices = vertexID + 1;

            _rawData.position = vertexID * _vertexSize + getAttribute(attrName).offset;
            _rawData.writeFloat(x);
            _rawData.writeFloat(y);
            _rawData.writeFloat(z);
            _rawData.writeFloat(w);
        }

        /** Reads an RGB color from the specified vertex and attribute (no alpha). */
        public function getColor(vertexID:int, attrName:String="color"):uint
        {
            var attribute:Attribute = getAttribute(attrName);
            _rawData.position = vertexID * _vertexSize + attribute.offset;
            var rgba:uint = switchEndian(_rawData.readUnsignedInt());
            if (attribute.pma) rgba = unmultiplyAlpha(rgba);
            return (rgba >> 8) & 0xffffff;
        }

        /** Writes the RGB color to the specified vertex and attribute (alpha is not changed). */
        public function setColor(vertexID:int, attrName:String, color:uint):void
        {
            var alpha:Number = vertexID < _numVertices ? getAlpha(vertexID, attrName) : 1.0;
            setColorAndAlpha(vertexID, attrName, color, alpha);
        }

        /** Reads the alpha value from the specified vertex and attribute. */
        public function getAlpha(vertexID:int, attrName:String="color"):Number
        {
            _rawData.position = vertexID * _vertexSize + getAttribute(attrName).offset;
            var rgba:uint = switchEndian(_rawData.readUnsignedInt());
            return (rgba & 0xff) / 255.0;
        }

        /** Writes the given alpha value to the specified vertex and attribute (range 0-1). */
        public function setAlpha(vertexID:int, attrName:String, alpha:Number):void
        {
            var color:uint = vertexID < _numVertices ? getColor(vertexID, attrName) : 0x0;
            setColorAndAlpha(vertexID, attrName, color, alpha);
        }

        /** Writes the given RGB and alpha values to the specified vertex and attribute. */
        public function setColorAndAlpha(vertexID:int, attrName:String, color:uint, alpha:Number):void
        {
            if (_numVertices < vertexID + 1)
                 numVertices = vertexID + 1;

            var attribute:Attribute = getAttribute(attrName);
            var minAlpha:Number = attribute.pma ? 5.0 / 255.0 : 0.0;

            if (alpha < minAlpha) alpha = minAlpha;
            else if (alpha > 1.0) alpha = 1.0;

            var rgba:uint = ((color << 8) & 0xffffff00) | (int(alpha * 255.0) & 0xff);
            if (attribute.pma && alpha != 1.0) rgba = premultiplyAlpha(rgba);

            _rawData.position = vertexID * _vertexSize + attribute.offset;
            _rawData.writeUnsignedInt(switchEndian(rgba));

            if (_numVertices < vertexID + 1)
                 numVertices = vertexID + 1;
        }

        /** Sets the specified range of vertices to the same RGB and alpha values. */
        public function setUniformColorAndAlpha(attrName:String, color:uint, alpha:Number,
                                                vertexID:int=0, numVertices:int=-1):void
        {
            if (numVertices < 0 || vertexID + numVertices > _numVertices)
                numVertices = _numVertices - vertexID;

            for (var i:int=0; i<numVertices; ++i)
                setColorAndAlpha(vertexID + i, attrName, color, alpha);
        }

        /** Multiplies the alpha values of subsequent vertices by a certain factor. */
        public function scaleAlphas(attrName:String, factor:Number, vertexID:int=0, numVertices:int=-1):void
        {
            if (factor == 1.0) return;
            if (numVertices < 0 || vertexID + numVertices > _numVertices)
                numVertices = _numVertices - vertexID;

            var i:int;
            var attribute:Attribute = getAttribute(attrName);

            if (attribute.pma)
            {
                for (i = 0; i < numVertices; ++i)
                    setAlpha(vertexID + i, attrName, getAlpha(vertexID + i) * factor);
            }
            else
            {
                var offset:int = vertexID * _vertexSize + attribute.offset + 3;
                var oldAlpha:Number;

                for (i = 0; i < numVertices; ++i)
                {
                    oldAlpha = _rawData[offset] / 255.0;
                    _rawData[offset] = int(oldAlpha * factor * 255.0);
                    offset += _vertexSize;
                }
            }
        }

        /** Calculates the bounds of the 2D vertex positions identified by the given name.
         *  The positions may optionally be transformed by a matrix before calculating the bounds.
         *  If you pass an 'out' Rectangle, the result will be stored in this rectangle
         *  instead of creating a new object. To use all vertices for the calculation, set
         *  'numVertices' to '-1'. */
        public function getBounds(attrName:String="position", matrix:Matrix=null,
                                  vertexID:int=0, numVertices:int=-1, out:Rectangle=null):Rectangle
        {
            if (out == null) out = new Rectangle();
            if (numVertices < 0 || vertexID + numVertices > _numVertices)
                numVertices = _numVertices - vertexID;

            if (numVertices == 0)
            {
                if (matrix == null)
                    out.setEmpty();
                else
                {
                    MatrixUtil.transformCoords(matrix, 0, 0, sHelperPoint);
                    out.setTo(sHelperPoint.x, sHelperPoint.y, 0, 0);
                }
            }
            else
            {
                var attribute:Attribute = getAttribute(attrName);
                var minX:Number = Number.MAX_VALUE, maxX:Number = -Number.MAX_VALUE;
                var minY:Number = Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE;
                var offset:int = vertexID * _vertexSize + attribute.offset;
                var x:Number, y:Number, i:int;

                if (matrix == null)
                {
                    for (i=0; i<numVertices; ++i)
                    {
                        _rawData.position = offset;
                        x = _rawData.readFloat();
                        y = _rawData.readFloat();
                        offset += _vertexSize;

                        if (minX > x) minX = x;
                        if (maxX < x) maxX = x;
                        if (minY > y) minY = y;
                        if (maxY < y) maxY = y;
                    }
                }
                else
                {
                    for (i=0; i<numVertices; ++i)
                    {
                        _rawData.position = offset;
                        x = _rawData.readFloat();
                        y = _rawData.readFloat();
                        offset += _vertexSize;

                        MatrixUtil.transformCoords(matrix, x, y, sHelperPoint);

                        if (minX > sHelperPoint.x) minX = sHelperPoint.x;
                        if (maxX < sHelperPoint.x) maxX = sHelperPoint.x;
                        if (minY > sHelperPoint.y) minY = sHelperPoint.y;
                        if (maxY < sHelperPoint.y) maxY = sHelperPoint.y;
                    }
                }

                out.setTo(minX, minY, maxX - minX, maxY - minY);
            }

            return out;
        }

        /** Calculates the bounds of the 2D vertex positions identified by the given name,
         *  projected into the XY-plane of a certain 3D space as they appear from the given
         *  camera position. Note that 'camPos' is expected in the target coordinate system
         *  (the same that the XY-plane lies in).
         *
         *  <p>If you pass an 'out' Rectangle, the result will be stored in this rectangle
         *  instead of creating a new object. To use all vertices for the calculation, set
         *  'numVertices' to '-1'.</p> */
        public function getBoundsProjected(attrName:String, matrix:Matrix3D,
                                           camPos:Vector3D, vertexID:int=0, numVertices:int=-1,
                                           out:Rectangle=null):Rectangle
        {
            if (out == null) out = new Rectangle();
            if (camPos == null) throw new ArgumentError("camPos must not be null");
            if (numVertices < 0 || vertexID + numVertices > _numVertices)
                numVertices = _numVertices - vertexID;

            if (numVertices == 0)
            {
                if (matrix)
                    MatrixUtil.transformCoords3D(matrix, 0, 0, 0, sHelperPoint3D);
                else
                    sHelperPoint3D.setTo(0, 0, 0);

                MathUtil.intersectLineWithXYPlane(camPos, sHelperPoint3D, sHelperPoint);
                out.setTo(sHelperPoint.x, sHelperPoint.y, 0, 0);
            }
            else
            {
                var attribute:Attribute = getAttribute(attrName);
                var minX:Number = Number.MAX_VALUE, maxX:Number = -Number.MAX_VALUE;
                var minY:Number = Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE;
                var offset:int = vertexID * _vertexSize + attribute.offset;
                var x:Number, y:Number, i:int;

                for (i=0; i<numVertices; ++i)
                {
                    _rawData.position = offset;
                    x = _rawData.readFloat();
                    y = _rawData.readFloat();
                    offset += _vertexSize;

                    if (matrix)
                        MatrixUtil.transformCoords3D(matrix, x, y, 0, sHelperPoint3D);
                    else
                        sHelperPoint3D.setTo(x, y, 0);

                    MathUtil.intersectLineWithXYPlane(camPos, sHelperPoint3D, sHelperPoint);

                    if (minX > sHelperPoint.x) minX = sHelperPoint.x;
                    if (maxX < sHelperPoint.x) maxX = sHelperPoint.x;
                    if (minY > sHelperPoint.y) minY = sHelperPoint.y;
                    if (maxY < sHelperPoint.y) maxY = sHelperPoint.y;
                }

                out.setTo(minX, minY, maxX - minX, maxY - minY);
            }

            return out;
        }

        /** Returns a string representation of the VertexData object,
         *  describing both its format and size. */
        public function toString():String
        {
            return StringUtil.format("[VertexData format=\"{0}\" numVertices={1}]",
                _format, _numVertices);
        }

        /** Indicates if the rgb values of the specified attribute are stored premultiplied with
         *  the alpha value. */
        public function getPremultipliedAlpha(attrName:String="color"):Boolean
        {
            return getAttribute(attrName).pma;
        }

        /** Changes the way alpha and color values are stored. Optionally updates all existing
         *  vertices. */
        public function setPremultipliedAlpha(attrName:String, value:Boolean=true, updateData:Boolean=true):void
        {
            var attribute:Attribute = getAttribute(attrName);

            if (updateData && value != attribute.pma)
            {
                var offset:int = attribute.offset;
                var oldColor:uint;
                var newColor:uint;

                for (var i:int=0; i<_numVertices; ++i)
                {
                    _rawData.position = offset;
                    oldColor = switchEndian(_rawData.readUnsignedInt());
                    newColor = value ? premultiplyAlpha(oldColor) : unmultiplyAlpha(oldColor);

                    _rawData.position = offset;
                    _rawData.writeUnsignedInt(switchEndian(newColor));

                    offset += _vertexSize;
                }
            }

            attribute.pma = value;
        }

        /** Indicates if any vertices have a non-white color or are not fully opaque. */
        public function isTinted(attrName:String="color"):Boolean
        {
            var offset:int = getAttribute(attrName).offset;

            for (var i:int=0; i<_numVertices; ++i)
            {
                _rawData.position = offset;

                if (_rawData.readUnsignedInt() != 0xffffffff)
                    return true;

                offset += _vertexSize;
            }

            return false;
        }

        /** Transforms the 2D positions of subsequent vertices by multiplication with a
         *  transformation matrix. */
        public function transformPoints(attrName:String, matrix:Matrix,
                                        vertexID:int=0, numVertices:int=1):void
        {
            if (numVertices < 0 || vertexID + numVertices > _numVertices)
                numVertices = _numVertices - vertexID;

            var x:Number, y:Number;
            var attribute:Attribute = getAttribute(attrName);
            var position:int = vertexID * _vertexSize + attribute.offset;
            var endPosition:int = position + (numVertices * _vertexSize);

            while (position < endPosition)
            {
                _rawData.position = position;
                x = _rawData.readFloat();
                y = _rawData.readFloat();

                _rawData.position = position;
                _rawData.writeFloat(matrix.a * x + matrix.c * y + matrix.tx);
                _rawData.writeFloat(matrix.d * y + matrix.b * x + matrix.ty);

                position += _vertexSize;
            }
        }

        /** Translate the position of a vertex by a certain offset. */
        public function translatePoint(vertexID:int, attrName:String, deltaX:Number, deltaY:Number):void
        {
            var x:Number, y:Number;
            var position:int = vertexID * _vertexSize + getAttribute(attrName).offset;

            _rawData.position = position;
            x = _rawData.readFloat();
            y = _rawData.readFloat();

            _rawData.position = position;
            _rawData.writeFloat(x + deltaX);
            _rawData.writeFloat(y + deltaY);
        }

        /** Returns the format of a certain vertex attribute, identified by its name.
          * Typical values: <code>float1, float2, float3, float4, bytes4</code>. */
        public function getFormat(attrName:String):String
        {
            return getAttribute(attrName).format;
        }

        /** Returns the size of a certain vertex attribute in bytes. */
        public function getSizeInBytes(attrName:String):int
        {
            return getAttribute(attrName).size;
        }

        /** Returns the size of a certain vertex attribute in 32 bit units. */
        public function getSizeIn32Bits(attrName:String):int
        {
            return getAttribute(attrName).size / 4;
        }

        /** Returns the offset (in bytes) of an attribute within a vertex. */
        public function getOffsetInBytes(attrName:String):int
        {
            return getAttribute(attrName).offset;
        }

        /** Returns the offset (in 32 bit units) of an attribute within a vertex. */
        public function getOffsetIn32Bits(attrName:String):int
        {
            return getAttribute(attrName).offset / 4;
        }

        /** Indicates if the VertexData instances contains an attribute with the specified name. */
        public function hasAttribute(attrName:String):Boolean
        {
            return getAttribute(attrName) != null;
        }

        // VertexBuffer helpers

        /** Creates a vertex buffer object with the right size to fit the complete data.
         *  Optionally, the current data is uploaded right away. */
        public function createVertexBuffer(upload:Boolean=false,
                                           bufferUsage:String="staticDraw"):VertexBuffer3D
        {
            var context:Context3D = Starling.context;
            if (context == null) throw new MissingContextError();

            var buffer:VertexBuffer3D = context.createVertexBuffer(
                _numVertices, _vertexSize / 4, bufferUsage);

            if (upload) uploadToVertexBuffer(buffer);
            return buffer;
        }

        /** Specifies the attribute to use at a certain register (identified by its index)
         *  in the vertex shader. */
        public function setVertexBufferAttribute(buffer:VertexBuffer3D, index:int, attrName:String):void
        {
            var attribute:Attribute = getAttribute(attrName);

            var context:Context3D = Starling.context;
            if (context == null) throw new MissingContextError();

            context.setVertexBufferAt(index, buffer, attribute.offset / 4, attribute.format);
        }

        /** Uploads the complete data (or a section of it) to the given vertex buffer. */
        public function uploadToVertexBuffer(buffer:VertexBuffer3D, vertexID:int=0, numVertices:int=-1):void
        {
            if (numVertices < 0 || vertexID + numVertices > _numVertices)
                numVertices = _numVertices - vertexID;

            buffer.uploadFromByteArray(_rawData, 0, vertexID, numVertices);
        }

        // helpers

        private function parseFormat(format:String):void
        {
            if (format == null || format == "")
                throw new ArgumentError("Format string must not be empty");
            else if (format in sFormatCache)
                readSettingsFromCache(format);
            else
            {
                _attributes = new <Attribute>[];
                _format = "";

                var parts:Array = format.split(",");
                var numParts:int = parts.length;
                var offset:int = 0;

                for (var i:int=0; i<numParts; ++i)
                {
                    var attrDesc:String = parts[i];
                    var openBracketPos:int  = attrDesc.indexOf("(");
                    var closeBracketPos:int = attrDesc.indexOf(")");

                    if (openBracketPos == -1 || closeBracketPos == -1)
                        throw new ArgumentError(("Missing parentheses: " + attrDesc));

                    var attrName:String = StringUtil.trim(attrDesc.substring(0, openBracketPos));
                    var attrFormat:String = StringUtil.trim(attrDesc.substring(openBracketPos + 1, closeBracketPos));

                    if (attrName.length == 0 || attrFormat.length == 0)
                        throw new ArgumentError(("Invalid format string: " + attrDesc));

                    if (attrName == "position")
                        _posOffset = offset;

                    var attr:Attribute = new Attribute(attrName, attrFormat, offset);
                    offset += attr.size;

                    _format += (i == 0 ? "" : ", ") + attr.name + "(" + attr.format + ")";
                    _attributes[_attributes.length] = attr; // avoid 'push'
                }

                _vertexSize = offset;
                _numAttributes = _attributes.length;
                _formatID = sFormats.indexOf(_format);

                if (_formatID == -1)
                {
                    _formatID = sFormats.length;
                    sFormats[_formatID] = _format;
                }

                writeSettingsToCache(format);
            }
        }

        private function readSettingsFromCache(format:String):void
        {
            var formatInfo:Object = sFormatCache[format];
            _format = formatInfo.format;
            _formatID = formatInfo.formatID;
            _posOffset = formatInfo.posOffset;
            _vertexSize = formatInfo.vertexSize;
            _numAttributes = formatInfo.attributes.length;
            _attributes = formatInfo.attributes.slice();
        }

        private function writeSettingsToCache(format:String):void
        {
            sFormatCache[format] = {
                format: _format, formatID: _formatID, posOffset: _posOffset,
                vertexSize: _vertexSize, attributes: _attributes.slice()
            };
        }

        [Inline]
        private final function getAttribute(name:String):Attribute
        {
            var i:int, attribute:Attribute;

            for (i=0; i<_numAttributes; ++i)
            {
                attribute = _attributes[i];
                if (attribute.name == name) return attribute;
            }

            return null;
        }

        [Inline]
        private static function switchEndian(value:uint):uint
        {
            return ( value        & 0xff) << 24 |
                   ((value >>  8) & 0xff) << 16 |
                   ((value >> 16) & 0xff) <<  8 |
                   ((value >> 24) & 0xff);
        }

        private static function premultiplyAlpha(rgba:uint):uint
        {
            var alpha:uint = rgba & 0xff;

            if (alpha == 0xff) return rgba;
            else
            {
                var factor:Number = alpha / 255.0;
                var r:uint = ((rgba >> 24) & 0xff) * factor;
                var g:uint = ((rgba >> 16) & 0xff) * factor;
                var b:uint = ((rgba >>  8) & 0xff) * factor;

                return (r & 0xff) << 24 |
                       (g & 0xff) << 16 |
                       (b & 0xff) <<  8 | alpha;
            }
        }

        private static function unmultiplyAlpha(rgba:uint):uint
        {
            var alpha:uint = rgba & 0xff;

            if (alpha == 0xff || alpha == 0x0) return rgba;
            else
            {
                var factor:Number = alpha / 255.0;
                var r:uint = ((rgba >> 24) & 0xff) / factor;
                var g:uint = ((rgba >> 16) & 0xff) / factor;
                var b:uint = ((rgba >>  8) & 0xff) / factor;

                return (r & 0xff) << 24 |
                       (g & 0xff) << 16 |
                       (b & 0xff) <<  8 | alpha;
            }
        }

        // properties

        /** The total number of vertices. If you make the object bigger, it will be filled up with
         *  <code>1.0</code> for all alpha values and zero for everything else. */
        public function get numVertices():int { return _numVertices; }
        public function set numVertices(value:int):void
        {
            if (_numVertices == value) return;

            _rawData.length = value * _vertexSize;

            for (var i:int=0; i<_numAttributes; ++i)
            {
                var attribute:Attribute = _attributes[i] as Attribute;
                var attrName:String = attribute.name;

                // alpha values of all color-properties must be initialized with "1.0"

                if (attrName.indexOf("color") != -1 || attrName.indexOf("Color") != -1)
                {
                    var offset:int = attribute.offset + 3;
                    for (var j:int=_numVertices; j<value; ++j)
                        _rawData[j * _vertexSize + offset] = 0xff;
                }
            }

            _numVertices = value;
        }

        /** The raw vertex data; not a copy! */
        public function get rawData():ByteArray
        {
            return _rawData;
        }

        /** The normalized format that describes the attributes of each vertex. */
        public function get format():String
        {
            return _format;
        }

        /** The size (in bytes) of each vertex. */
        public function get vertexSizeInBytes():int
        {
            return _vertexSize;
        }

        /** The size (in 32 bit units) of each vertex. */
        public function get vertexSizeIn32Bits():int
        {
            return _vertexSize / 4;
        }
    }
}

class Attribute
{
    private static const FORMAT_SIZES:Object = {
        "bytes4": 4,
        "float1": 4,
        "float2": 8,
        "float3": 12,
        "float4": 16
    };

    public var name:String;
    public var format:String;
    public var offset:int; // in bytes
    public var size:int;   // in bytes
    public var pma:Boolean;

    public function Attribute(name:String, format:String, offset:int, pma:Boolean=false)
    {
        if (!(format in FORMAT_SIZES))
            throw new ArgumentError(
                    "Invalid attribute format: " + format + ". " +
                    "Use one of the following: 'float1'-'float4', 'bytes4'");

        this.name = name;
        this.format = format;
        this.offset = offset;
        this.pma = pma;
        this.size = FORMAT_SIZES[format];
    }
}