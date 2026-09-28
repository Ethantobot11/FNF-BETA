package;

import citro.object.CitroSprite;
import citro.object.CitroAnimate;
import citro.math.CitroMath;
import citro.CitroG;

using StringTools;

enum Alignment { LEFT; CENTERED; RIGHT; }

class Alphabet extends CitroSprite {
	private var _text:String = "";
	public var text(get, set):String;
	private function get_text():String return _text;
	private function set_text(newText:String):String {
		_text = newText.replace('\\n', '\n');
		clearLetters();
		createLetters(_text);
		updateAlignment();
		return _text;
	}

	private var _alignment:Alignment = LEFT;
	public var alignment(get, set):Alignment;
	private function get_alignment():Alignment return _alignment;
	private function set_alignment(align:Alignment):Alignment {
		_alignment = align;
		updateAlignment();
		return align;
	}

	public var bold:Bool = false;
	public var letters:Array<AlphaCharacter> = [];

	public var isMenuItem:Bool = false;
	public var targetY:Int = 0;
	public var changeX:Bool = true;
	public var changeY:Bool = true;

	public var rows:Int = 0;

	public var distancePerItemX:Float = 20;
	public var distancePerItemY:Float = 120;
	public var startPositionX:Float = 0;
	public var startPositionY:Float = 0;

	public function new(x:Float, y:Float, text:String = "", ?isBold:Bool = false) {
		super();
		this.x = x;
		this.y = y;
		this.bold = isBold;
		this.startPositionX = x;
		this.startPositionY = y;
		this.text = text;
	}

	public function setAlignmentFromString(align:String) {
		switch(align.toLowerCase().trim()) {
			case 'right': alignment = RIGHT;
			case 'center' | 'centered': alignment = CENTERED;
			default: alignment = LEFT;
		}
	}

	private function updateAlignment() {
		for (letter in letters) {
			var newOffset:Float = 0;
			switch(_alignment) {
				case CENTERED: newOffset = letter.rowWidth / 2;
				case RIGHT: newOffset = letter.rowWidth;
				default: newOffset = 0;
			}
			letter.alignOffset = newOffset;
		}
	}

	public function clearLetters() {
		var i:Int = letters.length;
		while (i > 0) {
			--i;
			var letter:AlphaCharacter = letters[i];
			if(letter != null) {
				letters.remove(letter);
				CitroG.state.members.remove(letter);
				letter.destroy();
			}
		}
		letters = [];
		rows = 0;
	}

	override public function update():Bool {
		if (isMenuItem) {
			var lerpVal:Float = CitroMath.clamp(CitroG.deltaTime * 9.6, 0, 1);
			if(changeX) this.x = CitroMath.lerp(this.x, (targetY * distancePerItemX) + startPositionX, lerpVal);
			if(changeY) this.y = CitroMath.lerp(this.y, (targetY * 1.3 * distancePerItemY) + startPositionY, lerpVal);
		}
		
		for (letter in letters) {
			letter.x = this.x + letter.spawnX;
			letter.y = this.y + letter.spawnY;
			letter.update();
		}
		
		return super.update();
	}

	public function snapToPosition() {
		if (isMenuItem) {
			if(changeX) this.x = (targetY * distancePerItemX) + startPositionX;
			if(changeY) this.y = (targetY * 1.3 * distancePerItemY) + startPositionY;
		}
	}

	private static var Y_PER_ROW:Float = 85;

	private function createLetters(newText:String) {
		var consecutiveSpaces:Int = 0;
		var xPos:Float = 0;
		var rowData:Array<Float> = [];
		rows = 0;
		
		for (character in newText.split('')) {
			if(character != '\n') {
				var spaceChar:Bool = (character == " " || (bold && character == "_"));
				if (spaceChar) consecutiveSpaces++;

				if (AlphaCharacter.allLetters.exists(character.toLowerCase()) && (!bold || !spaceChar)) {
					if (consecutiveSpaces > 0) {
						xPos += 28 * consecutiveSpaces * this.scale.x;
						if(!bold && xPos >= CitroG.WIDTH * 0.65) {
							xPos = 0;
							rows++;
						}
					}
					consecutiveSpaces = 0;

					var letter:AlphaCharacter = new AlphaCharacter(xPos, rows * Y_PER_ROW * this.scale.y, character, bold, this);
					letter.row = rows;
					
					letter.spawnX = letter.x;
					letter.spawnY = letter.y;

					xPos += letter.width + letter.letterOffset[0] * this.scale.x;
					rowData[rows] = xPos;

					letters.push(letter);
					CitroG.state.members.push(letter);
				}
			} else {
				xPos = 0;
				rows++;
			}
		}

		for (letter in letters) {
			letter.rowWidth = rowData[letter.row];
		}
		if(letters.length > 0) rows++;
	}

	public function startFlashing():Void {
		// Stub for compatibility
	}
}
