package;

#if haxe3ds
import haxe3ds.services.RomFS;
import haxe3ds.services.GFX;
import haxe3ds.services.misc.PLGLDR;
import citro.CitroGame;
import citro.object.CitroText;

using StringTools;
@:headerInclude("3ds.h")
#else
import leafy.LfEngine;
import leafy.backend.sdl.LfWindowRender;
#end

class Main
{
    #if haxe3ds
    public static var fpsText:CitroText;
    #end
    
    public static function main():Void
    {
        #if haxe3ds
        RomFS.init();
        CrashHandler.init();

        var plgResult = PLGLDR.init();
        if (plgResult == 0) {
            trace("Luma3DS Plugin Loader initialized successfully.");
            PLGLDR.displayMessage("Deltarune 3DS", "Luma3DS Plugin Loader active!");
        } else {
            trace("Luma3DS Plugin Loader not available (Result: " + plgResult + ")");
        }
        
        trace("Starting Deltarune 3DS Application...");

        AchievementManager.unlock("play_DELTARUNE_3DS");

        CitroGame.start(new LoadingState());
        
        #else
        LfEngine.initEngine("Deltarune", DRC, new WiiUMainMenuState());
        #end
    }
}
