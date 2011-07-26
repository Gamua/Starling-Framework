Starling Framework: the Hardware accelerated 2D Engine for Flash
================================================================

What is Starling?
-----------------

Starling is an ActionScript 3 library that mimics the conventional Flash display tree architecture. In contrast to conventional display objects, however, Starling "lives" entirely inside the Stage3D environment. That means that all objects are rendered directly by the GPU, which leads to a significant performance boost. 

Starling's API is not a direct 1:1 port of the Flash API. The classes were streamlined and optimized for working well with the GPU; common tasks in game development were simplified. Starling hides the Stage3D internals from developers, but makes it easy to access them for those who need to create custom display objects.

Just like its iOS sibling, the [Sparrow Framework][1], Starling aims to be as lightweight and easy to use as possible. As an Open Source project, much care was taken to make the source code easy to read, understand and extend.

[1]: http://www.sparrow-framework.org