package citro.backend;

class CitroSoundSystem {
    public var volume:Float = 1.0;
    public var muted:Bool = false;
    public var activeSounds:Array<CitroSound> = [];

    public function new() {
        #if (!wiiu || !cafe)
        untyped __cpp__("cwavUseEnvironment(0)");
        #end
    }

    public function play(path:String, ?vol:Float = 1.0, ?looped:Bool = false):CitroSound {
        var sound = new CitroSound(path);
        sound.volume = muted ? 0.0 : (vol != null ? vol : this.volume);
        sound.looped = looped;
        sound.play();
        activeSounds.push(sound);
        return sound;
    }

    public function load(path:String):CitroSound {
        var sound = new CitroSound(path);
        sound.volume = muted ? 0.0 : this.volume;
        activeSounds.push(sound);
        return sound;
    }

    public function update():Void {
        for (sound in activeSounds) {
            sound.update();
        }
    }
}
