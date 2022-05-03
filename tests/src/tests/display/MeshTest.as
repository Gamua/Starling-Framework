// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.display
{
    import flash.geom.Point;
    import flash.geom.Rectangle;

    import org.flexunit.asserts.assertEquals;
    import org.flexunit.asserts.assertNull;
    import org.hamcrest.assertThat;
    import org.hamcrest.number.closeTo;

    import starling.display.Mesh;
    import starling.rendering.IndexData;
    import starling.rendering.VertexData;
    import starling.styles.MeshStyle;
    import starling.textures.Texture;

    import tests.Helpers;
    import tests.utils.MockTexture;

    public class MeshTest
    {
        [Test]
        public function testGetBounds():void
        {
            var vertexData:VertexData = new VertexData("position:float2");
            vertexData.setPoint(0, "position", 10, 10);
            vertexData.setPoint(1, "position", 20, 10);
            vertexData.setPoint(2, "position", 10, 20);

            var indexData:IndexData = new IndexData();
            indexData.addTriangle(0, 1, 2);

            var mesh:Mesh = new Mesh(vertexData, indexData);
            var expected:Rectangle = new Rectangle(10, 10, 10, 10);
            Helpers.compareRectangles(expected, mesh.bounds);
            Helpers.compareRectangles(expected, mesh.getBounds(mesh));

            mesh.rotation = Math.PI / 2.0;
            expected.setTo(-20, 10, 10, 10);
            Helpers.compareRectangles(expected, mesh.bounds);
        }

        [Test]
        public function testColor():void
        {
            var vertexData:VertexData = new VertexData();
            vertexData.numVertices = 3;

            var indexData:IndexData = new IndexData();
            indexData.addTriangle(0, 1, 2);

            var mesh:Mesh = new Mesh(vertexData, indexData);
            mesh.setVertexColor(0, 0xff0000);
            mesh.setVertexColor(1, 0x00ff00);
            mesh.setVertexColor(2, 0x0000ff);

            assertEquals(0xff0000, mesh.getVertexColor(0));
            assertEquals(0x00ff00, mesh.getVertexColor(1));
            assertEquals(0x0000ff, mesh.getVertexColor(2));

            mesh.color = 0xf0f0f0;

            for (var i:int=0; i<3; ++i)
                assertEquals(0xf0f0f0, mesh.getVertexColor(i));
        }

        [Test]
        public function testAlpha():void
        {
            var vertexData:VertexData = new VertexData();
            vertexData.numVertices = 3;

            var indexData:IndexData = new IndexData();
            indexData.addTriangle(0, 1, 2);

            var mesh:Mesh = new Mesh(vertexData, indexData);
            mesh.setVertexAlpha(0, 0.2);
            mesh.setVertexAlpha(1, 0.5);
            mesh.setVertexAlpha(2, 0.8);

            const E:Number = 0.02;
            assertThat(mesh.getVertexAlpha(0), closeTo(0.2, E));
            assertThat(mesh.getVertexAlpha(1), closeTo(0.5, E));
            assertThat(mesh.getVertexAlpha(2), closeTo(0.8, E));
        }

        [Test]
        public function testTexCoords():void
        {
            var rootTexture:Texture = new MockTexture(100, 100);
            var subTexture:Texture = Texture.fromTexture(rootTexture, new Rectangle(50, 50, 50, 50));

            var vertexData:VertexData = new VertexData();
            vertexData.setPoint(0, "position",  0, 0);
            vertexData.setPoint(1, "position",  1, 0);
            vertexData.setPoint(2, "position",  0, 1);
            vertexData.setPoint(3, "position",  1, 1);
            vertexData.setPoint(0, "texCoords", 0, 0);
            vertexData.setPoint(1, "texCoords", 1, 0);
            vertexData.setPoint(2, "texCoords", 0, 1);
            vertexData.setPoint(3, "texCoords", 1, 1);

            var indexData:IndexData = new IndexData();
            indexData.addQuad(0, 1, 2, 3);

            var mesh:Mesh = new Mesh(vertexData, indexData);

            Helpers.comparePoints(new Point(0, 0), mesh.getTexCoords(0));
            Helpers.comparePoints(new Point(1, 1), mesh.getTexCoords(3));

            mesh.texture = subTexture; // should change internal texture coordinates

            Helpers.comparePoints(new Point(0, 0), mesh.getTexCoords(0));
            Helpers.comparePoints(new Point(1, 1), mesh.getTexCoords(3));

            Helpers.comparePoints(new Point(0.5, 0.5), vertexData.getPoint(0, "texCoords"));
            Helpers.comparePoints(new Point(1.0, 1.0), vertexData.getPoint(3, "texCoords"));

            mesh.setTexCoords(2, 0.25, 0.75);

            Helpers.comparePoints(new Point(0.25,  0.75),  mesh.getTexCoords(2));
            Helpers.comparePoints(new Point(0.625, 0.875), vertexData.getPoint(2, "texCoords"));

            mesh.texture = rootTexture;

            Helpers.comparePoints(new Point(0, 0), mesh.getTexCoords(0));
            Helpers.comparePoints(new Point(1, 1), mesh.getTexCoords(3));

            Helpers.comparePoints(new Point(0, 0), vertexData.getPoint(0, "texCoords"));
            Helpers.comparePoints(new Point(1, 1), vertexData.getPoint(3, "texCoords"));
            Helpers.comparePoints(new Point(0.25,  0.75),  vertexData.getPoint(2, "texCoords"));
        }

        [Test]
        public function testVertexPosition():void
        {
            var vertexData:VertexData = new VertexData();
            vertexData.numVertices = 3;

            var indexData:IndexData = new IndexData();
            indexData.addTriangle(0, 1, 2);

            var mesh:Mesh = new Mesh(vertexData, indexData);
            mesh.setVertexPosition(1, 1, 0);
            mesh.setVertexPosition(2, 1, 1);

            Helpers.comparePoints(mesh.getVertexPosition(0), new Point());
            Helpers.comparePoints(mesh.getVertexPosition(1), new Point(1, 0));
            Helpers.comparePoints(mesh.getVertexPosition(2), new Point(1, 1));
        }

        [Test]
        public function testHitTest():void
        {
            // +  0
            //   /|
            //  / |
            // 1--2--3
            //    | /
            //    |/
            //    4

            var vertexData:VertexData = new VertexData(MeshStyle.VERTEX_FORMAT, 5);
            vertexData.setPoint(0, "position", 1, 0);
            vertexData.setPoint(1, "position", 0, 1);
            vertexData.setPoint(2, "position", 1, 1);
            vertexData.setPoint(3, "position", 2, 1);
            vertexData.setPoint(4, "position", 1, 2);

            var indexData:IndexData = new IndexData(6);
            indexData.addTriangle(0, 2, 1);
            indexData.addTriangle(2, 3, 4);

            var mesh:Mesh = new Mesh(vertexData, indexData);
            assertNull(mesh.hitTest(new Point(0.49, 0.49)));
            assertNull(mesh.hitTest(new Point(1.01, 0.99)));
            assertNull(mesh.hitTest(new Point(0.99, 1.01)));
            assertNull(mesh.hitTest(new Point(1.51, 1.51)));
            assertEquals(mesh, mesh.hitTest(new Point(0.51, 0.51)));
            assertEquals(mesh, mesh.hitTest(new Point(0.99, 0.99)));
            assertEquals(mesh, mesh.hitTest(new Point(1.01, 1.01)));
            assertEquals(mesh, mesh.hitTest(new Point(1.49, 1.49)));

            mesh.visible = false;
            assertNull(mesh.hitTest(new Point(0.75, 0.75)));

            mesh.visible = true;
            mesh.touchable = false;
            assertNull(mesh.hitTest(new Point(0.75, 0.75)));
        }
    }
}
