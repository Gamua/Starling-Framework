Starling: Changelog
===================

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
