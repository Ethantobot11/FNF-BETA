package;

import citro.CitroG;
import citro.state.CitroState;
import citro.object.CitroSprite;
import citro.object.CitroAnimate;
import citro.object.CitroText;
import citro.math.CitroMath;
import citro.backend.CitroColor;
import citro.backend.CitroTween;
import haxe3ds.services.HID;
import haxe3ds.services.HID.HIDKey;

import cpp.UInt32;

using StringTools;

@:headerInclude("3ds.h")
class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.6.3';
	public static var curSelected:Int = 0;
	var gjHintText:CitroText;

	var menuItems:Array<MenuOption> = [];
	
	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		#if ACHIEVEMENTS_ALLOWED 'awards', #end
		'credits',
		#if !switch 'donate', #end
		'options'
	];

	var magenta:CitroSprite;
	var camFollowX:Float = 0;
	var camFollowY:Float = 0;
	var targetCamX:Float = 0;
	var targetCamY:Float = 0;
	var debugKeys:Array<UInt32>;

	override function create():Void
	{
		#if MODS_ALLOWED
		Paths.pushGlobalMods();
		#end
		WeekData.loadTheFirstEnabledMod();

		/*if (!TitleState.initialized) {
			SoundPlayer.preload(Paths.music('freakyMenu'));
			SoundPlayer.playSound(Paths.music('freakyMenu'));
		}*/

		loadTrophies();

		unlockTrophy(313080);
		unlockTrophy(313096);

		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		persistentUpdate = true;
		persistentDraw = true;

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		
		var bg:CitroSprite = new CitroSprite(-80, 0);
        bg.loadGraphic(Paths.image('menuBG'));
		bg.scale.set(0.35, 0.35);
		bg.screenCenter();
		CitroG.state.members.push(bg);

		magenta = new CitroSprite(-80, 0);
        magenta.loadGraphic(Paths.image('menuBG'));
		magenta.scale.set(0.35, 0.35);
		magenta.screenCenter();
		magenta.visible = false;
		magenta.color = 0xFFfd719b;
		CitroG.state.members.push(magenta);

		var scale:Float = 0.35; // Scaled for 3DS

		for (i in 0...optionShit.length)
		{
			var offset:Float = 40 - (Math.max(optionShit.length, 4) - 4) * 20;
			var menuItem:MenuOption = new MenuOption(Paths.cea('mainmenu/menu_' + optionShit[i]));
			menuItem.id = i;
			menuItem.x = 0;
			menuItem.y = (i * 55) + offset;
			menuItem.scale.set(scale, scale);
			menuItem.play('idle');
			menuItem.screenCenter(X);
			
			var scr:Float = (optionShit.length - 4) * 0.05;
			if(optionShit.length < 6) scr = 0;
			
			menuItems.push(menuItem);
			CitroG.state.members.push(menuItem);
		}

		var versionShit:CitroText = new CitroText(5, 240 - 15, "Psych v" + psychEngineVersion);
		versionShit.alignment = LEFT;
		versionShit.scale.set(0.4, 0.4);
		CitroG.state.members.push(versionShit);
		
		var versionShit2:CitroText = new CitroText(5, 240 - 6, "FNF v" + psychEngineVersion);
		versionShit2.alignment = LEFT;
		versionShit2.scale.set(0.4, 0.4);
		CitroG.state.members.push(versionShit2);

		gjHintText = new CitroText(0, 210, "Press [L] for GameJolt Login");
		gjHintText.alignment = CENTER;
		gjHintText.screenCenter(X);
		gjHintText.color = CitroColor.GRAY;
		CitroG.state.members.push(gjHintText);

		changeItem();

		super.create();
	}

	var selectedSomethin:Bool = false;

	override function update(delta:Int):Void
	{
		var elapsed:Float = delta / 1000.0;

		var lerpVal:Float = CitroMath.clamp(elapsed * 7.5, 0, 1);
		camFollowX = CitroMath.lerp(camFollowX, targetCamX, lerpVal);
		camFollowY = CitroMath.lerp(camFollowY, targetCamY, lerpVal);

		for (item in menuItems) {
            item.x = item.x - (camFollowX - CitroG.WIDTH / 2) * 0.05;
            item.y = item.y - (camFollowY - CitroG.HEIGHT / 2) * 0.05;
		}

		if (HID.keyPressed(HIDKey.L)) {
				MusicBeatState.switchState(new GameJoltLoginState());
				return;
		}

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
			{
				SoundPlayer.playSound(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_DOWN_P)
			{
				SoundPlayer.playSound(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				SoundPlayer.playSound(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				if (optionShit[curSelected] == 'donate')
				{
					// CitroG.openURL('https://ninja-muffin24.itch.io/funkin');
				}
				else
				{
					selectedSomethin = true;
					SoundPlayer.playSound(Paths.sound('confirmMenu'));

					if(ClientPrefs.flashing) {
						var props = new Map<String, Float>();
						props.set("alpha", 0);
						CitroTween.tweenObject(magenta, props, 0.15, {
							onComplete: function() {
								magenta.alpha = 1;
							}
						});
					}

					for (spr in menuItems)
					{
						if (curSelected != spr.id)
						{
							var props = new Map<String, Float>();
							props.set("alpha", 0);
							CitroTween.tweenObject(spr, props, 0.4, { 
                            onComplete: function() { 
                            spr.visible = false; } 
                            });
						}
						else
						{
							var props = new Map<String, Float>();
							props.set("alpha", 0);
							CitroTween.tweenObject(spr, props, 0.06, {
								onComplete: function() {
									spr.alpha = 1;
									var daChoice:String = optionShit[curSelected];
									switch (daChoice)
									{
										case 'story_mode':
											MusicBeatState.switchState(new StoryMenuState());
										case 'freeplay':
											MusicBeatState.switchState(new FreeplayState());
										#if MODS_ALLOWED
										case 'mods':
											MusicBeatState.switchState(new ModsMenuState());
										#end
										case 'awards':
											//MusicBeatState.switchState(new AchievementsMenuState());
										case 'credits':
											MusicBeatState.switchState(new CreditsState());
										case 'options':
											LoadingState.loadAndSwitchState(new options.OptionsState());
									}
								}
							});
						}
					}
				}
			}
			#if desktop
			else if (FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;
				//MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(delta);

		for (spr in menuItems) {
			spr.screenCenter(X);
		}
	}

	function changeItem(huh:Int = 0):Void
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		for (spr in menuItems)
		{
			spr.play('idle');
			if (spr.id == curSelected)
			{
				spr.play('selected');
				var add:Float = 0;
				if(menuItems.length > 4) {
					add = menuItems.length * 3;
				}
				targetCamX = spr.x + (spr.width * spr.scale.x) / 2;
				targetCamY = spr.y + (spr.height * spr.scale.y) / 2 - add;
			}
		}
	}
}

class MenuOption extends CitroAnimate
{
	public var id:Int = 0;
	
	public function new(ceaFile:String) {
		super(ceaFile);
	}
}
