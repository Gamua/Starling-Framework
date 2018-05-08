Scaffold Project for iOS
========================

This project is set up as a universal application supporting iPhone and iPad, as well as any Android device. Use it as the basis for your mobile application projects. The recommended approach is to simply copy the complete directory somewhere on your disk, rename the classes appropriately, and add your application logic step by step.

Features:

* Assets for low- and high-resolution devices are loaded depending on screen size.
* The "ScreenSetup" class figures out the optimal scale factor and stage size.
* Scenes are automatically updated when the device orientation changes.
* Some exemplary icons and launch images (iOS) are provided.
* While Starling is starting up, the splash screen is recreated in the classic display list.
  This provides a seamless startup process.
* The project proposes a simple structure to navigate between game and menu.
  This is done with three classes: _Root_, _Game_ and _Menu_.

To find out more about multi-resolution development, please visit the [Starling Wiki][1]. 
It also contains an article about [auto-rotation][2].

[1]: http://wiki.starling-framework.org/manual/multi-resolution_development
[2]: http://wiki.starling-framework.org/manual/auto-rotation

## How to build this project ##

If you are working with Flash Builder, you can import the project using "File - Import Flash Builder Project".
IntelliJ IDEA users can open the provided module file.

In other IDEs, set up the project as an "ActionScript Mobile Project" and add the directories "src", "system", and "assets" to your source paths (that's required so that they are added to the application package when the project is built).
Furthermore, you have to link Starling to the project (either its "src" directory or the precompiled SWC file).

**Note:** To deploy to actual Android or iOS devices, you will need the certificates and profiles provided by Google or Apple.
