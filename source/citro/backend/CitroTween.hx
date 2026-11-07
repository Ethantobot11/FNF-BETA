package citro.backend;

import haxe3ds.OS;
import citro.math.CitroMath;
import citro.CitroG;
import citro.backend.CitroColor;

enum abstract CitroEase(Int) {
	var LINEAR;
	var SINE_IN;
	var SINE_OUT;
	var SINE_INOUT;
	var QUAD_IN;
	var QUAD_OUT;
	var QUAD_INOUT;
	var CUBE_IN;
	var CUBE_OUT;
	var CUBE_INOUT;
	var QUART_IN;
	var QUART_OUT;
	var QUART_INOUT;
	var QUINT_IN;
	var QUINT_OUT;
	var QUINT_INOUT;
	var SMOOTHSTEP_IN;
	var SMOOTHSTEP_OUT;
	var SMOOTHSTEP_INOUT;
	var SMOOTHERSTEP_IN;
	var SMOOTHERSTEP_OUT;
	var SMOOTHERSTEP_INOUT;
	var BOUNCE_IN;
	var BOUNCE_OUT;
	var BOUNCE_INOUT;
	var CIRC_IN;
	var CIRC_OUT;
	var CIRC_INOUT;
	var EXPO_IN;
	var EXPO_OUT;
	var EXPO_INOUT;
	var BACK_IN;
	var BACK_OUT;
	var BACK_INOUT;
	var ELASTIC_IN;
	var ELASTIC_OUT;
	var ELASTIC_INOUT;
}

enum abstract CTTypes(Int) {
	var OBJECT;
	var VARIABLE;
}

private typedef CitroTweenProps = {
	var variableToUse:String;
	var destination:Float;
	var ?prop:Dynamic;
	var oldValue:Float;
}

typedef CitroTweenOptions = {
	/**
	 * The style of ease to use as.
	 */
	var ?ease:CitroEase;

	/**
	 * Callback function for tween completion.
	 */
	var ?onComplete:Void->Void;

	/**
	 * Callback function per frame called, if it's by a number then it returns the number, else returns as a percentage (0 - 1).
	 */
	var ?onUpdate:Float->Void;

	/**
	 * Delay before the tween starts, in seconds.
	 */
	var ?startDelay:Float;
}

private typedef CitroTweenArray = {
	variable:Null<Dynamic>,
	props:Array<CitroTweenProps>,
	oldTime:Int,
	length:Float,
	state:Bool,
	tweenType:CTTypes,
	options:CitroTweenOptions,
	delay:Float
}

/**
 * Class for doing tweens and such.
 */
class CitroTween {
	public static var cta:Array<CitroTweenArray> = [];

	static function createOptions(option:Null<CitroTweenOptions>):CitroTweenOptions {
		if (option == null) {
			return {
				ease: LINEAR
			}
		}

		if (option.ease == null) option.ease = LINEAR;
		return option;
	}

	/**
	 * Creates and starts a new tween from number to number.
	 * @param from Starting number.
	 * @param to Ending number.
	 * @param duration How long in seconds do you want it to tween for?
	 * @param options The current options to set up for the tween, can be null for default settings.
	 */
	public static function tweenNumber(from:Float, to:Float, duration:Float = 1, options:Null<CitroTweenOptions> = null):Bool {
		options = createOptions(options);
		if (options.onUpdate == null) {
			return false;
		}

		var delay = options.startDelay != null ? options.startDelay * 1000 : 0;

		return cta.push({
			variable: null,
			props: [{
				variableToUse: "",
				destination: to,
				oldValue: from
			}],
			oldTime: OS.time.toInt(),
			length: Std.int(duration * 1000),
			state: CitroG.substate == null,
			tweenType: VARIABLE,
			options: options,
			delay: delay
		}) != 0;
	}

	/**
	 * Creates and starts a new tween from object.
	 * @param object Object to use as.
	 * @param props A dynamic object mapper for the properties to use for this object (e.g., { x: 100, y: 50 }).
	 * @param duration How long in seconds do you want it to tween for?
	 * @param options The current options to set up for the tween, can be null for default settings.
	 */
	public static function tweenObject(object:Dynamic, props:Dynamic, duration:Float = 1, options:Null<CitroTweenOptions> = null):Bool {
		if (object == null || !Reflect.isObject(object)) {
			return false;
		}

		final propStates:Array<CitroTweenProps> = [];
		for (pName in Reflect.fields(props)) {
			final item:Float = Reflect.field(props, pName);
			final fieldPaths:Array<String> = pName.split(".");

			var field = object;
			if (fieldPaths.length > 1) {
				for (index => path in fieldPaths) {
					if (index == fieldPaths.length-1) {
						break;
					}
					field = Reflect.getProperty(field, path);
					if (!Reflect.isObject(field)) {
						throw 'Object Property "$path" is not an object.';
					}
				}
			}

			if (field == null) {
				throw 'Object does not have the property "$pName"';
			}

			final name:String = fieldPaths.pop();
			propStates.push({
				variableToUse: name,
				destination: item,
				oldValue: Reflect.getProperty(field, name),
				prop: field
			});
		}

		if (propStates.length == 0) {
			return false;
		}

		var opts = createOptions(options);
		var delay = opts.startDelay != null ? opts.startDelay * 1000 : 0;

		return cta.push({
			variable: object,
			props: propStates,
			oldTime: OS.time.toInt(),
			length: duration * 1000,
			state: CitroG.substate == null,
			tweenType: OBJECT,
			options: opts,
			delay: delay
		}) != 0;
	}

