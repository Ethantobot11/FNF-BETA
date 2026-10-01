package;

#if haxe3ds
import haxe3ds.services.RomFS;
import haxe3ds.services.GFX;
import haxe3ds.services.misc.PLGLDR;
import citro.CitroGame;
import citro.object.CitroText;
import gamejolt.GameJolt;

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

        GameJolt.gameID = 1103524;
        GameJolt.gameKey = "b1fa691d4d6afa7b4c1b2d0d305fa44f";

        var plgResult = PLGLDR.init();
        if (plgResult == 0) {
            trace("Luma3DS Plugin Loader initialized successfully.");
            PLGLDR.displayMessage("FNF 3DS", "Luma3DS Plugin Loader active!");
        } else {
            trace("Luma3DS Plugin Loader not available (Result: " + plgResult + ")");
        }
        
        trace("Starting FNF 3DS Application...");

        ClientPrefs.loadDefaultKeys();
        try {
            CitroGame.start(new TitleState());
        } catch (e:Dynamic) {
            CrashHandler.logException(e, "Uncaught Fatal Exception in Main Game Loop!");
            
            trace("Game crashed fatally. Check sdmc:/FNF-PE/crash/ for details.");
            Sys.exit(1); 
        }
        
        #else
        LfEngine.initEngine("FNF 3DS", DRC, new WiiUMainMenuState());
        #end
    }
}
