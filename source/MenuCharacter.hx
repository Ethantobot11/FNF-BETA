package;

import citro.object.CitroAnimate;
import citro.CitroG;
import sys.io.File;
import sys.FileSystem;
import haxe.Json;

using StringTools;

typedef MenuCharacterFile = {
	var image:String;
	var scale:Float;
	var position:Array<Int>;
	var idle_anim:String;
	var confirm_anim:String;
	var flipX:Bool;
}

class MenuCharacter extends CitroAnimate
{
	public var character:String;
	public var hasConfirmAnimation:Bool = false;
	private static var DEFAULT_CHARACTER:String = 'bf';

	public function new(x:Float, character:String = 'bf')
	{
		super(""); // Dummy path, will be reloaded in changeCharacter
		this.x = x;
		this.y = 0;

		changeCharacter(character);
	}

	public function changeCharacter(?character:String = 'bf'):Void {
		if(character == null) character = '';
		if(character == this.character) return;

		this.character = character;
		this.visible = true;
		hasConfirmAnimation = false;
		this.scale.set(1, 1);

		switch(character) {
			case '':
				this.visible = false;
			default:
				var characterPath:String = 'images/menucharacters/' + character + '.json';
				var rawJson:String = null;

				#if MODS_ALLOWED
				var path:String = Paths.modFolders(characterPath);
				if (!FileSystem.exists(path)) {
					path = Paths.getPreloadPath(characterPath);
				}

				if(!FileSystem.exists(path)) {
					path = Paths.getPreloadPath('images/menucharacters/' + DEFAULT_CHARACTER + '.json');
				}
				rawJson = File.getContent(path);
				#else
				var path:String = Paths.getPreloadPath(characterPath);
				if(!FileSystem.exists(path)) {
					path = Paths.getPreloadPath('images/menucharacters/' + DEFAULT_CHARACTER + '.json');
				}
				rawJson = File.getContent(path);
				#end
				
				var charFile:MenuCharacterFile = cast Json.parse(rawJson);
				
				// Load the Citro Engine Animation file
				var ceaPath:String = Paths.cea('menucharacters/' + charFile.image);
				this.reloadCEA(ceaPath, charFile.idle_anim);

				var confirmAnim:String = charFile.confirm_anim;
				if(confirmAnim != null && confirmAnim.length > 0 && confirmAnim != charFile.idle_anim)
				{
					// We assume the .cea file has this animation defined.
					hasConfirmAnimation = true;
				}

				this.flipX = (charFile.flipX == true);

				if(charFile.scale != null && charFile.scale != 1) {
					this.scale.set(charFile.scale, charFile.scale);
				}
				
				// Apply position offset (Citro doesn't have FlxSprite's offset property)
				if(charFile.position != null && charFile.position.length >= 2) {
					this.x += charFile.position[0];
					this.y += charFile.position[1];
				}
				
				this.play(charFile.idle_anim);
		}
	}
}