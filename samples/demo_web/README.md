How to build this Sample
========================

The web demo shows some of the features of Starling. It can be run via the Flash plugin.

This folder contains just the Startup-code. The rest of the code, as well as the assets, are found in the "demo" folder, and needs to be referenced in your project.

If you are working with Flash Builder, import the project contained in this folder and update the referenced source paths. If you are using another IDE/editor, create a project that is based in this folder and add the following source paths to your project:

  * '../demo/src' -> the actual code of the demo
  * '../demo/media' -> the assets of the demo
  * '../demo/system' -> the system graphics (icons, launch images) of the demo

Starling itself can either be linked via a source path, or by referencing its swc file.
