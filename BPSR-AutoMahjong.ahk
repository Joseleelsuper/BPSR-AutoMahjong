#Requires AutoHotkey v2.0
#SingleInstance Force

; ==============================================
;  AutoMahjong
; ----------------------------------------------
;   @name: BPSR-AutoMahjong.ahk
;   @description: Automatiza cola, aceptar partida, bot y cierre de pantalla final.
;   @author: José Gallardo
;   @version: 1.0.0
;   @date: 2026-05-30
;   @use
;       - Pulsa F9 para activar/desactivar la automatizacion.
;       - Pulsa F10 para detener el script completamente.
;       - El jugador debe estar cerca del NPC de Mahjong cuando se quiera iniciar cola.
; ==============================================

CoordMode("Pixel", "Screen")
CoordMode("Mouse", "Screen")

global Config := Map()
global State := Map()

; ============================
;  Inicializacion
; ============================
Init() {
    global Config

    Config["Base"] := { w: 1920, h: 1080 }
    Config["TimerInterval"] := 100
    Config["Tolerance"] := {
        primary: 25
    }

    Config["Timings"] := Map()
    Config["Timings"]["clickDelay"] := 80
    Config["Timings"]["afterAction"] := 600
    Config["Timings"]["afterAccept"] := 4500
    Config["Timings"]["afterQueueStart"] := 1200
    Config["Timings"]["botOptionsDelay"] := 5000
    Config["Timings"]["botClickDelay"] := 150
    Config["Timings"]["afterFinalConfirm"] := 5000
    Config["Timings"]["finalConfirmRetry"] := 10000
    Config["Timings"]["queueRetry"] := 20000

    Config["GameWindowExecutables"] := [
        "BPSR_STEAM.exe",
        "BPSR_EPIC.exe",
        "BPSR.exe"
    ]

    Config["PointsBase"] := Map()
    DefineBasePoints()

    Config["Signatures"] := Map()
    DefineSignatures()

    Config["LoggingEnabled"] := true
    Config["LogPath"] := A_ScriptDir . "\BPSR-AutoMahjong.log"

    ResetRuntimeState(false)
    RefreshGameWindow()

    Log("INFO", "Init completado")
}

DefineBasePoints() {
    global Config

    points := Config["PointsBase"]

    ; Inicio / lobby
    points["startPromptBg"] := { x: 1530, y: 565 }
    points["startPromptIcon"] := { x: 1420, y: 560 }
    points["startPromptLeft"] := { x: 1380, y: 560 }

    ; Aviso superior derecho de matchmaking
    points["matchingBoxLeft"] := { x: 1495, y: 20 }
    points["matchingBoxMid"] := { x: 1620, y: 20 }
    points["matchingTimer"] := { x: 1770, y: 28 }

    ; Match found
    points["acceptButton"] := { x: 1610, y: 925 }
    points["acceptBottom"] := { x: 1720, y: 955 }

    ; Opciones del bot en la mesa
    points["botWin"] := { x: 35, y: 625 }
    points["botCall"] := { x: 35, y: 725 }
    points["botDiscard"] := { x: 35, y: 790 }
    points["activeHandLeft"] := { x: 390, y: 1000 }
    points["activeHandMid"] := { x: 960, y: 1000 }
    points["activeTableCenter"] := { x: 960, y: 540 }
    points["activeLeftPanel"] := { x: 35, y: 565 }

    ; Confirm central: se detecta con varios pixeles para no confundirlo con fichas.
    points["confirmCenterClick"] := { x: 870, y: 1000 }
    points["confirmCenterTop"] := { x: 960, y: 960 }
    points["confirmCenterText"] := { x: 960, y: 993 }
    points["confirmCenterRight"] := { x: 1095, y: 1000 }
    points["confirmCenterBottom"] := { x: 960, y: 1020 }

    ; Confirm derecho de la segunda pantalla de resultado de ronda.
    ; Tambien cubre el primer confirm cuando la ronda termina en empate.
    points["confirmRightClick"] := { x: 1610, y: 985 }
    points["confirmRightInnerLeft"] := { x: 1580, y: 985 }
    points["confirmRightInnerTop"] := { x: 1720, y: 965 }
    points["confirmRightInnerRight"] := { x: 1820, y: 985 }
    points["confirmRightText"] := { x: 1720, y: 993 }
    points["confirmRightBottom"] := { x: 1720, y: 1020 }

    ; Pantalla final
    points["finalTitle"] := { x: 960, y: 165 }
    points["finalTitleGlow"] := { x: 960, y: 205 }
    points["finalTopBg"] := { x: 960, y: 65 }
}

