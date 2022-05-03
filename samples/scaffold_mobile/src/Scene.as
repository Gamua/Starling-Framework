// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package
{
    import starling.display.Sprite;

    /** A Scene represents a full-screen, high-level element of your game.
     *  The "Menu" and "Game" classes inherit from this class.
     *  The "Root" class allows you to navigate between scene objects.
     */
    public class Scene extends Sprite
    {
        private var _sceneWidth:Number;
        private var _sceneHeight:Number;

        /** Initializes all its display objects.
         *  When this method is called, the scene is already connected to the stage. */
        public function init():void
        {}

        /** Called once after 'init', and then again when the device orientation changes.
         *  (e.g. from portrait to landscape). Override in subclasses! */
        public function updatePositions():void
        {}

        /** Called by 'Root' when the size changes.
         *  'width' and 'height' indicate the safe area size (screen minus cutouts). */
        public function setSize(width:Number, height:Number):void
        {
            _sceneWidth = width;
            _sceneHeight = height;
            updatePositions();
        }

        public function get sceneWidth():Number { return _sceneWidth; }
        public function get sceneHeight():Number { return _sceneHeight; }
    }
}
