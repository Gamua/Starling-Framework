// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2015 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.rendering
{
    import flash.geom.Matrix;

    import starling.display.Mesh;

    /** Describes a class that can batch and render instances of the Mesh class (or its subclasses).
     *
     *  <p>The standard implementation of this interface is Starling's MeshBatch class.
     *  However, you can create your own batch renderers and let Starling use them to render
     *  standard or custom display objects.</p>
     *
     *  @see starling.display.Mesh
     *  @see starling.display.MeshBatch
     */
    public interface IMeshBatch
    {
        /** Removes all geometry. */
        function clear():void;

        /** Indicates if the given mesh instance fits to the current state of the batch.
         *  Must always return <code>true</code> for the first added object; later calls
         *  will check if critical properties differ in any way. */
        function canAddMesh(mesh:Mesh, blendMode:String):Boolean;

        /** Adds a mesh to the batch.
         *
         *  @param mesh      the mesh to add to the batch.
         *  @param matrix    transforms the mesh with a certain matrix before adding it.
         *  @param alpha     will be multiplied with each vertex' alpha value.
         *  @param blendMode will replace the blend mode of the mesh instance.
         */
        function addMesh(mesh:Mesh, matrix:Matrix=null, alpha:Number=1.0, blendMode:String=null):void;

        /** This method does the actual rendering of the object. */
        function render(painter:Painter):void;

        /** Releases all resources of the batch. */
        function dispose():void;

        /** The currently used blend mode (set by the first mesh that is added to the batch). */
        function get blendMode():String;
    }
}
