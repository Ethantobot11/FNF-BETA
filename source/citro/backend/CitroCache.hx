package citro.backend;

import citro.CitroG.VoidPtr;

@:cppFileCode('
#include <cwav.h>
#include <citro2d.h>
void SUPER_FREE(void **ptr2ptr) {
    if (ptr2ptr && *ptr2ptr) {
        free(*ptr2ptr);
        *ptr2ptr = NULL;
    }
}')
class CitroCache {
    public var cache:Map<String, VoidPtr> = new Map();
    public var meta:Map<String, Int> = new Map();

    public function new() {}

    public function exists(path:String):Bool {
        return cache.exists(path);
    }

    public function get(path:String):VoidPtr {
        return cache.get(path);
    }

    public function set(path:String, ptr:VoidPtr) {
        if (cache.exists(path)) {
            freeMemory(path);
        }
        cache.set(path, ptr);
    }

    public function getMeta(path:String):Null<Int> {
        return meta.get(path);
    }

    public function setMeta(path:String, value:Int) {
        meta.set(path, value);
    }

    public function remove(path:String) {
        if (cache.exists(path)) {
            freeMemory(path);
        }
    }

    public function keyValueIterator() {
        return cache.keyValueIterator();
    }

    function freeMemory(key:String) {
        final ptr = cache[key];
        untyped __cpp__('if (!{0}) return', ptr);
        var extension = key.split(".");
        var ext = extension[extension.length - 1].toLowerCase();
        switch (ext) {
            case "t3x":
                untyped __cpp__('C2D_SpriteSheetFree((C2D_SpriteSheet){0});', ptr);
            case "bcfnt":
                untyped __cpp__('C2D_FontFree((C2D_Font){0});', ptr);
            case "cwav":
                untyped __cpp__('cwavFileFree((CWAV*){0}); free({0});', ptr);
            default:
                untyped __cpp__('SUPER_FREE((void**)&{0})', ptr);
        }
        cache.remove(key);
        meta.remove(key);
    }

    public function clear() {
        var keys = [];
        for (key in cache.keys()) {
            keys.push(key);
        }
        for (key in keys) {
            freeMemory(key);
        }
        cache.clear();
        meta.clear();
    }
}