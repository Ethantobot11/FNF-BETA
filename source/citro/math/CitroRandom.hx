package citro.math;

import cpp.UInt32;

/**
 * Class that uses a randomizer by using stdlib and stuff.
 * Do not use this class directly, instead use `CitroG.random`.
 */
class CitroRandom {
	/**
	 * Returns a pseudorandom integer between min and max.
	 * @param from The minimum value that should be returned. 1 by default.
	 * @param to The maximum value that should be returned. 2,147,483,647 by default.
	 * @return A Random number depending on the arguments.
	 */
	public function integer(from:Int = 1, to:Int = 2147483647):Int {
		return from + Std.random(to + 1 - from);
	}

	/**
	 * Alias for `integer` to perfectly match HaxeFlixel's `FlxG.random.int`.
	 * @param from The minimum value that should be returned.
	 * @param to The maximum value that should be returned.
	 * @return A Random integer.
	 */
	public inline function int(from:Int = 1, to:Int = 2147483647):Int {
		return integer(from, to);
	}

	/**
	 * Returns a pseudorandom float value between Min (inclusive) and Max (exclusive).
	 */
	public function floating(from:Float = 1, to:Float = 2147483647):Float {
		return from + (Math.random() * (to - from));
	}

	/**
	 * Returns true or false based on the chance value (default 50%).
	 */
	public function boolean(chance:Float = 50):Bool {
		return floating(0, CitroMath.clamp(chance, 0, 100)) < chance;
	}

	/**
	 * Returns a random color depending by the arguments.
	 */
	public function color(from:Int = 0xFF000000, to:Int = 0xFFFFFFFF):UInt32 {
		final fromArr:Array<Int> = [for (i in 0...4) (from >> i * 8) & 0xFF];
		final toArr:Array<Int> = [for (i in 0...4) (to >> i * 8) & 0xFF];
		return integer(fromArr[3], toArr[3]) << 24 |
		       integer(fromArr[2], toArr[2]) << 16 |
		       integer(fromArr[1], toArr[1]) << 8 |
		       integer(fromArr[0], toArr[0]);
	}

	/**
	 * Gets and picks a random option from this array.
	 */
	public function array<T>(Array:Array<T>):T {
		return Array[integer(0, Array.length - 1)];
	}

	public function new() {}
}