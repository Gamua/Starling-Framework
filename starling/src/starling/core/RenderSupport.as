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
        
        // construction
        
        public function RenderSupport()
        {
            mMatrixStack = new Vector.<Matrix3D>();
            mProjectionMatrix = new Matrix3D();
            mModelViewMatrix = new Matrix3D();
            
            loadIdentity();
            setupOrthographicRendering(400, 300);
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
        
        // other helper methods
        
        public function setupDefaultBlendFactors():void
        {
            Starling.context.setBlendFactors(Context3DBlendFactor.ONE, 
                                             Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
        }
        
        public function clear(argb:uint=0):void
        {
            Starling.context.clear(
                Color.getRed(argb)   / 255.0, 
                Color.getGreen(argb) / 255.0, 
                Color.getBlue(argb)  / 255.0,
                Color.getAlpha(argb) / 255.0);
        }
    }
}