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
        protected var _width:Number;
        protected var _height:Number;

        /** Sets up the screen, i.e. initializes all its display objects.
         *  When this method is called, the scene is already connected to the stage. */
        public function init(width:Number, height:Number):void
        {
            _width = width;
            _height = height;
        }

        /** Called when the orientation of the device changes (e.g. from portrait to landscape).
         *  If you don't need auto-orientation support, you can remove the "resizeTo" method here
         *  and in any subclasses.
         */
        public function resizeTo(width:Number, height:Number):void
        {
            _width = width;
            _height = height;
        }
    }
}
