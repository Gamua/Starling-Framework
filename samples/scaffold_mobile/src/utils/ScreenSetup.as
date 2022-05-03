// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package utils
{
    import flash.display.Screen;
    import flash.display.Stage;
    import flash.events.Event;
    import flash.geom.Rectangle;
    import flash.system.Capabilities;

    import starling.utils.Pool;
    import starling.utils.SystemUtil;

    public class ScreenSetup
    {
        private var _nativeStage:Stage;
        private var _viewPort:Rectangle; // pixels!
        private var _stageWidth:Number;  // points
        private var _stageHeight:Number; // points
        private var _safeArea:Rectangle; // points
        private var _scale:Number;
        private var _assetScale:Number;
        private var _assetScales:Array;

        public function ScreenSetup(nativeStage:Stage, assetScales:Array=null)
        {
            if (assetScales == null || assetScales.length == 0) assetScales = [1];

            _nativeStage = nativeStage;
            _assetScales = assetScales;
            _assetScales.sort(Array.NUMERIC | Array.DESCENDING);

            _viewPort = new Rectangle();
            _safeArea = new Rectangle();

            _nativeStage.addEventListener(Event.RESIZE,
                function (e:Event):void { recalculate(); });

            recalculate();
        }

        private function recalculate():void
        {
            var screenDPI:int = Capabilities.screenDPI;
            var isAndroid:Boolean = SystemUtil.isAndroid;
            var isIPad:Boolean = Capabilities.os.indexOf("iPad") != -1;
            var isAirSimulator:Boolean = Capabilities.os.match(/(windows|mac)/ig).length != 0;
            var screenWidth:int = _nativeStage.fullScreenWidth;
            var screenHeight:int = _nativeStage.fullScreenHeight;

            if (!isAirSimulator)
            {
                var screen:Screen = Screen.mainScreen;
                screenWidth = isAndroid ? screen.visibleBounds.width : screen.bounds.width;
                screenHeight = isAndroid ? screen.visibleBounds.height : screen.bounds.height;
            }

            var baseDPI:Number = isIPad ? 130 : 160;
            var exactScale:Number = screenDPI / baseDPI;

            if (exactScale < 1.25) _scale = 1.0;
            else if (exactScale < 1.75) _scale = 1.5;
            else _scale = Math.round(exactScale);

            _assetScale = _assetScales[0];

            for (var i:int=0; i<_assetScales.length; ++i)
                if (_assetScales[i] >= _scale) _assetScale = _assetScales[i];

            _stageWidth = screenWidth / scale;
            _stageHeight = screenHeight / scale;
            _viewPort.setTo(0, 0, screenWidth, screenHeight);
            _safeArea.setTo(0, 0, _stageWidth, _stageHeight);

            // Activate notch support by getting the "Application" ANE from distriqt:
            // https://airnativeextensions.com/extension/com.distriqt.Application
            // Then uncomment the code below, as well as the part in the application XML.
            /*
            if (Application.isSupported && !isAndroid)
            {
                // On Android, content is only displayed within the safe area by default.
                // Thus, a 'safe area' is currently only used on iOS.
                //
                // However, you *can* use the full size on Android, too. Have a look at
                // distriqt's 'Application' ANE and look for the `CUTOUT_SHORT_EDGES` layout mode.
                // In that case, remove the `&& !isAndroid` part from above.

                var cutout:DisplayCutout = Application.service.display.getDisplayCutout();
                var topInset:Number = cutout.safeInsetTop / _scale;
                var bottomInset:Number = cutout.safeInsetBottom / _scale;
                var leftInset:Number = cutout.safeInsetLeft / _scale;
                var rightInset:Number = cutout.safeInsetRight / _scale;

                _safeArea.setTo(leftInset, topInset,
                    _stageWidth - leftInset - rightInset,
                    _stageHeight - topInset - bottomInset);
            }
            */
        }

        /** Indicates if the screen is held in portrait mode. */
        public function get isPortrait():Boolean { return _stageWidth < _stageHeight; }

        /** The recommended stage width in points. */
        public function get stageWidth():Number { return _stageWidth; }

        /** The recommended stage height in points. */
        public function get stageHeight():Number { return _stageHeight; }

        /** The recommended viewPort rectangle in pixels. */
        public function get viewPort():Rectangle { return _viewPort; }

        /** The scale factor resulting from the recommended viewPort and stage sizes. */
        public function get scale():Number { return _scale; }

        /** From the available sets of assets, those with this scale factor will look best. */
        public function get assetScale():Number { return _assetScale; }

        /** The region of the screen that's not obscured by a notch or navigation bar, in points. */
        public function get safeArea():Rectangle { return _safeArea; }
    }
}
