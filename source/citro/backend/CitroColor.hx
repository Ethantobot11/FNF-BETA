package citro.backend;

import citro.math.CitroMath;
import cpp.UInt8;
import cpp.UInt32;

/**
 * Advanced coloring options.
 */
enum abstract CitroColor(UInt32) from UInt32 to UInt32 {
    // --- Commonly used color constants ---
    public static inline var WHITE:CitroColor = 0xFFFFFFFF;
    public static inline var BLACK:CitroColor = 0xFF000000;
    public static inline var RED:CitroColor = 0xFFFF0000;
    public static inline var GREEN:CitroColor = 0xFF00FF00;
    public static inline var BLUE:CitroColor = 0xFF0000FF;
	public static inline var YELLOW:CitroColor = 0xFFFFFF00;
	public static inline var ORANGE:CitroColor = 0xFFFFA500;
	public static inline var GRAY:CitroColor = 0xFF808080;

    public var alpha(get, set):UInt8;
    function get_alpha():UInt8 return (this >> 24) & 0xFF;
    inline function set_alpha(alpha:UInt8):UInt8 {
        this &= 0x00ffffff;
        this |= Std.int(CitroMath.clamp(alpha, 0, 0xFF)) << 24;
        return alpha;
    }

    public var red(get, set):UInt8;
    function get_red():UInt8 return (this >> 16) & 0xFF;
    inline function set_red(red:UInt8):UInt8 {
        this &= 0xff00ffff;
        this |= Std.int(CitroMath.clamp(red, 0, 0xFF)) << 16;
        return red;
    }

    public var green(get, set):UInt8;
    function get_green():UInt8 return (this >> 8) & 0xFF;
    inline function set_green(green:UInt8):UInt8 {
        this &= 0xffff00ff;
        this |= Std.int(CitroMath.clamp(green, 0, 0xFF)) << 8;
        return green;
    }

    public var blue(get, set):UInt8;
    function get_blue():UInt8 return this & 0xFF;
    inline function set_blue(blue:UInt8):UInt8 {
        this &= 0xffffff00;
        this |= Std.int(CitroMath.clamp(blue, 0, 0xFF));
        return blue;
    }

    public function toString() {
        return StringTools.hex(this);
    }
}