	/**
	 * Creates and starts a new color tween on an object.
	 * @param object Object containing the color property (e.g., a CitroSprite).
	 * @param prop The string name of the color property (e.g., "color" or "alpha").
	 * @param toColor The destination CitroColor.
	 * @param duration How long in seconds.
	 * @param options Tween options (ease, onComplete, etc.).
	 */
	public static function tweenColor(object:Dynamic, prop:String, toColor:CitroColor, duration:Float = 1, options:Null<CitroTweenOptions> = null):Bool {
		if (object == null || !Reflect.isObject(object)) return false;
		final currentColor:CitroColor = Reflect.getProperty(object, prop);	
		final startR = currentColor.red;
		final startG = currentColor.green;
		final startB = currentColor.blue;
		final startA = currentColor.alpha;
		final endR = toColor.red;
		final endG = toColor.green;
		final endB = toColor.blue;
		final endA = toColor.alpha;
		var opts = createOptions(options);
		opts.onUpdate = function(t:Float) {
			final newR = Std.int(startR + (endR - startR) * t);
			final newG = Std.int(startG + (endG - startG) * t);
			final newB = Std.int(startB + (endB - startB) * t);
			final newA = Std.int(startA + (endA - startA) * t);
			Reflect.setProperty(object, prop, CitroColor.fromRGB(newR, newG, newB, newA));
		};

		var delay = opts.startDelay != null ? opts.startDelay * 1000 : 0;
		return cta.push({
			variable: object,
			props: [{
				variableToUse: prop,
				destination: 1,
				oldValue: 0,
				prop: object
			}],
			oldTime: OS.time.toInt(),
			length: Std.int(duration * 1000),
			state: CitroG.substate == null,
			tweenType: OBJECT,
			options: opts,
			delay: delay
		}) != 0;
	}

	/**
	 * Alias for tweenObject to match FlxTween.tween
	 */
	public static inline function tween(object:Dynamic, props:Dynamic, duration:Float = 1, options:Null<CitroTweenOptions> = null):Bool {
		return tweenObject(object, props, duration, options);
	}

	/**
	 * Alias for tweenNumber to match FlxTween.num
	 */
	public static inline function num(from:Float, to:Float, duration:Float = 1, options:Null<CitroTweenOptions> = null):Bool {
		return tweenNumber(from, to, duration, options);
	}

	/**
	 * Alias for cancelTweensFrom to match FlxTween.cancelTweensOf
	 */
	public static inline function cancelTweensOf(object:Dynamic):Void {
		cancelTweensFrom(object);
	}

	/**
	 * Updates all tweens, should not be used.
	 * @param delta Time since last frame in milliseconds.
	 */
	public static function update() {
		for (spr in cta) {
			if (spr.state == (CitroG.substate != null)) {
				continue;
			}

			var currentTime = OS.time.toInt() - spr.oldTime;
			if (currentTime < spr.delay) {
				continue;
			}

			final progress:Float = CitroMath.clamp((currentTime - spr.delay) / spr.length, 0, 1);
			var useVar:Float = progress;
			for (prop in spr.props) {
				final res:Float = CitroMath.lerp(prop.oldValue, prop.destination, applyEase(spr.options.ease, progress));
				switch (spr.tweenType) {
					case OBJECT:
						Reflect.setProperty(prop.prop, prop.variableToUse, res);

					case VARIABLE:
						useVar = res;
				}
			}

			if (spr.options.onUpdate != null) {
				spr.options.onUpdate(useVar);
			}

			if (progress >= 1) {
				if (spr.options.onComplete != null) {
					spr.options.onComplete();
				}
				cta.remove(spr);
			}
		}
	}

	/**
	 * Cancels any tweens provided from the object argument.
	 * @param object Object to cancel tweens.
	 */
	public static function cancelTweensFrom(object:Dynamic) {
		for (s in cta) {
			if (s.variable == object) {
				cta.remove(s);
			}
		}
	}

	static function smoothStepInOut(t:Float):Float {
		return t * t * (t * -2 + 3);
	}

	static function smootherStepInOut(t:Float):Float {
		return t * t * t * (t * (t * 6 - 15) + 10);
	}

