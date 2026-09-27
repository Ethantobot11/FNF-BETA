package;

import citro.object.CitroSprite;
import citro.object.CitroObject;
import citro.CitroG;

class CheckboxThingie extends CitroSprite
{
	public var sprTracker:CitroObject = null;
	public var daValue(default, set):Bool;
	public var copyAlpha:Bool = true;
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;

	public function new(x:Float = 0, y:Float = 0, ?checked = false) {
		super(x, y);
		this.reloadCEA(Paths.cea('checkboxanim'), checked ? 'checking' : 'unchecking');
		this.scale.set(0.9, 0.9);
		animationFinished(checked ? 'checking' : 'unchecking');
		daValue = checked;
	}

	override public function update():Bool {
		if (sprTracker != null) {
			this.x = sprTracker.x - 130 + offsetX;
			this.y = sprTracker.y + 30 + offsetY;
			if(copyAlpha) this.alpha = sprTracker.alpha;
		}
		
		if (this.curAnim != null && this.finished) {
			animationFinished(this.curAnim);
		}

		return super.update();
	}

	private function set_daValue(check:Bool):Bool {
		if(check) {
			if(this.curAnim != 'checked' && this.curAnim != 'checking') {
				this.play('checking');
			}
		} else if(this.curAnim != 'unchecked' && this.curAnim != 'unchecking') {
			this.play("unchecking");
		}
		return check;
	}

	private function animationFinished(name:String):Void {
		switch(name) {
			case 'checking': this.play('checked');
			case 'unchecking': this.play('unchecked');
		}
	}
}