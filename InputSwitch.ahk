LoadKeywordsFromFile()

global currentInputMethod := "" ; Tracks the current input method state

; This function switches the input method based on the mode passed to it, only if different from current
SwitchInputMethod(mode) {
    if (currentInputMethod != mode) {
        Run, powershell.exe -ExecutionPolicy Bypass -File "SwitchLanguage.ps1" -Mode %mode%, , Hide
        currentInputMethod := mode ; Update the current input method state
    }
}

; Load keywords from keywords.txt into UserSpecifiedApps class data
LoadKeywordsFromFile() {
    global UserSpecifiedApps
    scriptDir := A_ScriptDir ; Get directory of the current script
    filePath := scriptDir . "\keywords.txt" ; Path to keywords.txt
    FileRead, fileContents, %filePath%
    if (ErrorLevel == 0) { ; Check if file read was successful
        UserSpecifiedApps.Data := StrSplit(fileContents, "`n", "`r") ; Split file contents into array by new lines
    } else {
        MsgBox, % "Failed to read keywords.txt"
    }
}

; Checks if the current window is fullscreen and focused
IsFullscreenAndFocused() {
    WinGet, activeID, ID, A
    WinGet, Style, Style, A
    ; Check if window is fullscreen (no taskbar visible)
    fullscreen := (Style & 0x800000) && !(Style & 0xC40000)
    return fullscreen
}

; Improved to check if the current window's title contains any of the specified keywords
IsUserSpecifiedApp() {
    WinGetTitle, currentTitle, A
    for index, keyword in UserSpecifiedApps {
        if InStr(currentTitle, keyword) {
            return true
        }
    }
    return false
}

SetTimer, CheckActiveWindow, 500
return

CheckActiveWindow:
    if (IsFullscreenAndFocused() || IsUserSpecifiedApp()) {
        SwitchInputMethod("English")
    } else {
        SwitchInputMethod("Chinese")
    }
return

^!p:: ; Ctrl + Alt + P
    loopActive := false
    SetTimer, CheckActiveWindow, Off
    SwitchInputMethod("Restore")
    Sleep, 3000
    ExitApp
return

class UserSpecifiedApps
{
    static Data := []

    _NewEnum()
    {
        return new CEnumerator(this.Data)
    }
}

class CEnumerator
{
    __New(Object)
    {
        this.Object := Object
        this.first := true
        ; Cache for speed. Useful if custom MaxIndex() functions have poor performance.
        ; In return, that means that no key-value pairs may be inserted during iteration or the range will become invalid.
        this.ObjMaxIndex := Object.MaxIndex()
    }

    Next(ByRef key, ByRef value)
    {
        if (this.first)
        {
            this.Remove("first")
            key := 1
        }
        else
            key ++
        if (key <= this.ObjMaxIndex)
            value := this.Object[key]
        else
            key := ""
        return key != ""
    }
}