DefineSignatures() {
    global Config

    signatures := Config["Signatures"]

    signatures["matching"] := [{ point: "matchingBoxLeft", color: 0xF7A265, tolerance: 45 }, { point: "matchingBoxMid",
        color: 0xF19E64, tolerance: 45 }, { point: "matchingTimer", color: 0xDD9863, tolerance: 55 }
    ]

    signatures["startPrompt"] := [{ point: "startPromptIcon", color: 0xFEFEFE, tolerance: 35 }, { point: "startPromptLeft",
        color: 0xE4E4E3, tolerance: 45 }, { point: "startPromptBg", color: 0x110908, tolerance: 25 }
    ]

    signatures["acceptGame"] := [{ point: "acceptButton", color: 0xE8E8E8, tolerance: 30 }, { point: "acceptBottom",
        color: 0xE8E8E8, tolerance: 30 }]

    signatures["centerConfirm"] := [{ point: "confirmCenterTop", color: 0xE8E8E8, tolerance: 35 }, { point: "confirmCenterText",
        color: 0xE8E8E8, tolerance: 35 }, { point: "confirmCenterRight", color: 0xC8C8C8, tolerance: 35 }, { point: "confirmCenterBottom",
            color: 0xE8E8E8, tolerance: 35 }
    ]

    signatures["rightConfirm"] := [{ point: "confirmRightClick", color: 0xE8E8E8, tolerance: 55 }, { point: "confirmRightInnerLeft",
        color: 0xE8E8E8, tolerance: 55 }, { point: "confirmRightInnerTop", color: 0xE8E8E8, tolerance: 55 }, { point: "confirmRightInnerRight",
            color: 0xE8E8E8, tolerance: 55 }, { point: "confirmRightText", color: 0xE8E8E8, tolerance: 55 }, { point: "confirmRightBottom",
                color: 0xE8E8E8, tolerance: 55 }
    ]

    signatures["finalScreen"] := [{ point: "finalTitle", color: 0xFFFFFF, tolerance: 30 }, { point: "finalTitleGlow",
        color: 0x747475, tolerance: 55 }, { point: "finalTopBg", color: 0x111217, tolerance: 35 }, { point: "confirmCenterTop",
            color: 0xE8E8E8, tolerance: 35 }, { point: "confirmCenterText", color: 0xE8E8E8, tolerance: 35 }
    ]

    signatures["activeRound"] := [{ point: "botWin", color: 0x221E1A, tolerance: 45 }, { point: "botCall", color: 0x41403D,
        tolerance: 45 }, { point: "botDiscard", color: 0x24201B, tolerance: 45 }, { point: "activeHandLeft", color: 0xEAEAEA,
            tolerance: 55 }, { point: "activeHandMid", color: 0xCBCCCC, tolerance: 65 }, { point: "activeTableCenter",
                color: 0xD0CFB7, tolerance: 60 }, { point: "activeLeftPanel", color: 0x4E7071, tolerance: 70 }
    ]
}

ResetRuntimeState(keepToggle := true) {
    global State

    currentToggle := keepToggle && State.Has("toggle") ? State["toggle"] : false
    State.Clear()
    State["toggle"] := currentToggle
    State["busy"] := false
    State["lastActionTime"] := 0
    State["holdUntil"] := 0
    State["screen"] := "init"
    State["queueRequested"] := false
    State["queueRequestedAt"] := 0
    State["roundDetectedAt"] := 0
    State["botOptionsClicked"] := false
    State["finalConfirmClicked"] := false
    State["finalConfirmAt"] := 0
}

; ============================
;  Ventana y Escalado
; ============================
RefreshGameWindow() {
    global Config

    DetectGameWindow()
    Config["Scale"] := {
        x: (Config["GameWindow"].w + 0.0) / Config["Base"].w,
        y: (Config["GameWindow"].h + 0.0) / Config["Base"].h
    }

    ratio := (Config["GameWindow"].w + 0.0) / Max(Config["GameWindow"].h, 1)
    if (Abs(ratio - (16 / 9)) > 0.04) {
        Log("WARN", "La ventana no parece 16:9: ratio=" . Round(ratio, 3))
    }

    Config["Points"] := Map()
    RebuildScaledPoints()

    Log("INFO", "Ventana: " . Config["GameWindow"].w . "x" . Config["GameWindow"].h
        . " @ (" . Config["GameWindow"].x . "," . Config["GameWindow"].y . ")"
        . " | Escala: " . Round(Config["Scale"].x, 3) . "x" . Round(Config["Scale"].y, 3)
        . " | exe=" . Config["GameWindow"].exe)
}

