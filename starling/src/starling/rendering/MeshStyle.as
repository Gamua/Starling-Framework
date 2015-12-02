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
    import flash.geom.Point;

    import starling.core.starling_internal;
    import starling.display.Mesh;
    import starling.textures.Texture;
    import starling.textures.TextureSmoothing;

    /** MeshStyles provide a means to completely modify the way a mesh is rendered.
     *  The base class provides Starling's standard mesh rendering functionality: colored and
     *  (optionally) textured meshes. Subclasses may add support for additional features like
     *  color transformations, normal mapping, etc.
     *
     *  <p><strong>Using 'MeshStyle'</strong></p>
     *
     *  <p>First, create an instance of the desired style. Configure the style by updating its
     *  properties, then assign it to the mesh. Here is an example that uses a fictitious
     *  <code>ColorizedMeshStyle</code>:</p>
     *
     *  <listing>
     *  var image:Image = new Image(heroTexture);
     *  var colorStyle:ColorizedMeshStyle = new ColorizedMeshStyle();
     *  colorStyle.redOffset = 0.5;
     *  colorStyle.redMultiplier = 2.0;
     *  image.style = colorStyle;</listing>
     *
     *  <p>Note that a style might require the use of a specific vertex format; when the style
     *  is assigned, the mesh is converted to that format.</p>
     *
     *  <p><strong>Extending 'MeshStyle'</strong></p>
     *
     *  <p>To create custom rendering code in Starling, you need to extend two classes:
     *  <code>MeshStyle</code> and <code>MeshEffect</code>. While the effect class contains
     *  the actual AGAL rendering code, the style provides the API that developers will
     *  interact with when using a style.</p>
     *
     *  <p>Subclasses will, of course, add specific properties that configure the style's usage,
     *  like the <code>redOffset</code> and <code>redMultiplier</code> properties in the sample
     *  above. Furthermore, they have to follow some rules:</p>
     *
     *  <ul>
     *    <li>They must provide a constructor that can be called without any arguments.</li>
     *    <li>They must override <code>copyFrom</code>.</li>
     *    <li>They must override <code>createEffect</code>.</li>
     *    <li>They must override <code>updateEffect</code>.</li>
     *    <li>They must override <code>canBatchWith</code>.</li>
     *  </ul>
     *
     *  <p>If the style requires a custom vertex format, you must also:</p>
     *
     *  <ul>
     *    <li>add a static constant called <code>VERTEX_FORMAT</code> to the class and</li>
     *    <li>override <code>get vertexFormat</code> and let it return exactly that format.</li>
     *  </ul>
     *
     *  <p>When that's done, you can turn to the implementation of your <code>MeshEffect</code>;
     *  the <code>createEffect</code>-override will return an instance of this class.
     *  Directly before rendering begins, Starling will then call <code>updateEffect</code>
     *  to set it up.</p>
     *
     *  @see MeshEffect
     *  @see VertexDataFormat
     *  @see starling.display.Mesh
     */
    public class MeshStyle
    {
        /** The vertex format expected by this style (the same as found in the MeshEffect-class). */
        public static const VERTEX_FORMAT:VertexDataFormat = MeshEffect.VERTEX_FORMAT;

        private var _type:Class;
        private var _target:Mesh;
        private var _texture:Texture;
        private var _textureSmoothing:String;
        private var _vertexData:VertexData;
        private var _indexData:IndexData;

        // helper objects
        private static var sPoint:Point = new Point();

        /** Creates a new MeshStyle instance.
         *  Subclasses must provide a constructor that can be called without any arguments. */
        public function MeshStyle(texture:Texture=null)
        {
            _texture = texture;
            _textureSmoothing = TextureSmoothing.BILINEAR;
            _type = Object(this).constructor as Class;
        }

        /** Copies all properties of the given style to the current instance (or a subset, if the
         *  classes don't match). Must be overridden by all subclasses!
         */
        public function copyFrom(meshStyle:MeshStyle):void
        {
            _texture = meshStyle._texture;
            _textureSmoothing = meshStyle._textureSmoothing;
        }

        /** Creates a clone of this instance. The method will work for subclasses automatically,
         *  no need to override it. */
        public function clone():MeshStyle
        {
            var clone:MeshStyle = new _type();
            clone.copyFrom(this);
            return clone;
        }

        /** Creates the effect that does the actual, low-level rendering.
         *  Must be overridden by all subclasses!
         */
        public function createEffect():MeshEffect
        {
            return new MeshEffect();
        }

        /** Updates the settings of the given effect to match the current style.
         *  The given <code>effect</code> will always match the class returned by
         *  <code>createEffect</code>.
         *
         *  <p>Must be overridden by all subclasses!</p>
         */
        public function updateEffect(effect:MeshEffect, state:RenderState):void
        {
            effect.texture = _texture;
            effect.textureSmoothing = _textureSmoothing;
            effect.mvpMatrix = state.mvpMatrix3D;
            effect.alpha = state.alpha;
        }

        /** Indicates if the current instance can be batched with the given style.
         *  Must be overridden by all subclasses!
         */
        public function canBatchWith(meshStyle:MeshStyle):Boolean
        {
            if (_type == meshStyle._type)
            {
                var newTexture:Texture = meshStyle._texture;

                if (_texture == null && newTexture == null) return true;
                else if (_texture && newTexture)
                    return _texture.base == newTexture.base &&
                           _textureSmoothing == meshStyle._textureSmoothing;
                else return false;
            }
            else return false;
        }

        /** Copies the raw vertex data of the target mesh to the given VertexData instance.
         *  If you pass a matrix, all vertices will be transformed during the process.
         *
         *  <p>This method is called on batching. Subclasses may override it if they need to modify
         *  the vertex data in that process. Per default, just the "position" attribute is
         *  transformed.</p>
         */
        public function copyVertexDataTo(target:VertexData, targetVertexID:int=0, matrix:Matrix=null,
                                         vertexID:int=0, numVertices:int=-1):void
        {
            _vertexData.copyTo(target, targetVertexID, matrix, vertexID, numVertices);
        }

        /** Copies the raw index data to the given IndexData instance.
         *  The given offset value will be added to all indices during the process.
         *
         *  <p>This method is called on batching. Subclasses may override it if they need to modify
         *  the index data in that process.</p>
         */
        public function copyIndexDataTo(target:IndexData, targetIndexID:int=0, offset:int=0,
                                        indexID:int=0, numIndices:int=-1):void
        {
            _indexData.copyTo(target, targetIndexID, offset, indexID, numIndices);
        }

        /** Call this method if the target needs to be redrawn.
         *  The call is simply forwarded to the mesh. */
        protected function setRequiresRedraw():void
        {
            if (_target)
                _target.setRequiresRedraw();
        }

        /** Called when assigning the target mesh. Override to plug in class-specific logic. */
        protected function onTargetAssigned(target:Mesh):void
        { }

        // internal methods

        /** @private */
        starling_internal function setTarget(target:Mesh, vertexData:VertexData, indexData:IndexData):void
        {
            _target = target;
            _vertexData = vertexData;
            _vertexData.format = vertexFormat;
            _indexData = indexData;

            onTargetAssigned(target);
        }

        /** @private */
        starling_internal function clearTarget():void
        {
            _target = null;
            _vertexData = null;
            _indexData = null;
        }

        // vertex manipulation

        /** Returns the alpha value of the vertex at the specified index. */
        public function getVertexAlpha(vertexID:int):Number
        {
            return _vertexData.getAlpha(vertexID);
        }

        /** Sets the alpha value of the vertex at the specified index to a certain value. */
        public function setVertexAlpha(vertexID:int, alpha:Number):void
        {
            _vertexData.setAlpha(vertexID, "color", alpha);
            setRequiresRedraw();
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
            setRequiresRedraw();
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

            setRequiresRedraw();
        }

        // properties

        /** References the vertex data from the assigned target. */
        protected function get vertexData():VertexData { return _vertexData; }

        /** References the index data from the assigned target. */
        protected function get indexData():IndexData { return _indexData; }

        /** The actual class of this style. */
        public function get type():Class { return _type; }

        /** Changes the color of all vertices to the same value.
         *  The getter simply returns the color of the first vertex. */
        public function get color():uint
        {
            if (_vertexData.numVertices > 0) return _vertexData.getColor(0);
            else return 0x0;
        }

        public function set color(value:uint):void
        {
            var i:int;
            var numVertices:int = _vertexData.numVertices;

            for (i=0; i<numVertices; ++i)
                _vertexData.setColor(i, "color", value);

            setRequiresRedraw();
        }

        /** The format used to store the vertices. */
        public function get vertexFormat():VertexDataFormat
        {
            return VERTEX_FORMAT;
        }

        /** The texture that is mapped to the mesh (or <code>null</code>, if there is none). */
        public function get texture():Texture { return _texture; }
        public function set texture(value:Texture):void
        {
            if (value != _texture)
            {
                var i:int;
                var numVertices:int = _vertexData ? _vertexData.numVertices : 0;

                for (i = 0; i < numVertices; ++i)
                {
                    getTexCoords(i, sPoint);
                    if (value) value.setTexCoords(_vertexData, i, "texCoords", sPoint.x, sPoint.y);
                }

                _texture = value;
                setRequiresRedraw();
            }
        }

        /** The smoothing filter that is used for the texture. @default bilinear */
        public function get textureSmoothing():String { return _textureSmoothing; }
        public function set textureSmoothing(value:String):void
        {
            if (value != _textureSmoothing)
            {
                _textureSmoothing = value;
                setRequiresRedraw();
            }
        }

        /** The target the style is currently assigned to. */
        public function get target():Mesh { return _target; }
    }
}
