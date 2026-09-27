package;

import citro.state.CitroSubState;
import citro.CitroG;
import Controls;
import PlayerSettings;

class MusicBeatSubstate extends CitroSubState
{
	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	
	private var controls(get, never):Controls;
	inline function get_controls():Controls return PlayerSettings.player1.controls;

	override public function update(delta:Int):Void {
		var elapsed:Float = delta / 1000.0;
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep > 0) stepHit();
		super.update(delta);
	}

	private function updateBeat():Void {
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}

	private function updateCurStep():Void {
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);
		var shit = ((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public function stepHit():Void {
		if (curStep % 4 == 0) beatHit();
	}

	public function beatHit():Void {}
}