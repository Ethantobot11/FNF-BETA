package;

import citro.CitroG;

class Highscore
{
	public static var weekScores:Map<String, Int> = new Map();
	public static var songScores:Map<String, Int> = new Map();
	public static var songRating:Map<String, Float> = new Map();

	public static function resetSong(song:String, diff:Int = 0):Void {
		var daSong:String = formatSong(song, diff);
		setScore(daSong, 0);
		setRating(daSong, 0);
	}

	public static function resetWeek(week:String, diff:Int = 0):Void {
		var daWeek:String = formatSong(week, diff);
		setWeekScore(daWeek, 0);
	}

	public static function floorDecimal(value:Float, decimals:Int):Float {
		if(decimals < 1) return Math.floor(value);
		var tempMult:Float = 1;
		for (i in 0...decimals) tempMult *= 10;
		var newValue:Float = Math.floor(value * tempMult);
		return newValue / tempMult;
	}

	public static function saveScore(song:String, score:Int = 0, ?diff:Int = 0, ?rating:Float = -1):Void {
		var daSong:String = formatSong(song, diff);
		if (songScores.exists(daSong)) {
			if (songScores.get(daSong) < score) {
				setScore(daSong, score);
				if(rating >= 0) setRating(daSong, rating);
			}
		} else {
			setScore(daSong, score);
			if(rating >= 0) setRating(daSong, rating);
		}
	}

	public static function saveWeekScore(week:String, score:Int = 0, ?diff:Int = 0):Void {
		var daWeek:String = formatSong(week, diff);
		if (weekScores.exists(daWeek)) {
			if (weekScores.get(daWeek) < score) setWeekScore(daWeek, score);
		} else setWeekScore(daWeek, score);
	}

	static function setScore(song:String, score:Int):Void {
		songScores.set(song, score);
		CitroG.save.data.songScores = songScores;
		CitroG.save.flush();
	}
	
	static function setWeekScore(week:String, score:Int):Void {
		weekScores.set(week, score);
		CitroG.save.data.weekScores = weekScores;
		CitroG.save.flush();
	}

	static function setRating(song:String, rating:Float):Void {
		songRating.set(song, rating);
		CitroG.save.data.songRating = songRating;
		CitroG.save.flush();
	}

	public static function formatSong(song:String, diff:Int):String {
		return Paths.formatToSongPath(song) + CoolUtil.getDifficultyFilePath(diff);
	}

	public static function getScore(song:String, diff:Int):Int {
		var daSong:String = formatSong(song, diff);
		if (!songScores.exists(daSong)) setScore(daSong, 0);
		return songScores.get(daSong);
	}

	public static function getRating(song:String, diff:Int):Float {
		var daSong:String = formatSong(song, diff);
		if (!songRating.exists(daSong)) setRating(daSong, 0);
		return songRating.get(daSong);
	}

	public static function getWeekScore(week:String, diff:Int):Int {
		var daWeek:String = formatSong(week, diff);
		if (!weekScores.exists(daWeek)) setWeekScore(daWeek, 0);
		return weekScores.get(daWeek);
	}

	public static function load():Void {
		CitroG.save.bind('funkin', 'ninjamuffin99');
		if (CitroG.save.data.weekScores != null) weekScores = CitroG.save.data.weekScores;
		if (CitroG.save.data.songScores != null) songScores = CitroG.save.data.songScores;
		if (CitroG.save.data.songRating != null) songRating = CitroG.save.data.songRating;
	}
}