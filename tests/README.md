To run Starling's unit tests, you need libraries from both "FlexUnit" and from the "Flex SDK":

    flexunit-4.2.0-20140410-as3_4.12.0.swc
    flexunit-aircilistener-4.2.0-20140410-4.12.0.swc
    flexunit-cilistener-4.2.0-20140410-4.12.0.swc
    flexunit-flexcoverlistener-4.2.0-20140410-4.12.0.swc
    flexunit-uilistener-4.2.0-20140410-4.12.0.swc
    flexunitextended.swc
    fluint-extensions-4.2.0-20140410-4.12.0.swc
    hamcrest-as3-flex-1.1.3.swc → from turnkey/libs inside the FlexUnit download
    framework.swc → from the Flex SDK

(Note that you must not add "flexunit-4.2.0-...-flex_4.12.0.swc" if you're working with the AIR SDK, otherwise you'll get errors.)

You don't need Flex for normal Starling development, so you probably don't have those libraries at hand. For your convenience, I put together an archive with all the required SWC files. You can download it here:

http://goo.gl/KypNQT

Put those files into the "libs" directory, and you're good to go.