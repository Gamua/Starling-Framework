// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.filters
{
    import starling.textures.Texture;

    /** An interface describing the access methods available to filters in the <code>process</code>
     *  method in order to acquire or release textures.
     *
     *  @see FragmentFilter#process() */
    public interface ITexturePool
    {
        /** Gets a texture from the pool, or creates a new one (cleared and ready to be used
         *  as render target). Its size is dictated by the bounds of the target display object
         *  plus padding. */
        function getTexture():Texture;

        /** Puts a texture back into the pool to be reused later (or to be disposed
         *  with the pool). */
        function putTexture(texture:Texture):void;
    }
}
