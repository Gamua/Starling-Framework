Starling: Changelog
===================

version 1.4.1 - 2013-10-15
--------------------------

- added public 'AssetManager.numQueuedAssets' property
- added protected 'AssetManager.queue' property
- added 'Starling.registerProgramFromSource' method
- optimized text rendering on buttons by enabling their 'batchable' property
- optimized fragment filter construction by caching shader programs (thanks to IonSwitz)
- optimized 'VertexData.numVertices' setter (thanks to hamidhomatash)
- fixed erroneous 'clipRect' when it was completely outside the stage bounds
- fixed error in 'AssetManager.loadQueue' when 'purgeQueue' was called during active timout
- fixed anonymous function for FDT compatibility of Scaffold project

version 1.4 - 2013-09-23
------------------------

- added 'Sprite.clipRect' property for simple rectangular masking (thanks to Tim Conkling)
- added 'DisplacementMapFilter'
- added support for 'HiDPI' (i.e. retina MacBooks)
- added support for RectangleTextures introduced in AIR 3.8
- added support for updated ATF file format
- added 'Texture.root.onRestore()' for manual texture restoration on context loss
- added 'Texture.fromEmbeddedAsset()'
- added 'TextField.autoSize' (thanks to Tim Conkling)
- added 'AssetManager.enqueueWithName()' for custom naming of assets
- added protected 'AssetManager.getName()' for custom naming rules in subclasses
- added protected 'TextField.formatText()' for subclassing (thanks to Grant Mathews)
- added support for generic XML, ByteArrays and JSON data to AssetManager
- added 'Stage.drawToBitmapData()' method for game screenshots
- added 'TextureAtlas.texture' property
- added 'Tween.getEndValue()' (thanks to Josh Tynjala)
- added 'Tween.getProgress()'
- added 'Quad.premultipliedAlpha' (for consistency)
- added 'AssetManager.checkPolicyFile'
- added 'AssetManager.purgeQueue()' method: empties the queue & stops all pending load operations
- added Event.TEXTURES_RESTORED, dispatched by AssetManager after context loss
- added 'TextField.redraw()' method to force immediate drawing of contents
- added 'DisplayObject.alignPivot()' for simple object alignment
- added optional 'id' paramter to 'TouchEvent.getTouch()' method
- added optional QuadBatch batching via 'QuadBatch.batchable'
- added 'RenderSupport.getTextureLookupFlags()'
- added 'Image.setTexCoordsTo()' method
- added 'Texture.adjustTexCoords()' method
- added support for all new Stage3D texture formats (including runtime compression on Desktop)
- added support for custom TouchProcessors (thanks to Tim Conkling)
- added 'suspendRendering' argument to 'Starling.stop()' method (for AIR 3.9 background execution)
- added more vertex & quad manipulation methods to QuadBatch
- optimized broadcast of ENTER_FRAME event
- optimized rendering by doing copy-transform simultaneously
- optimized 'DisplayObject.transformationMatrix' calculations (thanks to Ville Koskela)
- optimized hidden object allocations on iOS (thanks to Nisse Bryngfors & Adobe Scout)
- optimized handling of texture recreation in case of a context loss (requires much less memory)
- optimized usage of QuadBatches used during rendering (now trimming them)
- optimized 'Button' by removing TextField when text is empty String
- optimized 'DisplayObjectContainer.setChildIndex()' (thanks to Josh Tynjala)
- updated filename / URL parsing of AssetManager to be more robust (thanks to peerobo)
- updated Keyboard events: they are now broadcasted to all display objects
- updated 'transporter_chief.rb' to use 'iOS-deploy' instead of 'fruitstrap'
- updated the region a filter draws into (now limited to object bounds + margin)
- updated bitmap font registration to be case insensitive
- updated AssetManager to use texture file name as name for bitmap font
- updated QuadBatch: 'QuadBatch.mVertexData' is now protected, analog to 'Quad'
- updated Ant build-file to include ASDoc data in starling SWC
- fixed multitouch support on devices with both mouse and touch screen
- fixed that AssetManager sometimes never finished loading the queue
- fixed 'MovieClip.totalTime' calculations to avoid floating point errors
- fixed some problems with special cases within 'MovieClip.advanceTime()'
- fixed layout of monospace bitmap fonts
- fixed unwanted context3D-recreation in 'Starling.dispose()' (thanks to Sebastian Marketsmüller)
- fixed various errors in VertexData (thanks to hamidhomatash)
- fixed missing pivotX/Y-updates in 'DisplayObject.transformationMatrix' setter
- fixed native TextField padding value
- fixed that small filtered objects would cause frequent texture uploads
- fixed that 'DisplayObjectContainer.sortChildren()' used an unstable sorting algorithm
- fixed 'VertexData.getBounds()' for empty object
- fixed recursion error when applying filter on flattened object
- fixed dispatching of ADDED events when child was re-added to the same parent
- fixed missing HOVER event after ended Touches (caused hand-cursor to appear only after movement)
- fixed that clipping rectangle sometimes did not intersect framebuffer, leading to an error
- fixed TextField errors when the TextField-area was empty
- fixed UTF-8/16/32 recognition in AssetManager

version 1.3 - 2013-01-14
------------------------

