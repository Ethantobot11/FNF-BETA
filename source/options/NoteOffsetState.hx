package options;

import citro.CitroG;
import citro.object.CitroSprite;
import citro.object.CitroText;
import citro.backend.CitroColor;
import citro.backend.CitroTween;

using StringTools;

class NoteOffsetState extends MusicBeatState
{
	var boyfriend:Character;
	var gf:Character;

	var coolText:CitroText;
	var rating:CitroSprite;
	var comboNums:Array<CitroSprite> = [];
	var dumbTexts:Array<CitroText> = [];

	var barPercent:Float = 0;
	var delayMin:Int = 0;
	var delayMax:Int = 500;
	var timeBarBG:CitroSprite;
	var timeBar:CitroSprite;
	var timeTxt:CitroText;
	var beatText:Alphabet;
	var changeModeText:CitroText;

	var onComboMenu:Bool = true;
	var holdTime:Float = 0;

	override public function create():Void
	{
		persistentUpdate = true;
		persistentDraw = true;

		var bg:CitroSprite = new CitroSprite(-600, -200);
		bg.loadGraphic(Paths.image('stageback'));
		bg.scale.set(0.9, 0.9);
		CitroG.state.members.push(bg);

		var stageFront:CitroSprite = new CitroSprite(-650, 600);
		stageFront.loadGraphic(Paths.image('stagefront'));
		stageFront.scale.set(0.9 * 1.1, 0.9 * 1.1);
		CitroG.state.members.push(stageFront);

		if(!ClientPrefs.lowQuality) {
			var stageLight1:CitroSprite = new CitroSprite(-125, -100);
			stageLight1.loadGraphic(Paths.image('stage_light'));
			stageLight1.scale.set(0.9 * 1.1, 0.9 * 1.1);
			CitroG.state.members.push(stageLight1);

			var stageLight2:CitroSprite = new CitroSprite(1225, -100);
			stageLight2.loadGraphic(Paths.image('stage_light'));
			stageLight2.scale.set(0.9 * 1.1, 0.9 * 1.1);
			stageLight2.scale.x = -Math.abs(stageLight2.scale.x);
			CitroG.state.members.push(stageLight2);

			var stageCurtains:CitroSprite = new CitroSprite(-500, -300);
			stageCurtains.loadGraphic(Paths.image('stagecurtains'));
			stageCurtains.scale.set(1.3 * 0.9, 1.3 * 0.9);
			CitroG.state.members.push(stageCurtains);
		}

		gf = new Character(400, 130, 'gf');
		gf.x += gf.positionArray[0];
		gf.y += gf.positionArray[1];
		
		boyfriend = new Character(770, 100, 'bf', true);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		
		CitroG.state.members.push(gf);
		CitroG.state.members.push(boyfriend);

		coolText = new CitroText(0, 0, '');
		coolText.alignment = CENTER;
		coolText.x = CitroG.WIDTH * 0.35;
		coolText.y = CitroG.HEIGHT / 2;
		CitroG.state.members.push(coolText);

		rating = new CitroSprite();
		rating.loadGraphic(Paths.image('sick'));
		rating.scale.set(0.7, 0.7);
		rating.antialiasing = ClientPrefs.globalAntialiasing;
		CitroG.state.members.push(rating);

		var seperatedScore:Array<Int> = [Std.random(10), Std.random(10), Std.random(10)];
		var daLoop:Int = 0;
		for (i in seperatedScore) {
			var numScore:CitroSprite = new CitroSprite(0, 0);
			numScore.loadGraphic(Paths.image('num' + i));
			numScore.scale.set(0.5, 0.5);
			numScore.antialiasing = ClientPrefs.globalAntialiasing;
			comboNums.push(numScore);
			CitroG.state.members.push(numScore);
			daLoop++;
		}

		createTexts();
		repositionCombo();

		beatText = new Alphabet(0, 0, 'Beat Hit!', true);
		beatText.scale.set(0.6, 0.6);
		beatText.x = 260;
		beatText.alpha = 0;
		beatText.visible = false;
		CitroG.state.members.push(beatText);
		
		timeTxt = new CitroText(0, 600, "");
		timeTxt.alignment = CENTER;
		timeTxt.visible = false;
		CitroG.state.members.push(timeTxt);

		timeBarBG = new CitroSprite(0, timeTxt.y + 8);
		timeBarBG.loadGraphic(Paths.image('timeBar'));
		timeBarBG.scale.set(1.2, 1.2);
		timeBarBG.screenCenter(X);
		timeBarBG.visible = false;
		CitroG.state.members.push(timeBarBG);

		timeBar = new CitroSprite(timeBarBG.x, timeBarBG.y + 4);
		var maxWidth = Std.int((timeBarBG.width * 1.2) - 8);
		var maxHeight = Std.int((timeBarBG.height * 1.2) - 8);
		timeBar.makeGraphic(maxWidth, maxHeight, CitroColor.WHITE);
		timeBar.screenCenter(X);
		timeBar.visible = false;
		CitroG.state.members.push(timeBar);

		var blackBox:CitroSprite = new CitroSprite(0, 0).makeGraphic(CitroG.WIDTH, 40, CitroColor.BLACK);
		blackBox.alpha = 0.6;
		CitroG.state.members.push(blackBox);

		changeModeText = new CitroText(0, 4, "");
		changeModeText.alignment = CENTER;
		CitroG.state.members.push(changeModeText);
		
		barPercent = ClientPrefs.noteOffset;
		updateNoteDelay();
		updateMode();

		SoundPlayer.playSound(Paths.music('offsetSong'));
		Conductor.changeBPM(128.0);

		super.create();
	}

