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
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.system.Capabilities;
    import flash.utils.getQualifiedClassName;
    
    import starling.core.starling_internal;
    import starling.errors.AbstractClassError;
    import starling.events.Event;
    import starling.rendering.BatchToken;
    import starling.rendering.Painter;
    import starling.utils.MatrixUtil;

    use namespace starling_internal;
    
    /**
     *  A DisplayObjectContainer represents a collection of display objects.
     *  It is the base class of all display objects that act as a container for other objects. By 
     *  maintaining an ordered list of children, it defines the back-to-front positioning of the 
     *  children within the display tree.
     *  
     *  <p>A container does not a have size in itself. The width and height properties represent the 
     *  extents of its children. Changing those properties will scale all children accordingly.</p>
     *  
     *  <p>As this is an abstract class, you can't instantiate it directly, but have to 
     *  use a subclass instead. The most lightweight container class is "Sprite".</p>
     *  
     *  <strong>Adding and removing children</strong>
     *  
     *  <p>The class defines methods that allow you to add or remove children. When you add a child, 
     *  it will be added at the frontmost position, possibly occluding a child that was added 
     *  before. You can access the children via an index. The first child will have index 0, the 
     *  second child index 1, etc.</p> 
     *  
     *  Adding and removing objects from a container triggers non-bubbling events.
     *  
     *  <ul>
     *   <li><code>Event.ADDED</code>: the object was added to a parent.</li>
     *   <li><code>Event.ADDED_TO_STAGE</code>: the object was added to a parent that is 
     *       connected to the stage, thus becoming visible now.</li>
     *   <li><code>Event.REMOVED</code>: the object was removed from a parent.</li>
     *   <li><code>Event.REMOVED_FROM_STAGE</code>: the object was removed from a parent that 
     *       is connected to the stage, thus becoming invisible now.</li>
     *  </ul>
     *  
     *  Especially the <code>ADDED_TO_STAGE</code> event is very helpful, as it allows you to 
     *  automatically execute some logic (e.g. start an animation) when an object is rendered the 
     *  first time.
     *  
     *  @see Sprite
     *  @see DisplayObject
     */
    public class DisplayObjectContainer extends DisplayObject
    {
        // members

		public var childFirst:DisplayObject;
		public var childLast:DisplayObject;
        private var _numChildren:int = 0;
		
        private var _touchGroup:Boolean;
        
        // helper objects
        private static var sHelperMatrix:Matrix = new Matrix();
        private static var sHelperPoint:Point = new Point();
        private static var sBroadcastListeners:Vector.<DisplayObject> = new <DisplayObject>[];
        private static var sSortBuffer:Vector.<DisplayObject> = new <DisplayObject>[];
        private static var sCacheToken:BatchToken = new BatchToken();
        
        // construction
        
        /** @private */
        public function DisplayObjectContainer()
        {
            if (Capabilities.isDebugger && 
                getQualifiedClassName(this) == "starling.display::DisplayObjectContainer")
            {
                throw new AbstractClassError();
            }
        }
        
        /** Disposes the resources of all children. */
        public override function dispose():void
        {
			var child:DisplayObject = this.childFirst;
			var next:DisplayObject = child;
           	while(next) {
				next = child.next;
				child.dispose();
			}
            
            super.dispose();
        }
        
        // child management
        
        /** Adds a child to the container. It will be at the frontmost position. */
        public function addChild(child:DisplayObject):DisplayObject
        {
			if(child.parent) {
				child.parent.removeChild(child);
			}
			
			setRequiresRedraw();
			
			child.setParent(this);
			
			if(childLast) {
				child.prev = childLast;
				childLast.next = child;
				childLast = child;
			} else {
				childFirst = child;
				childLast = child;
			}
			
			if (stage)
			{
				var container:DisplayObjectContainer = child as DisplayObjectContainer;
				if (container) container.broadcastEventWith(Event.ADDED_TO_STAGE);
				else           child.dispatchEventWith(Event.ADDED_TO_STAGE);
			}
			
			_numChildren++;
			return child;
        }
		
		public function insertChildBeforeAll(child:DisplayObject):void {
			if(childFirst) insertChildBefore(child, childFirst);
			else addChild(child);
		}
		
		public function insertChildBefore(child1:DisplayObject, child2:DisplayObject):void {
			if(child2.parent != this) {
				return;
			}
			
			if(child1.parent != this) {
				addChild(child1);
			} else {
				setRequiresRedraw();
			}
			
			unlinkChild(child1);
			
			if(child2.prev) {
				child2.prev.next = child1;
			} else {
				childFirst = child1;
			}
			
			child1.prev = child2.prev;
			child1.next = child2;
			child2.prev = child1;
		}
		
		public function insertChildAfter(child1:DisplayObject, child2:DisplayObject):void {
			if(child2.parent != this) {
				return;
			}
			
			if(child1.parent != this) {
				addChild(child1);
			} else {
				setRequiresRedraw();
			}
			
			unlinkChild(child1);
			
			if(child2.next) {
				child2.next.prev = child1;
			} else {
				childLast = child1;
			}
			
			child1.prev = child2;
			child1.next = child2.next;
			child2.next = child1;
		}
		
		protected function unlinkChild(child:DisplayObject):void {
			if(child.prev) {
				child.prev.next = child.next;
			} else {
				childFirst = child.next;
			}
			
			if(child.next) {
				child.next.prev = child.prev;
			} else {
				childLast = child.prev;
			}
			
			child.prev = null;
			child.next = null;
		}
		
		public function swapChildren(child1:DisplayObject, child2:DisplayObject):void {
			if(child1.parent != this || child2.parent != this) {
				return;
			}
			
			if(child1.prev) {
				child1.prev.next = child2;
			} else {
				childFirst = child2;
			}
			
			if(child2.prev) {
				child2.prev.next = child1;
			} else {
				childFirst = child1;
			}
			
			if(child1.next) {
				child1.next.prev = child2;
			} else {
				childLast = child2;
			}
			
			if(child2.next) {
				child2.next.prev = child1;
			} else {
				childLast = child1;
			}
			
			var swap:DisplayObject;
			
			swap = child1.prev;
			child1.prev = child2.prev;
			child2.prev = swap;
			
			swap = child1.next;
			child1.next = child2.next;
			child2.next = swap;
			
			setRequiresRedraw();
		}
        
        /** Removes a child from the container. If the object is not a child, nothing happens. 
         *  If requested, the child will be disposed right away. */
        public function removeChild(child:DisplayObject, dispose:Boolean=false):DisplayObject
        {
            if(child.parent == this) {
				setRequiresRedraw();
				
				child.dispatchEventWith(Event.REMOVED, true);
				if (stage)
				{
					var container:DisplayObjectContainer = child as DisplayObjectContainer;
					if (container) container.broadcastEventWith(Event.REMOVED_FROM_STAGE);
					else           child.dispatchEventWith(Event.REMOVED_FROM_STAGE);
				}
				
				unlinkChild(child);
				child.setParent(null);
				_numChildren--;
				
				if (dispose) child.dispose();
			}
            return child;
        }
        
        /** Removes a range of children from the container (endIndex included). 
         *  If no arguments are given, all children will be removed. */
        public function removeChildren(dispose:Boolean=false):void
        {
            while(childFirst) {
				removeChild(childFirst);
			}
        }
		
        
        /** Sorts the children according to a given function (that works just like the sort function
         *  of the Vector class). */
        public function sortChildren(compareFunction:Function):void
        {
            throw new Error("not implemented");
        }
        
        /** Determines if a certain object is a child of the container (recursively). */
        public function contains(child:DisplayObject):Boolean
        {
            while (child)
            {
                if (child == this) return true;
                else child = child.parent;
            }
            return false;
        }
        
        // other methods
        
        /** @inheritDoc */ 
        public override function getBounds(targetSpace:DisplayObject, out:Rectangle=null):Rectangle
        {
            if (out == null) out = new Rectangle();
            
            if (_numChildren == 0)
            {
                getTransformationMatrix(targetSpace, sHelperMatrix);
                MatrixUtil.transformCoords(sHelperMatrix, 0.0, 0.0, sHelperPoint);
                out.setTo(sHelperPoint.x, sHelperPoint.y, 0, 0);
            }
            else if (_numChildren == 1)
            {
                childFirst.getBounds(targetSpace, out);
            }
            else
            {
                var minX:Number = Number.MAX_VALUE, maxX:Number = -Number.MAX_VALUE;
                var minY:Number = Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE;

				var child:DisplayObject = childFirst;
                while(child)
                {
                    child.getBounds(targetSpace, out);

                    if (minX > out.x)      minX = out.x;
                    if (maxX < out.right)  maxX = out.right;
                    if (minY > out.y)      minY = out.y;
                    if (maxY < out.bottom) maxY = out.bottom;
					
					child = child.next;
                }

                out.setTo(minX, minY, maxX - minX, maxY - minY);
            }
            
            return out;
        }

        /** @inheritDoc */
        public override function hitTest(localPoint:Point):DisplayObject
        {
            if (!visible || !touchable || !hitTestMask(localPoint)) return null;

            var target:DisplayObject = null;
            var localX:Number = localPoint.x;
            var localY:Number = localPoint.y;

			var child:DisplayObject = childFirst;
			var prev:DisplayObject = child;
            while(prev) // front to back!
            {
				child = prev;
				prev = child.prev;
                if (child.isMask) continue;

                sHelperMatrix.copyFrom(child.transformationMatrix);
                sHelperMatrix.invert();

                MatrixUtil.transformCoords(sHelperMatrix, localX, localY, sHelperPoint);
                target = child.hitTest(sHelperPoint);

                if (target) return _touchGroup ? this : target;
            }

            return null;
        }
        
        /** @inheritDoc */
        public override function render(painter:Painter):void
        {
            var frameID:uint = painter.frameID;
            var selfOrParentChanged:Boolean = _lastParentOrSelfChangeFrameID == frameID;

			var child:DisplayObject = childFirst;
            while(child)
            {
                if (child._hasVisibleArea)
                {
                    if (selfOrParentChanged)
                        child._lastParentOrSelfChangeFrameID = frameID;

                    if (child._lastParentOrSelfChangeFrameID != frameID &&
                        child._lastChildChangeFrameID != frameID &&
                        child._tokenFrameID == frameID - 1)
                    {
                        painter.pushState(sCacheToken);
                        painter.drawFromCache(child._pushToken, child._popToken);
                        painter.popState(child._popToken);

                        child._pushToken.copyFrom(sCacheToken);
                    }
                    else
                    {
                        // TODO add support for filters

                        var mask:DisplayObject = child._mask;

                        painter.pushState(child._pushToken);
                        painter.setStateTo(child.transformationMatrix, child.alpha, child.blendMode);

                        if (mask) painter.drawMask(mask);

                        child.render(painter);

                        if (mask) painter.eraseMask(mask);

                        painter.popState(child._popToken);
                    }

                    child._tokenFrameID = frameID;
                }
				
				child = child.next;
            }
        }

        /** Dispatches an event on all children (recursively). The event must not bubble. */
        public function broadcastEvent(event:Event):void
        {
            if (event.bubbles)
                throw new ArgumentError("Broadcast of bubbling events is prohibited");
            
            // The event listeners might modify the display tree, which could make the loop crash. 
            // Thus, we collect them in a list and iterate over that list instead.
            // And since another listener could call this method internally, we have to take 
            // care that the static helper vector does not get corrupted.
            
            var fromIndex:int = sBroadcastListeners.length;
            getChildEventListeners(this, event.type, sBroadcastListeners);
            var toIndex:int = sBroadcastListeners.length;
            
            for (var i:int=fromIndex; i<toIndex; ++i)
                sBroadcastListeners[i].dispatchEvent(event);
            
            sBroadcastListeners.length = fromIndex;
        }
        
        /** Dispatches an event with the given parameters on all children (recursively). 
         *  The method uses an internal pool of event objects to avoid allocations. */
        public function broadcastEventWith(eventType:String, data:Object=null):void
        {
            var event:Event = Event.fromPool(eventType, false, data);
            broadcastEvent(event);
            Event.toPool(event);
        }
        
        /** The number of children of this container. */
        public function get numChildren():int { return _numChildren; }
        
        /** If a container is a 'touchGroup', it will act as a single touchable object.
         *  Touch events will have the container as target, not the touched child.
         *  (Similar to 'mouseChildren' in the classic display list, but with inverted logic.)
         *  @default false */
        public function get touchGroup():Boolean { return _touchGroup; }
        public function set touchGroup(value:Boolean):void { _touchGroup = value; }

        // helpers
        
        private static function mergeSort(input:Vector.<DisplayObject>, compareFunc:Function, 
                                          startIndex:int, length:int, 
                                          buffer:Vector.<DisplayObject>):void
        {
            // This is a port of the C++ merge sort algorithm shown here:
            // http://www.cprogramming.com/tutorial/computersciencetheory/mergesort.html
            
            if (length > 1)
            {
                var i:int;
                var endIndex:int = startIndex + length;
                var halfLength:int = length / 2;
                var l:int = startIndex;              // current position in the left subvector
                var r:int = startIndex + halfLength; // current position in the right subvector
                
                // sort each subvector
                mergeSort(input, compareFunc, startIndex, halfLength, buffer);
                mergeSort(input, compareFunc, startIndex + halfLength, length - halfLength, buffer);
                
                // merge the vectors, using the buffer vector for temporary storage
                for (i = 0; i < length; i++)
                {
                    // Check to see if any elements remain in the left vector; 
                    // if so, we check if there are any elements left in the right vector;
                    // if so, we compare them. Otherwise, we know that the merge must
                    // take the element from the left vector. */
                    if (l < startIndex + halfLength && 
                        (r == endIndex || compareFunc(input[l], input[r]) <= 0))
                    {
                        buffer[i] = input[l];
                        l++;
                    }
                    else
                    {
                        buffer[i] = input[r];
                        r++;
                    }
                }
                
                // copy the sorted subvector back to the input
                for(i = startIndex; i < endIndex; i++)
                    input[i] = buffer[int(i - startIndex)];
            }
        }

        /** @private */
        internal function getChildEventListeners(object:DisplayObject, eventType:String, 
                                                 listeners:Vector.<DisplayObject>):void
        {
            var container:DisplayObjectContainer = object as DisplayObjectContainer;
            
            if (object.hasEventListener(eventType))
                listeners[listeners.length] = object; // avoiding 'push'                
            
            if (container)
            {
				var child:DisplayObject = container.childFirst;
				while(child) {
                    getChildEventListeners(child, eventType, listeners);
					child = child.next;
				}
            }
        }
    }
}
