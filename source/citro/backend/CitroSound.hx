package citro.backend;

#if (!wiiu || !cafe)
import citro.CitroG;
import citro.CitroG.VoidPtr;
@:headerInclude("3ds.h")
@:headerInclude("cwav.h")
class CitroSound {
    public var volume:Float = 1.0;
    public var looped:Bool = false;
    public var isPlaying(default, null):Bool = false;
    public var path:String;
    
    private var cwavPtr:VoidPtr;
    private static var initialized:Bool = false;
    private var wasPlaying:Bool = false;

    public function new(path:String) {
        this.path = path;
        this.cwavPtr = null;
    }

    private function init():Void {
        if (initialized) return;
        untyped __cpp__("ndspInit()");
        untyped __cpp__("cwavUseEnvironment(0)");
        initialized = true;
        trace("CitroSound initialized with NDSP.");
    }

    public function load():Void {
        init();
        if (cwavPtr != null) return;
        
        var cached = CitroG.caches.get(path);
        if (cached != null) {
            this.cwavPtr = cached;
            return;
        }

        this.cwavPtr = cast untyped __cpp__("calloc(1, sizeof(CWAV))");
        untyped __cpp__("cwavFileLoad({0}, {1}, 4)", this.cwavPtr, path);

        var status:Int = untyped __cpp__("((CWAV*){0})->loadStatus", this.cwavPtr);
        if (status == 1) {
            CitroG.caches.set(path, this.cwavPtr);
            trace('Successfully cached and loaded sound: $path');
        } else {
            trace('ERROR: Failed to load CWAV file "$path". Status code: $status');
            untyped __cpp__("free({0})", this.cwavPtr);
            this.cwavPtr = null;
        }
    }

    public function play(?force:Bool = false):Void {
        if (isPlaying && !force) return;
        
        if (cwavPtr == null) {
            load();
        }
        if (cwavPtr != null) {
            untyped __cpp__("((CWAV*){0})->volume = {1}", this.cwavPtr, this.volume);
            untyped __cpp__("cwavPlay({0}, 0, -1)", this.cwavPtr);
            this.isPlaying = true;
            this.wasPlaying = true;
        }
    }

    public function stop():Void {
        if (cwavPtr != null) {
            untyped __cpp__("cwavStop({0}, -1, -1)", this.cwavPtr);
            this.isPlaying = false;
            this.wasPlaying = false;
        }
    }
    
    public function pause():Void {
        stop();
    }
    
    public function resume():Void {
        play();
    }

    public function update():Void {
        if (looped && wasPlaying && cwavPtr != null) {
            var currentlyPlaying:Bool = untyped __cpp__("cwavIsPlaying({0})", this.cwavPtr);
            if (!currentlyPlaying) {
                play(true);
            }
        }
    }
}
#end
