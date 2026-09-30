package gamejolt;

import gamejolt.formats.*;
import gamejolt.types.*;
import haxe.Http;
import haxe.Json;

using Lambda;
using StringTools;

class GJRequest {
	public var url(get, never):String;
	public var lastResponse(default, null):Response = {success: false, message: "No response has been received yet"};
	public var call(default, set):RequestType;
	public var executing(default, null):Bool = false;

	public var onComplete:Response->Void;
	public var onError:String->Void;

	public function new(Call:RequestType) {
		call = Call;
	}

	function get_url():String {
		return sign('https://api.gamejolt.com/api/game/v1_2${parseType(call)}');
	}

	public function set_call(value:RequestType):RequestType {
		if (executing) return call;
		return call = value;
	}

	public function send() {
		if (executing) return;
		executing = true;

		var loader = new Http(url);
		loader.onData = function(data:String) {
			try {
				var parsed = Json.parse(data);
				lastResponse = formatImages(parsed.response);
				if (lastResponse.message != null) {
					if (onError != null) onError('Response Error: ${lastResponse.message}');
				} else {
					if (onComplete != null) onComplete(lastResponse);
				}
			} catch (e:Dynamic) {
				if (onError != null) onError('JSON Parse Error: ' + e);
			}
			executing = false;
		};
		
		loader.onError = function(error:String) {
			lastResponse = {success: false, message: 'Request Error: $error'};
			if (onError != null) onError(lastResponse.message);
			executing = false;
		};
		
		loader.request(); 
	}

	static function formatImages(res:Response):Response {
		if (res.users != null)
			res.users.iter(u -> u.avatar_url = '${u.avatar_url.substring(0, 32)}1000${u.avatar_url.substr(34)}'.replace(".jpg", ".png").replace(".webp", ".png"));
		if (res.trophies != null)
			res.trophies.iter(function(t) {
				var newUrl:String = "";
				if (t.image_url.startsWith('https://m.'))
					newUrl = '${t.image_url.substring(0, 37)}1000${t.image_url.substr(40)}'.replace(".jpg", ".png").replace(".webp", ".png");
				else {
					newUrl = "https://s.gjcdn.net/assets/";
					newUrl += switch (t.image_url.substring(24).replace(".jpg", "").replace(".webp", "")) {
						case "trophy-bronze-1": "9c2c91d0";
						case "trophy-silver-1": "b46e352e";
						case "trophy-gold-1": "363ce2dc";
						case "trophy-platinum-1": "92e5330d";
						default: "";
					};
					newUrl += ".png";
				}
				t.image_url = newUrl;
			});
		if (res.responses != null)
			res.responses.iter(res2 -> res2 = formatImages(res2));
		return res;
	}

