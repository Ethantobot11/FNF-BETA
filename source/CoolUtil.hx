package;

import sys.io.File;
import sys.FileSystem;

class CoolUtil {
    public static var difficulties:Array<String> = ['easy', 'normal', 'hard'];
    public static var defaultDifficulty:String = 'normal';
    public static var defaultDifficulties:Array<String> = ['easy', 'normal', 'hard'];
    
    public static function difficultyString():String {
        return difficulties[PlayState.storyDifficulty].toUpperCase();
    }
    
    public static function getDifficultyFilePath(?diff:Int):String {
        if(diff == null) diff = PlayState.storyDifficulty;
        if(diff >= difficulties.length) diff = 0;
        return '-' + difficulties[diff].toLowerCase();
    }
    
    public static function coolTextFile(path:String):Array<String> {
        if(!FileSystem.exists(path)) return [];
        return File.getContent(path).split('\n');
    }
    
    public static function listFromString(str:String):Array<String> {
        return str.split('\n');
    }
    
    public static function boundTo(val:Float, min:Float, max:Float):Float {
        return Math.max(min, Math.min(max, val));
    }
    
    public static function getRandomObject(array:Array<Array<String>>):Array<String> {
        if(array.length == 0) return [];
        return array[Std.random(array.length)];
    }
}