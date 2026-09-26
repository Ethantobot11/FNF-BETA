package;

#if (!wiiu || !cafe)

import cpp.RawPointer;
import cpp.ConstCharStar;

@:native("CWAV")
extern class CWAVData {}

@:headerCode('
#include "cwav.h"
')
class CWAVHelper
{
    public static inline function useEnvironment(envMode:Int):Void
    {
        untyped __cpp__("cwavUseEnvironment({0})", envMode);
    }

    public static inline function fileLoad(out:RawPointer<CWAVData>, filename:ConstCharStar, maxSPlays:Int):Void
    {
        untyped __cpp__("cwavFileLoad({0}, {1}, {2})", out, filename, maxSPlays);
    }

    public static inline function play(cwav:RawPointer<CWAVData>, leftChannel:Int, rightChannel:Int):Void
    {
        untyped __cpp__("cwavPlay({0}, {1}, {2})", cwav, leftChannel, rightChannel);
    }

    public static inline function stop(cwav:RawPointer<CWAVData>, leftChannel:Int, rightChannel:Int):Void
    {
        untyped __cpp__("cwavStop({0}, {1}, {2})", cwav, leftChannel, rightChannel);
    }

    public static inline function fileFree(cwav:RawPointer<CWAVData>):Void
    {
        untyped __cpp__("cwavFileFree({0})", cwav);
    }
}

#end
