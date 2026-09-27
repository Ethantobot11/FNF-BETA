package;

import citro.CitroG;
import citro.state.CitroState;
import citro.object.CitroSprite;
import citro.object.CitroText;
import citro.object.CitroCamera;
import citro.math.CitroMath;
import citro.backend.CitroColor;
import citro.backend.CitroTimer;
import citro.backend.CitroTween;
import citro.backend.CitroTween.CitroEase; 

import sys.io.File;
import sys.FileSystem;
import haxe.Json;

using StringTools;

class PlayState extends MusicBeatState
{
	public static var STRUM_X:Float = 42;
	public static var STRUM_X_MIDDLESCROLL:Float = -278;
	
	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], ['Shit', 0.4], ['Bad', 0.5], ['Bruh', 0.6],
		['Meh', 0.69], ['Nice', 0.7], ['Good', 0.8], ['Great', 0.9], ['Sick!', 1], ['Perfect!!', 1]
	];

	public var boyfriend:Character = null;
	public var dad:Character = null;
	public var gf:Character = null;

	public var notes:Array<Note> = [];
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];
	
	public var strumLineNotes:Array<StrumNote> = [];
	public var opponentStrums:Array<StrumNote> = [];
	public var playerStrums:Array<StrumNote> = [];
	public var grpNoteSplashes:Array<NoteSplash> = [];

	public var camGame:CitroCamera;
	public var camHUD:CitroCamera;
	public var camFollow:CitroSprite; // Use a dummy CitroSprite to follow

	public var health:Float = 1;
	public var combo:Int = 0;
	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var songLength:Float = 0;
	public var songPercent:Float = 0;
	public var startingSong:Bool = false;
	public var endingSong:Bool = false;
	public var generatedMusic:Bool = false;
	public var startedCountdown:Bool = false;
	public var inCutscene:Bool = false;

	public var healthBar:SimpleBar;
	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var scoreTxt:CitroText;
	public var timeTxt:CitroText;

	public static var SONG:SwagSong = null;
    public static var isPixelStage:Bool = false;
    public static var daPixelZoom:Float = 6;
    public static var instance:PlayState;

	override public function create():Void {
		instance = this;
		Paths.clearStoredMemory();

		if (SONG == null) SONG = Song.loadFromJson('tutorial');
		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		// --- Cameras ---
		camGame = new CitroCamera();
		camHUD = new CitroCamera();
		// Note: CitroCamera management might require adding them to CitroG.state or a custom renderer
		// For now, we assume CitroG handles default drawing.

		camFollow = new CitroSprite();
		CitroG.state.members.push(camFollow);

		// --- Characters ---
		boyfriend = new Boyfriend(770, 100, SONG.player1, true);
		dad = new Character(100, 100, SONG.player2, false);
		// gf = new Character(400, 130, SONG.gfVersion, false); // Uncomment if needed

		CitroG.state.members.push(dad);
		CitroG.state.members.push(boyfriend);
		// CitroG.state.members.push(gf);

		// --- UI & HUD ---
		healthBar = new SimpleBar(CitroG.width / 2 - 200, CitroG.height * 0.89, 400, 20, CitroColor.WHITE);
		healthBar.maxValue = 2;
		healthBar.minValue = 0;
		healthBar.value = 1;
		CitroG.state.members.push(healthBar);

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP2 = new HealthIcon(dad.healthIcon, false);
		CitroG.state.members.push(iconP1);
		CitroG.state.members.push(iconP2);

		scoreTxt = new CitroText(0, healthBar.y + 36, "Score: 0");
		// scoreTxt.loadFont(Paths.font("vcr.bcfnt")); // Ensure you have a .bcfnt font
		scoreTxt.alignment = CENTER;
		CitroG.state.members.push(scoreTxt);

		timeTxt = new CitroText(CitroG.width / 2 - 100, 19, "0:00");
		timeTxt.alignment = CENTER;
		CitroG.state.members.push(timeTxt);

		// --- Groups ---
		grpNoteSplashes = [];
		strumLineNotes = [];
		opponentStrums = [];
		playerStrums = [];

		generateSong(SONG.song);
		generateStaticArrows(0);
		generateStaticArrows(1);

		startCountdown();
		super.create();
	}

	override public function update(delta:Int):Void {
		var elapsed:Float = delta / 1000.0;

		if (startedCountdown) {
			Conductor.songPosition += elapsed * 1000 * playbackRate;
		}

		if (startingSong && startedCountdown && Conductor.songPosition >= 0) {
			startSong();
		}

		// --- Note Spawning ---
		if (unspawnNotes.length > 0) {
			var time:Float = 2000 / songSpeed;
			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time) {
				var dunceNote:Note = unspawnNotes.shift();
				notes.push(dunceNote);
				dunceNote.spawned = true;
				CitroG.state.members.push(dunceNote);
			}
		}

		// --- Note Logic ---
		if (generatedMusic && !inCutscene) {
			if(!cpuControlled) keyShit();

			var i = notes.length - 1;
			while (i >= 0) {
				var daNote = notes[i];
				daNote.update(delta);

				// Calculate Y position based on strum
				var strumGroup = daNote.mustPress ? playerStrums : opponentStrums;
				var strumY = strumGroup[daNote.noteData].y;
				var strumScroll = strumGroup[daNote.noteData].downScroll;
				
				var dist = (strumScroll ? 0.45 : -0.45) * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed;
				daNote.distance = dist;
				
				if(daNote.copyY) daNote.y = strumY + dist;

				// Miss logic
				if (Conductor.songPosition > 350 + daNote.strumTime) {
					if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && !endingSong && !daNote.wasGoodHit) {
						noteMiss(daNote);
					}
					CitroG.state.members.remove(daNote);
					notes.remove(daNote);
					daNote.destroy();
				}
				i--;
			}
		}

		// --- UI Updates ---
		iconP1.x = healthBar.x + (healthBar.width * (CitroMath.remapToRange(healthBar.value, 0, 2, 1, 0) * 0.01)) - 75;
		iconP1.y = healthBar.y - 75;
		iconP2.x = healthBar.x + (healthBar.width * (CitroMath.remapToRange(healthBar.value, 0, 2, 1, 0) * 0.01)) - 75;
		iconP2.y = healthBar.y - 75;

		if (controls.PAUSE && startedCountdown) {
			// Open Pause State logic here
		}

		super.update(delta);
	}

	function startSong():Void {
		startingSong = false;
		// SoundPlayer.playMusic(Paths.inst(SONG.song)); // Adapt to your music player
		// vocals.play();
		songLength = 100000; // Replace with actual music length
	}

	function generateStaticArrows(player:Int):Void {
		for (i in 0...4) {
			var babyArrow = new StrumNote(STRUM_X, 50, i, player);
			babyArrow.downScroll = ClientPrefs.downScroll;
			strumLineNotes.push(babyArrow);
			CitroG.state.members.push(babyArrow);
			if (player == 1) playerStrums.push(babyArrow);
			else opponentStrums.push(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	function generateSong(dataPath:String):Void {
		var songData = SONG;
		Conductor.changeBPM(songData.bpm);
		notes = [];
		unspawnNotes = [];
		
		for (section in songData.notes) {
			for (songNotes in section.sectionNotes) {
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);
				var gottaHitNote:Bool = section.mustHitSection;
				if (songNotes[1] > 3) gottaHitNote = !section.mustHitSection;

				var oldNote:Note = unspawnNotes.length > 0 ? unspawnNotes[unspawnNotes.length - 1] : null;
				var swagNote = new Note(daStrumTime, daNoteData, oldNote, false, false);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				unspawnNotes.push(swagNote);

				// Sustain tail generation (simplified)
				var floorSus:Int = Math.floor(swagNote.sustainLength / Conductor.stepCrochet);
				if(floorSus > 0) {
					for (susNote in 0...floorSus+1) {
						var sustainNote = new Note(daStrumTime + (Conductor.stepCrochet * susNote), daNoteData, swagNote, true, false);
						sustainNote.mustPress = gottaHitNote;
						swagNote.tail.push(sustainNote);
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);
		}
				}
			}
		}
		generatedMusic = true;
	}

	function startCountdown():Void {
		startedCountdown = true;
		Conductor.songPosition = -Conductor.crochet * 5;
		var swagCounter:Int = 0;
		
		CitroTimer.start(Conductor.crochet / 1000 / playbackRate, function() {
			// Countdown logic (spawn "Ready", "Set", "Go" CitroSprites here)
			swagCounter++;
			if(swagCounter >= 4) {
				// Countdown finished
			}
		}, 5);
	}

	function keyShit():Void {
		var parsedHoldArray = parseKeys();
		if (startedCountdown && !boyfriend.stunned && generatedMusic) {
			for (daNote in notes) {
				if (daNote.isSustainNote && parsedHoldArray[daNote.noteData] && daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit) {
					goodNoteHit(daNote);
				}
			}
		}
		
		// Check for new presses
		for (i in 0...4) {
			if (Reflect.getProperty(controls, 'NOTE_' + ['UP','DOWN','LEFT','RIGHT'][i] + '_P')) {
				var hit = false;
				for (daNote in notes) {
					if (daNote.noteData == i && daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote) {
						goodNoteHit(daNote);
						hit = true;
						break; // Hit the closest note
					}
				}
				if (!hit && !ClientPrefs.ghostTapping) noteMissPress(i);
				
				var spr = playerStrums[i];
				if(spr != null) {
					spr.playAnim('confirm', true);
					spr.resetAnim = 0.15;
				}
			}
		}
	}

	function parseKeys():Array<Bool> {
		return [
			Reflect.getProperty(controls, 'NOTE_LEFT'),
			Reflect.getProperty(controls, 'NOTE_DOWN'),
			Reflect.getProperty(controls, 'NOTE_UP'),
			Reflect.getProperty(controls, 'NOTE_RIGHT')
		];
	}

	function goodNoteHit(note:Note):Void {
		if (!note.wasGoodHit) {
			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled) {
				SoundPlayer.playSound(Paths.sound('hitsound'));
			}
			if(note.hitCausesMiss) {
				noteMiss(note);
				return;
			}
			
			if (!note.isSustainNote) {
				combo += 1;
				popUpScore(note);
			}
			health += note.hitHealth * healthGain;
			boyfriend.playAnim('sing' + ['UP','DOWN','LEFT','RIGHT'][Std.int(Math.abs(note.noteData))], true);
			boyfriend.holdTimer = 0;
			
			note.wasGoodHit = true;
			if (!note.isSustainNote) {
				CitroG.state.members.remove(note);
				notes.remove(note);
				note.destroy();
			}
		}
	}

	function noteMiss(daNote:Note):Void {
		combo = 0;
		health -= daNote.missHealth * healthLoss;
		songMisses++;
		totalPlayed++;
		RecalculateRating(true);
		
		if(daNote.mustPress && !daNote.noMissAnimation) {
			boyfriend.playAnim('sing' + ['UP','DOWN','LEFT','RIGHT'][Std.int(Math.abs(daNote.noteData))] + 'miss', true);
		}
		
		CitroG.state.members.remove(daNote);
		notes.remove(daNote);
		daNote.destroy();
	}

	function noteMissPress(direction:Int = 1):Void {
		if(ClientPrefs.ghostTapping) return;
		health -= 0.05 * healthLoss;
		combo = 0;
		songMisses++;
		totalPlayed++;
		RecalculateRating(true);
		SoundPlayer.playSound(Paths.soundRandom('missnote', 1, 3));
		boyfriend.playAnim('sing' + ['UP','DOWN','LEFT','RIGHT'][Std.int(Math.abs(direction))] + 'miss', true);
	}

	function popUpScore(note:Note):Void {
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
		var daRating:Dynamic = Conductor.judgeNote(note, noteDiff / playbackRate);
		
		totalNotesHit += daRating.ratingMod;
		songScore += daRating.score;
		songHits++;
		totalPlayed++;
		RecalculateRating(false);

		// Spawn Rating Text
		var ratingTxt = new CitroText(CitroG.width * 0.35, CitroG.height * 0.4, daRating.name.toUpperCase());
		ratingTxt.alignment = CENTER;
		CitroG.state.members.push(ratingTxt);
		
		var props = new Map<String, Float>();
		props.set("y", ratingTxt.y - 60);
		props.set("alpha", 0);
		CitroTween.tweenObject(ratingTxt, props, 0.2 / playbackRate, {
			ease: CitroEase.CUBE_OUT,
			onComplete: function() {
				CitroG.state.members.remove(ratingTxt);
				ratingTxt.destroy();
			}
		});

		// Spawn Combo
		var comboTxt = new CitroText(CitroG.width * 0.35, CitroG.height * 0.4 + 60, Std.string(combo));
		comboTxt.alignment = CENTER;
		CitroG.state.members.push(comboTxt);
		
		var props2 = new Map<String, Float>();
		props2.set("y", comboTxt.y - 40);
		props2.set("alpha", 0);
		CitroTween.tweenObject(comboTxt, props2, 0.2 / playbackRate, {
			ease: CitroEase.CUBE_OUT,
			startDelay: 0.05,
			onComplete: function() {
				CitroG.state.members.remove(comboTxt);
				comboTxt.destroy();
			}
		});
	}

	public function RecalculateRating(badHit:Bool = false):Void {
		if(totalPlayed < 1) return;
		var ratingPercent = CitroMath.clamp(totalNotesHit / totalPlayed, 0, 1);
		var ratingName = "?";
		for (i in 0...ratingStuff.length-1) {
			if(ratingPercent < ratingStuff[i][1]) {
				ratingName = ratingStuff[i][0];
				break;
			}
		}
		if(ratingPercent >= 1) ratingName = ratingStuff[ratingStuff.length-1][0];
		
		scoreTxt.text = 'Score: $songScore | Misses: $songMisses | Rating: $ratingName';
	}
}

// --- Helper Class for 3DS-Friendly Bars ---
class SimpleBar extends CitroSprite {
	public var value(get, set):Float;
	public var maxValue:Float = 1;
	public var minValue:Float = 0;
	private var _value:Float = 0;
	private var fullWidth:Float;

	public function new(x:Float, y:Float, width:Float, height:Float, color:CitroColor) {
		super(x, y);
		fullWidth = width;
		this.makeGraphic(Std.int(width), Std.int(height), color);
	}

	function get_value():Float return _value;
	function set_value(val:Float):Float {
		_value = val;
		var percent = (_value - minValue) / (maxValue - minValue);
		percent = CitroMath.clamp(percent, 0, 1);
		this.setSourceRect(0, 0, Std.int(fullWidth * percent), this.height);
		return _value;
	}
}