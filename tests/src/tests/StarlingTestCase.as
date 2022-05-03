// =================================================================================================
//
//  Starling Framework
//  Copyright Gamua GmbH. All Rights Reserved.
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
        private var _starling:Starling;
        private var _flashEventAdapter:flash.events.EventDispatcher;
        private var _eventListenerTargets:Vector.<starling.events.EventDispatcher>;
        
        [Before(async)]
        public function setUp():void
        {
            _eventListenerTargets = new Vector.<starling.events.EventDispatcher>();
            _flashEventAdapter = new flash.events.EventDispatcher();
            _starling = new Starling(TestGame, UIImpersonator.testDisplay.stage);
            proceedOnStarlingEvent(starling.events.Event.ROOT_CREATED, _starling);
            _starling.start();
        }
        
        [After]
        public function tearDown():void
        {
            removeEventListeners();
            _starling.dispose();
            _starling = null;
        }
        
        protected function proceedOnStarlingEvent(type:String, target:starling.events.EventDispatcher, timeout:uint=500):void
        {
            _eventListenerTargets.push(target);
            target.addEventListener(type, genericStarlingEventHandler);
            Async.proceedOnEvent(this, _flashEventAdapter, type, timeout);
        }
        
        protected function handleStarlingEvent(type:String, target:starling.events.EventDispatcher, handler:Function=null, timeout:uint=500):void
        {
            _eventListenerTargets.push(target);
            target.addEventListener(type, genericStarlingEventHandler);
            Async.handleEvent(this, _flashEventAdapter, type, handler, timeout);
        }
        
        private function genericStarlingEventHandler(event:starling.events.Event):void
        {
            _flashEventAdapter.dispatchEvent(new flash.events.Event(event.type));
        }
        
        private function removeEventListeners():void
        {
            var l:uint = _eventListenerTargets.length;
            
            for (var i:uint = 0; i < l; i++) {
                _eventListenerTargets[i].removeEventListeners();
            }
            
            _eventListenerTargets = null;
        }
    }
}

import starling.display.Sprite;

class TestGame extends Sprite { }