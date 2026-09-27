package debug;

import citro.object.CitroText;
import citro.backend.CitroColor;

/**
 * The FPS class provides an easy-to-use monitor to display
 * the current frame rate of a Citro project.
 */
class FPS extends CitroText
{
	/**
	 * The current frame rate, expressed using frames-per-second
	 */
	public var currentFPS(default, null):Int;

	private var cacheCount:Int;
	private var currentTime:Float;
	private var times:Array<Float>;

	public function new(x:Float = 10, y:Float = 10, color:CitroColor = 0xFFFFFFFF)
	{
		super(x, y, "FPS: 0");
		this.alignment = LEFT;

		currentFPS = 0;
		cacheCount = 0;
		currentTime = haxe.Timer.stamp() * 1000; // Convert seconds to milliseconds
		times = [];
	}

	/**
	 * Call this method every frame (e.g., in your state's update loop)
	 * to update the FPS counter.
	 */
	public function update():Void
	{
		var now:Float = haxe.Timer.stamp() * 1000;
		var deltaTime:Float = now - currentTime;
		currentTime = now;
		
		times.push(currentTime);

		// Keep only the timestamps from the last 1000ms (1 second)
		while (times.length > 0 && times[0] < currentTime - 1000)
		{
			times.shift();
		}

		var currentCount = times.length;
		currentFPS = Math.round((currentCount + cacheCount) / 2);
		
		// Optional: Cap to ClientPrefs.framerate if desired
		// if (currentFPS > ClientPrefs.framerate) currentFPS = ClientPrefs.framerate;

		if (currentCount != cacheCount)
		{
			this.text = "FPS: " + currentFPS;
			
			// Change color to red if FPS drops too low (e.g., below 30)
			if (currentFPS <= 30)
			{
				this.color = 0xFFFF0000; // Red
			}
			else
			{
				this.color = 0xFFFFFFFF; // White
			}
		}

		cacheCount = currentCount;
	}
}