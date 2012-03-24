package 
{
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    
    import scenes.RenderTextureScene;
    
    import starling.core.Starling;
    
    import xd.touch.DeviceManagerClient;
    
    [SWF(width="1500", height="1024", frameRate="60", backgroundColor="#222222")]
    public class DeviceStartup extends DeviceManagerClient
    {
        private var mStarling:Starling;
        
        public function DeviceStartup()
        {
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            
			RenderTextureScene.sHeight = 1024; // _devMgr.bounds.height;
			RenderTextureScene.sWidth = 2048;// _devMgr.bounds.width;
            Starling.multitouchEnabled = true;
            
            mStarling = new Starling(Game, stage,null,null,"auto",true);
            mStarling.simulateMultitouch = false;
            mStarling.enableErrorChecking = false;
            mStarling.start();
        }
    }
}