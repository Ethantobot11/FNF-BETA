package;

import Controls;

class PlayerSettings
{
	static public var numPlayers(default, null):Int = 0;
	static public var player1(default, null):PlayerSettings;
	static public var player2(default, null):PlayerSettings;

	public var id(default, null):Int;
	public var controls:Controls;

	function new(id:Int)
	{
		this.id = id;
		this.controls = new Controls();
	}

	static public function init():Void
	{
		if (player1 == null)
		{
			player1 = new PlayerSettings(0);
			numPlayers = 1;
		}

		ClientPrefs.loadDefaultKeys();
		ClientPrefs.reloadControls();
	}

	static public function reset():Void
	{
		player1 = null;
		player2 = null;
		numPlayers = 0;
	}
}