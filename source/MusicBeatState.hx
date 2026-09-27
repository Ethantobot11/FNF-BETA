package;

import citro.state.CitroState;
import citro.CitroG;

class MusicBeatState extends CitroState {
    public var persistentUpdate:Bool = true;
    public var persistentDraw:Bool = true;

	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	
	private var controls(get, never):Controls;
	inline function get_controls():Controls return PlayerSettings.player1.controls;

	override public function create():Void {
		super.create();
		// Custom fade transitions should be handled via CitroSprite overlays or CitroTween
	}

	override public function update(delta:Int):Void {
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep) {
			if(curStep > 0) stepHit();

			if(PlayState.SONG != null) {
				if (oldStep < curStep) updateSection();
				else rollbackSection();
			}
		}

		super.update(delta);
	}

	private function updateSection():Void {
		if(stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while(curStep >= stepsToDo) {
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void {
		if(curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length) {
			if (PlayState.SONG.notes[i] != null) {
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if(stepsToDo > curStep) break;
				curSection++;
			}
		}
		if(curSection > lastSection) sectionHit();
	}

	private function updateBeat():Void {
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void {
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);
		var shit = ((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function switchState(nextState:CitroState):Void {
		CitroG.switchState(nextState);
	}

	public static function resetState():Void {
		var stateClass = Type.getClass(CitroG.state);
		CitroG.switchState(Type.createInstance(stateClass, []));
	}

	public static function getState():MusicBeatState {
		return cast CitroG.state;
	}

	public function stepHit():Void {
		if (curStep % 4 == 0) beatHit();
	}

	public function beatHit():Void {
		// Override in subclasses
	}

	public function sectionHit():Void {
		// Override in subclasses
	}

    public function openSubState(substate:CitroSubState):Void {
        CitroG.substate = substate;
        substate.create();
    }

	function getBeatsOnSection():Float {
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) {
			val = PlayState.SONG.notes[curSection].sectionBeats;
		}
		return val == null ? 4 : val;
	}

    public function closeSubState():Void {
        if (CitroG.substate != null) {
            CitroG.substate.destroy();
            CitroG.substate = null;
        }
    }
}