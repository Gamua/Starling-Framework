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

## Building the project

Users of "IntelliJ IDEA" can open the project that's stored in `starling/build/idea`.
It has everything set up.

Users of "Visual Studio Code" can run this scaffold like this:

1. Install the "ActionScript & MXML" extension from Josh Tynjala and point it to the latest AIR SDK.
2. Open the project folder in Visual Studio Code.
3. (Optional) To run on an actual device, adapt the "signingOptions" in `asconfig.json` so that they point to your local development keys from Apple and Google.
4. Enter the "Run and Debug" menu in the sidebar and start of one of the available configurations.

All others, please refer to the documentation of their respective IDE.