	override public function update(delta:Int):Void {
		var elapsed:Float = delta / 1000.0;
		var addNum:Int = (controls.UI_UP || controls.UI_DOWN) ? 10 : 1; // Hold Up/Down to change by 10

		if(onComboMenu) {
			if (controls.UI_LEFT_P) { ClientPrefs.comboOffset[0] -= addNum; repositionCombo(); }
			if (controls.UI_RIGHT_P) { ClientPrefs.comboOffset[0] += addNum; repositionCombo(); }
			if (controls.UI_UP_P) { ClientPrefs.comboOffset[1] += addNum; repositionCombo(); }
			if (controls.UI_DOWN_P) { ClientPrefs.comboOffset[1] -= addNum; repositionCombo(); }

			if (controls.NOTE_LEFT_P) { ClientPrefs.comboOffset[2] -= addNum; repositionCombo(); }
			if (controls.NOTE_RIGHT_P) { ClientPrefs.comboOffset[2] += addNum; repositionCombo(); }
			if (controls.NOTE_UP_P) { ClientPrefs.comboOffset[3] += addNum; repositionCombo(); }
			if (controls.NOTE_DOWN_P) { ClientPrefs.comboOffset[3] -= addNum; repositionCombo(); }

			if(controls.RESET) {
				for (i in 0...ClientPrefs.comboOffset.length) ClientPrefs.comboOffset[i] = 0;
				repositionCombo();
			}
		} else {
			if(controls.UI_LEFT_P) {
				barPercent = Math.max(delayMin, Math.min(ClientPrefs.noteOffset - 1, delayMax));
				updateNoteDelay();
			} else if(controls.UI_RIGHT_P) {
				barPercent = Math.max(delayMin, Math.min(ClientPrefs.noteOffset + 1, delayMax));
				updateNoteDelay();
			}

			var mult:Int = 1;
			if(controls.UI_LEFT || controls.UI_RIGHT) {
				holdTime += elapsed;
				if(controls.UI_LEFT) mult = -1;
			} else {
				holdTime = 0;
			}

			if(holdTime > 0.5) {
				barPercent += 100 * elapsed * mult;
				barPercent = Math.max(delayMin, Math.min(barPercent, delayMax));
				updateNoteDelay();
			}

			if(controls.RESET) {
				holdTime = 0;
				barPercent = 0;
				updateNoteDelay();
			}
		}

		if(controls.ACCEPT) {
			onComboMenu = !onComboMenu;
			updateMode();
		}

		if(controls.BACK) {
			persistentUpdate = false;
			MusicBeatState.switchState(new OptionsState());
			SoundPlayer.playSound(Paths.music('freakyMenu'));
		}

		// Conductor.songPosition = MusicPlayer.getTime(); // TODO
		super.update(delta);
	}

