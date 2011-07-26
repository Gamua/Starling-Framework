package starling.errors
{
    public class MissingContextError extends Error
    {
        public function MissingContextError(message:*="", id:*=0)
        {
            super(message, id);
        }
    }
}