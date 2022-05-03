# Icons, Launch Storyboards and the Assets Catalog

Our friends from _distriqt_ have written [extensive documentation][1] on how to add an icon (in numerous variants), as well as a launch screen, for deployment to iOS.
This folder contains an Xcode project that you can use to customize and export the required files.

* After making the modifications (as described in the above link), build the project with Xcode.
* Then, right-click on "iOS Asset Project.app" (in the project navigator on the left) and select 'Show in Finder'.
* In the Finder, click on the app file again and choose 'Show Package Contents'.
* Copy the files `Assets.car` and `LaunchScreen.storyboardc` (optional) to the Starling Scaffold (`system` subfolder) or your own AIR project.

[1]: https://docs.airnativeextensions.com/docs/tutorials/ios-icons-assets-car

### Launch Screen storyboard vs. Harman 'Free Tier'

On the "Free Tier" of AIR, you're required to show a splash screen with the AIR logo.
The AIR SDK handles this via its own "launch screen" storyboard.
It will replace any custom one you've made (like the one in this Xcode project).

However, if you supply an `Assets.car` file (and you will, because it contains the app icon), you need to provide the splash image assets, as well.
They're found in the AIR SDK (`lib/aot/res` folder), but I've also included them in the Xcode project.

So, in the free tier:

* Make sure the `Assets.car` file contains the AIR splash images.
* Don't bother to customize and export the launch screen storyboard, as will be ignored by AIR.

If you're in a commercial tier:

* You can remove `splash_landscape` and `splash_portrait` from `Assets.xcassets` (by deleting them from the Xcode project).
* Customize the launch screen storyboard, e.g. with your own logo and colors.
* Include `LaunchScreen.storyboardc` when you copy over your assets from the compiled app.
