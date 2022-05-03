Scaffold Project for Mobile Apps
================================

This project is set up as a universal application supporting iPhone and iPad, as well as any Android device.
Use it as the basis for your mobile application projects.
The recommended approach is to simply copy the complete directory somewhere onto your disk, rename the classes appropriately, and add your application logic step by step.

Features:

* Assets for low- and high-resolution devices are loaded depending on screen size.
* The "ScreenSetup" class figures out the optimal scale factor and stage size.
* Scenes are automatically updated when the device orientation changes.
* Contains exemplary adaptive icons for Android and an 'Assets.car' file for iOS icons.
* The project proposes a simple structure to navigate between game and menu.
  This is done with three classes: _Root_, _Game_ and _Menu_.
* Contains project files for _Visual Studio Code_ and _IntelliJ IDEA_.

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

## Updating application icon and launch screen

Since iOS 11, Apple requires the app icon to be added in the form of an `Assets.car` file that needs to be created via Xcode (or online tools created by the developer community). The details are explained in great detail by our friends from distriqt, so please refer to [their tutorial][4] for the details.

The same document also explains how to set up your launch screen (i.e. `LaunchScreen.storyboard`) – but beware that you only need to set that up if you're using a commercial version of AIR. If you're on the 'Free Tier', Harman will show a splash screen anyway, so don't bother with it.

In any case, have a look at the 'util' folder of the Starling download to find the Xcode project that was used to create icons and launch screen for the scaffold project.
Together with above's tutorial, you should be able to adapt it to your needs.

Android nowadays requires 'adaptive icons' for its apps, which means that they are split up into a foreground and a background image.
Those files are most easily created with _Android Studio_ and then imported into your app via a 'resource folder'.

Again, I want to forward you to the respective [tutorial][5] from distriqt.
The scaffold project has its resource folder inside `system/res`; the new `resdir` element inside the application XML will tell AIRs packaging tool where to find them.

[4]: https://docs.airnativeextensions.com/docs/tutorials/ios-icons-assets-car
[5]: https://docs.airnativeextensions.com/docs/tutorials/android-adaptive-icons

## Building the project

Users of "IntelliJ IDEA" can open the project that's stored in `starling/build/idea`.
It has everything set up.

Users of "Visual Studio Code" can run this scaffold like this:

1. Install the "ActionScript & MXML" extension from Josh Tynjala and point it to the latest AIR SDK.
2. Open the project folder in Visual Studio Code.
3. (Optional) To run on an actual device, adapt the "signingOptions" in `asconfig.json` so that they point to your local development keys from Apple and Google.
4. Enter the "Run and Debug" menu in the sidebar and start of one of the available configurations.

All others, please refer to the documentation of their respective IDE.
