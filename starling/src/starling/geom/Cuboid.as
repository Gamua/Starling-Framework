// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2014 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.geom
{
    import flash.geom.Rectangle;
    import flash.geom.Vector3D;

    import starling.utils.formatString;

    public class Cuboid
    {
        private var mX:Number;
        private var mY:Number;
        private var mZ:Number;

        private var mWidth:Number;
        private var mHeight:Number;
        private var mDepth:Number;

        public function Cuboid(x:Number=0, y:Number=0, z:Number=0,
                               width:Number=0, height:Number=0, depth:Number=0)
        {
            setTo(x, y, z, width, height, depth);
        }

        public function copyFrom(cuboid:Cuboid):void
        {
            setTo(cuboid.x, cuboid.y, cuboid.z, cuboid.width, cuboid.height, cuboid.depth);
        }

        public function copyFromRect(rect:Rectangle):void
        {
            setTo(rect.x, rect.y, 0, rect.width, rect.height, 0);
        }

        public function setTo(x:Number=0, y:Number=0, z:Number=0,
                              width:Number=0, height:Number=0, depth:Number=0):void
        {
            mX = x;
            mY = y;
            mZ = z;
            mWidth = width;
            mHeight = height;
            mDepth = depth;
        }

        public function getVertex(id:int, resultVertex:Vector3D=null):Vector3D
        {
            if (resultVertex == null) resultVertex = new Vector3D();

            switch (id)
            {
                case 0: resultVertex.setTo(mX,          mY,           mZ         ); break;
                case 1: resultVertex.setTo(mX + mWidth, mY,           mZ         ); break;
                case 2: resultVertex.setTo(mX,          mY + mHeight, mZ         ); break;
                case 3: resultVertex.setTo(mX + mWidth, mY + mHeight, mZ         ); break;
                case 4: resultVertex.setTo(mX,          mY,           mZ + mDepth); break;
                case 5: resultVertex.setTo(mX + mWidth, mY,           mZ + mDepth); break;
                case 6: resultVertex.setTo(mX,          mY + mHeight, mZ + mDepth); break;
                case 7: resultVertex.setTo(mX + mWidth, mY + mHeight, mZ + mDepth); break;
                default: throw new ArgumentError("Invalid edge id: " + id);
            }

            return resultVertex;
        }

        public function toString():String
        {
            return formatString("(x={0}, y={1}, z={2}, width={3}, height={4}, depth={5})",
                mX, mY, mZ, mWidth, mHeight, mDepth);
        }

        public function get left():Number { return mX; }
        public function set left(value:Number):void { mX = value; }

        public function get right():Number { return mX + mWidth; }
        public function set right(value:Number):void { mWidth = value - mX; }

        public function get top():Number { return mY; }
        public function set top(value:Number):void { mY = value; }

        public function get bottom():Number { return mY + mHeight; }
        public function set bottom(value:Number):void { mHeight = value - mY; }

        public function get front():Number { return mZ; }
        public function set front(value:Number):void { mZ = value; }

        public function get back():Number { return mZ + mDepth; }
        public function set back(value:Number):void { mDepth = value - mZ; }

        public final function get x():Number { return mX; }
        public final function set x(value:Number):void { mX = value; }

        public final function get y():Number { return mY; }
        public final function set y(value:Number):void { mY = value; }

        public final function get z():Number { return mZ; }
        public final function set z(value:Number):void { mZ = value; }

        public final function get width():Number { return mWidth; }
        public final function set width(value:Number):void { mWidth = value; }

        public final function get height():Number { return mHeight; }
        public final function set height(value:Number):void { mHeight = value; }

        public final function get depth():Number { return mDepth; }
        public final function set depth(value:Number):void { mDepth = value; }
    }
}