DetectGameWindow() {
    global Config

    hwnd := 0
    detectedExe := ""

    for _, exeName in Config["GameWindowExecutables"] {
        try {
            hwnd := WinGetID("ahk_exe " . exeName)
            if (hwnd) {
                detectedExe := exeName
                break
            }
        }
    }

    if (hwnd) {
        rect := Buffer(16, 0)
        DllCall("GetClientRect", "Ptr", hwnd, "Ptr", rect)
        clientW := NumGet(rect, 8, "Int")
        clientH := NumGet(rect, 12, "Int")

        point := Buffer(8, 0)
        DllCall("ClientToScreen", "Ptr", hwnd, "Ptr", point)
        clientX := NumGet(point, 0, "Int")
        clientY := NumGet(point, 4, "Int")

        Config["GameWindow"] := {
            x: clientX,
            y: clientY,
            w: clientW,
            h: clientH,
            hwnd: hwnd,
            exe: detectedExe
        }
        return
    }

    Config["GameWindow"] := {
        x: 0,
        y: 0,
        w: A_ScreenWidth,
        h: A_ScreenHeight,
        hwnd: 0,
        exe: "pantalla-completa-fallback"
    }
    Log("WARN", "No se detecto ventana del juego. Usando pantalla completa.")
}

RebuildScaledPoints() {
    global Config

    for pointName, basePt in Config["PointsBase"] {
        Config["Points"][pointName] := {
            x: Round(basePt.x * Config["Scale"].x) + Config["GameWindow"].x,
            y: Round(basePt.y * Config["Scale"].y) + Config["GameWindow"].y
        }
    }
}

; ============================
;  Inicializacion y Hotkeys
; ============================
Init()
OnExit(OnExitHandler)

F9:: ToggleAutomation()
F10:: ExitScript()

ToggleAutomation() {
    global Config, State

    State["toggle"] := !State["toggle"]
    if (State["toggle"]) {
        ResetRuntimeState(true)
        RefreshGameWindow()
        Log("INFO", "Script ACTIVADO -> timer " . Config["TimerInterval"] . " ms")
        SetTimer(CheckLogic, Config["TimerInterval"])
        return
    }

    Log("INFO", "Script DESACTIVADO")
    SetTimer(CheckLogic, 0)
    SafeCleanup()
}

; ============================
;  Bucle Principal
; ============================
CheckLogic() {
    global State

    if (!State["toggle"] || State["busy"]) {
        return
    }

    State["busy"] := true
    try {
        RunAutomationCycle()
    } catch as e {
        Log("ERROR", "CheckLogic fallo: " . e.Message)
    }
    State["busy"] := false
}

RunAutomationCycle() {
    global State

    now := A_TickCount
    if (now < State["holdUntil"]) {
        return
    }

    if (IsAcceptGameScreen()) {
        ResetFinalConfirmState()
        SetScreen("accept_game")
        ClickAcceptGame()
        return
    }

    if (IsMatchingActive()) {
        ResetFinalConfirmState()
        SetScreen("matching")
        State["queueRequested"] := true
        if (!State["queueRequestedAt"]) {
            State["queueRequestedAt"] := now
        }
        return
    }

    if (IsFinalScreen()) {
        ObserveFinalScreen()
        return
    }

    if (IsActiveRoundScreen()) {
        ResetFinalConfirmState()
        SetScreen("active_round")
        HandleActiveRound()
        return
    }

    if (IsStartPromptVisible()) {
        ResetFinalConfirmState()
        SetScreen("start_prompt")
        if (ShouldStartQueue()) {
            StartQueue()
        }
        return
    }

    if (IsCenterResultScreen()) {
        ResetFinalConfirmState()
        ObserveRoundResultScreen("round_result_center")
        return
    }

    if (IsRightResultScreen()) {
        ResetFinalConfirmState()
        ObserveRoundResultScreen("round_result_right")
        return
    }

    SetScreen("unknown")
}

