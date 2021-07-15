Scaffold Project for Mobile Apps
================================

This project is set up as a universal application supporting iPhone and iPad, as well as any Android device. 
Use it as the basis for your mobile application projects. 
The recommended approach is to simply copy the complete directory somewhere on your disk, rename the classes appropriately, and add your application logic step by step.

Features:

* Assets for low- and high-resolution devices are loaded depending on screen size.
* The "ScreenSetup" class figures out the optimal scale factor and stage size.
* Scenes are automatically updated when the device orientation changes.
* Contains exemplary adaptive icons for Android and an 'Assets.car' file for iOS icons.
* The project proposes a simple structure to navigate between game and menu.
  This is done with three classes: _Root_, _Game_ and _Menu_.

To find out more about multi-resolution development, please visit the [Starling Manual][1]. 
It also contains an article about [device rotation][2].

[1]: https://manual.starling-framework.org/en/#_multi_resolution_development
[2]: https://manual.starling-framework.org/en/#_device_rotation

## Notch support

AIR currently doesn't tell us where a possible 'notch' or display cutout is placed. 
On Android, only the area below the notch is available, so this will work out of the box.
On iOS, however, the viewport fills the complete screen, including notch and home indicator.

My recommendation: get the excellent [Application ANE][3] from distriqt and use it to get the available 'safe area'.
The scaffold project already contains the code you need to use it, although it's commented out.
Change the relevant areas inside `Scaffold_Mobile-app.xml`, as well as `utils/ScreenSetup`, to use the ANE.

[3]: https://airnativeextensions.com/extension/com.distriqt.Application

## How to build this project ##

If you are working with Flash Builder, you can import the project using "File - Import Flash Builder Project".
IntelliJ IDEA users can open the provided module file.

In other IDEs, set up the project as an "ActionScript Mobile Project" and add the directories "src", "system", and "assets" to your source paths (that's required so that they are added to the application package when the project is built).
Furthermore, you have to link Starling to the project (either its "src" directory or the precompiled SWC file).

**Note:** To deploy to actual Android or iOS devices, you will need the certificates and profiles provided by Google or Apple.
