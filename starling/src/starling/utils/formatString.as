// ActionScript file

package starling.utils
{
    // TODO: add number formatting options
    
    public function formatString(format:String, ...args):String
    {
        for (var i:int=0; i<args.length; ++i)
            format = format.replace(new RegExp("\\{"+i+"\\}", "g"), args[i]);
        
        return format;
    }
}