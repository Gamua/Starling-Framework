package starling.assets
{
    import flash.media.Sound;
    import flash.utils.ByteArray;

    /** This AssetFactory creates sound assets. */
    public class SoundFactory extends AssetFactory
    {
        /** Creates a new instance. */
        public function SoundFactory()
        {
            addMimeTypes("audio/mp3", "audio/mpeg3", "audio/mpeg");
            addExtensions("mp3");
        }

        /** @inheritDoc */
        override public function canHandle(reference:AssetReference):Boolean
        {
            return reference.data is Sound || super.canHandle(reference);
        }

        /** @inheritDoc */
        override public function create(reference:AssetReference, helper:AssetFactoryHelper,
                                        onComplete:Function, onError:Function):void
        {
            var sound:Sound = reference.data as Sound;
            var bytes:ByteArray = reference.data as ByteArray;

            if (bytes)
            {
                try
                {
                    sound = new Sound();
                    sound.loadCompressedDataFromByteArray(bytes, bytes.length);
                }
                catch (e:Error)
                {
                    onError("Could not load sound data: " + e.message);
                    return;
                }

            }

            onComplete(reference.name, sound);
        }
    }
}
