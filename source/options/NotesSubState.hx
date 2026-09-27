package options;

import citro.CitroG;
import citro.object.CitroSprite;
import citro.backend.CitroColor;

using StringTools;

class NotesSubState extends MusicBeatSubstate {
	private static var curSelected:Int = 0;
	private static var typeSelected:Int = 0;
	private var grpNumbers:Array<Alphabet> = [];
	private var grpNotes:Array<CitroSprite> = [];
	var curValue:Float = 0;
	var holdTime:Float = 0;
	var nextAccept:Int = 5;

	var blackBG:CitroSprite;
	var hsbText:Alphabet;

	var posX = 230;

	public function new() {
		super();
		
		var bg:CitroSprite = new CitroSprite();
		bg.loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.screenCenter();
		this.members.push(bg);
		
		blackBG = new CitroSprite(posX - 25, 0).makeGraphic(870, 200, CitroColor.BLACK);
		blackBG.alpha = 0.4;
		this.members.push(blackBG);

		for (i in 0...ClientPrefs.arrowHSV.length) {
			var yPos:Float = (165 * i) + 35;
			for (j in 0...3) {
				var optionText:Alphabet = new Alphabet(posX + (225 * j) + 250, yPos + 60, Std.string(ClientPrefs.arrowHSV[i][j]), true);
				grpNumbers.push(optionText);
				this.members.push(optionText);
			}

			var note:CitroSprite = new CitroSprite(posX, yPos);
			note.loadGraphic(Paths.image('NOTE_assets'));
			// Note: Animation logic would go here if NOTE_assets is a .cea file
			grpNotes.push(note);
			this.members.push(note);
		}

		hsbText = new Alphabet(posX + 560, 0, "Hue    Saturation  Brightness", false);
		hsbText.scale.set(0.6, 0.6);
		this.members.push(hsbText);

		changeSelection();
	}

	var changingNote:Bool = false;

	override public function update(delta:Int):Void {
		var elapsed:Float = delta / 1000.0;

		if(changingNote) {
			if(holdTime < 0.5) {
				if(controls.UI_LEFT_P) { updateValue(-1); SoundPlayer.playSound(Paths.sound('scrollMenu')); } 
				else if(controls.UI_RIGHT_P) { updateValue(1); SoundPlayer.playSound(Paths.sound('scrollMenu')); } 
				else if(controls.RESET) { resetValue(curSelected, typeSelected); SoundPlayer.playSound(Paths.sound('scrollMenu')); }
				
				if(controls.UI_LEFT_R || controls.UI_RIGHT_R) holdTime = 0;
				else if(controls.UI_LEFT || controls.UI_RIGHT) holdTime += elapsed;
			} else {
				var add:Float = 90;
				switch(typeSelected) { case 1, 2: add = 50; }
				if(controls.UI_LEFT) updateValue(elapsed * -add);
				else if(controls.UI_RIGHT) updateValue(elapsed * add);
				
				if(controls.UI_LEFT_R || controls.UI_RIGHT_R) {
					SoundPlayer.playSound(Paths.sound('scrollMenu'));
					holdTime = 0;
				}
			}
		} else {
			if (controls.UI_UP_P) { changeSelection(-1); SoundPlayer.playSound(Paths.sound('scrollMenu')); }
			if (controls.UI_DOWN_P) { changeSelection(1); SoundPlayer.playSound(Paths.sound('scrollMenu')); }
			if (controls.UI_LEFT_P) { changeType(-1); SoundPlayer.playSound(Paths.sound('scrollMenu')); }
			if (controls.UI_RIGHT_P) { changeType(1); SoundPlayer.playSound(Paths.sound('scrollMenu')); }
			
			if(controls.RESET) {
				for (i in 0...3) resetValue(curSelected, i);
				SoundPlayer.playSound(Paths.sound('scrollMenu'));
			}
			
			if (controls.ACCEPT && nextAccept <= 0) {
				SoundPlayer.playSound(Paths.sound('scrollMenu'));
				changingNote = true;
				holdTime = 0;
				for (i in 0...grpNumbers.length) {
					grpNumbers[i].alpha = ((curSelected * 3) + typeSelected == i) ? 1 : 0;
				}
				for (i in 0...grpNotes.length) {
					grpNotes[i].alpha = (curSelected == i) ? 1 : 0;
				}
				super.update(delta);
				return;
			}
		}

		if (controls.BACK || (changingNote && controls.ACCEPT)) {
			if(!changingNote) closeSub();
			else changeSelection();
			changingNote = false;
			SoundPlayer.playSound(Paths.sound('cancelMenu'));
		}

		if(nextAccept > 0) nextAccept -= 1;
		super.update(delta);
	}

	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0) curSelected = ClientPrefs.arrowHSV.length - 1;
		if (curSelected >= ClientPrefs.arrowHSV.length) curSelected = 0;

		curValue = ClientPrefs.arrowHSV[curSelected][typeSelected];
		updateValue();

		for (i in 0...grpNumbers.length) {
			grpNumbers[i].alpha = ((curSelected * 3) + typeSelected == i) ? 1 : 0.6;
		}
		for (i in 0...grpNotes.length) {
			grpNotes[i].alpha = (curSelected == i) ? 1 : 0.6;
			grpNotes[i].scale.set((curSelected == i) ? 1 : 0.75, (curSelected == i) ? 1 : 0.75);
			if (curSelected == i) {
				hsbText.y = grpNotes[i].y - 70;
				blackBG.y = grpNotes[i].y - 20;
			}
		}
		SoundPlayer.playSound(Paths.sound('scrollMenu'));
	}

	function changeType(change:Int = 0) {
		typeSelected += change;
		if (typeSelected < 0) typeSelected = 2;
		if (typeSelected > 2) typeSelected = 0;

		curValue = ClientPrefs.arrowHSV[curSelected][typeSelected];
		updateValue();

		for (i in 0...grpNumbers.length) {
			grpNumbers[i].alpha = ((curSelected * 3) + typeSelected == i) ? 1 : 0.6;
		}
	}

	function resetValue(selected:Int, type:Int) {
		curValue = 0;
		ClientPrefs.arrowHSV[selected][type] = 0;
		var item = grpNumbers[(selected * 3) + type];
		item.text = '0';
	}

	function updateValue(change:Float = 0) {
		curValue += change;
		var roundedValue:Int = Math.round(curValue);
		var max:Float = 180;
		switch(typeSelected) { case 1, 2: max = 100; }

		if(roundedValue < -max) curValue = -max;
		else if(roundedValue > max) curValue = max;
		
		roundedValue = Math.round(curValue);
		ClientPrefs.arrowHSV[curSelected][typeSelected] = roundedValue;

		var item = grpNumbers[(curSelected * 3) + typeSelected];
		item.text = Std.string(roundedValue);
	}
}