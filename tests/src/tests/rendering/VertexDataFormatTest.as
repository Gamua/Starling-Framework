// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.rendering
{
    import starling.rendering.VertexDataFormat;
    import starling.unit.UnitTest;

    public class VertexDataFormatTest extends UnitTest
    {
        private static const STD_FORMAT:String = "position:float2, texCoords:float2, color:bytes4";

        public function testFormatParsing():void
        {
            var vdf:VertexDataFormat = VertexDataFormat.fromString(STD_FORMAT);

            assertEqual( 2, vdf.getSizeIn32Bits("position"));
            assertEqual( 8, vdf.getSize("position"));
            assertEqual( 2, vdf.getSizeIn32Bits("texCoords"));
            assertEqual( 8, vdf.getSize("texCoords"));
            assertEqual( 1, vdf.getSizeIn32Bits("color"));
            assertEqual( 4, vdf.getSize("color"));
            assertEqual( 5, vdf.vertexSizeIn32Bits);
            assertEqual(20, vdf.vertexSize);

            assertEqual("float2", vdf.getFormat("position"));
            assertEqual("float2", vdf.getFormat("texCoords"));
            assertEqual("bytes4", vdf.getFormat("color"));

            assertEqual( 0, vdf.getOffsetIn32Bits("position"));
            assertEqual( 0, vdf.getOffset("position"));
            assertEqual( 2, vdf.getOffsetIn32Bits("texCoords"));
            assertEqual( 8, vdf.getOffset("texCoords"));
            assertEqual( 4, vdf.getOffsetIn32Bits("color"));
            assertEqual(16, vdf.getOffset("color"));

            assertEqual(STD_FORMAT, vdf.formatString);
        }

        public function testEmpty():void
        {
            var vdf:VertexDataFormat = VertexDataFormat.fromString(null);
            assertEqual("", vdf.formatString);
            assertEqual(0, vdf.numAttributes);
        }

        public function testCaching():void
        {
            var formatA:String = "  position :float2  ,color:  bytes4   ";
            var formatB:String = "position:float2,color:bytes4";

            var vdfA:VertexDataFormat = VertexDataFormat.fromString(formatA);
            var vdfB:VertexDataFormat = VertexDataFormat.fromString(formatB);

            assertEqual(vdfA.formatString, vdfB.formatString);
            assertEqual(vdfA.numAttributes, vdfB.numAttributes);
            assertEqual(vdfA.vertexSize, vdfB.vertexSize);
        }

        public function testNormalization():void
        {
            var format:String = "   position :float2  ,color:  bytes4   ";
            var normalizedFormat:String = "position:float2, color:bytes4";
            var vdf:VertexDataFormat = VertexDataFormat.fromString(format);
            assertEqual(normalizedFormat, vdf.formatString);
        }

        public function testExtend():void
        {
            var formatString:String = "position:float2";
            var baseFormat:VertexDataFormat = VertexDataFormat.fromString(formatString);
            var exFormat:VertexDataFormat = baseFormat.extend("color:float4");
            assertEqual("position:float2, color:float4", exFormat.formatString);
            assertEqual(2, exFormat.numAttributes);
            assertEqual("float2", exFormat.getFormat("position"));
            assertEqual("float4", exFormat.getFormat("color"));
        }

        public function testInvalidFormatString():void
        {
            assertThrows(function():void { VertexDataFormat.fromString("color:double2"); });
        }

        public function testInvalidFormatString2():void
        {
            assertThrows(function():void { VertexDataFormat.fromString("color.float4"); });
        }
    }
}
