// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2015 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.utils
{
    import com.adobe.utils.AGALMiniAssembler;

    import flash.display.Stage3D;
    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DRenderMode;
    import flash.display3D.Context3DTextureFormat;
    import flash.display3D.Program3D;
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.utils.setTimeout;

    import starling.core.Starling;
    import starling.display.BlendMode;
    import starling.errors.AbstractClassError;
    import starling.errors.MissingContextError;
    import starling.textures.TextureSmoothing;

    /** A utility class containing methods related to Stage3D and rendering in general. */
    public class RenderUtil
    {
        private static var sAssembler:AGALMiniAssembler = new AGALMiniAssembler();

        /** @private */
        public function RenderUtil()
        {
            throw new AbstractClassError();
        }

        /** Clears the render context with a certain color and alpha value. */
        public static function clear(rgb:uint=0, alpha:Number=0.0):void
        {
            Starling.context.clear(
                    Color.getRed(rgb)   / 255.0,
                    Color.getGreen(rgb) / 255.0,
                    Color.getBlue(rgb)  / 255.0,
                    alpha);
        }

        /** Sets up the render context's blending factors with a certain blend mode. */
        public static function setBlendFactors(premultipliedAlpha:Boolean, blendMode:String="normal"):void
        {
            var blendFactors:Array = BlendMode.getBlendFactors(blendMode, premultipliedAlpha);
            Starling.context.setBlendFactors(blendFactors[0], blendFactors[1]);
        }

        /** Assembles fragment- and vertex-shaders, passed as Strings, to a Program3D. If you
         *  pass a 'resultProgram', it will be uploaded to that program; otherwise, a new program
         *  will be created on the current Stage3D context. */
        public static function assembleAgal(vertexShader:String, fragmentShader:String,
                                            resultProgram:Program3D=null):Program3D
        {
            if (resultProgram == null)
            {
                var context:Context3D = Starling.context;
                if (context == null) throw new MissingContextError();
                resultProgram = context.createProgram();
            }

            resultProgram.upload(
                    sAssembler.assemble(Context3DProgramType.VERTEX, vertexShader),
                    sAssembler.assemble(Context3DProgramType.FRAGMENT, fragmentShader));

            return resultProgram;
        }

        /** Returns the flags that are required for AGAL texture lookup,
         *  including the '&lt;' and '&gt;' delimiters. */
        public static function getTextureLookupFlags(format:String, mipMapping:Boolean,
                                                     repeat:Boolean=false,
                                                     smoothing:String="bilinear"):String
        {
            var options:Array = ["2d", repeat ? "repeat" : "clamp"];

            if (format == Context3DTextureFormat.COMPRESSED)
                options.push("dxt1");
            else if (format == "compressedAlpha")
                options.push("dxt5");

            if (smoothing == TextureSmoothing.NONE)
                options.push("nearest", mipMapping ? "mipnearest" : "mipnone");
            else if (smoothing == TextureSmoothing.BILINEAR)
                options.push("linear", mipMapping ? "mipnearest" : "mipnone");
            else
                options.push("linear", mipMapping ? "miplinear" : "mipnone");

            return "<" + options.join() + ">";
        }

        /** Requests a context3D object from the given Stage3D object.
         *
         * @param stage3D    The stage3D object the context needs to be requested from.
         * @param renderMode The 'Context3DRenderMode' to use when requesting the context.
         * @param profile    If you know exactly which 'Context3DProfile' you want to use, simply
         *                   pass a String with that profile.
         *
         *                   <p>If you are unsure which profiles are supported on the current
         *                   device, you can also pass an Array of profiles; they will be
         *                   tried one after the other (starting at index 0), until a working
         *                   profile is found. If none of the given profiles is supported,
         *                   the Stage3D object will dispatch an ERROR event.</p>
         *
         *                   <p>You can also pass the String 'auto' to use the best available
         *                   profile automatically. This will try all known Stage3D profiles,
         *                   beginning with the most powerful.</p>
         */
        public static function requestContext3D(stage3D:Stage3D, renderMode:String, profile:*):void
        {
            var profiles:Array;
            var currentProfile:String;

            if (profile == "auto")
                profiles = ["standardExtended", "standard", "standardConstrained",
                            "baselineExtended", "baseline", "baselineConstrained"];
            else if (profile is String)
                profiles = [profile as String];
            else if (profile is Array)
                profiles = profile as Array;
            else
                throw new ArgumentError("Profile must be of type 'String' or 'Array'");

            stage3D.addEventListener(Event.CONTEXT3D_CREATE, onCreated, false, 100);
            stage3D.addEventListener(ErrorEvent.ERROR, onError, false, 100);

            requestNextProfile();

            function requestNextProfile():void
            {
                currentProfile = profiles.shift();

                try { execute(stage3D.requestContext3D, renderMode, currentProfile); }
                catch (error:Error)
                {
                    if (profiles.length != 0) setTimeout(requestNextProfile, 1);
                    else throw error;
                }
            }

            function onCreated(event:Event):void
            {
                var context:Context3D = stage3D.context3D;

                if (renderMode == Context3DRenderMode.AUTO && profiles.length != 0 &&
                        context.driverInfo.indexOf("Software") != -1)
                {
                    onError(event);
                }
                else
                {
                    onFinished();
                }
            }

            function onError(event:Event):void
            {
                if (profiles.length != 0)
                {
                    event.stopImmediatePropagation();
                    setTimeout(requestNextProfile, 1);
                }
                else onFinished();
            }

            function onFinished():void
            {
                stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onCreated);
                stage3D.removeEventListener(ErrorEvent.ERROR, onError);
            }
        }
    }
}
