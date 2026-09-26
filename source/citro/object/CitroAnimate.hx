package citro.object;

#if (!wiiu || !cafe)

import sys.io.File;
import citro.object.CitroSprite;
import citro.object.CitroObject;
import citro.CitroG;

using StringTools;

typedef CitroFrame = {
    var srcX:Float;
    var srcY:Float;
    var srcWidth:Float;
    var srcHeight:Float;
    var offsetX:Float;
    var offsetY:Float;
    var frameWidth:Float;
    var frameHeight:Float;
}

class CitroAnimate extends CitroObject {
    var timeLeft:Float = 0;
    var frames:Map<String, CitroFrame>;
    var atlasSprite:CitroSprite = null;
    var atlasPath:String = "";

    public var framerate:Float = 24;
    public var frame:Int = 0;
    public var curAnim:String = "";
    public var finished:Bool = false;
    public var looped:Bool = false;

    public function new(ceaFile:String, defaultAnim:String = "") {
        super();
        frames = new Map();
        loadCEA(ceaFile, defaultAnim);
    }

    function loadCEA(ceaFile:String, defaultAnim:String):Void {
        final file:String = File.getContent(ceaFile);
        var dir:String = ceaFile.substr(0, ceaFile.lastIndexOf("/"));
        if (dir == "") dir = ".";

        if (file != "") {
            var firstAnimFound:String = "";
            for (line in file.split("\n")) {
                line = line.trim();
                if (line == "" || line.startsWith("#")) continue; 
                
                final row:Array<String> = line.split("?");
                if (row.length < 10) continue;

                final atlasFile:String = row[0].trim();
                final srcX:Float = Std.parseFloat(row[1]);
                final srcY:Float = Std.parseFloat(row[2]);
                final srcWidth:Float = Std.parseFloat(row[3]);
                final srcHeight:Float = Std.parseFloat(row[4]);
                final offsetX:Float = Std.parseFloat(row[5]);
                final offsetY:Float = Std.parseFloat(row[6]);
                final frameWidth:Float = Std.parseFloat(row[7]);
                final frameHeight:Float = Std.parseFloat(row[8]);
                final fullKey:String = row[9].trim();

                if (atlasPath == "") {
                    atlasPath = '$dir/$atlasFile';
                    atlasSprite = new CitroSprite();
                    if (!atlasSprite.loadGraphic(atlasPath)) {
                        atlasSprite.destroy();
                        atlasSprite = null;
                        return; 
                    }
                }

                final dashIndex:Int = fullKey.lastIndexOf("-");
                final animName:String = dashIndex != -1 ? fullKey.substr(0, dashIndex) : fullKey;
                if (firstAnimFound == "") firstAnimFound = animName;

                frames.set(fullKey, {
                    srcX: srcX, srcY: srcY, srcWidth: srcWidth, srcHeight: srcHeight,
                    offsetX: offsetX, offsetY: offsetY, frameWidth: frameWidth, frameHeight: frameHeight
                });
            }
            if (defaultAnim == "") defaultAnim = firstAnimFound;
        }
        play(defaultAnim);
    }

    public function play(animation:String):Bool {
        if (isDestroyed || atlasSprite == null) return false;
        final animFormat:String = '$animation-0';
        if (frames.exists(animFormat)) {
            timeLeft = 1000 / framerate;
            finished = false;
            curAnim = animation;
            frame = 0;
            final frm = frames[animFormat];
            width = frm.frameWidth;
            height = frm.frameHeight;
            return true;
        }
        return false;
    }

    public function reloadCEA(ceaFile:String, defaultAnim:String):Void {
        if (atlasSprite != null) { atlasSprite.destroy(); atlasSprite = null; }
        frames = new Map();
        atlasPath = "";
        loadCEA(ceaFile, defaultAnim);
    }

    inline function format():String return '${curAnim}-$frame';

    override function update():Bool {
        if (isDestroyed || atlasSprite == null) return false;

        if (!visible || alpha <= 0) return false;

        if ((timeLeft -= CitroG.deltaTime) < 1) {
            timeLeft = 1000 / framerate;
            frame++;
            if (!frames.exists(format())) {
                finished = true;
                frame = looped ? 0 : frame - 1;
            } else {
                final frm = frames[format()];
                width = frm.frameWidth;
                height = frm.frameHeight;
            }
        }

        if (frames.exists(format()) && visible) {
            final frm = frames[format()];
            
            width = frm.frameWidth;
            height = frm.frameHeight;
            atlasSprite.x = x - frm.offsetX;
            atlasSprite.y = y - frm.offsetY;
            atlasSprite.scale.x = scale.x;
            atlasSprite.scale.y = scale.y;
            atlasSprite.alpha = alpha;
            atlasSprite.color = color;
            atlasSprite.setSourceRect(frm.srcX, frm.srcY, frm.srcWidth, frm.srcHeight);
            
            return atlasSprite.update();
        }

        return false;
    }

    override function destroy() {
        if (atlasSprite != null) { atlasSprite.destroy(); atlasSprite = null; }
        frames = new Map();
        super.destroy();
    }
}
#end