	static final B3:Float = 1.5 / 2.75;
	static final B5:Float = 2.25 / 2.75;
	static final B6:Float = 2.625 / 2.75;

	static function bounceOut(t:Float):Float {
		if (t < 1 / 2.75) return 7.5625 * t * t;
		if (t < 2 / 2.75) return 7.5625 * (t - B3) * (t - B3) + .75;
		if (t < 2.5 / 2.75) return 7.5625 * (t - B5) * (t - B5) + .9375;
		return 7.5625 * (t - B6) * (t - B6) + .984375;
	}

	static function backInOut(t:Float):Float {
		t *= 2;
		if (t < 1) return t * t * (2.70158 * t - 1.70158) / 2;
		t--;
		return (1 - (t--) * (t) * (-2.70158 * t - 1.70158)) / 2 + .5;
	}

	static function applyEase(ease:CitroEase, t:Float):Float {
		return switch(ease) {
			case LINEAR: t;

			case SINE_IN: 1 - Math.cos((t * Math.PI) / 2);
			case SINE_OUT: Math.sin((t * Math.PI) / 2);
			case SINE_INOUT: -(Math.cos(Math.PI * t) - 1) / 2;

			case QUAD_IN: t * t;
			case QUAD_OUT: -t * (t - 2);
			case QUAD_INOUT: t <= .5 ? t * t * 2 : 1 - (t--) * t * 2;

			case CUBE_IN: t * t * t;
			case CUBE_OUT: 1 + (t--) * t * t;
			case CUBE_INOUT: t <= .5 ? t * t * t * 4 : 1 + (t--) * t * t * 4;

			case QUART_IN: t * t * t * t;
			case QUART_OUT: 1 - (t -= 1) * t * t * t;
			case QUART_INOUT: t <= .5 ? t * t * t * t * 8 : (1 - (t = t * 2 - 2) * t * t * t) / 2 + .5;

			case QUINT_IN: t * t * t * t * t;
			case QUINT_OUT: (t = t - 1) * t * t * t * t + 1;
			case QUINT_INOUT: ((t *= 2) < 1) ? (t * t * t * t * t) / 2 : ((t -= 2) * t * t * t * t + 2) / 2;

			case SMOOTHSTEP_IN: 2 * smoothStepInOut(t / 2);
			case SMOOTHSTEP_OUT: 2 * smoothStepInOut(t / 2 + 0.5) - 1;
			case SMOOTHSTEP_INOUT: smoothStepInOut(t);

			case SMOOTHERSTEP_IN: 2 * smootherStepInOut(t / 2);
			case SMOOTHERSTEP_OUT: 2 * smootherStepInOut(t / 2 + 0.5) - 1;
			case SMOOTHERSTEP_INOUT: smootherStepInOut(t);

			case BOUNCE_IN: 1 - bounceOut(1 - t);
			case BOUNCE_OUT: bounceOut(t);
			case BOUNCE_INOUT: t < 0.5 ? (1 - bounceOut(1 - 2 * t)) / 2 : (1 + bounceOut(2 * t - 1)) / 2;

			case CIRC_IN: -(Math.sqrt(1 - t * t) - 1);
			case CIRC_OUT: Math.sqrt(1 - (t - 1) * (t - 1));
			case CIRC_INOUT: t <= .5 ? (Math.sqrt(1 - t * t * 4) - 1) / -2 : (Math.sqrt(1 - (t * 2 - 2) * (t * 2 - 2)) + 1) / 2;

			case EXPO_IN: Math.pow(2, 10 * (t - 1));
			case EXPO_OUT: -Math.pow(2, -10 * t) + 1;
			case EXPO_INOUT: t < .5 ? Math.pow(2, 10 * (t * 2 - 1)) / 2 : (-Math.pow(2, -10 * (t * 2 - 1)) + 2) / 2;

			case BACK_IN: t * t * (2.70158 * t - 1.70158);
			case BACK_OUT: 1 - (t--) * (t) * (-2.70158 * t - 1.70158);
			case BACK_INOUT: backInOut(t);

			case ELASTIC_IN: -(1 * Math.pow(2, 10 * (t -= 1)) * Math.sin((t - (.4 / (2 * Math.PI) * Math.asin(1 / 1))) * (2 * Math.PI) / .4));
			case ELASTIC_OUT: (1 * Math.pow(2, -10 * t) * Math.sin((t - (.4 / (2 * Math.PI) * Math.asin(1 / 1))) * (2 * Math.PI) / .4) + 1);
			case ELASTIC_INOUT: t < 0.5 ? -0.5 * (Math.pow(2, 10 * (t -= 0.5)) * Math.sin((t - (.4 / 4)) * (2 * Math.PI) / .4)) : Math.pow(2, -10 * (t -= 0.5)) * Math.sin((t - (.4 / 4)) * (2 * Math.PI) / .4) * 0.5 + 1;

			default: t;
		}
	}
}