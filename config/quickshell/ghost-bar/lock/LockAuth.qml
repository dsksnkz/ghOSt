import QtQuick
import Quickshell.Services.Pam

QtObject {
    id: auth
    required property var context
    property string pendingResponse: ""
    property bool busy: false
    property bool authenticated: false
    property string error: ""
    signal accepted

    function submit(response) {
        if (authenticated || busy || !response.length)
            return false;
        error = "";
        if (context.active) {
            if (!context.responseRequired)
                return false;
            busy = true;
            context.respond(response);
        } else {
            pendingResponse = response;
            busy = true;
            if (!context.start()) {
                pendingResponse = "";
                busy = false;
                error = "Authentication unavailable";
                return false;
            }
        }
        return true;
    }
    function respondToPrompt() {
        if (!context.responseRequired)
            return;
        if (pendingResponse.length) {
            const response = pendingResponse;
            pendingResponse = "";
            context.respond(response);
        } else {
            busy = false;
        }
    }
    function complete(result) {
        pendingResponse = "";
        busy = false;
        if (result === PamResult.Success) {
            authenticated = true;
            accepted();
        } else {
            error = result === PamResult.Failed ? "Incorrect password" : "Authentication failed. Try again.";
        }
    }
}
