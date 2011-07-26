package starling.errors
{
    public class ObjectDisposedError extends Error
    {
        public function ObjectDisposedError(message:*="", id:*=0)
        {
            super(message, id);
        }
    }
}