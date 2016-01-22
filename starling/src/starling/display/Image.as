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
    import flash.geom.Rectangle;

    import starling.rendering.IndexData;
    import starling.rendering.VertexData;
    import starling.textures.Texture;

    /** An Image is a quad with a texture mapped onto it.
     *
     *  <p>Typically, the Image class will act as an equivalent of Flash's Bitmap class. Instead
     *  of BitmapData, Starling uses textures to represent the pixels of an image. To display a
     *  texture, you have to map it onto a quad - and that's what the Image class is for.</p>
     *
     *  <p>While the base class <code>Quad</code> already supports textures, the <code>Image</code>
     *  class adds some additional functionality.</p>
     *
     *  <p>First of all, it provides a convenient constructor that will automatically synchronize
     *  the size of the image with the displayed texture.</p>
     *
     *  <p>Furthermore, it adds support for a "Scale9" grid. This splits up the image into
     *  nine regions, the corners of which will always maintain their original aspect ratio.
     *  The center region stretches in both directions to fill the remaining space; the side
     *  regions will stretch accordingly in either horizontal or vertical direction.</p>
     *
     *  @see starling.textures.Texture
     *  @see Quad
     */ 
    public class Image extends Quad
    {
        private var _scale9Grid:Rectangle;

        // helper objects
        private static var s9Grid:Rectangle = new Rectangle();
        private static var sHorizSizes:Vector.<Number> = new Vector.<Number>(3, true);
        private static var sVertSizes:Vector.<Number> = new Vector.<Number>(3, true);

        /** Creates an image with a texture mapped onto it. */
        public function Image(texture:Texture)
        {
            super(100, 100);
            this.texture = texture;
            readjustSize();
        }

        /** The current scaling grid that is in effect. If set to null, the image is scaled just
         *  like any other display object; assigning a rectangle will divide the image into a grid
         *  of nine regions, based on the center rectangle. The four corners of this grid will
         *  always maintain their original aspect ratio; the other regions will stretch accordingly
         *  (horizontally, vertically, or both) to fill the complete area.
         *
         *  <p>Note: assigning a Scale9 rectangle will change the number of vertices from four
         *  to sixteen, and all vertices will be colored like vertex 0 (the top left vertex).
         *  Furthermore, with a Scale9 rectangle assigned, any change of the texture will
         *  implicitly call <code>readjustSize</code>.</p>
         *
         *  @default null
         */
        public function get scale9Grid():Rectangle { return _scale9Grid; }
        public function set scale9Grid(value:Rectangle):void
        {
            if (value)
            {
                if (_scale9Grid == null) _scale9Grid = value.clone();
                else _scale9Grid.copyFrom(value);
            }
            else _scale9Grid = null;

            setupVertexPositions();
            setupTextureCoordinates();
        }

        /** @private */
        override protected function setupVertexPositions():void
        {
            if (_scale9Grid && texture) setupVertexPositionsForScale9Grid();
            else super.setupVertexPositions();
        }

        /** @private */
        override protected function setupTextureCoordinates():void
        {
            if (_scale9Grid && texture) setupTextureCoordinatesForScale9Grid();
            else super.setupTextureCoordinates();
        }

        /** @private */
        override public function readjustSize():void
        {
            super.readjustSize();

            if (_scale9Grid && texture)
                setupTextureCoordinates();
        }

        /** @private */
        override public function set scaleX(value:Number):void
        {
            super.scaleX = value;

            if (_scale9Grid && texture)
                setupVertexPositions();
        }

        /** @private */
        override public function set scaleY(value:Number):void
        {
            super.scaleY = value;

            if (_scale9Grid && texture)
                setupVertexPositions();
        }

        /** @private */
        override public function set texture(value:Texture):void
        {
            if (value != texture)
            {
                super.texture = value;

                if (_scale9Grid && value)
                    readjustSize();
            }
        }

        // scale9 vertex setup

        private function setupVertexPositionsForScale9Grid():void
        {
            s9Grid.copyFrom(_scale9Grid);

            var texture:Texture = this.texture;
            var frame:Rectangle = texture.frame;
            var absScaleX:Number = scaleX > 0 ? scaleX : -scaleX;
            var absScaleY:Number = scaleY > 0 ? scaleY : -scaleY;
            var invScaleX:Number = 1.0 / absScaleX;
            var invScaleY:Number = 1.0 / absScaleY;
            var vertexData:VertexData = this.vertexData;
            var indexData:IndexData = this.indexData;
            var prevNumVertices:int = vertexData.numVertices;
            var startX:Number = 0.0, startY:Number = 0.0;
            var correction:Number;

            // calculate 3x3 grid according to texture and scale9 properties,
            // taking special care about the texture frame (headache included)

            if (frame)
            {
                s9Grid.x += frame.x;
                s9Grid.y += frame.y;
                startX = invScaleX * -frame.x;
                startY = invScaleY * -frame.y;
            }

            sHorizSizes[0] = s9Grid.x * invScaleX;
            sHorizSizes[1] = texture.frameWidth - (texture.frameWidth - s9Grid.width) * invScaleX;
            sHorizSizes[2] = (texture.width  - s9Grid.right) * invScaleX;

            sVertSizes[0] = s9Grid.y * invScaleY;
            sVertSizes[1] = texture.frameHeight - (texture.frameHeight - s9Grid.height) * invScaleY;
            sVertSizes[2] = (texture.height - s9Grid.bottom) * invScaleY;

            // if the total width / height becomes smaller than the outer columns / rows,
            // we hide the center column / row and scale the rest normally.

            if (sHorizSizes[1] < 0)
            {
                correction = texture.frameWidth / (texture.frameWidth - s9Grid.width) * absScaleX;
                startX *= correction;
                sHorizSizes[0] *= correction;
                sHorizSizes[1]  = 0;
                sHorizSizes[2] *= correction;
            }

            if (sVertSizes[1] < 0)
            {
                correction = texture.frameHeight / (texture.frameHeight - s9Grid.height) * absScaleY;
                startY *= correction;
                sVertSizes[0] *= correction;
                sVertSizes[1]  = 0;
                sVertSizes[2] *= correction;
            }

            // set the vertex positions according to the values calculated above

            var posX:Number, posY:Number = startY;
            var attrName:String = "position";
            var vertexID:int = 0;

            for (var row:int=0; row<4; ++row)
            {
                posX = startX;

                for (var col:int=0; col<4; ++col)
                {
                    vertexData.setPoint(vertexID++, attrName, posX, posY);
                    if (col != 3) posX += sHorizSizes[col];
                }

                if (row != 3) posY += sVertSizes[row];
            }

            // update indices

            indexData.numIndices = 0;
            indexData.appendQuad(0, 1, 4, 5);
            indexData.appendQuad(1, 2, 5, 6);
            indexData.appendQuad(2, 3, 6, 7);
            indexData.appendQuad(4, 5, 8, 9);
            indexData.appendQuad(5, 6, 9, 10);
            indexData.appendQuad(6, 7, 10, 11);
            indexData.appendQuad(8, 9, 12, 13);
            indexData.appendQuad(9, 10, 13, 14);
            indexData.appendQuad(10, 11, 14, 15);

            // if we just switched from a normal to a scale9 image, all vertices are colorized
            // just like the first one; we also trim the data instances to optimize memory usage.

            if (prevNumVertices != vertexData.numVertices)
            {
                vertexData.colorize("color", vertexData.getColor(0), vertexData.getAlpha(0));
                vertexData.trim();
                indexData.trim();
            }

            setRequiresRedraw();
        }

        private function setupTextureCoordinatesForScale9Grid():void
        {
            var texture:Texture = this.texture;
            var frame:Rectangle = texture.frame;
            var vertexData:VertexData = this.vertexData;
            var paddingLeft:Number = frame ? -frame.x : 0;
            var paddingTop:Number  = frame ? -frame.y : 0;

            sHorizSizes[0] = (_scale9Grid.x - paddingLeft) / texture.width;
            sHorizSizes[1] =  _scale9Grid.width / texture.width;
            sHorizSizes[2] = 1.0 - sHorizSizes[0] - sHorizSizes[1];

            sVertSizes[0] = (_scale9Grid.y - paddingTop) / texture.height;
            sVertSizes[1] =  _scale9Grid.height / texture.height;
            sVertSizes[2] = 1.0 - sVertSizes[0] - sVertSizes[1];

            var u:Number, v:Number = 0.0;
            var attrName:String = "texCoords";
            var vertexID:int = 0;

            for (var row:int=0; row<4; ++row)
            {
                u = 0.0;

                for (var col:int=0; col<4; ++col)
                {
                    texture.setTexCoords(vertexData, vertexID++, attrName, u, v);
                    if (col != 3) u += sHorizSizes[col];
                }

                if (row != 3) v += sVertSizes[row];
            }

            setRequiresRedraw();
        }
    }
}
