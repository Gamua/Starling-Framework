// =================================================================================================
//
//  Starling Framework
//  Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.rendering
{
    import flash.display3D.Context3D;
    import flash.display3D.VertexBuffer3D;
    import flash.errors.IllegalOperationError;
    import flash.geom.Matrix;
    import flash.geom.Matrix3D;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.geom.Vector3D;

    import starling.core.Starling;
    import starling.errors.MissingContextError;
    import starling.utils.MathUtil;
    import starling.utils.MatrixUtil;
    import starling.utils.StringUtil;

    /** The VertexData class manages a raw list of vertex information, allowing direct upload
     *  to Stage3D vertex buffers. <em>You only have to work with this class if you're writing
     *  your own rendering code (e.g. if you create custom display objects).</em>
     *
     *  <p>To render objects with Stage3D, you have to organize vertices and indices in so-called
     *  vertex- and index-buffers. Vertex buffers store the coordinates of the vertices that make
     *  up an object; index buffers reference those vertices to determine which vertices spawn
     *  up triangles. Those buffers reside in graphics memory and can be accessed very
     *  efficiently by the GPU.</p>
     *
     *  <p>Before you can move data into the buffers, you have to set it up in conventional
     *  memory — that is, in a Vector or a ByteArray. Since it's quite cumbersome to manually
     *  create and manipulate those data structures, the IndexData and VertexData classes provide
     *  a simple way to do just that. The data is stored sequentially (one vertex or index after
     *  the other) so that it can easily be uploaded to a buffer.</p>
     *
     *  <strong>Vertex Format</strong>
     *
     *  <p>The VertexData class requires a custom format string on initialization, or an instance
     *  of the VertexDataFormat class. Here is an example:</p>
     *
     *  <listing>
     *  vertexData = new VertexData("position:float2, color:float4");
     *  vertexData.setPoint(0, "position", 320, 480);
     *  vertexData.setColor(0, "color", 0xff00ff);</listing>
     *
     *  <p>This instance is set up with two attributes: "position" and "color". The keywords
     *  after the colons depict the format and size of the data that each property uses; in this
     *  case, we store two floats for the position (for the x- and y-coordinates) and four
     *  floats for the color. Please refer to the VertexDataFormat documentation for details.</p>
     *
     *  <p>The attribute names are then used to read and write data to the respective positions
     *  inside a vertex. Furthermore, they come in handy when copying data from one VertexData
     *  instance to another: attributes with equal name and data format may be transferred between
     *  different VertexData objects, even when they contain different sets of attributes or have
     *  a different layout.</p>
     *
     *  <strong>Colors</strong>
     *
     *  <p>Always use the format <code>float4</code> for color data. The color access methods
     *  expect that format, since you need four color channels (RGB and alpha). Furthermore,
     *  you should always include the string "color" (or "Color") in the name of color data;
     *  that way, it will be recognized as such and will always have its alpha value pre-filled
     *  with the value "1.0".</p>
     *
     *  <strong>Premultiplied Alpha</strong>
     *
     *  <p>Per default, color values are stored with premultiplied alpha values, which
     *  means that the <code>rgb</code> values were multiplied with the <code>alpha</code> values
     *  before saving them. You can change this behavior with the <code>premultipliedAlpha</code>
     *  property.</p>
     *
     *  <p>Beware: with premultiplied alpha, the alpha value always affects the resolution of
     *  the RGB channels. A small alpha value results in a lower accuracy of the other channels,
     *  and if the alpha value reaches zero, the color information is lost altogether.</p>
     *
     *  @see VertexDataFormat
     *  @see IndexData
     */
    public class VertexData
    {
        private var _rawData:Vector.<Number>;
        private var _numVertices:int;
        private var _format:VertexDataFormat;
        private var _attributes:Vector.<VertexDataAttribute>;
        private var _numAttributes:int;
        private var _premultipliedAlpha:Boolean;

        private var _posOffset:int;
        private var _colOffset:int;
        private var _vertexSize:int;

        private static const MIN_ALPHA:Number = 0.001;
        private static const MAX_ALPHA:Number = 1.0;

        // helper objects
        private static var sHelperPoint:Point = new Point();
        private static var sHelperPoint3D:Vector3D = new Vector3D();
        private static var sData:Vector.<Number> = new <Number>[];

        /** Creates an empty VertexData object with the given format and initial capacity.
         *
         *  @param format
         *
         *  Either a VertexDataFormat instance or a String that describes the data format.
         *  Refer to the VertexDataFormat class for more information. If you don't pass a format,
         *  the default <code>MeshStyle.VERTEX_FORMAT</code> will be used.
         *
         *  @param initialCapacity
         *
         *  The initial capacity affects just the length of the initial <code>rawData</code>
         *  vector, not the <code>numIndices</code> value, which will always be zero when the
         *  constructor returns. Make an educated guess, depending on the planned usage of the
         *  VertexData instance.
         */
        public function VertexData(format:*=null, initialCapacity:int=4)
        {
            if (format == null) _format = MeshStyle.VERTEX_FORMAT;
            else if (format is VertexDataFormat) _format = format;
            else if (format is String) _format = VertexDataFormat.fromString(format as String);
            else throw new ArgumentError("'format' must be String or VertexDataFormat");

            _rawData = new Vector.<Number>(initialCapacity * _format.vertexSize);
            _attributes = _format.attributes;
            _numAttributes = _attributes.length;
            _posOffset = _format.hasAttribute("position") ? _format.getOffset("position") : 0;
            _colOffset = _format.hasAttribute("color")    ? _format.getOffset("color")    : 0;
            _vertexSize = _format.vertexSize;
            _numVertices = 0;
            _premultipliedAlpha = true;
        }

        /** Explicitly frees up the memory used by the <code>rawData</code> vector. */
        public function clear():void
        {
            _rawData.length = 0;
            _numVertices = 0;
        }

        /** Creates a duplicate of the vertex data object. */
        public function clone():VertexData
        {
            var clone:VertexData = new VertexData(_format);
            clone._rawData = _rawData.slice();
            clone._numVertices = _numVertices;
            clone._premultipliedAlpha = _premultipliedAlpha;
            return clone;
        }

        /** Copies the vertex data (or a range of it, defined by 'vertexID' and 'numVertices')
         *  of this instance to another vertex data object, starting at a certain target index.
         *  If the target is not big enough, it will be resized to fit all the new vertices.
         *
         *  <p>If you pass a non-null matrix, the 2D position of each vertex will be transformed
         *  by that matrix before storing it in the target object. (The position being either an
         *  attribute with the name "position" or, if such an attribute is not found, the first
         *  attribute of each vertex. It must consist of two float values containing the x- and
         *  y-coordinates of the vertex.)</p>
         *
         *  <p>Source and target do not need to have the exact same format. Only properties that
         *  exist in the target will be copied; others will be ignored. If a property with the
         *  same name but a different format exists in the target, an exception will be raised.
         *  Beware, though, that the copy-operation becomes much more expensive when the formats
         *  differ.</p>
         */
        public function copyTo(target:VertexData, targetVertexID:int=0, matrix:Matrix=null,
                               vertexID:int=0, numVertices:int=-1):void
        {
            if (numVertices < 0 || vertexID + numVertices > _numVertices)
                numVertices = _numVertices - vertexID;

            if (_format === target._format)
            {
                if (target._numVertices < targetVertexID + numVertices)
                    target._numVertices = targetVertexID + numVertices;

                var i:int, x:Number, y:Number;
                var targetData:Vector.<Number> = target._rawData;
                var targetPos:int = targetVertexID * _vertexSize;
                var sourcePos:int = vertexID * _vertexSize;
                var sourceEnd:int = (vertexID + numVertices) * _vertexSize;

                if (matrix)
                {
                    for (i=0; i<_posOffset; ++i) // copy everything before 'position'
                        targetData[int(targetPos++)] = _rawData[int(sourcePos++)];

                    while (sourcePos < sourceEnd)
                    {
                        x = _rawData[int(sourcePos++)];
                        y = _rawData[int(sourcePos++)];

                        targetData[int(targetPos++)] = matrix.a * x + matrix.c * y + matrix.tx;
                        targetData[int(targetPos++)] = matrix.d * y + matrix.b * x + matrix.ty;

                        for (i=2; i<_vertexSize; ++i)
                            targetData[int(targetPos++)] = _rawData[int(sourcePos++)];
                    }
                }
                else
                {
                    while (sourcePos < sourceEnd)
                        targetData[int(targetPos++)] = _rawData[int(sourcePos++)];
                }
            }
            else
            {
                if (target._numVertices < targetVertexID + numVertices)
                    target.numVertices  = targetVertexID + numVertices; // ensure correct alphas!

                for (i=0; i<_numAttributes; ++i)
                {
                    var srcAttr:VertexDataAttribute = _attributes[i];
                    var tgtAttr:VertexDataAttribute = target.getAttribute(srcAttr.name);

                    if (tgtAttr) // only copy attributes that exist in the target, as well
                    {
                        if (srcAttr.offset == _posOffset)
                            copyAttributeTo_internal(target, targetVertexID, matrix,
                                    srcAttr, tgtAttr, vertexID, numVertices);
                        else
                            copyAttributeTo_internal(target, targetVertexID, null,
                                    srcAttr, tgtAttr, vertexID, numVertices);
                    }
                }
            }
        }

        /** Copies a specific attribute of all contained vertices (or a range of them, defined by
         *  'vertexID' and 'numVertices') to another VertexData instance. Beware that both name
         *  and format of the attribute must be identical in source and target.
         *  If the target is not big enough, it will be resized to fit all the new vertices.
         *
         *  <p>If you pass a non-null matrix, the specified attribute will be transformed by
         *  that matrix before storing it in the target object. It must consist of two float
         *  values.</p>
         */
        public function copyAttributeTo(target:VertexData, targetVertexID:int, attrName:String,
                                        matrix:Matrix=null, vertexID:int=0, numVertices:int=-1):void
        {
            var sourceAttribute:VertexDataAttribute = getAttribute(attrName);
            var targetAttribute:VertexDataAttribute = target.getAttribute(attrName);

            if (sourceAttribute == null)
                throw new ArgumentError("Attribute '" + attrName + "' not found in source data");

            if (targetAttribute == null)
                throw new ArgumentError("Attribute '" + attrName + "' not found in target data");

            copyAttributeTo_internal(target, targetVertexID, matrix,
                    sourceAttribute, targetAttribute, vertexID, numVertices);
        }

        private function copyAttributeTo_internal(
                target:VertexData, targetVertexID:int, matrix:Matrix,
                sourceAttribute:VertexDataAttribute, targetAttribute:VertexDataAttribute,
                vertexID:int, numVertices:int):void
        {
            if (sourceAttribute.format != targetAttribute.format)
                throw new IllegalOperationError("Attribute formats differ between source and target");

            if (numVertices < 0 || vertexID + numVertices > _numVertices)
                numVertices = _numVertices - vertexID;

            if (target._numVertices < targetVertexID + numVertices)
                target._numVertices = targetVertexID + numVertices;

            var i:int, j:int, x:Number, y:Number;
            var attributeSize:int = sourceAttribute.size;
            var sourceData:Vector.<Number> = _rawData;
            var targetData:Vector.<Number> = target._rawData;
            var sourceDelta:int = _vertexSize - attributeSize;
            var targetDelta:int = target._vertexSize - attributeSize;
            var sourcePos:int = vertexID * _vertexSize + sourceAttribute.offset;
            var targetPos:int = targetVertexID * target._vertexSize + targetAttribute.offset;

            if (matrix)
            {
                for (i=0; i<numVertices; ++i)
                {
                    x = sourceData[int(sourcePos++)];
                    y = sourceData[int(sourcePos++)];

                    targetData[int(targetPos++)] = matrix.a * x + matrix.c * y + matrix.tx;
                    targetData[int(targetPos++)] = matrix.d * y + matrix.b * x + matrix.ty;

                    sourcePos += sourceDelta;
                    targetPos += targetDelta;
                }
            }
            else
            {
                for (i=0; i<numVertices; ++i)
                {
                    for (j=0; j<attributeSize; ++j)
                        targetData[int(targetPos++)] = sourceData[int(sourcePos++)];

                    sourcePos += sourceDelta;
                    targetPos += targetDelta;
                }
            }
        }

        /** Optimizes the raw data so that it has exactly the required capacity, without
         *  wasting any memory. */
        public function trim():void
        {
            _rawData.length = _vertexSize * _numVertices;
        }

        /** Returns a string representation of the VertexData object,
         *  describing both its format and size. */
        public function toString():String
        {
            return StringUtil.format("[VertexData format=\"{0}\" numVertices={1}]",
                    _format.formatString, _numVertices);
        }

        // read / write attributes

        /** Reads a float value from the specified vertex and attribute. */
        public function getFloat(vertexID:int, attrName:String):Number
        {
            return _rawData[int(vertexID * _vertexSize + getAttribute(attrName).offset)];
        }

        /** Writes a float value to the specified vertex and attribute. */
        public function setFloat(vertexID:int, attrName:String, value:Number):void
        {
            if (_numVertices < vertexID + 1)
                 numVertices = vertexID + 1;

            _rawData[int(vertexID * _vertexSize + getAttribute(attrName).offset)] = value;
        }

        /** Reads a Point from the specified vertex and attribute. */
        public function getPoint(vertexID:int, attrName:String, out:Point=null):Point
        {
            if (out == null) out = new Point();

            var offset:int = attrName == "position" ? _posOffset : getAttribute(attrName).offset;
            var pos:int = vertexID * _vertexSize + offset;
            out.x = _rawData[pos];
            out.y = _rawData[int(pos+1)];

            return out;
        }

        /** Writes the given coordinates to the specified vertex and attribute. */
        public function setPoint(vertexID:int, attrName:String, x:Number, y:Number):void
        {
            if (_numVertices < vertexID + 1)
                 numVertices = vertexID + 1;

            var offset:int = attrName == "position" ? _posOffset : getAttribute(attrName).offset;
            var pos:int = vertexID * _vertexSize + offset;
            _rawData[pos] = x;
            _rawData[int(pos+1)] = y;
        }

        /** Reads a Vector3D from the specified vertex and attribute.
         *  The 'w' property of the Vector3D is ignored. */
        public function getPoint3D(vertexID:int, attrName:String, out:Vector3D=null):Vector3D
        {
            if (out == null) out = new Vector3D();

            var pos:int = vertexID * _vertexSize + getAttribute(attrName).offset;
            out.x = _rawData[pos];
            out.y = _rawData[int(pos+1)];
            out.z = _rawData[int(pos+2)];

            return out;
        }

        /** Writes the given coordinates to the specified vertex and attribute. */
        public function setPoint3D(vertexID:int, attrName:String, x:Number, y:Number, z:Number):void
        {
            if (_numVertices < vertexID + 1)
                 numVertices = vertexID + 1;

            var pos:int = vertexID * _vertexSize + getAttribute(attrName).offset;
            _rawData[pos] = x;
            _rawData[int(pos+1)] = y;
            _rawData[int(pos+2)] = z;
        }

        /** Reads a Vector3D from the specified vertex and attribute, including the fourth
         *  coordinate ('w'). */
        public function getPoint4D(vertexID:int, attrName:String, out:Vector3D=null):Vector3D
        {
            if (out == null) out = new Vector3D();

            var pos:int = vertexID * _vertexSize + getAttribute(attrName).offset;
            out.x = _rawData[pos];
            out.y = _rawData[int(pos+1)];
            out.z = _rawData[int(pos+2)];
            out.w = _rawData[int(pos+3)];

            return out;
        }

        /** Writes the given coordinates to the specified vertex and attribute. */
        public function setPoint4D(vertexID:int, attrName:String,
                                   x:Number, y:Number, z:Number, w:Number=1.0):void
        {
            if (_numVertices < vertexID + 1)
                 numVertices = vertexID + 1;

            var pos:int = vertexID * _vertexSize + getAttribute(attrName).offset;
            _rawData[pos] = x;
            _rawData[int(pos+1)] = y;
            _rawData[int(pos+2)] = z;
            _rawData[int(pos+3)] = w;
        }

        /** Reads an RGB color from the specified vertex and attribute (no alpha). */
        public function getColor(vertexID:int, attrName:String="color"):uint
        {
            var offset:int = attrName == "color" ? _colOffset : getAttribute(attrName).offset;
            var pos:int = vertexID * _vertexSize + offset;
            var divisor:Number = _premultipliedAlpha ? _rawData[int(pos+3)] : 1.0;

            if (divisor == 0) return 0;
            else
            {
                var red:Number   = _rawData[pos]        / divisor;
                var green:Number = _rawData[int(pos+1)] / divisor;
                var blue:Number  = _rawData[int(pos+2)] / divisor;

                return (int(red*255) << 16) | (int(green*255) << 8) | int(blue*255);
            }
        }

        /** Writes the RGB color to the specified vertex and attribute (alpha is not changed). */
        public function setColor(vertexID:int, attrName:String, color:uint):void
        {
            if (_numVertices < vertexID + 1)
                 numVertices = vertexID + 1;

            var offset:int = attrName == "color" ? _colOffset : getAttribute(attrName).offset;
            var pos:int = vertexID * _vertexSize + offset;
            var multiplier:Number = _premultipliedAlpha ? _rawData[int(pos+3)] : 1.0;

            _rawData[pos]        = ((color >> 16) & 0xff) / 255.0 * multiplier;
            _rawData[int(pos+1)] = ((color >>  8) & 0xff) / 255.0 * multiplier;
            _rawData[int(pos+2)] = ( color        & 0xff) / 255.0 * multiplier;
        }

        /** Reads the alpha value from the specified vertex and attribute. */
        public function getAlpha(vertexID:int, attrName:String="color"):Number
        {
            var offset:int = attrName == "color" ? _colOffset : getAttribute(attrName).offset;
            var pos:int = vertexID * _vertexSize + offset + 3;

            return _rawData[pos];
        }

        /** Writes the given alpha value to the specified vertex and attribute (range 0-1). */
        public function setAlpha(vertexID:int, attrName:String, alpha:Number):void
        {
            if (_numVertices < vertexID + 1)
                 numVertices = vertexID + 1;

            var color:uint = getColor(vertexID, attrName);
            colorize(attrName, color, alpha, vertexID, 1);
        }

        // bounds helpers

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
                var minX:Number = Number.MAX_VALUE, maxX:Number = -Number.MAX_VALUE;
                var minY:Number = Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE;
                var offset:int = attrName == "position" ? _posOffset : getAttribute(attrName).offset;
                var position:int = vertexID * _vertexSize + offset;
                var x:Number, y:Number, i:int;

                if (matrix == null)
                {
                    for (i=0; i<numVertices; ++i)
                    {
                        x = _rawData[position];
                        y = _rawData[int(position+1)];
                        position += _vertexSize;

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
                        x = _rawData[position];
                        y = _rawData[int(position+1)];
                        position += _vertexSize;

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
                var minX:Number = Number.MAX_VALUE, maxX:Number = -Number.MAX_VALUE;
                var minY:Number = Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE;
                var offset:int = attrName == "position" ? _posOffset : getAttribute(attrName).offset;
                var position:int = vertexID * _vertexSize + offset;
                var x:Number, y:Number, i:int;

                for (i=0; i<numVertices; ++i)
                {
                    x = _rawData[position];
                    y = _rawData[int(position+1)];
                    position += _vertexSize;

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

        /** Indicates if color attributes should be stored premultiplied with the alpha value.
         *  Changing this value does <strong>not</strong> modify any existing color data.
         *  If you want that, use the <code>setPremultipliedAlpha</code> method instead.
         *  @default true */
        public function get premultipliedAlpha():Boolean { return _premultipliedAlpha; }
        public function set premultipliedAlpha(value:Boolean):void
        {
            setPremultipliedAlpha(value, false);
        }

        /** Changes the way alpha and color values are stored. Optionally updates all existing
         *  vertices. */
        public function setPremultipliedAlpha(value:Boolean, updateData:Boolean):void
        {
            if (updateData && value != _premultipliedAlpha)
            {
                for (var i:int=0; i<_numAttributes; ++i)
                {
                    var attribute:VertexDataAttribute = _attributes[i];
                    if (attribute.isColor)
                    {
                        var pos:int = attribute.offset;

                        for (var j:int=0; j<_numVertices; ++j)
                        {
                            var alpha:Number = _rawData[int(pos+3)];
                            var divisor:Number = _premultipliedAlpha ? alpha : 1.0;
                            var multiplier:Number = value ? alpha : 1.0;

                            if (divisor != 0)
                            {
                                _rawData[pos]        = _rawData[pos]        / divisor * multiplier;
                                _rawData[int(pos+1)] = _rawData[int(pos+1)] / divisor * multiplier;
                                _rawData[int(pos+2)] = _rawData[int(pos+2)] / divisor * multiplier;
                            }

                            pos += _vertexSize;
                        }
                    }
                }
            }

            _premultipliedAlpha = value;
        }

        // modify multiple attributes

        /** Transforms the 2D positions of subsequent vertices by multiplication with a
         *  transformation matrix. */
        public function transformPoints(attrName:String, matrix:Matrix,
                                        vertexID:int=0, numVertices:int=-1):void
        {
            if (numVertices < 0 || vertexID + numVertices > _numVertices)
                numVertices = _numVertices - vertexID;

            var x:Number, y:Number;
            var offset:int = attrName == "position" ? _posOffset : getAttribute(attrName).offset;
            var pos:int = vertexID * _vertexSize + offset;
            var endPos:int = pos + numVertices * _vertexSize;

            while (pos < endPos)
            {
                x = _rawData[pos];
                y = _rawData[int(pos+1)];

                _rawData[pos]        = matrix.a * x + matrix.c * y + matrix.tx;
                _rawData[int(pos+1)] = matrix.d * y + matrix.b * x + matrix.ty;

                pos += _vertexSize;
            }
        }

        /** Translates the 2D positions of subsequent vertices by a certain offset. */
        public function translatePoints(attrName:String, deltaX:Number, deltaY:Number,
                                        vertexID:int=0, numVertices:int=-1):void
        {
            if (numVertices < 0 || vertexID + numVertices > _numVertices)
                numVertices = _numVertices - vertexID;

            var x:Number, y:Number;
            var offset:int = attrName == "position" ? _posOffset : getAttribute(attrName).offset;
            var pos:int = vertexID * _vertexSize + offset;
            var endPos:int = pos + numVertices * _vertexSize;

            while (pos < endPos)
            {
                x = _rawData[pos];
                y = _rawData[int(pos+1)];

                _rawData[pos]        = x + deltaX;
                _rawData[int(pos+1)] = y + deltaY;

                pos += _vertexSize;
            }
        }

        /** Multiplies the alpha values of subsequent vertices by a certain factor. */
        public function scaleAlphas(attrName:String, factor:Number,
                                    vertexID:int=0, numVertices:int=-1):void
        {
            if (factor == 1.0) return;
            if (numVertices < 0 || vertexID + numVertices > _numVertices)
                numVertices = _numVertices - vertexID;

            var i:int, red:Number, green:Number, blue:Number;
            var offset:int = attrName == "color" ? _colOffset : getAttribute(attrName).offset;
            var colorPos:int = vertexID * _vertexSize + offset;
            var alphaPos:int, oldAlpha:Number, newAlpha:Number;

            for (i=0; i<numVertices; ++i)
            {
                alphaPos = colorPos + 3;
                oldAlpha = _rawData[alphaPos];
                newAlpha = oldAlpha * factor;

                if (newAlpha > MAX_ALPHA)      newAlpha = MAX_ALPHA;
                else if (newAlpha < MIN_ALPHA) newAlpha = MIN_ALPHA;

                if (newAlpha == 1.0 || !_premultipliedAlpha)
                {
                    _rawData[alphaPos] = newAlpha;
                }
                else
                {
                    red     = _rawData[colorPos];
                    green   = _rawData[int(colorPos+1)];
                    blue    = _rawData[int(colorPos+2)];

                    if (oldAlpha)
                    {
                        _rawData[colorPos]        = (red   / oldAlpha) * newAlpha;
                        _rawData[int(colorPos+1)] = (green / oldAlpha) * newAlpha;
                        _rawData[int(colorPos+2)] = (blue  / oldAlpha) * newAlpha;
                        _rawData[alphaPos]        = newAlpha;
                    }
                }

                colorPos += _vertexSize;
            }
        }

        /** Writes the given RGB and alpha values to the specified vertices. */
        public function colorize(attrName:String, color:uint, alpha:Number=1.0,
                                 vertexID:int=0, numVertices:int=-1):void
        {
            if (numVertices < 0 || vertexID + numVertices > _numVertices)
                numVertices = _numVertices - vertexID;

            var offset:int = attrName == "color" ? _colOffset : getAttribute(attrName).offset;
            var pos:int = vertexID * _vertexSize + offset;
            var endPos:int = pos + numVertices * _vertexSize;

            if (alpha > MAX_ALPHA)      alpha = MAX_ALPHA;
            else if (alpha < MIN_ALPHA) alpha = MIN_ALPHA;

            var red:Number   = ((color >> 16) & 0xff) / 255.0;
            var green:Number = ((color >>  8) & 0xff) / 255.0;
            var blue:Number  = ( color        & 0xff) / 255.0;

            if (_premultipliedAlpha && alpha != 1.0)
            {
                red   *= alpha;
                green *= alpha;
                blue  *= alpha;
            }

            while (pos < endPos)
            {
                _rawData[pos] = red;
                _rawData[int(pos+1)] = green;
                _rawData[int(pos+2)] = blue;
                _rawData[int(pos+3)] = alpha;
                pos += _vertexSize;
            }
        }

        // format helpers

        /** Returns the format of a certain vertex attribute, identified by its name.
          * Possible values: <code>float1, float2, float3, float4</code>. */
        public function getFormat(attrName:String):String
        {
            return getAttribute(attrName).format;
        }

        /** Returns the size of a certain vertex attribute in 32 bit units. */
        public function getSize(attrName:String):int
        {
            return getAttribute(attrName).size;
        }

        /** Returns the offset (in 32 bit units) of an attribute within a vertex. */
        public function getOffset(attrName:String):int
        {
            return getAttribute(attrName).offset;
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
            if (_numVertices == 0) return null;

            var buffer:VertexBuffer3D = context.createVertexBuffer(
                _numVertices, _vertexSize, bufferUsage);

            if (upload) uploadToVertexBuffer(buffer);
            return buffer;
        }

        /** Uploads the complete data (or a section of it) to the given vertex buffer. */
        public function uploadToVertexBuffer(buffer:VertexBuffer3D, vertexID:int=0, numVertices:int=-1):void
        {
            if (numVertices < 0 || vertexID + numVertices > _numVertices)
                numVertices = _numVertices - vertexID;

            if (numVertices > 0)
                buffer.uploadFromVector(_rawData, vertexID, numVertices);
        }

        [Inline]
        private final function getAttribute(attrName:String):VertexDataAttribute
        {
            var i:int, attribute:VertexDataAttribute;

            for (i=0; i<_numAttributes; ++i)
            {
                attribute = _attributes[i];
                if (attribute.name == attrName) return attribute;
            }

            return null;
        }

        // properties

        /** The total number of vertices. If you make the object bigger, it will be filled up with
         *  <code>1.0</code> for all alpha values and zero for everything else. */
        public function get numVertices():int { return _numVertices; }
        public function set numVertices(value:int):void
        {
            if (value > _numVertices)
            {
                var newLength:int = value * _vertexSize;

                if (_rawData.length < newLength)
                    _rawData.length = newLength;

                for (var i:int=0; i<_numAttributes; ++i)
                {
                    var attribute:VertexDataAttribute = _attributes[i];
                    var pos:int = _vertexSize * _numVertices + attribute.offset;
                    var j:int, k:int;

                    if (attribute.isColor) // colors must be 0x0 (black) with alpha = 1.0
                    {
                        for (j=_numVertices; j<value; ++j)
                        {
                            _rawData[    pos     ] = 0.0;
                            _rawData[int(pos + 1)] = 0.0;
                            _rawData[int(pos + 2)] = 0.0;
                            _rawData[int(pos + 3)] = 1.0;
                            pos += _vertexSize;
                        }
                    }
                    else
                    {
                        for (j=_numVertices; j<value; ++j)
                        {
                            for (k=0; k<attribute.size; ++k) _rawData[int(pos + k)] = 0.0;
                            pos += _vertexSize;
                        }
                    }
                }
            }

            _numVertices = value;
        }

        /** The raw vertex data; not a copy! */
        public function get rawData():Vector.<Number>
        {
            return _rawData;
        }

        /** The format that describes the attributes of each vertex.
         *  When you assign a different format, the raw data will be converted accordingly,
         *  i.e. attributes with the same name will still point to the same data.
         *  New properties will be filled up with zeros (except for colors, which will be
         *  initialized with an alpha value of 1.0). As a side-effect, the instance will also
         *  be trimmed. */
        public function get format():VertexDataFormat
        {
            return _format;
        }

        public function set format(value:VertexDataFormat):void
        {
            if (_format === value) return;

            var a:int, i:int, j:int, srcPos:int, tgtPos:int;
            var srcVertexSize:int = _format.vertexSize;
            var tgtVertexSize:int = value.vertexSize;
            var numAttributes:int = value.numAttributes;
            var tmpData:Vector.<Number>;

            sData.length = tgtVertexSize * _numVertices;

            for (a=0; a<numAttributes; ++a)
            {
                var tgtAttr:VertexDataAttribute = value.attributes[a];
                var srcAttr:VertexDataAttribute = getAttribute(tgtAttr.name);

                if (srcAttr) // copy attributes that exist in both targets
                {
                    for (i=0; i<_numVertices; ++i)
                    {
                        srcPos = i * srcVertexSize + srcAttr.offset;
                        tgtPos = i * tgtVertexSize + tgtAttr.offset;

                        for (j=0; j<tgtAttr.size; ++j)
                            sData[int(tgtPos++)] = _rawData[int(srcPos++)];
                    }
                }
                else // initialize rest with zero (or colors with alpha = 1)
                {
                    for (i=0; i<_numVertices; ++i)
                    {
                        tgtPos = i * tgtVertexSize + tgtAttr.offset;

                        if (tgtAttr.isColor)
                        {
                            for (j=0; j<3; ++j)
                                sData[int(tgtPos++)] = 0.0;

                            sData[tgtPos] = 1.0; // alpha = 1
                        }
                        else
                        {
                            for (j=0; j<tgtAttr.size; ++j)
                                sData[int(tgtPos++)] = 0;
                        }
                    }
                }
            }

            tmpData = _rawData;
            _rawData = sData;
            sData = tmpData;
            sData.length = 0;

            _format = value;
            _attributes = _format.attributes;
            _numAttributes = _attributes.length;
            _vertexSize = _format.vertexSize;
            _posOffset = _format.hasAttribute("position") ? _format.getOffset("position") : 0;
            _colOffset = _format.hasAttribute("color")    ? _format.getOffset("color")    : 0;
        }

        /** The format string that describes the attributes of each vertex. */
        public function get formatString():String
        {
            return _format.formatString;
        }

        /** The size (in 32 bit units) of each vertex. */
        public function get vertexSize():int
        {
            return _vertexSize;
        }

        /** The size (in 32 bit units) of the raw vertex data. */
        public function get size():int
        {
            return _numVertices * _vertexSize;
        }
    }
}
