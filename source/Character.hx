package;

import citro.object.CitroAnimate;
import citro.math.CitroMath;
import citro.CitroG;
import sys.io.File;
import sys.FileSystem;
import haxe.Json;

using StringTools;

typedef CharacterFile = {
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Null<Float>;
	var sing_duration:Null<Float>;
	var healthicon:String;
	var position:Array<Float>;
	var camera_position:Array<Float>;
	var flip_x:Null<Bool>;
	var no_antialiasing:Null<Bool>;
	var healthbar_colors:Array<Int>;
}

typedef AnimArray = {
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}

class Character extends CitroAnimate
{
	public var animOffsets:Map<String, Array<Float>>;
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4;
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false;
	public var skipDance:Bool = false;

	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];

	public var hasMissAnimations:Bool = false;

	// Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var healthColorArray:Array<Int> = [255, 0, 0];

	public static var DEFAULT_CHARACTER:String = 'bf';

	// Base positions to handle Citro's lack of a separate 'offset' property
	private var baseX:Float = 0;
	private var baseY:Float = 0;
	private var _flipX:Bool = false;

	public var flipX(get, set):Bool;
	function get_flipX():Bool return _flipX;
	function set_flipX(value:Bool):Bool {
		_flipX = value;
		var absScaleX = Math.abs(this.scale.x);
		this.scale.x = _flipX ? -absScaleX : absScaleX;
		return _flipX;
	}

	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false)
	{
		super(""); // CitroAnimate ONLY takes the ceaFile string
    	this.x = x;    
		this.y = y;
		
		#if (haxe >= "4.0.0")
		animOffsets = new Map();
		#else
		animOffsets = new Map<String, Array<Float>>();
		#end

		curCharacter = character;
		this.isPlayer = isPlayer;
		baseX = x;
		baseY = y;

		var characterPath:String = 'characters/' + curCharacter + '.json';
		var path:String = "";

		#if MODS_ALLOWED
		path = Paths.modFolders(characterPath);
		if (!FileSystem.exists(path)) {
			path = Paths.getPreloadPath(characterPath);
		}
		if (!FileSystem.exists(path)) {
			path = Paths.getPreloadPath('characters/' + DEFAULT_CHARACTER + '.json');
		}
		var rawJson = File.getContent(path);
		#else
		path = Paths.getPreloadPath(characterPath);
		if (!FileSystem.exists(path)) {
			path = Paths.getPreloadPath('characters/' + DEFAULT_CHARACTER + '.json');
		}
		var rawJson = File.getContent(path);
		#end

		var json:CharacterFile = cast Json.parse(rawJson);
		imageFile = json.image;

		// Load the Citro Engine Animation (.cea) file
		var ceaPath = Paths.cea(json.image);
		this.reloadCEA(ceaPath, "idle");

		if(json.scale != null && json.scale != 1) {
			jsonScale = json.scale;
			this.scale.set(jsonScale, jsonScale);
		}

		positionArray = json.position != null ? json.position : [0, 0];
		cameraPosition = json.camera_position != null ? json.camera_position : [0, 0];

		healthIcon = json.healthicon != null ? json.healthicon : 'face';
		singDuration = json.sing_duration != null ? json.sing_duration : 4;
		
		originalFlipX = json.flip_x != null ? json.flip_x : false;
		this.flipX = originalFlipX;

		if(json.no_antialiasing) {
			noAntialiasing = true;
		}

		if(json.healthbar_colors != null && json.healthbar_colors.length >= 3) {
			healthColorArray = [json.healthbar_colors[0], json.healthbar_colors[1], json.healthbar_colors[2]];
		}

		animationsArray = json.animations != null ? json.animations : [];
		if(animationsArray.length > 0) {
			for (anim in animationsArray) {
				var animName:String = anim.anim;
				if(anim.offsets != null && anim.offsets.length >= 2) {
					animOffsets.set(animName, [anim.offsets[0], anim.offsets[1]]);
				}
			}
		} else {
			// Fallback if no animations are defined in JSON
			animOffsets.set('idle', [0, 0]);
		}

		if(animOffsets.exists('singLEFTmiss') || animOffsets.exists('singDOWNmiss') || animOffsets.exists('singUPmiss') || animOffsets.exists('singRIGHTmiss')) {
			hasMissAnimations = true;
		}

		recalculateDanceIdle();
		dance();

		if (isPlayer) {
			this.flipX = !this.flipX;
		}

		switch(curCharacter) {
			case 'pico-speaker':
				skipDance = true;
				loadMappedAnims();
				playAnim("shoot1");
		}
	}

	override public function update():Bool 
	{
    	var elapsed:Float = CitroG.deltaTime / 1000.0;

		if(!debugMode && this.curAnim != null) {
			if(heyTimer > 0) {
				heyTimer -= elapsed * PlayState.instance.playbackRate;
				if(heyTimer <= 0) {
					if(specialAnim && (this.curAnim == 'hey' || this.curAnim == 'cheer')) {
						specialAnim = false;
						dance();
					}
					heyTimer = 0;
				}
			} else if(specialAnim && this.finished) {
				specialAnim = false;
				dance();
			}
			
			switch(curCharacter) {
				case 'pico-speaker':
					if(animationNotes.length > 0 && Conductor.songPosition > animationNotes[0][0]) {
						var noteData:Int = 1;
						if(animationNotes[0][1] > 2) noteData = 3;
						noteData += Std.random(2); // 0 or 1
						playAnim('shoot' + noteData, true);
						animationNotes.shift();
					}
					if(this.finished) {
						playAnim(this.curAnim, false, false, this.frame);
					}
			}

			if (!isPlayer) {
				if (this.curAnim.startsWith('sing')) {
					holdTimer += elapsed;
				}

				var musicPitch = 1.0; // Fallback if music isn't playing yet
				if (holdTimer >= Conductor.stepCrochet * (0.0011 / musicPitch) * singDuration) {
					dance();
					holdTimer = 0;
				}
			}

			// Looping animation fallback
			if(this.finished && this.curAnim != null) {
				var loopAnim = this.curAnim + '-loop';
				// playAnim(loopAnim); 
			}
		}

		return super.update();
	}

	public var danced:Bool = false;

	public function dance():Void
	{
		if (!debugMode && !skipDance && !specialAnim) {
			if(danceIdle) {
				danced = !danced;
				if (danced) {
					playAnim('danceRight' + idleSuffix);
				} else {
					playAnim('danceLeft' + idleSuffix);
				}
			} else {
				playAnim('idle' + idleSuffix);
			}
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		specialAnim = false;
		
		this.play(AnimName);
		if(Frame > 0) {
			this.frame = Frame;
		}

		var daOffset = animOffsets.get(AnimName);
		if (daOffset != null) {
			this.x = baseX + daOffset[0];
			this.y = baseY + daOffset[1];
		} else {
			this.x = baseX;
			this.y = baseY;
		}

		if (curCharacter.startsWith('gf')) {
			if (AnimName == 'singLEFT') {
				danced = true;
			} else if (AnimName == 'singRIGHT') {
				danced = false;
			} else if (AnimName == 'singUP' || AnimName == 'singDOWN') {
				danced = !danced;
			}
		}
	}
	
	function loadMappedAnims():Void
	{
		var noteData:Array<Dynamic> = Song.loadFromJson('picospeaker', Paths.formatToSongPath(PlayState.SONG.song)).notes;
		for (section in noteData) {
			var sectionNotes:Array<Dynamic> = cast section.sectionNotes;
			for (songNotes in sectionNotes) {
				animationNotes.push(songNotes);
			}
		}
		// TankmenBG.animationNotes = animationNotes; // Uncomment if TankmenBG is implemented
		animationNotes.sort(sortAnims);
	}

	function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		var val1:Float = Obj1[0];
		var val2:Float = Obj2[0];
		if (val1 < val2) return -1;
		if (val1 > val2) return 1;
		return 0;
	}

	public var danceEveryNumBeats:Int = 2;
	private var settingCharacterUp:Bool = true;

	public function recalculateDanceIdle():Void 
	{
		var lastDanceIdle:Bool = danceIdle;
		// Check if danceLeft/danceRight exist in the .cea file
		danceIdle = (this.curAnim == 'danceLeft' || this.curAnim == 'danceRight'); // Simplified check; ideally query .cea metadata

		if(settingCharacterUp) {
			danceEveryNumBeats = (danceIdle ? 1 : 2);
		} else if(lastDanceIdle != danceIdle) {
			var calc:Float = danceEveryNumBeats;
			if(danceIdle) calc /= 2;
			else calc *= 2;
			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0):Void
	{
		animOffsets.set(name, [x, y]);
	}
}