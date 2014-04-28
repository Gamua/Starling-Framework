// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
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
    
    import starling.core.RenderSupport;
    import starling.core.starling_internal;
    import starling.errors.AbstractClassError;
    import starling.events.Event;
    import starling.filters.FragmentFilter;
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

        private var mChildren:Vector.<DisplayObject>;
        private var mTouchGroup:Boolean;
        
        /** Helper objects. */
        private static var sHelperMatrix:Matrix = new Matrix();
        private static var sHelperPoint:Point = new Point();
        private static var sBroadcastListeners:Vector.<DisplayObject> = new <DisplayObject>[];
        private static var sSortBuffer:Vector.<DisplayObject> = new <DisplayObject>[];
        
        // construction
        
        /** @private */
        public function DisplayObjectContainer()
        {
            if (Capabilities.isDebugger && 
                getQualifiedClassName(this) == "starling.display::DisplayObjectContainer")
            {
                throw new AbstractClassError();
            }
            
            mChildren = new <DisplayObject>[];
        }
        
        /** Disposes the resources of all children. */
        public override function dispose():void
        {
            for (var i:int=mChildren.length-1; i>=0; --i)
                mChildren[i].dispose();
            
            super.dispose();
        }
        
        // child management
        
        /** Adds a child to the container. It will be at the frontmost position. */
        public function addChild(child:DisplayObject):DisplayObject
        {
            addChildAt(child, numChildren);
            return child;
        }
        
        /** Adds a child to the container at a certain index. */
        public function addChildAt(child:DisplayObject, index:int):DisplayObject
        {
            var numChildren:int = mChildren.length; 
            
            if (index >= 0 && index <= numChildren)
            {
                if (child.parent == this)
                {
                    setChildIndex(child, index); // avoids dispatching events
                }
                else
                {
                    child.removeFromParent();
                    
                    // 'splice' creates a temporary object, so we avoid it if it's not necessary
                    if (index == numChildren) mChildren[numChildren] = child;
                    else                      mChildren.splice(index, 0, child);
                    
                    child.setParent(this);
                    child.dispatchEventWith(Event.ADDED, true);
                    
                    if (stage)
                    {
                        var container:DisplayObjectContainer = child as DisplayObjectContainer;
                        if (container) container.broadcastEventWith(Event.ADDED_TO_STAGE);
                        else           child.dispatchEventWith(Event.ADDED_TO_STAGE);
                    }
                }
                
                return child;
            }
            else
            {
                throw new RangeError("Invalid child index");
            }
        }
        
        /** Removes a child from the container. If the object is not a child, nothing happens. 
         *  If requested, the child will be disposed right away. */
        public function removeChild(child:DisplayObject, dispose:Boolean=false):DisplayObject
        {
            var childIndex:int = getChildIndex(child);
            if (childIndex != -1) removeChildAt(childIndex, dispose);
            return child;
        }
        
        /** Removes a child at a certain index. Children above the child will move down. If
         *  requested, the child will be disposed right away. */
        public function removeChildAt(index:int, dispose:Boolean=false):DisplayObject
        {
            if (index >= 0 && index < numChildren)
            {
                var child:DisplayObject = mChildren[index];
                child.dispatchEventWith(Event.REMOVED, true);
                
                if (stage)
                {
                    var container:DisplayObjectContainer = child as DisplayObjectContainer;
                    if (container) container.broadcastEventWith(Event.REMOVED_FROM_STAGE);
                    else           child.dispatchEventWith(Event.REMOVED_FROM_STAGE);
                }
                
                child.setParent(null);
                index = mChildren.indexOf(child); // index might have changed by event handler
                if (index >= 0) mChildren.splice(index, 1); 
                if (dispose) child.dispose();
                
                return child;
            }
            else
            {
                throw new RangeError("Invalid child index");
            }
        }
        
        /** Removes a range of children from the container (endIndex included). 
         *  If no arguments are given, all children will be removed. */
        public function removeChildren(beginIndex:int=0, endIndex:int=-1, dispose:Boolean=false):void
        {
            if (endIndex < 0 || endIndex >= numChildren) 
                endIndex = numChildren - 1;
            
            for (var i:int=beginIndex; i<=endIndex; ++i)
                removeChildAt(beginIndex, dispose);
        }
        
        /** Returns a child object at a certain index. */
        public function getChildAt(index:int):DisplayObject
        {
            if (index >= 0 && index < numChildren)
                return mChildren[index];
            else
                throw new RangeError("Invalid child index");
        }
        
        /** Returns a child object with a certain name (non-recursively). */
        public function getChildByName(name:String):DisplayObject
        {
            var numChildren:int = mChildren.length;
            for (var i:int=0; i<numChildren; ++i)
                if (mChildren[i].name == name) return mChildren[i];

            return null;
        }
        
        /** Returns the index of a child within the container, or "-1" if it is not found. */
        public function getChildIndex(child:DisplayObject):int
        {
            return mChildren.indexOf(child);
        }
        
        /** Moves a child to a certain index. Children at and after the replaced position move up.*/
        public function setChildIndex(child:DisplayObject, index:int):void
        {
            var oldIndex:int = getChildIndex(child);
            if (oldIndex == index) return;
            if (oldIndex == -1) throw new ArgumentError("Not a child of this container");
            mChildren.splice(oldIndex, 1);
            mChildren.splice(index, 0, child);
        }
        
        /** Swaps the indexes of two children. */
        public function swapChildren(child1:DisplayObject, child2:DisplayObject):void
        {
            var index1:int = getChildIndex(child1);
            var index2:int = getChildIndex(child2);
            if (index1 == -1 || index2 == -1) throw new ArgumentError("Not a child of this container");
            swapChildrenAt(index1, index2);
        }
        
        /** Swaps the indexes of two children. */
        public function swapChildrenAt(index1:int, index2:int):void
        {
            var child1:DisplayObject = getChildAt(index1);
            var child2:DisplayObject = getChildAt(index2);
            mChildren[index1] = child2;
            mChildren[index2] = child1;
        }
        
        /** Sorts the children according to a given function (that works just like the sort function
         *  of the Vector class). */
        public function sortChildren(compareFunction:Function):void
        {
            sSortBuffer.length = mChildren.length;
            mergeSort(mChildren, compareFunction, 0, mChildren.length, sSortBuffer);
            sSortBuffer.length = 0;
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
        public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
        {
            if (resultRect == null) resultRect = new Rectangle();
            
            var numChildren:int = mChildren.length;
            
            if (numChildren == 0)
            {
                getTransformationMatrix(targetSpace, sHelperMatrix);
                MatrixUtil.transformCoords(sHelperMatrix, 0.0, 0.0, sHelperPoint);
                resultRect.setTo(sHelperPoint.x, sHelperPoint.y, 0, 0);
            }
            else if (numChildren == 1)
            {
                resultRect = mChildren[0].getBounds(targetSpace, resultRect);
            }
            else
            {
                var minX:Number = Number.MAX_VALUE, maxX:Number = -Number.MAX_VALUE;
                var minY:Number = Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE;
                
                for (var i:int=0; i<numChildren; ++i)
                {
                    mChildren[i].getBounds(targetSpace, resultRect);
                    minX = minX < resultRect.x ? minX : resultRect.x;
                    maxX = maxX > resultRect.right ? maxX : resultRect.right;
                    minY = minY < resultRect.y ? minY : resultRect.y;
                    maxY = maxY > resultRect.bottom ? maxY : resultRect.bottom;
                }
                
                resultRect.setTo(minX, minY, maxX - minX, maxY - minY);
            }                
            
            return resultRect;
        }
        
        /** @inheritDoc */
        public override function hitTest(localPoint:Point, forTouch:Boolean=false):DisplayObject
        {
            if (forTouch && (!visible || !touchable))
                return null;
            
            var target:DisplayObject = null;
            var localX:Number = localPoint.x;
            var localY:Number = localPoint.y;
            var numChildren:int = mChildren.length;

            for (var i:int=numChildren-1; i>=0; --i) // front to back!
            {
                var child:DisplayObject = mChildren[i];
                getTransformationMatrix(child, sHelperMatrix);
                
                MatrixUtil.transformCoords(sHelperMatrix, localX, localY, sHelperPoint);
                target = child.hitTest(sHelperPoint, forTouch);
                
                if (target)
                    return forTouch && mTouchGroup ? this : target;
            }
            
            return null;
        }
        
        /** @inheritDoc */
        public override function render(support:RenderSupport, parentAlpha:Number):void
        {
            var alpha:Number = parentAlpha * this.alpha;
            var numChildren:int = mChildren.length;
            var blendMode:String = support.blendMode;
            
            for (var i:int=0; i<numChildren; ++i)
            {
                var child:DisplayObject = mChildren[i];
                
                if (child.hasVisibleArea)
                {
                    var filter:FragmentFilter = child.filter;

                    support.pushMatrix();
                    support.transformMatrix(child);
                    support.blendMode = child.blendMode;
                    
                    if (filter) filter.render(child, support, alpha);
                    else        child.render(support, alpha);
                    
                    support.blendMode = blendMode;
                    support.popMatrix();
                }
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
            // care that the static helper vector does not get currupted.
            
            var fromIndex:int = sBroadcastListeners.length;
            getChildEventListeners(this, event.type, sBroadcastListeners);
            var toIndex:int = sBroadcastListeners.length;
            
            for (var i:int=fromIndex; i<toIndex; ++i)
                sBroadcastListeners[i].dispatchEvent(event);
            
            sBroadcastListeners.length = fromIndex;
        }
        
        /** Dispatches an event with the given parameters on all children (recursively). 
         *  The method uses an internal pool of event objects to avoid allocations. */
        public function broadcastEventWith(type:String, data:Object=null):void
        {
            var event:Event = Event.fromPool(type, false, data);
            broadcastEvent(event);
            Event.toPool(event);
        }
        
        /** The number of children of this container. */
        public function get numChildren():int { return mChildren.length; }
        
        /** If a container is a 'touchGroup', it will act as a single touchable object.
         *  Touch events will have the container as target, not the touched child.
         *  (Similar to 'mouseChildren' in the classic display list, but with inverted logic.)
         *  @default false */
        public function get touchGroup():Boolean { return mTouchGroup; }
        public function set touchGroup(value:Boolean):void { mTouchGroup = value; }

        // helpers
        
        private static function mergeSort(input:Vector.<DisplayObject>, compareFunc:Function, 
                                          startIndex:int, length:int, 
                                          buffer:Vector.<DisplayObject>):void
        {
            // This is a port of the C++ merge sort algorithm shown here:
            // http://www.cprogramming.com/tutorial/computersciencetheory/mergesort.html
            
            if (length <= 1) return;
            else
            {
                var i:int = 0;
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
                var children:Vector.<DisplayObject> = container.mChildren;
                var numChildren:int = children.length;
                
                for (var i:int=0; i<numChildren; ++i)
                    getChildEventListeners(children[i], eventType, listeners);
            }
        }
    }
}
