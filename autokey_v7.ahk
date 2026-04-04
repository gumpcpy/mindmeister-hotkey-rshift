#Requires AutoHotkey v2.0
; MindMeister + Chrome — v6
;
; 新思路（預設 USE_SEND_LSHIFT_FOR_IME := true）：
;   右 Shift 被 $RShift 攔下，不會進瀏覽器 → MindMeister 收不到「右 Shift」就不會觸發 Add Media。
;   接著用 SendInput 送「一下左 Shift」給焦點視窗：微軟輸入法多半左/右 Shift 都能切中英，而 MindMeister 若只綁右 Shift，左 Shift 就不會彈媒體。
;
; 若送左 Shift 仍會觸發網頁快捷鍵，把 USE_SEND_LSHIFT_FOR_IME 改 false，改走下方舊版 IMM/HKL 備援（Chrome 常 himc=0，體感常不佳）。

global DEBUG := false

; --- 主要模式：攔右 Shift → 改送左 Shift（給 IME）---
global USE_SEND_LSHIFT_FOR_IME := true

global g_HKL_EN := 0x04090409
global g_HKL_ZH := 0x04040404
global IME_CMODE_NATIVE := 0x0001

global USE_SIMPLE_HKL_TOGGLE := false
global g_hklFlipZh := false

#HotIf BrowserMindMeisterActive()

$RShift:: {
    hwnd := WinExist("A")
    if !hwnd {
        KeyWait("RShift")
        return
    }

    if USE_SEND_LSHIFT_FOR_IME {
        ; 不送右 Shift；送一次左 Shift（與你習慣「用 Shift 切中英」最接近，且避開只綁 vk 右 Shift 的網頁行為）
        SendInput("{LShift}")
        if DEBUG
            DebugTip("v6：已攔 RShift，已送 SendInput {LShift}")
        KeyWait("RShift")
        return
    }

    ; ===== 舊備援：IMM → HKL（Chrome 常 himc=0）=====
    res := TryToggleImeConversion(hwnd)
    if res.ok {
        if DEBUG
            DebugTip(res.msg)
        KeyWait("RShift")
        return
    }

    pid := 0
    threadId := DllCall("GetWindowThreadProcessId", "ptr", hwnd, "uint*", &pid)
    curHkl := DllCall("GetKeyboardLayout", "uint", threadId, "ptr")

    nextHkl := 0
    hklNote := ""
    if USE_SIMPLE_HKL_TOGGLE {
        nextHkl := g_hklFlipZh ? g_HKL_ZH : g_HKL_EN
        g_hklFlipZh := !g_hklFlipZh
        hklNote := "（簡單輪替）"
    } else {
        nextHkl := ShouldUseChineseNext(curHkl) ? g_HKL_ZH : g_HKL_EN
        hklNote := "（依目前語系）"
    }

    if DEBUG
        DebugTip(res.msg "`n---`nHKL " hklNote " " FormatHkl(nextHkl))

    imeDefWnd := DllCall("imm32\ImmGetDefaultIMEWnd", "ptr", hwnd, "ptr")
    if imeDefWnd {
        try SendMessage(0x50, 0, nextHkl, , "ahk_id " imeDefWnd)
        catch {
            DllCall("ActivateKeyboardLayout", "ptr", nextHkl, "uint", 0)
        }
    } else {
        DllCall("ActivateKeyboardLayout", "ptr", nextHkl, "uint", 0)
    }

    KeyWait("RShift")
}

#HotIf

FormatHkl(hkl) {
    return Format("0x{:08X}", hkl)
}

DebugTip(s) {
    ToolTip(s)
    SetTimer(() => ToolTip(), -3500)
}

TryToggleImeConversion(hwndTop) {
    hwndImm := hwndTop
    himc := DllCall("imm32\ImmGetContext", "ptr", hwndImm, "ptr")
    tried := "top"

    if !himc {
        pid := 0
        tid := DllCall("GetWindowThreadProcessId", "ptr", hwndTop, "uint*", &pid)
        curTid := DllCall("GetCurrentThreadId")
        if tid && tid != curTid {
            DllCall("AttachThreadInput", "uint", curTid, "uint", tid, "int", 1)
            focusHwnd := DllCall("GetFocus", "ptr")
            DllCall("AttachThreadInput", "uint", curTid, "uint", tid, "int", 0)
            if focusHwnd {
                himc := DllCall("imm32\ImmGetContext", "ptr", focusHwnd, "ptr")
                if himc
                    hwndImm := focusHwnd
                tried := "top+GetFocus(0x" Format("{:X}", focusHwnd) ")"
            } else {
                tried := "top+GetFocus(0)"
            }
        }
    }

    if !himc {
        return {
            ok: false,
            msg: "IMM: himc=0（已試 " tried "）",
        }
    }

    conv := 0
    sent := 0
    ok := DllCall("imm32\ImmGetConversionStatus", "ptr", himc, "uint*", &conv, "uint*", &sent)
    if !ok {
        DllCall("imm32\ImmReleaseContext", "ptr", hwndImm, "ptr", himc)
        return { ok: false, msg: "IMM: ImmGetConversionStatus 失敗" }
    }

    newConv := conv ^ IME_CMODE_NATIVE
    ok2 := DllCall("imm32\ImmSetConversionStatus", "ptr", himc, "uint", newConv, "uint", sent)
    DllCall("imm32\ImmReleaseContext", "ptr", hwndImm, "ptr", himc)

    return { ok: ok2, msg: "IMM OK SetConversionStatus=" ok2 }
}

; 「視窗標題」= 標題列上的字（分頁標題 + 瀏覽器名），不是網址列。本函式不讀網址。
; 若分頁標題沒有 MindMeister/mindmeister（例如全在地化介面），請用 Window Spy 看實際標題後在下面加 InStr 條件。
BrowserMindMeisterActive() {
    t := WinGetTitle("A")
    if !t
        return false
    if !InStr(t, "MindMeister", false) && !InStr(t, "mindmeister", false)
        return false
    exe := StrLower(WinGetProcessName("A"))
    return exe = "chrome.exe" || exe = "msedge.exe" || exe = "brave.exe"
}

ShouldUseChineseNext(curHkl) {
    lang := curHkl & 0xFFFF
    if (lang = 0x0409)
        return true
    if (lang = 0x0404 || lang = 0x0804)
        return false
    return false
}
