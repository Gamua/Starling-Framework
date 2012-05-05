Scaffold Project for iOS
========================

This project is set up as a universal application supporting iPhone and iPad, as well as any Android device. Use it as the basis for your mobile game projects.

Features:

* Assets for low- and high-resolution devices are loaded depending on screen size.
* Devices with screens smaller than 480x720 use SD graphics (e.g. old iPhone).
* Devices with greater resolutions use HD graphics (e.g. Retina iPhone, iPad).
* App icons and Startup images are correctly set up.
* On iOS, the background image is displayed in the classic display list while Starling 
  is starting up.

To find out more about multi-resolution development, please visit the [Starling Wiki][1]. 
It also contains an article about [auto-rotation][2].

[1]: http://wiki.starling-framework.org/manual/multi-resolution_development
[2]: http://wiki.starling-framework.org/manual/auto-rotation

**Note:** You will need at least AIR 3.2 to deploy AIR applications on a mobile device. For iOS, you will furthermore need a developer certificate and provisioning profiles, both of which can be acquired from Apple when you are a member of the iOS Developer program. 
