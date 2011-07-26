package starling.core
{
    import flash.display3D.*;
    import flash.geom.*;
    import flash.utils.*;
    
    import starling.display.*;
    import starling.errors.*;
    import starling.utils.*;

    public class RenderSupport
    {
        // members        
        
        private var mProjectionMatrix:Matrix3D;
        private var mModelViewMatrix:Matrix3D;        
        private var mMatrixStack:Vector.<Matrix3D>;
        
        private var mPrograms:Dictionary;
        private var mContext:Context3D;        
        private var mQuadIndexBuffer:IndexBuffer3D;
        
        // construction
        
        public function RenderSupport(context:Context3D)
        {
            if (context == null)
                throw new ArgumentError("Context must not be null");
                        
            mMatrixStack = new Vector.<Matrix3D>();
            mPrograms = new Dictionary();            
            
            mProjectionMatrix = new Matrix3D();
            mModelViewMatrix = new Matrix3D();
            
            loadIdentity();
            setupOrthographicRendering(400, 300);
            
            mContext = context;
            mQuadIndexBuffer = mContext.createIndexBuffer(6);
            mQuadIndexBuffer.uploadFromVector(Vector.<uint>([0, 1, 2, 1, 2, 3]), 0, 6);
        }
        
        // matrix manipulation
        
        public function setupOrthographicRendering(width:Number, height:Number, 
                                                   near:Number=-1.0, far:Number=1.0):void
        {
            var coords:Vector.<Number> = new <Number>[                
                2.0/width, 0.0, 0.0, 0.0,
                0.0, -2.0/height, 0.0, 0.0,
                0.0, 0.0, -2.0/(far-near), 0.0,
                -1.0, 1.0, -(far+near)/(far-near), 1.0                
            ];
                
            mProjectionMatrix.copyRawDataFrom(coords);
        }
        
        public function loadIdentity():void
        {
            mModelViewMatrix.identity();
        }
        
        public function translateMatrix(dx:Number, dy:Number, dz:Number=0):void
        {
            mModelViewMatrix.prependTranslation(dx, dy, dz);
        }
        
        public function rotateMatrix(angle:Number, axis:Vector3D=null):void
        {
            mModelViewMatrix.prependRotation(rad2deg(angle), axis == null ? Vector3D.Z_AXIS : axis);
        }
        
        public function scaleMatrix(sx:Number, sy:Number, sz:Number=1.0):void
        {
            mModelViewMatrix.prependScale(sx, sy, sz);    
        }
        
        public function transformMatrix(object:DisplayObject):void
        {
            translateMatrix(object.x, object.y);
            rotateMatrix(object.rotation);
            scaleMatrix(object.scaleX, object.scaleY);
            translateMatrix(-object.pivotX, -object.pivotY);
        }
        
        public function pushMatrix():void
        {
            mMatrixStack.push(mModelViewMatrix.clone());
        }
        
        public function popMatrix():void
        {
            mModelViewMatrix = mMatrixStack.pop();
        }
        
        public function get mvpMatrix():Matrix3D
        {
            var mvpMatrix:Matrix3D = new Matrix3D();
            mvpMatrix.append(mModelViewMatrix);
            mvpMatrix.append(mProjectionMatrix);
            return mvpMatrix;
        }
        
        // program management
        
        public function registerProgram(name:String, vertexProgram:ByteArray, fragmentProgram:ByteArray):void
        {
            if (mPrograms.hasOwnProperty(name))
                throw new Error("Another program with this name is already registered");
            
            checkContext();
            var program:Program3D = mContext.createProgram();
            program.upload(vertexProgram, fragmentProgram);            
            mPrograms[name] = program;
        }
        
        public function unregisterProgram(name:String):void
        {
            var program:Program3D = getProgram(name);            
            if (program)
            {                
                program.dispose();
                delete mPrograms[name];
            }
        }
        
        public function getProgram(name:String):Program3D
        {
            return mPrograms[name] as Program3D;
        }
        
        // other helper methods
        
        public function get quadIndexBuffer():IndexBuffer3D { return mQuadIndexBuffer; }
        
        public function setupDefaultBlendFactors():void
        {
            checkContext();
            mContext.setBlendFactors(Context3DBlendFactor.ONE, 
                                     Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
        }
        
        public function clear(color:uint=0):void
        {
            checkContext();
            mContext.clear(Color.getRed(color), Color.getGreen(color), Color.getBlue(color));
        }
        
        private function checkContext():void
        {
            if (mContext != Starling.context)
                throw new Error("Inconsistent contexts in calls to RenderSupport");
        }
        
        // cleanup
        
        public function dispose():void
        {
            for each (var program:Program3D in mPrograms)
                program.dispose();
            mPrograms = new Dictionary();
            mQuadIndexBuffer.dispose();
        }
    }
}