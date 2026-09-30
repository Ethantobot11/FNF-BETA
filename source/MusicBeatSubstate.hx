package;

import citro.state.CitroSubState;
import citro.CitroG;
import Controls;
import PlayerSettings;
import gamejolt.GameJolt;
import gamejolt.GJRequest;
import gamejolt.types.RequestType;
import gamejolt.formats.Trophy;

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

	function loadTrophies():Void {
		GameJolt.userName = CitroG.save.data.gamejolt.username;
		GameJolt.userToken = CitroG.save.data.gamejolt.token;

		if (GameJolt.userName == "" || GameJolt.userToken == "") {
			trace("Cannot fetch trophies: User not logged in.");
			return;
		}

		var req = new GJRequest(RequestType.TROPHIES_FETCH());
		
		req.onComplete = function(response) {
			if (response.success && response.trophies != null) {
				trace("Successfully fetched " + response.trophies.length + " trophies!");
				
				for (trophy in response.trophies) {
					if (trophy.achieved != "false") {
						trace("UNLOCKED: " + trophy.title + " (ID: " + trophy.id + ")");
					} else {
						trace("LOCKED: " + trophy.title + " (ID: " + trophy.id + ")");
					}
				}
			} else {
				trace("Failed to fetch trophies: " + response.message);
			}
		};

		req.onError = function(error) {
			trace("Network error fetching trophies: " + error);
		};

		req.send();
	}

	function unlockTrophy(trophyID:Int):Void {
		GameJolt.userName = CitroG.save.data.gamejolt.username;
		GameJolt.userToken = CitroG.save.data.gamejolt.token;

		if (GameJolt.userName == "" || GameJolt.userToken == "") {
			trace("Cannot unlock trophy: User not logged in.");
			return;
		}

		var req = new GJRequest(RequestType.TROPHIES_ADD(trophyID));
		
		req.onComplete = function(response) {
			if (response.success) {
				trace("SUCCESS: Trophy " + trophyID + " unlocked!");
				SoundPlayer.playSound(Paths.sound('confirmMenu'));
			} else {
				trace("FAILED to unlock trophy: " + response.message);
			}
		};

		req.onError = function(error) {
			trace("NETWORK ERROR unlocking trophy: " + error);
		};

		req.send();
	}

	public function closeSub():Void {
		if (CitroG.substate != null) {
            CitroG.substate.destroy();
            CitroG.substate = null;
        }
	}
}