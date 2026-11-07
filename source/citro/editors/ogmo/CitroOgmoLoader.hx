package citro.editors.ogmo;

import citro.object.CitroTilemap;
import haxe.xml.Parser;
import haxe.xml.Access;
#if sys
import sys.io.File;
import sys.FileSystem;
#end

class CitroOgmoLoader {
    public var width:Int;
    public var height:Int;
    var _xml:Xml;
    var _fastXml:Access;
    public function new(LevelData:String) {
        var str:String = "";
        #if sys
        if (FileSystem.exists(LevelData)) {
            str = File.getContent(LevelData);
        } else {
            trace("Warning: Ogmo XML file does not exist at: " + LevelData);
        }
        #else
        trace("Error: sys.FileSystem is required to load Ogmo maps on this platform.");
        #end
        if (str == "") {
            trace("Error: Could not read Ogmo XML data from: " + LevelData);
            _xml = Xml.parse('<map width="0" height="0"></map>'); 
        } else {
            _xml = Parser.parse(str);
        }
        _fastXml = new Access(_xml.firstElement());
        width = Std.parseInt(_fastXml.att.width);
        height = Std.parseInt(_fastXml.att.height);
    }

    public function loadTilemap(tileGraphic:String, tileWidth:Int = 16, tileHeight:Int = 16, tileLayer:String = "tiles"):CitroTilemap {
        var tilemap = new CitroTilemap(0, 0, tileWidth);
        var layerNode = _fastXml.node.resolve(tileLayer);
        if (layerNode == null) {
            trace("Warning: Tile layer '" + tileLayer + "' not found in XML.");
            return tilemap;
        }
        var csvData:String = layerNode.innerData;
        tilemap.loadMapFromCSV(csvData, tileWidth);
        tilemap.loadGraphic(tileGraphic);
        return tilemap;
    }

    public function loadEntities(entityLoadCallback:Dynamic->Void, entityLayer:String = "entities"):Void {
        var actors = _fastXml.node.resolve(entityLayer);
        if (actors == null) return;
        for (a in actors.elements) {
            var entityData = {};
            Reflect.setField(entityData, "name", a.name);
            for (att in a.attributes()) {
                var val = a.get(att);
                var intVal = Std.parseInt(val);
                if (intVal != null) {
                    Reflect.setField(entityData, att, intVal);
                } else {
                    var floatVal = Std.parseFloat(val);
                    if (!Math.isNaN(floatVal)) {
                        Reflect.setField(entityData, att, floatVal);
                    } else {
                        Reflect.setField(entityData, att, val);
                    }
                }
            }
            entityLoadCallback(entityData);
        }
    }
}