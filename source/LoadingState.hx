package;

import citro.CitroG;
import citro.state.CitroState;
import citro.object.CitroSprite;
import citro.backend.CitroTimer;
import citro.backend.CitroColor;

class LoadingState extends MusicBeatState
{
	inline static var MIN_TIME = 4.0;
	var target:CitroState;
	var stopMusic:Bool = false;

	var funkay:CitroSprite;
	var loadBar:CitroSprite;
	var loadProgress:Float = 0;

	function new(target:CitroState, stopMusic:Bool) {
		super();
		this.target = target;
		this.stopMusic = stopMusic;
	}

	override function create() {
		var bg:CitroSprite = new CitroSprite(0, 0).makeGraphic(CitroG.width, CitroG.height, 0xffcaff4d);
		CitroG.state.members.push(bg);
		
		funkay = new CitroSprite(0, 0).loadGraphic(Paths.image('funkay'));
		funkay.scale.set(1, CitroG.height / funkay.height);
		funkay.screenCenter();
		CitroG.state.members.push(funkay);

		loadBar = new CitroSprite(0, CitroG.height - 20).makeGraphic(CitroG.width, 10, 0xffff16d2);
		loadBar.screenCenter(X);
		CitroG.state.members.push(loadBar);
		
		// 3DS loads assets synchronously from SD/romfs, so we just fake a short loading screen
		CitroTimer.start(MIN_TIME, function() {
			onLoad();
		});
		
		super.create();
	}
	
	override function update(delta:Int) {
		var elapsed:Float = delta / 1000.0;
		super.update(delta);
		
		loadProgress += elapsed / MIN_TIME;
		if(loadProgress > 1) loadProgress = 1;
		loadBar.scale.x = loadProgress;
		loadBar.x = (CitroG.width - loadBar.width * loadBar.scale.x) / 2;
	}
	
	function onLoad() {
		if (stopMusic) {
			// Stop music via SoundPlayer if needed
		}
		MusicBeatState.switchState(target);
	}
	
	inline static public function loadAndSwitchState(target:CitroState, stopMusic:Bool = false) {
		MusicBeatState.switchState(getNextState(target, stopMusic));
	}
	
	static function getNextState(target:CitroState, stopMusic:Bool = false):CitroState {
		return new LoadingState(target, stopMusic);
	}
}