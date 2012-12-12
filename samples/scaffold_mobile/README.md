Scaffold Project for iOS
========================

This project is set up as a universal application supporting iPhone and iPad, as well as any Android device. Use it as the basis for your mobile game projects. The recommended approach is to simply copy the complete directory somewhere on your disk, rename the classes appropriately for your game, and add your game logic step by step.

Features:

* Assets for low- and high-resolution devices are loaded depending on screen size.
* Devices with screens smaller than 480x720 use SD graphics (e.g. old iPhone).
* Devices with greater resolutions use HD graphics (e.g. Retina iPhone, iPad).
* The assets are loaded from disk (instead of embedding them) to save memory.
* The "AssetManager" class simplifies management of your game assets.
* App icons and Startup images are correctly set up.
* While Starling is starting up, the background image is displayed in the classic 
  display list. This provides a seamless startup process.
* The project proposes a simple structure to navigate between game and menu. This
  is done with three classes: "Root", "Game" and "Menu".

To find out more about multi-resolution development, please visit the [Starling Wiki][1]. 
It also contains an article about [auto-rotation][2].

[1]: http://wiki.starling-framework.org/manual/multi-resolution_development
[2]: http://wiki.starling-framework.org/manual/auto-rotation

## How to build this project ##

If you are working with Flash Builder, you can import the project using "File - Import Flash Builder Project". In other IDEs, set up the project as an "ActionScript Mobile Project" and add the directories "src", "system", and "assets" to your source paths (that's required so that they are added to the application package when the project is built). Furthermore, you have to link Starling to the project (either its "src" directory or the precompiled SWC file).

**Note:** You will need at least AIR 3.2 to deploy AIR applications on a mobile device. To deploy to actual Android or iOS devices, you will need the certificates and profiles provided by Google or Apple.
