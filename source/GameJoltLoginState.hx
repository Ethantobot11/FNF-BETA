package;

import citro.CitroG;
import citro.state.CitroState;
import citro.object.CitroSprite;
import citro.object.CitroText;
import citro.backend.CitroColor;
import citro.backend.CitroTween;
import gamejolt.GameJolt;
import gamejolt.GJRequest;
import gamejolt.types.RequestType;
import haxe3ds.services.HID;
import haxe3ds.services.HID.HIDKey;
import haxe3ds.applet.SWKBD.SWKBDHandler;
import haxe3ds.applet.SWKBD.SWKBDType;

@:headerInclude("3ds.h")
class GameJoltLoginState extends MusicBeatState
{
    var bg:CitroSprite;
    var titleText:CitroText;
    var statusText:CitroText;
    var infoText:CitroText;
    var backText:CitroText;

    var isAuthenticating:Bool = false;

    override function create():Void
    {
        super.create();

        bg = new CitroSprite().makeGraphic(400, 240, CitroColor.BLACK);
        CitroG.state.members.push(bg);

        titleText = new CitroText(0, 30, "GameJolt Login");
        titleText.alignment = CENTER;
        titleText.screenCenter(X);
        CitroG.state.members.push(titleText);

        if (CitroG.save.data.gamejolt == null) {
            CitroG.save.data.gamejolt = { username: "", token: "" };
        }

        updateStatusText();

        backText = new CitroText(0, 210, "[B] Back to MenuState");
        backText.alignment = CENTER;
        backText.screenCenter(X);
        backText.color = CitroColor.GRAY;
        CitroG.state.members.push(backText);
    }

    function updateStatusText():Void
    {
        if (statusText != null) CitroG.state.members.remove(statusText);
        if (infoText != null) CitroG.state.members.remove(infoText);

        var savedUser = CitroG.save.data.gamejolt.username;
        var savedToken = CitroG.save.data.gamejolt.token;

        if (savedUser != "" && savedToken != "") {
            statusText = new CitroText(0, 80, "Logged in as: " + savedUser);
            statusText.color = CitroColor.GREEN;
            infoText = new CitroText(0, 120, "Press A to Re-Authenticate\nPress Y to Clear Credentials\nPress B to go back");
        } else {
            statusText = new CitroText(0, 80, "Status: Not Logged In");
            statusText.color = CitroColor.RED;
            infoText = new CitroText(0, 120, "Press A to Set Credentials\nPress B to go back");
        }
        
        statusText.alignment = CENTER;
        statusText.screenCenter(X);
        infoText.alignment = CENTER;
        infoText.screenCenter(X);
        
        CitroG.state.members.push(statusText);
        CitroG.state.members.push(infoText);
    }

    override function update(delta:Int):Void
    {
        if (isAuthenticating) {
            super.update(delta);
            return;
        }

        if (controls.BACK) {
            SoundPlayer.playSound(Paths.sound('cancelMenu'));
            MusicBeatState.switchState(new MainMenuState());
        }
        else if (controls.ACCEPT) {
            SoundPlayer.playSound(Paths.sound('confirmMenu'));
            promptForCredentials();
        }
        else if (HID.keyPressed(HIDKey.Y) && CitroG.save.data.gamejolt.username != "") {
            CitroG.save.data.gamejolt.username = "";
            CitroG.save.data.gamejolt.token = "";
            CitroG.save.flush();
            
            SoundPlayer.playSound(Paths.sound('cancelMenu'));
            updateStatusText();
        }

        super.update(delta);
    }

    function promptForCredentials():Void
    {
        var usernameKeyboard = new SWKBDHandler(NORMAL, 2, 32);
        usernameKeyboard.hintText = "Enter GameJolt Username";
        usernameKeyboard.initialText = CitroG.save.data.gamejolt.username;
        usernameKeyboard.buttonData[0] = { input: "Cancel", buttonWillSubmit: false };
        usernameKeyboard.buttonData[1] = { input: "Next", buttonWillSubmit: true };
        
        var username = usernameKeyboard.display();
        
        if (username == "") {
            return; 
        }

        var tokenKeyboard = new SWKBDHandler(NORMAL, 2, 64);
        tokenKeyboard.hintText = "Enter GameJolt User Token";
        tokenKeyboard.initialText = CitroG.save.data.gamejolt.token;
        tokenKeyboard.buttonData[0] = { input: "Cancel", buttonWillSubmit: false };
        tokenKeyboard.buttonData[1] = { input: "Login", buttonWillSubmit: true };
        
        var token = tokenKeyboard.display();

        if (token == "") {
            return;
        }

        CitroG.save.data.gamejolt.username = username;
        CitroG.save.data.gamejolt.token = token;
        CitroG.save.flush();

        attemptLogin();
    }

    function attemptLogin():Void
    {
        var savedUser = CitroG.save.data.gamejolt.username;
        var savedToken = CitroG.save.data.gamejolt.token;

        isAuthenticating = true;
        statusText.text = "Status: Authenticating...";
        statusText.color = CitroColor.WHITE;

        GameJolt.userName = savedUser;
        GameJolt.userToken = savedToken;

        var req = new GJRequest(RequestType.USER_AUTH);
        
        req.onComplete = function(response) {
            if (response.success) {
                statusText.text = "Status: Login Successful!";
                statusText.color = CitroColor.GREEN;
                infoText.text = "Welcome, " + GameJolt.userName + "!\nPress B to return.";
            } else {
                statusText.text = "Status: Login Failed";
                statusText.color = CitroColor.RED;
                infoText.text = "Invalid credentials.\nPress Y to clear and try again.\nPress B to return.";
            }
            isAuthenticating = false;
        };

        req.onError = function(error) {
            statusText.text = "Status: Network Error";
            statusText.color = CitroColor.RED;
            infoText.text = "Could not connect to\nGameJolt API.\nPress B to return.";
            isAuthenticating = false;
        };

        req.send();
    }
}