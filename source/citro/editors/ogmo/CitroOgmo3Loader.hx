package citro.editors.ogmo;

import citro.object.CitroTilemap;
import haxe.Json;
#if sys
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;

class CitroOgmo3Loader {
    public var project:Dynamic;
    public var level:Dynamic;

    public function new(projectDataPath:String, levelDataPath:String) {
        trace("[CitroOgmo3Loader] new() START");
        var rawProjectText = "";
        var rawLevelText = "";

        #if sys
        try {
            trace("[CitroOgmo3Loader] Checking project path: " + projectDataPath);
            if (FileSystem.exists(projectDataPath)) {
                trace("[CitroOgmo3Loader] Reading project file...");
                rawProjectText = File.getContent(projectDataPath);
                trace("[CitroOgmo3Loader] Project file read successfully. Length: " + rawProjectText.length);
            } else {
                trace("Warning: Project file does not exist at: " + projectDataPath);
            }
            
            trace("[CitroOgmo3Loader] Checking level path: " + levelDataPath);
            if (FileSystem.exists(levelDataPath)) {
                trace("[CitroOgmo3Loader] Reading level file...");
                rawLevelText = File.getContent(levelDataPath);
                trace("[CitroOgmo3Loader] Level file read successfully. Length: " + rawLevelText.length);
            } else {
                trace("Warning: Level file does not exist at: " + levelDataPath);
            }
        } catch (e:Dynamic) { 
            trace("Error loading Ogmo files: " + e); 
        }
        #end

        trace("[CitroOgmo3Loader] Sanitizing JSON...");
        var projectText = sanitizeJson(rawProjectText);
        var levelText = sanitizeJson(rawLevelText);
        trace("[CitroOgmo3Loader] Sanitization done.");

        if (projectText.length > 0) {
            try { 
                trace("[CitroOgmo3Loader] Parsing project JSON...");
                project = Json.parse(projectText); 
                trace("[CitroOgmo3Loader] Project JSON parsed successfully.");
            } catch (e:Dynamic) { 
                trace("Project JSON parse error: " + e); 
                project = {}; 
            }
        } else { 
            trace("[CitroOgmo3Loader] Project text is empty.");
            project = {}; 
        }

        if (levelText.length > 0) {
            try { 
                trace("[CitroOgmo3Loader] Parsing level JSON...");
                level = Json.parse(levelText); 
                trace("[CitroOgmo3Loader] Level JSON parsed successfully.");
            } catch (e:Dynamic) { 
                trace("Level JSON parse error: " + e); 
                level = {}; 
            }
        } else { 
            trace("[CitroOgmo3Loader] Level text is empty.");
            level = {}; 
        }
        trace("[CitroOgmo3Loader] new() END");
    }

    static function getFieldTrimmed(obj:Dynamic, key:String):Dynamic {
        if (obj == null) return null;
        if (Reflect.hasField(obj, key)) return Reflect.field(obj, key);
        for (f in Reflect.fields(obj)) {
            if (f.trim() == key) return Reflect.field(obj, f);
        }
        return null;
    }

    static function sanitizeJson(json:String):String {
        if (json == null) return "";
        var buf = new StringBuf();
        for (i in 0...json.length) {
            var code = json.charCodeAt(i);
            if (code >= 32 || code == 9 || code == 10 || code == 13) {
                buf.addChar(code);
            }
        }
        return buf.toString();
    }

