package;

import haxe3ds.services.HID;
import haxe3ds.services.HID.HIDKey;

enum abstract Action(String) to String from String {
	var UI_UP = "ui_up";
	var UI_LEFT = "ui_left";
	var UI_RIGHT = "ui_right";
	var UI_DOWN = "ui_down";
	var NOTE_UP = "note_up";
	var NOTE_LEFT = "note_left";
	var NOTE_RIGHT = "note_right";
	var NOTE_DOWN = "note_down";
	var ACCEPT = "accept";
	var BACK = "back";
	var PAUSE = "pause";
	var RESET = "reset";
}

class Controls {
	public function new() {}

	public function check(action:Action):Bool {
		return switch(action) {
			case Action.UI_UP: HID.keyPressed(HIDKey.UP);
			case Action.UI_DOWN: HID.keyPressed(HIDKey.DOWN);
			case Action.UI_LEFT: HID.keyPressed(HIDKey.LEFT);
			case Action.UI_RIGHT: HID.keyPressed(HIDKey.RIGHT);
			
			case Action.NOTE_UP: HID.keyPressed(HIDKey.UP);
			case Action.NOTE_DOWN: HID.keyPressed(HIDKey.DOWN);
			case Action.NOTE_LEFT: HID.keyPressed(HIDKey.LEFT);
			case Action.NOTE_RIGHT: HID.keyPressed(HIDKey.RIGHT);
			
			case Action.ACCEPT: HID.keyPressed(HIDKey.A);
			case Action.BACK: HID.keyPressed(HIDKey.B);
			case Action.PAUSE: HID.keyPressed(HIDKey.START);
			case Action.RESET: HID.keyPressed(HIDKey.SELECT);
		}
	}

	public var UI_UP(get, never):Bool;
	inline function get_UI_UP() return check(Action.UI_UP);

	public var UI_LEFT(get, never):Bool;
	inline function get_UI_LEFT() return check(Action.UI_LEFT);

	public var UI_RIGHT(get, never):Bool;
	inline function get_UI_RIGHT() return check(Action.UI_RIGHT);

	public var UI_DOWN(get, never):Bool;
	inline function get_UI_DOWN() return check(Action.UI_DOWN);

	public var NOTE_UP(get, never):Bool;
	inline function get_NOTE_UP() return check(Action.NOTE_UP);

	public var NOTE_LEFT(get, never):Bool;
	inline function get_NOTE_LEFT() return check(Action.NOTE_LEFT);

	public var NOTE_RIGHT(get, never):Bool;
	inline function get_NOTE_RIGHT() return check(Action.NOTE_RIGHT);

	public var NOTE_DOWN(get, never):Bool;
	inline function get_NOTE_DOWN() return check(Action.NOTE_DOWN);

	public var ACCEPT(get, never):Bool;
	inline function get_ACCEPT() return check(Action.ACCEPT);

	public var BACK(get, never):Bool;
	inline function get_BACK() return check(Action.BACK);

	public var PAUSE(get, never):Bool;
	inline function get_PAUSE() return check(Action.PAUSE);

	public var RESET(get, never):Bool;
	inline function get_RESET() return check(Action.RESET);
}