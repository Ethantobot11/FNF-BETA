package citro.object;

import citro.CitroG;
import citro.object.CitroObject;

class CitroGroup extends CitroObject
{
    public var members:Array<CitroObject>;
    public var length(get, never):Int;

    public function new(MaxSize:Int = 0) 
    {
        super();
        members = [];
        if (MaxSize > 0) {
            for (i in 0...MaxSize) {
                members.push(new CitroObject());
                members[i].exists = false;
            }
        }
    }

    public function add(Object:CitroObject):CitroObject 
    {
        if (members.indexOf(Object) == -1) {
            members.push(Object);
        }
        Object.exists = true;
        return Object;
    }

    public function remove(Object:CitroObject, Splice:Bool = false):CitroObject 
    {
        Object.exists = false;
        if (Splice) {
            members.remove(Object);
        }
        return Object;
        }

    public function recycle(ObjectClass:Class<CitroObject>):CitroObject 
    {
        for (member in members) {
            if (!member.exists) {
                member.exists = true;
                return member;
            }
        }
        var newObj = Type.createInstance(ObjectClass, []);
        return add(newObj);
    }

    public function forEach(Action:CitroObject->Void, Recurse:Bool = false):Void 
    {
        for (member in members) {
            if (member.exists) Action(member);
        }
    }

    public function countAlive():Int 
    {
        var count = 0;
        for (member in members) if (member.exists) count++;
        return count;
    }

    override public function update():Bool 
    {
        for (member in members) {
            if (member.exists && !member.isDestroyed) {
                member.update();
            }
        }
        return super.update();
    }

    inline function get_length():Int return members.length;
}