; ============================
;  Acciones de Mahjong
; ============================
ClickAcceptGame() {
    global Config, State

    if (!CanAct()) {
        return
    }

    ClickPoint("acceptButton")
    UpdateActionTime()
    State["holdUntil"] := A_TickCount + Config["Timings"]["afterAccept"]
    ResetRoundState()
    Log("ACTION", "Partida aceptada")
}

StartQueue() {
    global Config, State

    if (!CanAct()) {
        return
    }

    ActivateGameWindow()
    Send("{f down}")
    Sleep(60)
    Send("{f up}")
    UpdateActionTime()
    State["queueRequested"] := true
    State["queueRequestedAt"] := A_TickCount
    State["holdUntil"] := A_TickCount + Config["Timings"]["afterQueueStart"]
    Log("ACTION", "Solicitud de cola enviada con F")
}

ObserveRoundResultScreen(screenName) {
    SetScreen(screenName)
    ResetRoundState()
}

ObserveFinalScreen() {
    global Config, State

    SetScreen("final_screen")
    ResetRoundState()

    if (!State["finalConfirmClicked"]
        || (A_TickCount - State["finalConfirmAt"]) >= Config["Timings"]["finalConfirmRetry"]) {
        ClickFinalConfirm()
    }
}

ClickFinalConfirm() {
    global Config, State

    if (!CanAct()) {
        return
    }

    ClickPoint("confirmCenterClick")
    UpdateActionTime()
    State["holdUntil"] := A_TickCount + Config["Timings"]["afterFinalConfirm"]
    State["finalConfirmClicked"] := true
    State["finalConfirmAt"] := A_TickCount
    ResetRoundState()
    Log("ACTION", "Final Round confirmado; esperando prompt F para nueva cola")
}

ResetFinalConfirmState() {
    global State

    State["finalConfirmClicked"] := false
    State["finalConfirmAt"] := 0
}

ResetRoundState() {
    global State

    State["queueRequested"] := false
    State["queueRequestedAt"] := 0
    State["roundDetectedAt"] := 0
    State["botOptionsClicked"] := false
}

HandleActiveRound() {
    global Config, State

    now := A_TickCount
    State["queueRequested"] := false
    State["queueRequestedAt"] := 0

    if (!State["roundDetectedAt"]) {
        State["roundDetectedAt"] := now
        State["botOptionsClicked"] := false
        Log("STATE", "Ronda detectada; esperando " . Config["Timings"]["botOptionsDelay"] . " ms antes de activar bot")
        return
    }

    if (State["botOptionsClicked"]) {
        return
    }

    if ((now - State["roundDetectedAt"]) < Config["Timings"]["botOptionsDelay"]) {
        return
    }

    if (!CanAct()) {
        return
    }

    ClickPoint("botWin")
    Sleep(Config["Timings"]["botClickDelay"])
    ClickPoint("botCall")
    Sleep(Config["Timings"]["botClickDelay"])
    ClickPoint("botDiscard")
    UpdateActionTime()

    State["botOptionsClicked"] := true
    State["holdUntil"] := A_TickCount + Config["Timings"]["afterAction"]
    Log("ACTION", "Opciones del bot activadas una vez para la ronda")
}

ShouldStartQueue() {
    global Config, State

    if (!State["queueRequested"]) {
        return true
    }

    return (A_TickCount - State["queueRequestedAt"]) >= Config["Timings"]["queueRetry"]
}

; ============================
;  Detecciones de Pantalla
; ============================
IsMatchingActive() {
    return CheckSignature("matching", 2)
}

IsStartPromptVisible() {
    return CheckSignature("startPrompt", 2)
}

IsAcceptGameScreen() {
    return CheckSignature("acceptGame", 2)
}

IsCenterResultScreen() {
    return CheckSignature("centerConfirm", 3)
}

IsRightResultScreen() {
    return CheckSignature("rightConfirm", 3)
}

IsFinalScreen() {
    return CheckSignature("finalScreen", 4)
}

IsActiveRoundScreen() {
    ; La ficha inferior evita confundir overlays de resultado con una ronda jugable.
    return CheckColorAtPoint("activeHandLeft", 0xEAEAEA, 55)
    && CheckSignature("activeRound", 4)
}

