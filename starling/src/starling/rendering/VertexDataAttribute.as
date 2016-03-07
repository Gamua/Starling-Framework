// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.rendering
{
    /** Holds the properties of a single attribute in a VertexDataFormat instance.
     *  The member variables must never be changed; they are only <code>public</code>
     *  for performance reasons. */
    internal class VertexDataAttribute
    {
        private static const FORMAT_SIZES:Object = {
            "float1": 1,
            "float2": 2,
            "float3": 3,
            "float4": 4
        };

        public var name:String;
        public var format:String;
        public var isColor:Boolean;
        public var offset:int;
        public var size:int;

        /** Creates a new instance with the given properties. */
        public function VertexDataAttribute(name:String, format:String, offset:int)
        {
            if (!(format in FORMAT_SIZES))
                throw new ArgumentError(
                    "Invalid attribute format: " + format + ". " +
                    "Use one of the following: 'float1'-'float4'");

            this.name = name;
            this.format = format;
            this.offset = offset;
            this.size = FORMAT_SIZES[format];
            this.isColor = name.indexOf("color") != -1 || name.indexOf("Color") != -1
        }
    }
}