    public function loadTilemap(tileGraphic:String, tileLayer:String = "tiles", tileSize:Int = 16):CitroTilemap {
        trace("[CitroOgmo3Loader] loadTilemap() START");
        trace("[CitroOgmo3Loader] Getting tile layer: " + tileLayer);
        var layer = getTileLayer(level, tileLayer);
        if (layer == null) {
            trace("Warning: Tile layer '" + tileLayer + "' not found.");
            return new CitroTilemap(0, 0, tileSize);
        }
        trace("[CitroOgmo3Loader] Tile layer found.");

        trace("[CitroOgmo3Loader] Getting grid dimensions...");
        var gridCellsX:Int = Std.int(getFieldTrimmed(layer, "gridCellsX"));
        var gridCellsY:Int = Std.int(getFieldTrimmed(layer, "gridCellsY"));
        trace("[CitroOgmo3Loader] Grid dimensions: " + gridCellsX + "x" + gridCellsY);
        
        trace("[CitroOgmo3Loader] Creating CitroTilemap...");
        var tilemap = new CitroTilemap(gridCellsX, gridCellsY, tileSize);
        trace("[CitroOgmo3Loader] CitroTilemap created.");
        
        trace("[CitroOgmo3Loader] Loading graphic: " + tileGraphic);
        tilemap.loadGraphic(tileGraphic);
        trace("[CitroOgmo3Loader] Graphic loaded.");

        trace("[CitroOgmo3Loader] Getting arrayMode...");
        var arrayMode:Int = Std.int(getFieldTrimmed(layer, "arrayMode"));
        trace("[CitroOgmo3Loader] arrayMode: " + arrayMode);
        
        if (arrayMode == 0 && getFieldTrimmed(layer, "data") != null) {
            trace("[CitroOgmo3Loader] Parsing 1D data array...");
            var data:Array<Int> = cast getFieldTrimmed(layer, "data");
            if (data != null) {
                for (i in 0...data.length) {
                    tilemap.data[Math.floor(i / tilemap.widthInTiles)][i % tilemap.widthInTiles] = data[i];
                }
            }
            trace("[CitroOgmo3Loader] 1D data array parsed.");
        } else if (arrayMode == 1 && getFieldTrimmed(layer, "data2D") != null) {
            trace("[CitroOgmo3Loader] Parsing 2D data array...");
            var data2D:Array<Array<Int>> = cast getFieldTrimmed(layer, "data2D");
            if (data2D != null) {
                for (y in 0...data2D.length) {
                    for (x in 0...data2D[y].length) {
                        tilemap.data[y][x] = data2D[y][x];
                    }
                }
            }
            trace("[CitroOgmo3Loader] 2D data array parsed.");
        } else if (getFieldTrimmed(layer, "dataCSV") != null) {
            trace("[CitroOgmo3Loader] Parsing CSV data...");
            var dataCSV:String = cast getFieldTrimmed(layer, "dataCSV");
            if (dataCSV != null) tilemap.loadMapFromCSV(dataCSV, tileSize);
            trace("[CitroOgmo3Loader] CSV data parsed.");
        }

        trace("[CitroOgmo3Loader] loadTilemap() END");
        return tilemap;
    }

    public function loadEntities(entityLoadCallback:Dynamic->Void, entityLayer:String = "entities"):Void {
        trace("[CitroOgmo3Loader] loadEntities() START");
        if (level == null || !Reflect.hasField(level, "layers")) {
            trace("[CitroOgmo3Loader] No layers found.");
            return;
        }
        
        var layers:Array<Dynamic> = cast Reflect.field(level, "layers");
        var layer:Dynamic = null;
        
        for (l in layers) {
            var name:String = Std.string(getFieldTrimmed(l, "name"));
            if (name != null && name.trim() == entityLayer) {
                layer = l;
                break;
            }
        }

        if (layer != null && getFieldTrimmed(layer, "entities") != null) {
            trace("[CitroOgmo3Loader] Found entities layer, iterating...");
            var entities:Array<Dynamic> = cast getFieldTrimmed(layer, "entities");
            if (entities != null) {
                for (entity in entities) {
                    entityLoadCallback(entity);
                }
            }
            trace("[CitroOgmo3Loader] Entities iterated.");
        } else {
            trace("[CitroOgmo3Loader] No entities found in layer.");
        }
        trace("[CitroOgmo3Loader] loadEntities() END");
    }

    static function getTileLayer(data:Dynamic, name:String):Dynamic {
        if (data == null || !Reflect.hasField(data, "layers")) return null;
        var layers:Array<Dynamic> = cast Reflect.field(data, "layers");
        if (layers != null) {
            for (layer in layers) {
                var layerName:String = Std.string(getFieldTrimmed(layer, "name"));
                if (layerName != null && layerName.trim() == name) return layer;
            }
        }
        return null;
    }

    static function getEntityLayer(data:Dynamic, name:String):Dynamic {
        if (data == null || !Reflect.hasField(data, "layers")) return null;
        var layers:Array<Dynamic> = cast Reflect.field(data, "layers");
        if (layers != null) {
            for (layer in layers) {
                var layerName:String = Std.string(getFieldTrimmed(layer, "name"));
                if (layerName != null && layerName.trim() == name) return layer;
            }
        }
        return null;
    }
}
