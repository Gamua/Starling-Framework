// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2014 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.utils
{
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.system.Capabilities;
    import flash.utils.getDefinitionByName;
    
    import starling.errors.AbstractClassError;

    /** A utility class with methods related to the current platform and runtime. */
    public class SystemUtil
    {
        private static var sInitialized:Boolean = false;
        private static var sApplicationActive:Boolean = true;
        private static var sWaitingCalls:Array = [];
        private static var sPlatform:String;
        private static var sVersion:String;
        private static var sAIR:Boolean;
        
        /** @private */
        public function SystemUtil() { throw new AbstractClassError(); }
        
        /** Initializes the <code>ACTIVATE/DEACTIVATE</code> event handlers on the native
         *  application. This method is automatically called by the Starling constructor. */
        public static function initialize():void
        {
            if (sInitialized) return;
            
            sInitialized = true;
            sPlatform = Capabilities.version.substr(0, 3);
            sVersion = Capabilities.version.substr(4);
            
            try
            {
                var nativeAppClass:Object = getDefinitionByName("flash.desktop::NativeApplication");
                var nativeApp:EventDispatcher = nativeAppClass["nativeApplication"] as EventDispatcher;
                
                nativeApp.addEventListener(Event.ACTIVATE, onActivate, false, 0, true);
                nativeApp.addEventListener(Event.DEACTIVATE, onDeactivate, false, 0, true);
                
                sAIR = true;
            }
            catch (e:Error)
            {
                sAIR = false;
            }
        }
        
        private static function onActivate(event:Object):void
        {
            sApplicationActive = true;
            
            for each (var call:Array in sWaitingCalls)
                call[0].apply(null, call[1]);
            
            sWaitingCalls = [];
        }
        
        private static function onDeactivate(event:Object):void
        {
            sApplicationActive = false;
        }
        
        /** Executes the given function with its arguments the next time the application is active.
         *  (If it <em>is</em> active already, the call will be executed right away.) */
        public static function executeWhenApplicationIsActive(call:Function, ...args):void
        {
            initialize();
            
            if (sApplicationActive) call.apply(null, args);
            else sWaitingCalls.push([call, args]);
        }

        /** Indicates if the application is currently active. On Desktop, this means that it has
         *  the focus; on mobile, that it is in the foreground. In the Flash Plugin, always
         *  returns true. */
        public static function get isApplicationActive():Boolean
        {
            initialize();
            return sApplicationActive;
        }

        /** Indicates if the code is executed in an Adobe AIR runtime (true)
         *  or Flash plugin/projector (false). */
        public static function get isAIR():Boolean
        {
            initialize();
            return sAIR;
        }
        
        /** Indicates if the code is executed on a Desktop computer with Windows, OS X or Linux
         *  operating system. If the method returns 'false', it's probably a mobile device
         *  or a Smart TV. */
        public static function get isDesktop():Boolean
        {
            initialize();
            return /(WIN|MAC|LNX)/.exec(sPlatform) != null;
        }
        
        /** Returns the three-letter platform string of the current system. These are
         *  the most common platforms: <code>WIN, MAC, LNX, IOS, AND, QNX</code>. Except for the
         *  last one, which indicates "Blackberry", all should be self-explanatory. */
        public static function get platform():String
        {
            initialize();
            return sPlatform;
        }

        /** Returns the Flash Player/AIR version string. The format of the version number is:
         *  <em>majorVersion,minorVersion,buildNumber,internalBuildNumber</em>. */
        public static function get version():String
        {
            initialize();
            return sVersion;
        }

        /** Prior to Flash/AIR 15, there was a restriction that the clear function must be
         *  called on a render target before drawing. This requirement was removed subsequently,
         *  and this property indicates if that's the case in the current runtime. */
        public static function get supportsRelaxedTargetClearRequirement():Boolean
        {
            return parseInt(/\d+/.exec(sVersion)[0]) >= 15;
        }
    }
}