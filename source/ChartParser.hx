package;

using StringTools;

class ChartParser
{
	static public function parse(songName:String, section:Int):Array<Dynamic>
	{
		trace('WARNING: ChartParser.parse() called for $songName section $section. PNG chart parsing is not supported on 3DS. Use JSON charts instead.');
		return [];
	}
}