CheckSignature(signatureName, minMatches := 0) {
    global Config

    if (!Config["Signatures"].Has(signatureName)) {
        Log("ERROR", "Firma inexistente: " . signatureName)
        return false
    }

    samples := Config["Signatures"][signatureName]
    required := minMatches > 0 ? minMatches : samples.Length
    matches := 0

    for _, sample in samples {
        tolerance := sample.HasOwnProp("tolerance") ? sample.tolerance : Config["Tolerance"]["primary"]
        if (CheckColorAtPoint(sample.point, sample.color, tolerance)) {
            matches += 1
        }
    }

    return matches >= required
}

; ============================
;  Utilidades
; ============================
ActivateGameWindow() {
    global Config

    hwnd := Config["GameWindow"].hwnd
    if (!hwnd) {
        return
    }

    try {
        WinActivate("ahk_id " . hwnd)
        Sleep(50)
    } catch as e {
        Log("WARN", "No se pudo activar la ventana: " . e.Message)
    }
}

GetColorAtXY(x, y) {
    try {
        return PixelGetColor(x, y, "RGB")
    } catch as e {
        Log("ERROR", "PixelGetColor fallo en " . x . "," . y . ": " . e.Message)
        return 0
    }
}

GetColorAtPoint(pointName) {
    global Config

    if (!Config["Points"].Has(pointName)) {
        Log("ERROR", "Punto inexistente: " . pointName)
        return 0
    }

    pt := Config["Points"][pointName]
    return GetColorAtXY(pt.x, pt.y)
}

ColorCloseEnough(color1, color2, tolerance := 10) {
    c1r := (color1 >> 16) & 0xFF
    c1g := (color1 >> 8) & 0xFF
    c1b := color1 & 0xFF
    c2r := (color2 >> 16) & 0xFF
    c2g := (color2 >> 8) & 0xFF
    c2b := color2 & 0xFF

    return (Abs(c1r - c2r) <= tolerance)
    && (Abs(c1g - c2g) <= tolerance)
    && (Abs(c1b - c2b) <= tolerance)
}

CheckColorAtPoint(pointName, targetColor, tolerance := -1) {
    global Config

    if (tolerance = -1) {
        tolerance := Config["Tolerance"]["primary"]
    }

    currentColor := GetColorAtPoint(pointName)
    return ColorCloseEnough(currentColor, targetColor, tolerance)
}

ClickPoint(pointName) {
    global Config

    if (!Config["Points"].Has(pointName)) {
        Log("ERROR", "No se puede hacer click: punto inexistente " . pointName)
        return false
    }

    ActivateGameWindow()
    pt := Config["Points"][pointName]
    Click(pt.x . " " . pt.y)
    Sleep(Config["Timings"]["clickDelay"])
    return true
}

CanAct(cooldownMs := -1) {
    global State

    if (A_TickCount < State["holdUntil"]) {
        return false
    }

    return CheckCooldown(cooldownMs)
}

CheckCooldown(cooldownMs := -1) {
    global Config, State

    if (cooldownMs = -1) {
        cooldownMs := Config["Timings"]["afterAction"]
    }

    return (A_TickCount - State["lastActionTime"]) >= cooldownMs
}

UpdateActionTime() {
    global State
    State["lastActionTime"] := A_TickCount
}

SetScreen(screenName) {
    global State

    if (State["screen"] = screenName) {
        return
    }

    State["screen"] := screenName
    Log("SCREEN", screenName)
}

SafeCleanup() {
    global State

    SetTimer(CheckLogic, 0)
    State["busy"] := false
    State["holdUntil"] := 0
    Log("INFO", "SafeCleanup completado")
}

ExitScript() {
    global State

    Log("EXIT", "F10 presionado -> saliendo")
    State["toggle"] := false
    SafeCleanup()
    ExitApp
}

Log(type, msg) {
    global Config

    if (!Config.Has("LoggingEnabled") || !Config["LoggingEnabled"]) {
        return
    }

    type := StrUpper(type)
    stamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    line := "[" . stamp . "] [" . type . "] " . msg . "`r`n"

    try {
        FileAppend(line, Config["LogPath"], "UTF-8")
    } catch as e {
        ; No detener la automatizacion si el log esta bloqueado o sin permisos.
    }
}

OnExitHandler(reason, exitCode) {
    Log("EXIT", "OnExit -> razon=" . reason . " | code=" . exitCode)
}
