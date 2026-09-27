package;

import citro.state.CitroSubState;
import citro.object.CitroSprite;
import citro.backend.CitroColor;
import citro.backend.CitroTween;
import citro.CitroG;

class CustomFadeTransition extends CitroSubState {
	public static var finishCallback:Void->Void;
	var isTransIn:Bool = false;
	var transBlack:CitroSprite;

	public function new(duration:Float, isTransIn:Bool) {
		super();
		this.isTransIn = isTransIn;
		
		transBlack = new CitroSprite().makeGraphic(CitroG.WIDTH, CitroG.HEIGHT, CitroColor.BLACK);
		this.members.push(transBlack);

		if(isTransIn) {
			transBlack.alpha = 1;
			CitroTween.tweenNumber(1, 0, duration, {
				onUpdate: function(val:Float) { transBlack.alpha = val; },
				onComplete: function() { close(); }
			});
		} else {
			transBlack.alpha = 0;
			CitroTween.tweenNumber(0, 1, duration, {
				onUpdate: function(val:Float) { transBlack.alpha = val; },
				onComplete: function() {
					if(finishCallback != null) finishCallback();
				}
			});
		}
	}

	override function destroy() {
		super.destroy();
	}
}