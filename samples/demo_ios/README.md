How to build this Sample
========================

This folder contains additional source code and assets that allow you to deploy the standard demo project on the iPhone.

In Flash Builder, create a new "ActionScript Mobile" project, and add the following source paths:

* the "src" directory of the standard demo project and
* the "media" directory of the iOS demo project.

Then exchange the source files that were created by the Flash Builder project wizard with the source files in the "src" folder of the iOS demo project. Use "Startup_iOS" as the startup class.

**Note:** You will need AIR 3.2 to deploy AIR applications on a mobile device. Furthermore, you need a developer certificate and provisioning profiles, both of which can be acquired from Apple when you are a member of the iOS Developer program. 

Known Issues:
-------------

* AIR 3.2 causes problems when you try to run/debug the app in the device simulator: you need to set "fullscreen" to "false" in the app's configuration file to see any rendering output. This is fixed in AIR 3.3.