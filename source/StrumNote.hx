package;

import citro.object.CitroAnimate;
import citro.CitroG;

using StringTools;

class StrumNote extends CitroAnimate
{
	public var resetAnim:Float = 0;
	private var noteData:Int = 0;
	public var direction:Float = 90;
	public var downScroll:Bool = false;
	public var sustainReduce:Bool = true;
	private var player:Int;
	public var texture(default, set):String = null;

	private function set_texture(value:String):String {
		if(texture != value) {
			texture = value;
			reloadNote();
		}
		return value;
	}

	public function new(x:Float, y:Float, leData:Int, player:Int) {
		super(x, y, "");
		noteData = leData;
		this.player = player;
		var skin:String = 'NOTE_assets';
		if(PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) skin = PlayState.SONG.arrowSkin;
		texture = skin;
	}

	public function reloadNote() {
		var lastAnim:String = this.curAnim;
		if(PlayState.isPixelStage) {
			this.reloadCEA(Paths.cea('pixelUI/' + texture), lastAnim != null ? lastAnim : "static");
			this.scale.set(PlayState.daPixelZoom, PlayState.daPixelZoom);
		} else {
			this.reloadCEA(Paths.cea(texture), lastAnim != null ? lastAnim : "static");
			this.scale.set(0.7, 0.7);
		}
		if(lastAnim != null) this.play(lastAnim);
	}

	public function postAddedToGroup() {
		this.play('static');
		this.x += Note.swagWidth * noteData;
		this.x += 50;
		this.x += ((WIDTH / 2) * player);
	}

	override public function update(delta:Int):Bool {
		var elapsed:Float = delta / 1000.0;
		if(resetAnim > 0) {
			resetAnim -= elapsed;
			if(resetAnim <= 0) {
				this.play('static');
				resetAnim = 0;
			}
		}
		return super.update(delta);
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		this.play(anim);
	}
}