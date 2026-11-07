package citro.state;

import CrashHandler;
import citro.object.CitroObject;
import citro.object.CitroText;

class CitroState {
    public static var fpsText:CitroText;
    public var members:Array<CitroObject> = [];

    public function new() {};

    public function create() {
    };

    public function update(delta:Int) {
        CrashHandler.protect(function() {
            for (member in members) {
                if (member != null && member.exists) {
                    member.update();
                }
            }
        }, null);
    }

    public function destroy() {
        for (member in members) {
            member.destroy();
        }
        members.splice(0, members.length);
    }

    function check(member:CitroObject):Bool {
        if (member == null) return true;
        if (members.indexOf(member) > -1) return true;
        return false;
    }

    public function add(member:CitroObject) {
        if (check(member)) return;
        final index:Int = members.indexOf(null);
        if (index != -1) {
            members[index] = member;
            return;
        }
        members.push(member);
    }

    public function insert(index:Int, member:CitroObject) {
        if (check(member)) return;
        if (index < members.length && members[index] == null) {
            members[index] = member;
            return;
        }
        members.insert(index, member);
    }

    public function remove(member:CitroObject, once:Bool = true) {
        while (members.remove(member) && once) {}
    }

    public function openSubstate(substate:CitroSubState) {
        if (CitroG.substate != null) {
            return;
        }
        CitroG.substate = substate;
        substate.create();
    }
}