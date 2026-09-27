package;

import citro.CitroG;

using StringTools;

class Boyfriend extends Character
{
	public var startedDeath:Bool = false;

	public function new(x:Float, y:Float, ?char:String = 'bf')
	{
		super(x, y, char, true);
	}

	override public function update():Bool
	{
		var elapsed:Float = CitroG.deltaTime / 1000.0;

		if (!debugMode && this.curAnim != null)
		{
			if (this.curAnim.startsWith('sing'))
			{
				holdTimer += elapsed;
			}
			else
			{
				holdTimer = 0;
			}

			if (this.curAnim.endsWith('miss') && this.finished && !debugMode)
			{
				playAnim('idle', true, false, 10);
			}

			if (this.curAnim == 'firstDeath' && this.finished && startedDeath)
			{
				playAnim('deathLoop');
			}
		}

		return super.update();
	}
}