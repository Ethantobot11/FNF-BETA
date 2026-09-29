package;

import citro.object.CitroAnimate;
import citro.CitroG;

class NoteSplash extends CitroAnimate
{
	private var textureLoaded:String = null;

	public function new(x:Float = 0, y:Float = 0, ?note:Int = 0) {
		super("");
		this.x = x;
		this.y = y;
		
		var skin:String = 'noteSplashes';
		if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) {
			skin = PlayState.SONG.splashSkin;
		}
		setupNoteSplash(x, y, note, skin);
	}

	public function setupNoteSplash(x:Float, y:Float, note:Int = 0, texture:String = null, hueColor:Float = 0, satColor:Float = 0, brtColor:Float = 0) {
		this.x = x - Note.swagWidth * 0.95;
		this.y = y - Note.swagWidth;
		this.alpha = 0.6;

		if(texture == null) {
			texture = 'noteSplashes';
			if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) {
				texture = PlayState.SONG.splashSkin;
			}
		}

		if(textureLoaded != texture) {
			this.reloadCEA(Paths.cea(texture), "idle");
			textureLoaded = texture;
		}

		var animNum:Int = Std.random(2) + 1;
		this.play('note' + note + '-' + animNum);
	}

	override public function update():Bool {
		if(this.curAnim != null && this.finished) {
			this.visible = false;
		}
		return super.update();
	}
}
