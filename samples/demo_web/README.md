How to build this Sample
========================

The web demo shows some of the features of Starling. It can be run via the Flash plugin.

This folder contains just the Startup-code. The rest of the code, as well as the assets, are found in the "demo" folder, and needs to be referenced in your project.

If you are working with Flash Builder, you can import the project using "File - Import Flash Builder Project". However, the project requires you to set up an Eclipse workspace path pointing to Starling. To do that, enter "Preferences - General - Workspace - Linked Resources" and add a new path variable called STARLING_FRAMEWORK that points to the root of the Starling-Framework directory.

If you are using another IDE, it might unfortunately be a little more complicated. You have to create a project that is based in this folder and add the following source paths to your project:

  * '../demo/src' -> the actual code of the demo
  * '../demo/media' -> the assets of the demo
  * '../demo/system' -> the system graphics (icons, launch images) of the demo

Starling itself can either be linked via a source path, or by referencing its swc file.

If your IDE doesn't allow adding source paths outside the project root, I recommend you create a new folder where you manually merge the "demo" and "demo_web" folders together. Then add just the "media" and "system" folders to your source paths (that's required so that the "Embed" statements can find them).
