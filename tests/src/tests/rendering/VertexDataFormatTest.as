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
    import org.flexunit.asserts.assertEquals;
    import org.flexunit.asserts.assertStrictlyEquals;

    import starling.rendering.VertexDataFormat;

    public class VertexDataFormatTest
    {
        private static const STD_FORMAT:String = "position:float2, texCoords:float2, color:bytes4";

        [Test]
        public function testFormatParsing():void
        {
            var vdf:VertexDataFormat = VertexDataFormat.fromString(STD_FORMAT);

            assertEquals( 2, vdf.getSizeIn32Bits("position"));
            assertEquals( 8, vdf.getSize("position"));
            assertEquals( 2, vdf.getSizeIn32Bits("texCoords"));
            assertEquals( 8, vdf.getSize("texCoords"));
            assertEquals( 1, vdf.getSizeIn32Bits("color"));
            assertEquals( 4, vdf.getSize("color"));
            assertEquals( 5, vdf.vertexSizeIn32Bits);
            assertEquals(20, vdf.vertexSize);

            assertEquals("float2", vdf.getFormat("position"));
            assertEquals("float2", vdf.getFormat("texCoords"));
            assertEquals("bytes4", vdf.getFormat("color"));

            assertEquals( 0, vdf.getOffsetIn32Bits("position"));
            assertEquals( 0, vdf.getOffset("position"));
            assertEquals( 2, vdf.getOffsetIn32Bits("texCoords"));
            assertEquals( 8, vdf.getOffset("texCoords"));
            assertEquals( 4, vdf.getOffsetIn32Bits("color"));
            assertEquals(16, vdf.getOffset("color"));

            assertEquals(STD_FORMAT, vdf.formatString);
        }

        [Test]
        public function testEmpty():void
        {
            var vdf:VertexDataFormat = VertexDataFormat.fromString(null);
            assertEquals("", vdf.formatString);
            assertEquals(0, vdf.numAttributes);
        }

        [Test]
        public function testCaching():void
        {
            var formatA:String = "  position :float2  ,color:  bytes4   ";
            var formatB:String = "position:float2,color:bytes4";

            var vdfA:VertexDataFormat = VertexDataFormat.fromString(formatA);
            var vdfB:VertexDataFormat = VertexDataFormat.fromString(formatB);

            assertStrictlyEquals(vdfA, vdfB);
        }

        [Test]
        public function testNormalization():void
        {
            var format:String = "   position :float2  ,color:  bytes4   ";
            var normalizedFormat:String = "position:float2, color:bytes4";
            var vdf:VertexDataFormat = VertexDataFormat.fromString(format);
            assertEquals(normalizedFormat, vdf.formatString);
        }

        [Test]
        public function testExtend():void
        {
            var formatString:String = "position:float2";
            var baseFormat:VertexDataFormat = VertexDataFormat.fromString(formatString);
            var exFormat:VertexDataFormat = baseFormat.extend("color:float4");
            assertEquals("position:float2, color:float4", exFormat.formatString);
            assertEquals(2, exFormat.numAttributes);
            assertEquals("float2", exFormat.getFormat("position"));
            assertEquals("float4", exFormat.getFormat("color"));
        }

        [Test(expects="Error")]
        public function testInvalidFormatString():void
        {
            VertexDataFormat.fromString("color:double2");
        }

        [Test(expects="Error")]
        public function testInvalidFormatString2():void
        {
            VertexDataFormat.fromString("color.float4");
        }
    }
}
