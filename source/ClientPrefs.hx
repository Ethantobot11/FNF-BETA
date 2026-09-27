package;

import cpp.UInt32;
import citro.CitroG;
import haxe3ds.services.HID.HIDKey;
import Controls;
@:headerInclude("3ds.h")
class ClientPrefs {
	public static var downScroll:Bool = false;
	public static var middleScroll:Bool = false;
	public static var opponentStrums:Bool = true;
	public static var showFPS:Bool = true;
	public static var flashing:Bool = true;
	public static var globalAntialiasing:Bool = true;
	public static var noteSplashes:Bool = true;
	public static var lowQuality:Bool = false;
	public static var shaders:Bool = true; // Kept for compatibility, though 3DS shaders are limited
	public static var framerate:Int = 60; // 3DS is hardware-locked to 60/30, but kept for save compatibility
	public static var camZooms:Bool = true;
	public static var hideHud:Bool = false;
	public static var noteOffset:Int = 0;
	public static var arrowHSV:Array<Array<Int>> = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]];
	public static var ghostTapping:Bool = true;
	public static var timeBarType:String = 'Time Left';
	public static var scoreZoom:Bool = true;
	public static var noReset:Bool = false;
	public static var healthBarAlpha:Float = 1;
	public static var controllerMode:Bool = true; // Default to true on 3DS!
	public static var hitsoundVolume:Float = 0;
	public static var pauseMusic:String = 'Tea Time';
	public static var checkForUpdates:Bool = false; // Disable on 3DS homebrew to prevent crashes
	public static var comboStacking:Bool = true;

	// Global audio variables (Hook these into your SoundPlayer.hx)
	public static var globalVolume:Float = 1.0;
	public static var muted:Bool = false;

	public static var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative',
		'songspeed' => 1.0,
		'healthgain' => 1.0,
		'healthloss' => 1.0,
		'instakill' => false,
		'practice' => false,
		'botplay' => false,
		'opponentplay' => false
	];

	public static var comboOffset:Array<Int> = [0, 0, 0, 0];
	public static var ratingOffset:Int = 0;
	public static var sickWindow:Int = 45;
	public static var goodWindow:Int = 90;
	public static var badWindow:Int = 135;
	public static var safeFrames:Float = 10;

	public static var keyBinds:Map<String, Array<UInt32>> = [
		'note_left'		=> [HIDKey.A, HIDKey.LEFT],
		'note_down'		=> [HIDKey.B, HIDKey.DOWN],
		'note_up'		=> [HIDKey.X, HIDKey.UP],
		'note_right'	=> [HIDKey.Y, HIDKey.RIGHT],
		
		'ui_left'		=> [HIDKey.DLEFT, HIDKey.CPAD_LEFT],
		'ui_down'		=> [HIDKey.DDOWN, HIDKey.CPAD_DOWN],
		'ui_up'			=> [HIDKey.DUP, HIDKey.CPAD_UP],
		'ui_right'		=> [HIDKey.DRIGHT, HIDKey.CPAD_RIGHT],
		
		'accept'		=> [HIDKey.A],
		'back'			=> [HIDKey.B],
		'pause'			=> [HIDKey.START],
		'reset'			=> [HIDKey.SELECT],
		
		'volume_mute'	=> [HIDKey.ZL],
		'volume_up'		=> [HIDKey.R],
		'volume_down'	=> [HIDKey.L], // New 3DS only, fallback handled in Controls
		
		'debug_1'		=> [HIDKey.L],
		'debug_2'		=> [HIDKey.R]
	];

	public static var defaultKeys:Map<String, Array<UInt32>> = null;

	public static function loadDefaultKeys():Void {
		defaultKeys = keyBinds.copy();
	}

	public static function saveSettings():Void {
		// Bind and save using Citro's save system
		CitroG.save.data('funkin', 'ninjamuffin99');
		
		CitroG.save.data.downScroll = downScroll;
		CitroG.save.data.middleScroll = middleScroll;
		CitroG.save.data.opponentStrums = opponentStrums;
		CitroG.save.data.showFPS = showFPS;
		CitroG.save.data.flashing = flashing;
		CitroG.save.data.globalAntialiasing = globalAntialiasing;
		CitroG.save.data.noteSplashes = noteSplashes;
		CitroG.save.data.lowQuality = lowQuality;
		CitroG.save.data.camZooms = camZooms;
		CitroG.save.data.noteOffset = noteOffset;
		CitroG.save.data.hideHud = hideHud;
		CitroG.save.data.arrowHSV = arrowHSV;
		CitroG.save.data.ghostTapping = ghostTapping;
		CitroG.save.data.timeBarType = timeBarType;
		CitroG.save.data.scoreZoom = scoreZoom;
		CitroG.save.data.noReset = noReset;
		CitroG.save.data.healthBarAlpha = healthBarAlpha;
		CitroG.save.data.comboOffset = comboOffset;
		CitroG.save.data.ratingOffset = ratingOffset;
		CitroG.save.data.sickWindow = sickWindow;
		CitroG.save.data.goodWindow = goodWindow;
		CitroG.save.data.badWindow = badWindow;
		CitroG.save.data.safeFrames = safeFrames;
		CitroG.save.data.gameplaySettings = gameplaySettings;
		CitroG.save.data.controllerMode = controllerMode;
		CitroG.save.data.hitsoundVolume = hitsoundVolume;
		CitroG.save.data.pauseMusic = pauseMusic;
		CitroG.save.data.checkForUpdates = checkForUpdates;
		CitroG.save.data.comboStacking = comboStacking;
		CitroG.save.data.globalVolume = globalVolume;
		CitroG.save.data.muted = muted;

		CitroG.save.flush();

		// Separate save for controls so they aren't wiped by general resets
		CitroG.save.data('controls_v2', 'ninjamuffin99');
		CitroG.save.data.customControls = keyBinds;
		CitroG.save.flush();
		
		trace("Settings saved!");
	}

	public static function loadPrefs():Void {
		CitroG.save.data('funkin', 'ninjamuffin99');
		
		if(CitroG.save.data.downScroll != null) downScroll = CitroG.save.data.downScroll;
		if(CitroG.save.data.middleScroll != null) middleScroll = CitroG.save.data.middleScroll;
		if(CitroG.save.data.opponentStrums != null) opponentStrums = CitroG.save.data.opponentStrums;
		if(CitroG.save.data.showFPS != null) showFPS = CitroG.save.data.showFPS;
		if(CitroG.save.data.flashing != null) flashing = CitroG.save.data.flashing;
		if(CitroG.save.data.globalAntialiasing != null) globalAntialiasing = CitroG.save.data.globalAntialiasing;
		if(CitroG.save.data.noteSplashes != null) noteSplashes = CitroG.save.data.noteSplashes;
		if(CitroG.save.data.lowQuality != null) lowQuality = CitroG.save.data.lowQuality;
		if(CitroG.save.data.camZooms != null) camZooms = CitroG.save.data.camZooms;
		if(CitroG.save.data.hideHud != null) hideHud = CitroG.save.data.hideHud;
		if(CitroG.save.data.noteOffset != null) noteOffset = CitroG.save.data.noteOffset;
		if(CitroG.save.data.arrowHSV != null) arrowHSV = CitroG.save.data.arrowHSV;
		if(CitroG.save.data.ghostTapping != null) ghostTapping = CitroG.save.data.ghostTapping;
		if(CitroG.save.data.timeBarType != null) timeBarType = CitroG.save.data.timeBarType;
		if(CitroG.save.data.scoreZoom != null) scoreZoom = CitroG.save.data.scoreZoom;
		if(CitroG.save.data.noReset != null) noReset = CitroG.save.data.noReset;
		if(CitroG.save.data.healthBarAlpha != null) healthBarAlpha = CitroG.save.data.healthBarAlpha;
		if(CitroG.save.data.comboOffset != null) comboOffset = CitroG.save.data.comboOffset;
		if(CitroG.save.data.ratingOffset != null) ratingOffset = CitroG.save.data.ratingOffset;
		if(CitroG.save.data.sickWindow != null) sickWindow = CitroG.save.data.sickWindow;
		if(CitroG.save.data.goodWindow != null) goodWindow = CitroG.save.data.goodWindow;
		if(CitroG.save.data.badWindow != null) badWindow = CitroG.save.data.badWindow;
		if(CitroG.save.data.safeFrames != null) safeFrames = CitroG.save.data.safeFrames;
		if(CitroG.save.data.controllerMode != null) controllerMode = CitroG.save.data.controllerMode;
		if(CitroG.save.data.hitsoundVolume != null) hitsoundVolume = CitroG.save.data.hitsoundVolume;
		if(CitroG.save.data.pauseMusic != null) pauseMusic = CitroG.save.data.pauseMusic;
		if(CitroG.save.data.checkForUpdates != null) checkForUpdates = CitroG.save.data.checkForUpdates;
		if(CitroG.save.data.comboStacking != null) comboStacking = CitroG.save.data.comboStacking;
		if(CitroG.save.data.globalVolume != null) globalVolume = CitroG.save.data.globalVolume;
		if(CitroG.save.data.muted != null) muted = CitroG.save.data.muted;

		if(CitroG.save.data.gameplaySettings != null) {
			var savedMap:Map<String, Dynamic> = CitroG.save.data.gameplaySettings;
			for (name => value in savedMap) {
				gameplaySettings.set(name, value);
			}
		}

		// Load custom controls
		CitroG.save.data('controls_v2', 'ninjamuffin99');
		if(CitroG.save.data.customControls != null) {
			var loadedControls:Map<String, Array<UInt32>> = CitroG.save.data.customControls;
			for (control => keys in loadedControls) {
				keyBinds.set(control, keys);
			}
		}
		
		reloadControls();
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic):Dynamic {
		return (gameplaySettings.exists(name) ? gameplaySettings.get(name) : defaultValue);
	}

	public static function reloadControls():Void {
		// Re-initialize the Controls class with the new keybinds
		PlayerSettings.player1.controls = new Controls();
		
		// Note: Volume keys are now handled via HIDKey in the Controls class
	}

	public static function copyKey(arrayToCopy:Array<UInt32>):Array<UInt32> {
		return arrayToCopy.copy();
	}
}