	var lastBeatHit:Int = -1;
	override public function beatHit():Void {
		super.beatHit();

		if(lastBeatHit == curBeat) return;

		if(curBeat % 2 == 0) {
			boyfriend.dance();
			gf.dance();
		}
		
		if(curBeat % 4 == 2) {
			beatText.alpha = 1;
			beatText.y = 320;
			
			var props = new Map<String, Float>();
			props.set("alpha", 0);
			props.set("y", beatText.y - 50);
			CitroTween.tweenObject(beatText, props, 1, {
				onComplete: function() {
					beatText.alpha = 0;
				}
			});
		}

		lastBeatHit = curBeat;
	}

	function repositionCombo():Void {
		rating.screenCenter(X);
		rating.x = coolText.x - 40 + ClientPrefs.comboOffset[0];
		rating.y = coolText.y - 60 + ClientPrefs.comboOffset[1];

		var comboX = coolText.x - 90 + ClientPrefs.comboOffset[2];
		var comboY = coolText.y + 80 - ClientPrefs.comboOffset[3];
		
		var daLoop:Int = 0;
		for (num in comboNums) {
			num.x = comboX + (43 * daLoop);
			num.y = comboY;
			daLoop++;
		}
		reloadTexts();
	}

	function createTexts():Void {
		for (i in 0...4) {
			var yPos = 48 + (i * 30) + (i > 1 ? 24 : 0);
			var text:CitroText = new CitroText(10, yPos, '');
			text.alignment = LEFT;
			dumbTexts.push(text);
			CitroG.state.members.push(text);
		}
	}

	function reloadTexts():Void {
		for (i in 0...dumbTexts.length) {
			switch(i) {
				case 0: dumbTexts[i].text = 'Rating Offset:';
				case 1: dumbTexts[i].text = '[' + ClientPrefs.comboOffset[0] + ', ' + ClientPrefs.comboOffset[1] + ']';
				case 2: dumbTexts[i].text = 'Numbers Offset:';
				case 3: dumbTexts[i].text = '[' + ClientPrefs.comboOffset[2] + ', ' + ClientPrefs.comboOffset[3] + ']';
			}
		}
	}

	function updateNoteDelay():Void {
		ClientPrefs.noteOffset = Math.round(barPercent);
		timeTxt.text = 'Current offset: ' + Math.floor(barPercent) + ' ms';
		
		var percent = (barPercent - delayMin) / (delayMax - delayMin);
		var maxWidth = Std.int((timeBarBG.width * 1.2) - 8);
		timeBar.setSourceRect(0, 0, Std.int(maxWidth * percent), timeBar.height);
	}

	function updateMode():Void {
		rating.visible = onComboMenu;
		for (num in comboNums) num.visible = onComboMenu;
		for (txt in dumbTexts) txt.visible = onComboMenu;
		
		timeBarBG.visible = !onComboMenu;
		timeBar.visible = !onComboMenu;
		timeTxt.visible = !onComboMenu;
		beatText.visible = !onComboMenu;

		if(onComboMenu)
			changeModeText.text = '< Combo Offset (Press Accept to Switch) >';
		else
			changeModeText.text = '< Note/Beat Delay (Press Accept to Switch) >';
	}
}