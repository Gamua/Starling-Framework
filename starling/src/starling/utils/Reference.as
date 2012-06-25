package starling.utils
{
    import flash.utils.Dictionary;

    /** A class that saves a weak or strong reference to another object.
     * 
     *  <p>Normally, when you save a reference to an object, this is done in a 'strong' way, 
     *  which means that the Garbage Collector won't dispose the object as long as this reference
     *  exists. This class allows you to save the reference in a 'weak' way. If the only object
     *  referencing the 'target' is the Reference instance, it will be garbage collected.  
     *  The 'target' property will return 'null' then.</p>
     *  
     */
    public class Reference
    {
        private var mDictionary:Dictionary;
        private var mWeak:Boolean;
        
        /** Creates an instance that references target either weakly or strongly. */
        public function Reference(target:Object, weak:Boolean)
        {
            mWeak = weak;
            mDictionary = new Dictionary(weak);
            mDictionary[target] = null;
        }
        
        /** Returns the referenced object. */
        public function get target():Object
        {
            for (var key:Object in mDictionary)
                return key;
            
            return null;
        }
        
        /** Indicates if the reference is weak or strong. */
        public function get isWeak():Boolean { return mWeak; }
    }
}