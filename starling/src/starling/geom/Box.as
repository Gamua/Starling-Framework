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
    
    import starling.utils.formatString;

    public class Box
    {
        private var mX:Number;
        private var mY:Number;
        private var mZ:Number;
        private var mWidth:Number;
        private var mHeight:Number;
        private var mDepth:Number;

        public function Box(x:Number=0, y:Number=0, z:Number=0,
                            width:Number=0, height:Number=0, depth:Number=0)
        {
            setTo(x, y, z, width, height, depth);
        }

        public function copyFrom(box:Box):void
        {
            setTo(box.x, box.y, box.z, box.width, box.height, box.depth);
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

        public function toString():String
        {
            return formatString("(x={0}, y={1}, z={2}, width={3}, height={4}, depth={5})",
                mX, mY, mZ, mWidth, mHeight, mDepth);
        }

        public final function get left():Number { return mX; }
        public final function set left(value:Number):void { mX = value; }

        public final function get right():Number { return mX + mWidth; }
        public final function set right(value:Number):void { mWidth = value - mX; }

        public final function get top():Number { return mY; }
        public final function set top(value:Number):void { mY = value; }

        public final function get bottom():Number { return mY + mHeight; }
        public final function set bottom(value:Number):void { mHeight = value - mY; }

        public final function get front():Number { return mZ; }
        public final function set front(value:Number):void { mZ = value; }

        public final function get back():Number { return mZ + mDepth; }
        public final function set back(value:Number):void { mDepth = value - mZ; }

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