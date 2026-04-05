#Requires AutoHotkey v2.0
; MindMeister + Chrome — v8
;
; v7 → v8 改進：
;   ✔ 保留：攔截右 Shift，不讓 MindMeister 收到 → 防止觸發 Add Media
;   ✔ 保留：右 Shift 單獨按下放開 → 微軟輸入法切換中英文
;   ✔ 新增：右 Shift 按住 + 字母 → 打出大寫英文（Shift 修飾鍵功能）
;   ✔ 新增：右 Shift + 空格 → 切換全形/半形（微軟輸入法 Shift+Space）
;
; 原理：
;   v7 在 RShift 按下瞬間送完整個 {LShift}（按＋放），然後 KeyWait 等放開
;   → RShift 持續按住期間沒有 Shift 效果 → 無法大寫、無法觸發 Shift+Space
;
;   v8 改為 RShift ↓ → {LShift Down}，RShift ↑ → {LShift Up}
;   → 整段持續期間系統都看到 LShift 被按住 → 自然支援大寫和 Shift+Space
;   → 單獨一按一放時 IME 看到完整 LShift 週期 → 仍切換中英文
;   （微軟輸入法只在 Shift 單獨按放、中間無其他按鍵時才切換中英，
;     所以 Shift+字母 或 Shift+空格 不會誤觸中英切換）

global DEBUG := false

; --- 主要模式：攔右 Shift → 改送左 Shift ---
global USE_SEND_LSHIFT_FOR_IME := true

global g_HKL_EN := 0x04090409
global g_HKL_ZH := 0x04040404
global IME_CMODE_NATIVE := 0x0001

global USE_SIMPLE_HKL_TOGGLE := false
global g_hklFlipZh := false

; v8 新增：追蹤 RShift 是否正在被重映射（防止焦點切換時 LShift 卡住）
global g_rshiftRemapped := false

; ====================================================================
; 主邏輯：在 MindMeister 視窗中攔截 RShift
; ====================================================================

#HotIf BrowserMindMeisterActive()

$RShift:: {
    hwnd := WinExist("A")
    if !hwnd
        return

    if USE_SEND_LSHIFT_FOR_IME {
        global g_rshiftRemapped := true
        SendInput("{LShift Down}")
        if DEBUG
            DebugTip("v8：RShift ↓ → LShift ↓（持續按住）")
        return
    }

    ; ===== 舊備援（USE_SEND_LSHIFT_FOR_IME = false，與 v7 相同）=====
    ; 此模式下 RShift 會被完全消費，不具備修飾鍵功能
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
        global g_hklFlipZh := !g_hklFlipZh
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

$RShift Up:: {
    ; 只在主模式（LShift 重映射）下需要處理
    ; 舊備援模式在 $RShift:: 中已用 KeyWait 處理完畢
    global g_rshiftRemapped
    if !g_rshiftRemapped
        return
    g_rshiftRemapped := false

    SendInput("{LShift Up}")
    if DEBUG
        DebugTip("v8：RShift ↑ → LShift ↑")
}

#HotIf

; ====================================================================
; 安全措施：焦點從 MindMeister 切走時若 RShift 仍被按住，
; 確保 LShift 正確放開，避免卡鍵
; ====================================================================

#HotIf g_rshiftRemapped
$RShift Up:: {
    global g_rshiftRemapped := false
    SendInput("{LShift Up}")
    if DEBUG
        DebugTip("v8：安全放開 LShift（焦點已離開 MindMeister）")
}
#HotIf

; ====================================================================
; 輔助函式
; ====================================================================

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

; 「視窗標題」= 標題列上的字（分頁標題 + 瀏覽器名），不是網址列。
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
