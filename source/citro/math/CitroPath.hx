package citro.math;

import citro.object.CitroObject;

typedef PathPoint = { x:Float, y:Float }

class CitroPath
{
    public var points:Array<PathPoint>;
    public var currentNode:Int;
    public var speed:Float;
    public var active:Bool;

    public function new() 
    {
        points = [];
        currentNode = 0;
        speed = 100;
        active = false;
    }

    public function add(X:Float, Y:Float):Void 
    {
        points.push({ x: X, y: Y });
    }

    public function start(Object:CitroObject, StartNode:Int = 0):Void 
    {
        currentNode = StartNode;
        active = true;
        if (points.length > 0) {
            Object.x = points[currentNode].x;
            Object.y = points[currentNode].y;
        }
    }

    public function update(Object:CitroObject, DeltaTime:Float):Void 
    {
        if (!active || points.length == 0) return;

        var target = points[currentNode];
        var dx = target.x - Object.x;
        var dy = target.y - Object.y;
        var distance = Math.sqrt(dx * dx + dy * dy);

        if (distance < 2) {
            Object.x = target.x;
            Object.y = target.y;
            currentNode++;
            if (currentNode >= points.length) {
                active = false;
            }
        } else {
            var moveDistance = speed * (DeltaTime / 1000.0);
            var ratio = moveDistance / distance;
            Object.x += dx * ratio;
            Object.y += dy * ratio;
        }
    }
}
