package starling.display
{
    import flash.errors.IllegalOperationError;
    import flash.geom.Point;
    
    import starling.events.EnterFrameEvent;
    import starling.events.Event;
    
    public class Stage extends DisplayObjectContainer
    {
        private var mWidth:Number;
        private var mHeight:Number;
        
        public function Stage(width:Number, height:Number)
        {
            mWidth = width;
            mHeight = height;
        }
        
        public function advanceTime(passedTime:Number):void
        {
            dispatchEventOnChildren(new EnterFrameEvent(Event.ENTER_FRAME, passedTime));
        }
        
        public function broadcastEvent(event:Event):void
        {
            if (event.bubbles) 
                throw new ArgumentError("Broadcast of bubbling events is prohibited");
            
            dispatchEventOnChildren(event);
        }
        
        public override function hitTestPoint(localPoint:Point, forTouch:Boolean=false):DisplayObject
        {
            if (forTouch && (!visible || !touchable))
                return null;
            
            // if nothing else is hit, the stage returns itself as target
            var target:DisplayObject = super.hitTestPoint(localPoint, forTouch);
            if (target == null) target = this;
            return target;
        }
        
        public override function get width():Number { return mWidth; }
        public override function set width(value:Number):void 
        { 
            throw new IllegalOperationError("Cannot set width of stage");
        }
        
        public override function get height():Number { return mHeight; }
        public override function set height(value:Number):void
        {
            throw new IllegalOperationError("Cannot set height of stage");
        }
        
        public override function set x(value:Number):void
        {
            throw new IllegalOperationError("Cannot set x-coordinate of stage");
        }
        
        public override function set y(value:Number):void
        {
            throw new IllegalOperationError("Cannot set y-coordinate of stage");
        }
        
        public override function set scaleX(value:Number):void
        {
            throw new IllegalOperationError("Cannot scale stage");
        }
        
        public override function set scaleY(value:Number):void
        {
            throw new IllegalOperationError("Cannot scale stage");
        }
        
        public override function set rotation(value:Number):void
        {
            throw new IllegalOperationError("Cannot rotate stage");
        }
    }
}