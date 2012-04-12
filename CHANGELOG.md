Starling: Changelog
===================

version 1.0 - 2012-02-24
------------------------

- reduced memory consumption a LOT by getting rid of many temporary objects
- added numerous performance enhancements (by inlining methods, removing closures, etc.)
- added 'sortChildren' method to DisplayObjectContainer, for easy child arrangement
- added 'useHandCursor' property to Sprite class
- added 'useHandCursor' activation to Button class
- added 'stage3D' property to Starling class
- added hover phase for both cursors in multitouch simulation
- added support to handle a lost device context
- added check for display tree recursions (a child must not add a parent)
- added support for having multiple Starling instances simultaneously
- added 'Event.COMPLETE' and using it in MovieClip class
- added Ant build file (thanks to groves!)
- added new artwork to demo project
- optimized MovieClip 'advanceTime' method
- changed IAnimatable interface:
    - removed 'isComplete' method
    - instead, the Juggler listens to the new event type REMOVE_FROM_JUGGLER
- fixed 'isComplete' method of various classes (possible due to IAnimatable change)
- fixed null reference exception in BitmapFont class that popped up when a kerned character
  was not defined (thanks to jamieowen!)
- fixed handling of platforms that have both mouse and a multitouch device
- fixed reliability of multitouch simulation
- fixed dispose method of main Starling class
- fixed bounds calculation on empty containers (thanks to groves!)
- fixed SubTextures: they are now smart enough to dispose unused base textures.
- fixed right mouse button issues in AIR (now only listening to left mouse button)

version 0.9.1 - 2011-12-11
--------------------------

- added property to access native stage from Starling class
- added property to access Starling stage from Starling class
- added exception when render function is not implemented
- moved touch marker image into src directory for better portability
- added bubbling for Event.ADDED and Event.REMOVED
- added 'readjustSize' method to Image
- added major performance enhancements:
    - created QuadBatch class as a replacement for the QuadGroup class, and using it for all quad
      rendering
    - optimized VertexData class
    - removed many Matrix allocations in RenderSupport class
    - removed many temporary object allocations
    - accelerated re-flattening of flattened sprites  
    - replaced performance critical 'for each' loops with faster 'for' loops
- demo now automatically uses 30 fps in Software mode    
- fixed center of rotation in multitouch demo
- fixed mouse/touch positions when stage size is changed
- fixed alpha propagation in flattened sprites
- fixed ignored bold property in TextField constructor
- fixed code to output fewer warnings in FDT

version 0.9 - 2011-09-11
------------------------

- first public version 
