package starling.utils
{
    public function getNextPowerOfTwo(number:int):int
    {
        var result:int = 1;
        while (result < number) result *= 2;
        return result;   
    }
}