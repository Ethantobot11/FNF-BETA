package;

import citro.CitroG;
import citro.object.CitroSprite;
import citro.math.CitroMath;
import citro.backend.CitroTimer;

class GameOverSubstate extends MusicBeatSubstate
{
	public var boyfriend:Boyfriend;
	var camFollowX:Float = 0;
	var camFollowY:Float = 0;
	var camFollowPosX:Float = 0;
	var camFollowPosY:Float = 0;
	var updateCamera:Bool = false;
	var playingDeathSound:Bool = false;

	public static var characterName:String = 'bf-dead';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';

	public static var instance:GameOverSubstate;

	public static function resetVariables() {
		characterName = 'bf-dead';
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';
	}

	override public function create():Void {
		instance = this;
		PlayState.instance.callOnLuas('onGameOverStart', []);
		super.create();
	}

	public function new(x:Float, y:Float, camX:Float, camY:Float) {
		super();
		PlayState.instance.setOnLuas('inGameOver', true);
		Conductor.songPosition = 0;

		boyfriend = new Boyfriend(x, y, characterName);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		CitroG.state.members.push(boyfriend);

		camFollowX = boyfriend.x + (boyfriend.width * boyfriend.scale.x) / 2;
		camFollowY = boyfriend.y + (boyfriend.height * boyfriend.scale.y) / 2;
		camFollowPosX = camX;
		camFollowPosY = camY;

		SoundPlayer.playSound(Paths.sound(deathSoundName));
		Conductor.changeBPM(100);
		boyfriend.playAnim('firstDeath');
	}

	var isFollowingAlready:Bool = false;

	override public function update(delta:Int):Void {
		var elapsed:Float = delta / 1000.0;
		super.update(delta);
		PlayState.instance.callOnLuas('onUpdate', [elapsed]);

		if(updateCamera) {
			var lerpVal:Float = CitroMath.clamp(elapsed * 0.6, 0, 1);
			camFollowPosX = CitroMath.lerp(camFollowPosX, camFollowX, lerpVal);
			camFollowPosY = CitroMath.lerp(camFollowPosY, camFollowY, lerpVal);
			// Note: Actual camera following is handled by PlayState's camFollowPos
			PlayState.instance.camFollow.x = camFollowPosX;
			PlayState.instance.camFollow.y = camFollowPosY;
		}

		if (controls.ACCEPT) endBullshit();

		if (controls.BACK) {
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;
			PlayState.chartingMode = false;
			WeekData.loadTheFirstEnabledMod();
			if (PlayState.isStoryMode) MusicBeatState.switchState(new StoryMenuState());
			else MusicBeatState.switchState(new FreeplayState());
			PlayState.instance.callOnLuas('onGameOverConfirm', [false]);
		}

		if (boyfriend.curAnim == 'firstDeath') {
			// CitroAnimate doesn't have curFrame easily accessible without modifying CitroAnimate.hx, 
			// but we can check if it's been playing for a certain time or just rely on `finished`
			if(boyfriend.finished && !isFollowingAlready) {
				updateCamera = true;
				isFollowingAlready = true;
			}
			if (boyfriend.finished && !playingDeathSound) {
				if (PlayState.SONG.stage == 'tank') {
					playingDeathSound = true;
					coolStartDeath(0.2);
					// Tank death sound logic simplified for 3DS
				} else {
					coolStartDeath();
				}
				boyfriend.startedDeath = true;
			}
		}
		PlayState.instance.callOnLuas('onUpdatePost', [elapsed]);
	}

	var isEnding:Bool = false;

	function coolStartDeath(?volume:Float = 1):Void {
		MusicPlayer.playMusic(Paths.music(loopSoundName)); // Hook up to your MusicPlayer
	}

	function endBullshit():Void {
		if (!isEnding) {
			isEnding = true;
			boyfriend.playAnim('deathConfirm', true);
			CitroTimer.start(0.7, function() {
				MusicBeatState.resetState();
			});
			PlayState.instance.callOnLuas('onGameOverConfirm', [true]);
		}
	}
}