- added FragmentFilter class for filter effects
- added BlurFilter for blur, drop shadow and glow effects
- added ColorMatrixFilter for color effects
- added experimental 'AssetManager' class to scaffold and demo projects
- added convenience method 'Juggler.tween'
- added 'repeatDelay' property to Tween class
- added 'onRepeat' and 'onRepeatArgs' callback to Tween class
- added 'repeatCount' and 'reverse' properties to Tween class
- added 'nextTween' property to Tween class
- added support for custom transition functions without string reference
- added 'TextureAtlas.getNames' method
- added text alignment properties to the Button class (thanks to piterwilson)
- added workaround for viewport limitations in constrained mode (thanks to jamikado)
- added setting of correct stage scale mode and align to Starling constructor
- added 'RectangleUtil' class with Rectangle helper methods
- added support for asynchronous loading of ATF textures
- added 'renderTarget' property to RenderSupport class
- added 'scissorRect' property to RenderSupport class
- added 'nativeWidth' & 'nativeHeight' properties to Texture classes
- added 'Juggler.contains' method (thanks to Josh Tynjala)
- added support for directly modifying Starling viewPort rectangle (without re-assigning)
- added option to ignore mip maps of ATF textures
- added 'reset' method to 'DelayedCall' class (thanks to Oldes)
- added support for infinite 'DelayedCall' repetitions
- added 'pressure' and 'size' properties to Touch
- added optional 'result' argument to 'Touch.getTouches' (thanks to Josh Tynjala)
- added optional 'result' argument to 'TextureAtlas.getTextures/getNames'
- added support for carriage return char in BitmapFont (thanks to marcus7262)
- added arguments for mipmaps and scale to 'fromBitmap' method (thanks to elsassph)
- added preloader to demo project
- added scale parameter to 'Starling.showStatsAt'
- added support for Event.MOUSE_LEAVE on native stage (thans to jamikado)
- added support for Maven builds (thanks to bsideup)
- added 'contextData' property on Starling instance
- added 'RenderSupport.assembleAgal'
- updated mobile scaffold and demo projects, now using the same startup class for Android & iOS
- updated methods in 'Transitions' class to be protected
- updated 'DisplayObject.hasVisibleArea' method to be public
- updated MovieClip.fps setter for better performance (thanks to radamchin)
- updated handling of shared context situations (now also supporting context loss)
- removed embedded assets to avoid dependency on 'mx.core' library
- fixed display list rendering when Starling is stopped (thanks to jamikado)
- fixed 'DisplayObject.transformationMatrix' setter
- fixed skewing to work just like in Flash Pro (thanks to tconkling)
- fixed 'Touch.get(Previous)Location' (threw error when touch target was no longer on the stage)
- fixed wrong x-offset on first bitmap char of a line (thanks to Calibretto)
- fixed bug when creating a SubTexture / calling 'Texture.fromTexture()' from a RenderTexture
- fixed disruptive left-over touches on interruption of AIR app
- fixed multiply blend mode for ATF textures
- fixed error when juggler purge was triggered from advanceTime
- fixed: bubble chain is now frozen when touch reaches phase "BEGAN"
- fixed: now disposing children in reverse order
- fixed: now forcing correct depth test and stencil settings
- fixed: stats display now remembers previous position

version 1.2 - 2012-08-15
------------------------

- added enhanced event system with automatic event pooling and new 'dispatchEventWith' method
- added support for Context3D profiles (available in AIR 3.4)
- added support for final ATF file format
- added support for skewing through new properties 'skewX' and 'skewY' on DisplayObjects
  (thanks to aduros, tconkling, spmallick and groves)
- added support for manually assigning a transformation matrix to a display object 
  (thanks to spmallick)
- added new 'DRW' value in statistics display, showing the number of draw calls per frame
- added 'BitmapFont.createSprite' method, useful for simple text effects
- added support for a shared context3D (useful for combining Starling with other frameworks)
- added 'Starling.root' property to access the root class instance
- added 'BitmapFont.getBitmapFont' method
- added support for custom bitmap font names
- added support for batching QuadBatch instances
- added check that MovieClip's fps value is greater than zero
- added 'MatrixUtil' class containing Matrix helper methods
- added more optional 'result*'-parameters to avoid temporary object creation
- added native filter support to TextField class (thanks to RRAway)
- added 'getRegion' and 'getFrame' methods to TextureAtlas
- added new 'DisplayObject.base' property that replaces old 'DisplayObject.root' functionality.
- now, 'DisplayObject.root' returns the topmost object below the stage, just as in classic Flash.
- now determining bubble chain before dispatching event, just as in classic Flash
- now returning the removed/added child in remove/add methods of DisplayObject
- now returning the name of the bitmap font in 'registerBitmapFont' method
- moved 'useHandCursor' property from Sprite to DisplayObject
- updated AGALMiniAssembler to latest version
- optimized performance by using 2D matrices (instead of Matrix3D) almost everywhere
- optimized performance by caching transformation matrices of DisplayObjects
- optimized handling of empty batches in 'RenderSupport.finishQuadBatch' method
- optimized temporary object handling, avoiding it at even more places
- optimized localToGlobal and globalToLocal methods
- optimized bitmap char arrangement by moving color assignment out of the loop
- optimized bitmap char arrangement by pooling char location objects
- optimized abstract class check (now only done in debug player)
- optimized 'advanceTime' method in Juggler
- optimized MovieClip constructor
- fixed wrong char arrangement when last bitmap char is missing (thanks to qoolbox)
- fixed handling of touches that begin outside the viewport
- fixed wrong 'tinted' value when setting color to white
- fixed scaling implementation (did not take cached transformation matrix into account)
- fixed handling of duplicate event listeners
- fixed handling of duplicate tweens in juggler (thanks to bsideup)
- fixed bitmap font line position when text is truncated
- fixed memory leak when using Juggler.purge (thanks to vync79)
- fixed leak when computing display object's transformation matrix (thanks to Fraggle)
- fixed error caused by removal of sibling in REMOVED_FROM_STAGE event (thanks to Josh)
- fixed that ROOT_CREATED was sometimes dispatched in wrong situations (thanks to Alex and Marc)

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
