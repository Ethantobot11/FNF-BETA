package citro.object;

import haxe.xml.Parser;
import sys.io.File;

class CitroAtlas 
{
    public var name:String;
    public var frames:Map<String, { x:Float, y:Float, w:Float, h:Float }>;
    public var texturePath:String;

    public function new(Name:String, XmlPath:String, TexturePath:String) 
    {
        name = Name;
        texturePath = TexturePath;
        frames = new Map();

        try {
            var xmlString = File.getContent(XmlPath);
            var xml = Parser.parse(xmlString);
            
            for (node in xml.elementsNamed("SubTexture")) {
                var frameName = node.get("name");
                var x = Std.parseFloat(node.get("x"));
                var y = Std.parseFloat(node.get("y"));
                var w = Std.parseFloat(node.get("width"));
                var h = Std.parseFloat(node.get("height"));
                frames.set(frameName, { x: x, y: y, w: w, h: h });
            }
        } catch (e:Dynamic) {
            trace("Failed to load atlas: " + XmlPath + " - " + e);
        }
    }

    public function getFrame(FrameName:String):{ x:Float, y:Float, w:Float, h:Float } 
    {
        return frames.get(FrameName);
    }
}
