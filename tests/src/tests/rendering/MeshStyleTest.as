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
    import starling.display.Mesh;
    import starling.display.Quad;
    import starling.events.EnterFrameEvent;
    import starling.events.Event;
    import starling.styles.MeshStyle;
    import starling.unit.UnitTest;

    public class MeshStyleTest extends UnitTest
    {
        public function testAssignment():void
        {
            var quad0:Quad = new Quad(100, 100);
            var quad1:Quad = new Quad(100, 100);
            var style:MeshStyle = new MeshStyle();
            var meshStyleType:Class = (new MeshStyle()).type;

            quad0.style = style;
            assertEqual(style, quad0.style);
            assertEqual(style.target, quad0);

            quad1.style = style;
            assertEqual(style, quad1.style);
            assertEqual(style.target, quad1);
            assertFalse(quad0.style == style);
            assertEqual(quad0.style.type, meshStyleType);

            quad1.style = null;
            assertEqual(quad1.style.type, meshStyleType);
            assertNull(style.target);
        }

        public function testEnterFrameEvent():void
        {
            var eventCount:int = 0;
            var event:EnterFrameEvent = new EnterFrameEvent(Event.ENTER_FRAME, 0.1);
            var style:MeshStyle = new MeshStyle();
            var quad0:Quad = new Quad(100, 100);
            var quad1:Quad = new Quad(100, 100);

            style.addEventListener(Event.ENTER_FRAME, onEvent);
            quad0.dispatchEvent(event);
            assertEqual(0, eventCount);

            quad0.style = style;
            quad0.dispatchEvent(event);
            assertEqual(1, eventCount);

            quad0.dispatchEvent(event);
            assertEqual(2, eventCount);

            quad1.style = style;
            quad0.dispatchEvent(event);
            assertEqual(2, eventCount);

            quad0.style = style;
            quad0.dispatchEvent(event);
            assertEqual(3, eventCount);

            style.removeEventListener(Event.ENTER_FRAME, onEvent);
            quad0.dispatchEvent(event);
            assertEqual(3, eventCount);

            function onEvent(event:EnterFrameEvent):void
            {
                ++eventCount;
            }
        }

        public function testDefaultStyle():void
        {
            var origStyle:Class = Mesh.defaultStyle;
            var quad:Quad = new Quad(100, 100);
            assertTrue(quad.style is origStyle);

            Mesh.defaultStyle = MockStyle;

            quad = new Quad(100, 100);
            assertTrue(quad.style is MockStyle);

            Mesh.defaultStyle = origStyle;
        }

        public function testDefaultStyleFactory():void
        {
            var quad:Quad;
            var origStyle:Class = Mesh.defaultStyle;
            var origStyleFactory:Function = Mesh.defaultStyleFactory;

            Mesh.defaultStyleFactory = function(mesh:Mesh):MeshStyle { return new MockStyle(); };
            quad = new Quad(100, 100);
            assertTrue(quad.style is MockStyle);

            Mesh.defaultStyleFactory = function():MeshStyle { return null; };
            quad = new Quad(100, 100);
            assertTrue(quad.style is origStyle);

            Mesh.defaultStyleFactory = null;
            quad = new Quad(100, 100);
            assertTrue(quad.style is origStyle);

            Mesh.defaultStyle = origStyle;
            Mesh.defaultStyleFactory = origStyleFactory;
        }
    }
}

import starling.styles.MeshStyle;

class MockStyle extends MeshStyle { }
