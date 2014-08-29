// =================================================================================================
//
//  Starling Framework
//  Copyright 2011-2014 Gamua. All Rights Reserved.
//
//  This program is free software. You can redistribute and/or modify it
//  in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests
{
    import flash.events.Event;
    import flash.events.EventDispatcher;
    
    import org.flexunit.async.Async;
    import org.fluint.uiImpersonation.UIImpersonator;
    
    import starling.core.Starling;
    import starling.events.Event;
    import starling.events.EventDispatcher;

    public class StarlingTestCase
    {
        
        private var starling:Starling;
        private var flashEventAdapter:flash.events.EventDispatcher;
        private var eventListenerTargets:Vector.<starling.events.EventDispatcher>;
        
        [Before(async)]
        public function setUp():void
        {
            eventListenerTargets = new Vector.<starling.events.EventDispatcher>();
            flashEventAdapter = new flash.events.EventDispatcher();
            starling = new Starling(TestGame, UIImpersonator.testDisplay.stage);
            proceedOnStarlingEvent(starling.events.Event.ROOT_CREATED, starling);
            starling.start();
        }
        
        [After]
        public function tearDown():void
        {
            removeEventListeners();
            starling.dispose();
            starling = null;
        }
        
        protected function proceedOnStarlingEvent(type:String, target:starling.events.EventDispatcher, timeout:uint=500):void
        {
            eventListenerTargets.push(target);
            target.addEventListener(type, genericStarlingEventHandler);
            Async.proceedOnEvent(this, flashEventAdapter, type, timeout);
        }
        
        protected function handleStarlingEvent(type:String, target:starling.events.EventDispatcher, handler:Function=null, timeout:uint=500):void
        {
            eventListenerTargets.push(target);
            target.addEventListener(type, genericStarlingEventHandler);
            Async.handleEvent(this, flashEventAdapter, type, handler, timeout);
        }
        
        private function genericStarlingEventHandler(event:starling.events.Event):void
        {
            flashEventAdapter.dispatchEvent(new flash.events.Event(event.type));
        }
        
        private function removeEventListeners():void
        {
            var l:uint = eventListenerTargets.length;
            
            for (var i:uint = 0; i < l; i++) {
                eventListenerTargets[i].removeEventListeners();
            }
            
            eventListenerTargets = null;
        }
        
    }
}

import starling.display.Sprite;

class TestGame extends Sprite { }