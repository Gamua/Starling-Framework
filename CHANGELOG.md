Starling: Changelog
===================

version 1.1 - 2012-05-06
------------------------

- added support for multi-resolution development through 'contentScaleFactor'
- added demo project for mobile devices
- added scaffold project for mobile devices
- added blend modes
- added Flash Builder project files
- added ability to erase content from a render texture (through 'BlendMode.ERASE')
- added 'toString' method to Touch class
- added 'getBounds' utility method to VertexData class and using it in Quad class
- added ability to use 'QuadBatch' class as a display object
- added 'Starling.showStats' method for FPS and MEM monitoring
- added minimal Bitmap Font 'mini'
- added 'baseline' property to BitmapFont class
- added ability to use multiples of 'BitmapFont.NATIVE_SIZE'
- added 'Touch.getMovement' property
- added 'Transport Chief' script to deploy iOS apps via the terminal
- added reset method to tween class to support instance pooling (thanks to pchertok!)
- added 'Event.ROOT_CREATED', dispatched when the root object is ready (thanks to fogAndWhisky!)
- optimized shaders for iPad and comparable devices, leading to a much better performance
- optimized vertex buffer uploading for faster iPad 1 performance
- optimized 'Quad.getBounds' method
- optimized Bitmap Font rendering greatly
- optimized 'DisplayObjectContainer.contains' method greatly (thanks to joshtynjala!)
- optimized some matrix and rendering code (thanks to jSandhu!)
- fixed error when TextField text property was set to 'null'
- fixed wrong error output in 'Image.smoothing' setter
- fixed: pausing and restarting Starling now resets passed time 
- fixed exception when child of flattened sprite had zero scaleX- or scaleY-value
- fixed exception on mipmap creation when texture was only one pixel high/wide
- fixed lost color data when pma vertex data was set to 'alpha=0' (thanks to Tomyail!)
- fixed: mouse, touch & keyboard events are now ignored when Starling is stopped
- fixed: native overlay is now still updated when Starling is stopped
- fixed possible blurring of persistent render texture (thanks to grahamma!)
- fixed drawing erros in render texture that occured with certain scale factors
- fixed error when MovieClip was manipulated from a COMPLETE handler

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
