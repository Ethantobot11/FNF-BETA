package;

import citro.object.CitroAnimate;
import citro.CitroG;
import citro.math.CitroMath;

using StringTools;

typedef EventNote = {
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

class Note extends CitroAnimate
{
	public var extraData:Map<String,Dynamic>;
	public var strumTime:Float = 0;
	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;
	public var nextNote:Note;
	public var spawned:Bool = false;
	public var tail:Array<Note> = [];
	public var parent:Note;
	public var blockHit:Bool = false;
	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var noteType(default, set):String = null;

	public var inEditor:Bool = false;
	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var earlyHitMult:Float = 0.5;
	public var lateHitMult:Float = 1;
	public var lowPriority:Bool = false;

	public static var swagWidth:Float = 160 * 0.7;
	private var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];

	public var noteSplashDisabled:Bool = false;
	public var noteSplashTexture:String = null;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hitHealth:Float = 0.023;
	public var missHealth:Float = 0.0475;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0;
	public var ratingDisabled:Bool = false;

	public var texture(default, set):String = null;
	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000;
	public var hitsoundDisabled:Bool = false;

	private function set_multSpeed(value:Float):Float {
		resizeByRatio(value / multSpeed);
		multSpeed = value;
		return value;
	}

	public function resizeByRatio(ratio:Float) {
		if(isSustainNote && this.curAnim != null && !this.curAnim.endsWith('end')) {
			this.scale.y *= ratio;
		}
	}

	private function set_texture(value:String):String {
		if(texture != value) reloadNote('', value);
		texture = value;
		return value;
	}

	private function set_noteType(value:String):String {
		noteSplashTexture = PlayState.SONG.splashSkin;
		if(noteData > -1 && noteType != value) {
			switch(value) {
				case 'Hurt Note':
					ignoreNote = mustPress;
					reloadNote('HURT');
					noteSplashTexture = 'HURTnoteSplashes';
					lowPriority = true;
					missHealth = isSustainNote ? 0.1 : 0.3;
					hitCausesMiss = true;
				case 'Alt Animation': animSuffix = '-alt';
				case 'No Animation':
					noAnimation = true;
					noMissAnimation = true;
				case 'GF Sing': gfNote = true;
			}
			noteType = value;
		}
		return value;
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false) {
		super("");
        this.x = 0;
        this.y = 0;
		
		if (prevNote == null) prevNote = this;
		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.inEditor = inEditor;
		this.strumTime = strumTime;
		if(!inEditor) this.strumTime += ClientPrefs.noteOffset;
		this.noteData = noteData;

		if(noteData > -1) {
			texture = '';
			if(!isSustainNote && noteData > -1 && noteData < 4) {
				this.play(colArray[noteData % 4] + 'Scroll');
			}
		}
		if(prevNote != null) prevNote.nextNote = this;

		if (isSustainNote && prevNote != null) {
			this.alpha = 0.6;
			multAlpha = 0.6;
			hitsoundDisabled = true;
			if(ClientPrefs.downScroll) this.scale.y = -Math.abs(this.scale.y);
			if (prevNote.isSustainNote) prevNote.play(colArray[prevNote.noteData % 4] + 'hold');
		} else if(!isSustainNote) {
			earlyHitMult = 1;
		}
	}

	public function reloadNote(?prefix:String = '', ?texture:String = '', ?suffix:String = '') {
		var skin:String = texture;
		if(texture.length < 1) {
			skin = PlayState.SONG.arrowSkin;
			if(skin == null || skin.length < 1) skin = 'NOTE_assets';
		}
		var arraySkin:Array<String> = skin.split('/');
		arraySkin[arraySkin.length-1] = prefix + arraySkin[arraySkin.length-1] + suffix;
		var blahblah:String = arraySkin.join('/');
		var lastScaleY:Float = this.scale.y;
		var currentAnim:String = this.curAnim != null ? this.curAnim : "idle";

		if(PlayState.isPixelStage) {
			var pixelPath = 'pixelUI/' + blahblah;
			if(isSustainNote) pixelPath += 'ENDS';
			this.reloadCEA(Paths.cea(pixelPath), currentAnim);
			this.scale.set(PlayState.daPixelZoom, PlayState.daPixelZoom);
		} else {
			this.reloadCEA(Paths.cea(blahblah), currentAnim);
			this.scale.set(0.7, 0.7);
		}
		if(isSustainNote) this.scale.y = lastScaleY;
		if(this.curAnim != null) this.play(this.curAnim);
	}

	override public function update():Bool {
        var elapsed:Float = CitroG.deltaTime / 1000.0;
        
        if (mustPress) {
            canBeHit = (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult) && strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult));
            if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit) tooLate = true;
        } else {
            canBeHit = false;
            if (strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult)) {
                if((isSustainNote && prevNote.wasGoodHit) || strumTime <= Conductor.songPosition) wasGoodHit = true;
            }
        }
        if (tooLate && !inEditor && this.alpha > 0.3) this.alpha = 0.3;
        
        return super.update();
    }
}