package 
{
    import flash.display.Sprite;
    
    import starling.core.Starling;
    
    [SWF(width="320", height="480", frameRate="30", backgroundColor="#222222")]
    public class Startup extends Sprite
    {
        private var mStarling:Starling;
        
        public function Startup()
        {
            Starling.multitouchEnabled = true;
            
            mStarling = new Starling(Game, stage);
            mStarling.simulateMultitouch = true;
            mStarling.enableErrorChecking = false;
            mStarling.start();
        }
    }
}