	static function parseType(request:RequestType, signed:Bool = false):String {
		var command:String = "";
		var action:String = "";
		var params:Array<{name:String, value:String}> = [];

		switch (request) {
			case BATCH(parallel, breakOnError, requests):
				command = "batch";
				params.push({name: "parallel", value: '$parallel'});
				params.push({name: "break_on_error", value: '$breakOnError'});
				requests.iter(req -> params.push({name: "requests[]", value: parseType(req, true)}));
			case DATA_FETCH(key, fromUser):
				command = "data-store";
				params.push({name: "key", value: key.urlEncode()});
				if (fromUser) {
					params.push({name: "username", value: GameJolt.userName});
					params.push({name: "user_token", value: GameJolt.userToken});
				}
			case DATA_GETKEYS(fromUser, pattern):
				command = "data-store";
				action = "get-keys";
				if (pattern != null && pattern != "")
					params.push({name: "pattern", value: pattern.urlEncode()});
				if (fromUser) {
					params.push({name: "username", value: GameJolt.userName});
					params.push({name: "user_token", value: GameJolt.userToken});
				}
			case DATA_REMOVE(key, fromUser):
				command = "data-store";
				action = "remove";
				params.push({name: "key", value: key.urlEncode()});
				if (fromUser) {
					params.push({name: "username", value: GameJolt.userName});
					params.push({name: "user_token", value: GameJolt.userToken});
				}
			case DATA_SET(key, data, toUser):
				command = "data-store";
				action = "set";
				params.push({name: "key", value: key.urlEncode()});
				params.push({name: "data", value: data.urlEncode()});
				if (toUser) {
					params.push({name: "username", value: GameJolt.userName});
					params.push({name: "user_token", value: GameJolt.userToken});
				}
			case DATA_UPDATE(key, operation, toUser):
				command = "data-store";
				action = "update";
				params.push({name: "key", value: key.urlEncode()});
				if (toUser) {
					params.push({name: "username", value: GameJolt.userName});
					params.push({name: "user_token", value: GameJolt.userToken});
				}
				switch (operation) {
					case Add(n):
						params.push({name: 'operation', value: 'add'});
						params.push({name: 'value', value: '$n'});
					case Substract(n):
						params.push({name: 'operation', value: 'substract'});
						params.push({name: 'value', value: '$n'});
					case Multiply(n):
						params.push({name: 'operation', value: 'multiply'});
						params.push({name: 'value', value: '$n'});
					case Divide(n):
						params.push({name: 'operation', value: 'divide'});
						params.push({name: 'value', value: '$n'});
					case Append(t):
						params.push({name: 'operation', value: 'append'});
						params.push({name: 'value', value: t.urlEncode()});
					case Prepend(t):
						params.push({name: 'operation', value: 'prepend'});
						params.push({name: 'value', value: t.urlEncode()});
				}
			case FRIENDS:
				command = "friends";
				params.push({name: "username", value: GameJolt.userName});
				params.push({name: "user_token", value: GameJolt.userToken});
			case TIME:
				command = "time";
			case USER_AUTH:
				command = "users";
				action = "auth";
				params.push({name: "username", value: GameJolt.userName});
				params.push({name: "user_token", value: GameJolt.userToken});
			case USER_FETCH(userOrID):
				command = "users";
				var letters:Array<String> = "ABCDEFGHIJKLMNÑOPQRSTUVWXYZ_-".split("");
				if (letters.exists(l -> userOrID.contains(l.toUpperCase()) || userOrID.contains(l.toLowerCase())))
					params.push({name: "username", value: userOrID});
				else
					params.push({name: "user_id", value: userOrID.replace(",", "%2C")});
			case SESSION_OPEN:
				command = "sessions";
				action = "open";
				params.push({name: "username", value: GameJolt.userName});
				params.push({name: "user_token", value: GameJolt.userToken});
			case SESSION_PING(active):
				command = "sessions";
				action = "ping";
				params.push({name: "status", value: active ? "active" : "idle"});
				params.push({name: "username", value: GameJolt.userName});
				params.push({name: "user_token", value: GameJolt.userToken});
			case SESSION_CHECK:
				command = "sessions";
				action = "check";
				params.push({name: "username", value: GameJolt.userName});
				params.push({name: "user_token", value: GameJolt.userToken});
			case SESSION_CLOSE:
				command = "sessions";
				action = "close";
				params.push({name: "username", value: GameJolt.userName});
				params.push({name: "user_token", value: GameJolt.userToken});
			case SCORES_ADD(score, sort, extra_data, table_id):
				command = "scores";
				action = "add";
				params.push({name: "score", value: score});
				params.push({name: "sort", value: '$sort'});
				if (extra_data != null && extra_data != "")
					params.push({name: "extra_data", value: extra_data.urlEncode()});
				if (table_id != null)
					params.push({name: "table_id", value: '$table_id'});
				if (GameJolt.userToken != "") {
					params.push({name: "username", value: GameJolt.userName});
					params.push({name: "user_token", value: GameJolt.userToken});
				} else
					params.push({name: "guest", value: GameJolt.userName});
			case SCORES_GETRANK(sort, table_id):
				command = "scores";
				action = "get-rank";
				params.push({name: "sort", value: '$sort'});
				if (table_id != null)
					params.push({name: "table_id", value: '$table_id'});
			case SCORES_FETCH(fromUser, table_id, limit, betterThan):
				command = "scores";
				if (table_id != null)
					params.push({name: "table_id", value: '$table_id'});
				if (limit != null)
					params.push({name: "limit", value: '$limit'});
				if (betterThan != null)
					params.push({name: betterThan < 0 ? "worse_than" : "better_than", value: '${Math.abs(betterThan)}'});
				if (fromUser) {
					if (GameJolt.userToken != "") {
						params.push({name: "username", value: GameJolt.userName});
						params.push({name: "user_token", value: GameJolt.userToken});
					} else
						params.push({name: "guest", value: GameJolt.userName});
				}
			case SCORES_TABLES:
				command = "scores";
				action = "tables";
			case TROPHIES_FETCH(achieved, trophy_id):
				command = "trophies";
				if (achieved != null)
					params.push({name: "achieved", value: '$achieved'});
				if (trophy_id != null)
					params.push({name: "trophy_id", value: '$trophy_id'});
				params.push({name: "username", value: GameJolt.userName});
				params.push({name: "user_token", value: GameJolt.userToken});
			case TROPHIES_ADD(trophy_id):
				command = "trophies";
				action = "add-achieved";
				params.push({name: "trophy_id", value: '$trophy_id'});
				params.push({name: "username", value: GameJolt.userName});
				params.push({name: "user_token", value: GameJolt.userToken});
			case TROPHIES_REMOVE(trophy_id):
				command = "trophies";
				action = "remove-achieved";
				params.push({name: "trophy_id", value: '$trophy_id'});
				params.push({name: "username", value: GameJolt.userName});
				params.push({name: "user_token", value: GameJolt.userToken});
		}

		var urlSection:String = '/$command${action != "" ? '/$action' : ""}?game_id=${GameJolt.gameID}${[for (p in params) '&${p.name}=${p.value}'].join("")}';
		if (signed)
			urlSection = sign(urlSection).urlEncode();
		return urlSection;
	}

	static function sign(daUrl:String):String {
		var urlToEncode:String = daUrl + GameJolt.gameKey;
		return '$daUrl&signature=${GameJolt.usingMd5 ? haxe.crypto.Md5.encode(urlToEncode) : haxe.crypto.Sha1.encode(urlToEncode)}';
	}
}