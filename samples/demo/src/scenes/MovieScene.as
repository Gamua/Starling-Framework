package scenes
{
    import flash.media.Sound;

    import starling.core.Starling;
    import starling.display.MovieClip;
    import starling.events.Event;
    import starling.textures.Texture;

    public class MovieScene extends Scene
    {
        private var _movie:MovieClip;
        
        public function MovieScene()
        {
            var frames:Vector.<Texture> = Game.assets.getTextures("flight");
            _movie = new MovieClip(frames, 15);
            
            // add sounds
            var stepSound:Sound = Game.assets.getSound("wing_flap");
            _movie.setFrameSound(2, stepSound);
            
            // move the clip to the center and add it to the stage
            _movie.x = Constants.CenterX - int(_movie.width / 2);
            _movie.y = Constants.CenterY - int(_movie.height / 2);
            addChild(_movie);
            
            // like any animation, the movie needs to be added to the juggler!
            // this is the recommended way to do that.
            addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
        }
        
        private function onAddedToStage():void
        {
            Starling.juggler.add(_movie);
        }
        
        private function onRemovedFromStage():void
        {
            Starling.juggler.remove(_movie);
        }
        
        public override function dispose():void
        {
            removeEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
            removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            super.dispose();
        }
    }
}