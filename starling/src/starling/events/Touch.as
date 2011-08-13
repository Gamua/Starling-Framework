// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.events
{
    import flash.geom.Matrix;
    import flash.geom.Point;
    
    import starling.display.DisplayObject;

    public class Touch
    {
        private var mID:int;
        private var mGlobalX:Number;
        private var mGlobalY:Number;
        private var mPreviousGlobalX:Number;
        private var mPreviousGlobalY:Number;
        private var mTapCount:int;
        private var mPhase:String;
        private var mTarget:DisplayObject;
        private var mTimestamp:Number;
        
        public function Touch(id:int, globalX:Number, globalY:Number, phase:String, target:DisplayObject)
        {
            mID = id;
            mGlobalX = mPreviousGlobalX = globalX;
            mGlobalY = mPreviousGlobalY = globalY;
            mTapCount = 0;
            mPhase = phase;
            mTarget = target;
        }
        
        public function getLocation(space:DisplayObject):Point
        {
            var point:Point = new Point(mGlobalX, mGlobalY);
            var transformationMatrix:Matrix = mTarget.root.getTransformationMatrixToSpace(space);
            return transformationMatrix.transformPoint(point);
        }
        
        public function getPreviousLocation(space:DisplayObject):Point
        {
            var point:Point = new Point(mPreviousGlobalX, mPreviousGlobalY);
            var transformationMatrix:Matrix = mTarget.root.getTransformationMatrixToSpace(space);
            return transformationMatrix.transformPoint(point);
        }
        
        public function clone():Touch
        {
            var clone:Touch = new Touch(mID, mGlobalX, mGlobalY, mPhase, mTarget);
            clone.mPreviousGlobalX = mPreviousGlobalX;
            clone.mPreviousGlobalY = mPreviousGlobalY;
            clone.mTapCount = mTapCount;
            clone.mTimestamp = mTimestamp;
            return clone;
        }
        
        public function get id():int { return mID; }
        public function get globalX():Number { return mGlobalX; }
        public function get globalY():Number { return mGlobalY; }
        public function get previousGlobalX():Number { return mPreviousGlobalX; }
        public function get previousGlobalY():Number { return mPreviousGlobalY; }
        public function get tapCount():int { return mTapCount; }
        public function get phase():String { return mPhase; }
        public function get target():DisplayObject { return mTarget; }
        public function get timestamp():Number { return mTimestamp; }
        
        // internal methods
        
        internal function setPosition(globalX:Number, globalY:Number):void
        {
            mPreviousGlobalX = mGlobalX;
            mPreviousGlobalY = mGlobalY;
            mGlobalX = globalX;
            mGlobalY = globalY;
        }
        
        internal function setPhase(value:String):void { mPhase = value; }
        internal function setTapCount(value:int):void { mTapCount = value; }
        internal function setTarget(value:DisplayObject):void { mTarget = value; }
        internal function setTimestamp(value:Number):void { mTimestamp = value; }
    }
}