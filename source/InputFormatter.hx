package;

class InputFormatter {
	public static function getKeyName(key:Int):String {
		switch(key) {
			case 0: return "LEFT";
			case 1: return "RIGHT";
			case 2: return "UP";
			case 3: return "DOWN";
			case 4: return "A";
			case 5: return "B";
			case 6: return "X";
			case 7: return "Y";
			case 8: return "L";
			case 9: return "R";
			case 10: return "START";
			case 11: return "SELECT";
			default: return "KEY_" + key;
		}
	}
}