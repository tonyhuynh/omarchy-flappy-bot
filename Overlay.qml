import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.Commons

// Overlay entry point for centered or fullscreen Flappy Bot. The shell drives
// lifecycle through open(payload) / close() and reads `opened`; everything
// below is a self-contained game that recolors itself from the active theme.
Item {
  id: root

  // ---- Lifecycle (driven by the shell) -------------------------------------
  property var shell: null
  property var manifest: null
  property bool opened: false
  property bool fullscreenMode: false
  property bool resizingMode: false
  property var modeSnapshot: null

  function open(payload) {
    root.fullscreenMode = root.payloadRequestsFullscreen(payload)
    root.resizingMode = false
    root.modeSnapshot = null
    root.opened = true
    root.loadBest(root.bestFile ? root.bestFile.text() : "")
    root.restart()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function close() {
    root.opened = false
    root.resizingMode = false
    root.modeSnapshot = null
    root.restart()
  }

  function dismiss() {
    root.close()
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "tonyhuynh.flappy-bot")
  }

  function toggle() { root.opened ? root.dismiss() : root.open("") }

  // Introspection for `omarchy-shell shell call tonyhuynh.flappy-bot status ''`.
  function status() {
    return JSON.stringify({
      opened: root.opened,
      state: root.gameState,
      score: root.score,
      best: root.best,
      level: root.difficultyLevel,
      difficulty: root.difficultyName,
      mode: root.fullscreenMode ? "fullscreen" : "centered",
      W: Math.round(root.wdt),
      H: Math.round(root.hgt)
    })
  }

  // ---- Theme palette (tracks the active Omarchy theme) ---------------------
  readonly property color skyTop: Qt.lighter(Color.background, 1.16)
  readonly property color skyBottom: Color.background
  readonly property color pipeCol: Qt.darker(Color.foreground, 1.05)
  readonly property color pipeCapCol: Qt.darker(Color.foreground, 1.35)
  readonly property color groundCol: Qt.darker(Color.muted, 1.28)
  readonly property color grassCol: Color.muted
  readonly property color botBody: Color.accent
  readonly property color botHighlight: Qt.lighter(Color.accent, 1.28)
  readonly property color botPanel: Qt.darker(Color.accent, 1.28)
  readonly property color botVisor: Color.background
  readonly property color botDisplay: Color.foreground
  readonly property color botStatus: Color.urgent
  readonly property color textCol: Color.foreground
  readonly property color panelCol: Util.alpha(Color.background, 0.92)
  readonly property color panelBorder: Util.alpha(Color.accent, 0.9)
  readonly property color cloudCol: Util.alpha(Color.foreground, 0.05)

  // ---- Layout (derived from window size) -----------------------------------
  readonly property real hgt: panel.height
  readonly property real wdt: panel.width
  readonly property real screenW: panel.screen ? panel.screen.width : 1280
  readonly property real screenH: panel.screen ? panel.screen.height : 720
  readonly property int compactH: Math.round(Math.min(700,
    Math.max(480, root.screenH * 0.72)))
  readonly property int compactW: Math.round(Math.min(root.screenW * 0.82,
    root.compactH * 1.45))
  readonly property real groundH: hgt * 0.14
  readonly property real groundTop: hgt - groundH
  readonly property real botR: Math.max(11, hgt * 0.030)
  readonly property real botX: wdt * 0.30
  // Softer acceleration and a terminal fall speed keep the bot buoyant rather
  // than making each input read like a hard rubber-ball bounce.
  readonly property real gravity: hgt * 1.90
  readonly property real flapV: -hgt * 0.48
  readonly property real maxFallV: hgt * 0.72
  readonly property real flapResponse: 0.88
  readonly property real rotationResponse: 9.0
  readonly property real boostDuration: 0.16
  // Difficulty advances continuously with score and announces a new level
  // every eight pipes. Flight physics stay fixed so the controls remain
  // predictable; only the obstacle course becomes more demanding.
  readonly property int scorePerLevel: 8
  readonly property int maxDifficultyLevel: 10
  readonly property int difficultyLevel: root.levelForScore(root.score)
  readonly property var difficultyNames: [
    "Cruise", "Boost", "Turbo", "Overdrive", "Vector",
    "Pulse", "Redline", "Warp", "Hyperdrive", "Singularity"
  ]
  readonly property string difficultyName: root.difficultyNames[root.difficultyLevel - 1]
  readonly property string difficultyLabel: "Level " + String(root.difficultyLevel)
    + " - " + root.difficultyName
  // Preserve the original Cruise-to-Overdrive curve through score 24, then
  // extend it across six tougher endgame levels that peak at score 72.
  readonly property real overdriveScore: 3 * root.scorePerLevel
  readonly property real maximumDifficultyScore:
    (root.maxDifficultyLevel - 1) * root.scorePerLevel
  readonly property real baseDifficultyProgress: Math.min(1,
    root.score / root.overdriveScore)
  readonly property real endgameDifficultyProgress: Math.max(0, Math.min(1,
    (root.score - root.overdriveScore)
      / (root.maximumDifficultyScore - root.overdriveScore)))
  // Cruise starts with a 15% pace assist, which still fades by Overdrive.
  readonly property real startingPace: 0.85 + root.baseDifficultyProgress * 0.15
  readonly property real pipeSpeed: hgt
    * (0.36 + root.baseDifficultyProgress * 0.11
      + root.endgameDifficultyProgress * 0.10) * root.startingPace
  readonly property real pipeW: Math.max(46, hgt * 0.11)
  readonly property real pipeGap: hgt * (0.30
    - root.baseDifficultyProgress * 0.045
    - root.endgameDifficultyProgress * 0.035)
  readonly property real pipeSpacing: hgt * (0.46
    - root.baseDifficultyProgress * 0.015
    - root.endgameDifficultyProgress * 0.025)
  readonly property real pipePool: 7

  // ---- Game state -----------------------------------------------------------
  property string gameState: "ready" // ready | playing | over
  property real t: 0
  property real botY: hgt * 0.45
  property real botV: 0
  property real botRot: 0
  property int score: 0
  property int best: 0
  property real deathTime: 0
  property real levelUpTime: -10
  property var pipes: []
  property real groundScroll: 0
  property real wingPhase: 0
  property real lastBoostTime: -10
  readonly property real boostPulse: root.gameState === "playing"
    ? Math.max(0, 1 - (root.t - root.lastBoostTime) / root.boostDuration)
    : 0

  // ---- Persistence ----------------------------------------------------------
  // High score lives under the Omarchy state dir, next to theme state.
  property FileView bestFile: FileView {
    path: Color.home + "/.local/state/omarchy/flappy-bot-best"
    watchChanges: false
    atomicWrites: true
    printErrors: false
    onLoaded: root.loadBest(text())
    onLoadFailed: root.loadBest("")
  }

  function loadBest(raw) {
    var txt = String(raw === undefined || raw === null ? "" : raw).trim()
    var n = parseInt(txt, 10)
    root.best = isNaN(n) ? 0 : n
  }

  function saveBest() {
    root.bestFile.setText(String(root.best))
  }

  // ---- Game logic -----------------------------------------------------------
  function restart() {
    root.gameState = "ready"
    root.score = 0
    root.pipes = []
    root.botY = root.hgt * 0.45
    root.botV = 0
    root.botRot = 0
    root.wingPhase = 0
    root.lastBoostTime = -10
    root.deathTime = 0
    root.levelUpTime = -10
    root.groundScroll = 0
  }

  function startGame() {
    root.gameState = "playing"
    root.score = 0
    root.pipes = []
    root.botY = root.hgt * 0.45
    root.botV = root.flapV
    root.botRot = 0
    root.lastBoostTime = root.t
    root.levelUpTime = -10
  }

  function flap() {
    // Blend toward the lift velocity instead of discarding all existing
    // momentum. A late recovery still responds strongly, while closely spaced
    // taps no longer produce identical saw-tooth jumps.
    root.botV += (root.flapV - root.botV) * root.flapResponse
    root.lastBoostTime = root.t
  }

  function integrateBot(dt) {
    var nextV = Math.min(root.maxFallV, root.botV + root.gravity * dt)
    // Average-velocity integration is less frame-rate-sensitive than moving
    // with only the newly accelerated velocity.
    root.botY += (root.botV + nextV) * 0.5 * dt
    root.botV = nextV
  }

  function updateFlightRotation(dt) {
    var targetRot
    if (root.botV < 0) {
      var liftRatio = Math.min(1, -root.botV / -root.flapV)
      targetRot = -22 * liftRatio
    } else {
      var fallRatio = Math.min(1, root.botV / root.maxFallV)
      targetRot = 68 * fallRatio
    }

    var blend = 1 - Math.exp(-root.rotationResponse * dt)
    root.botRot += (targetRot - root.botRot) * blend
  }

  function action() {
    if (root.gameState === "ready") { root.startGame(); return }
    if (root.gameState === "playing") { root.flap(); return }
    if (root.gameState === "over" && (root.t - root.deathTime) > 0.45) { root.startGame() }
  }

  function die() {
    root.gameState = "over"
    root.deathTime = root.t
    if (root.score > root.best) {
      root.best = root.score
      root.saveBest()
    }
  }

  function payloadRequestsFullscreen(payload) {
    if (payload === undefined || payload === null || String(payload).trim() === "")
      return false
    try {
      var request = JSON.parse(String(payload))
      return request && (request.fullscreen === true || request.mode === "fullscreen")
    } catch (e) {
      return false
    }
  }

  // Layer-shell can switch between an unanchored, centered surface and a
  // four-edge full-screen surface. Preserve the run in normalized playfield
  // coordinates while the compositor negotiates the new geometry.
  function toggleFullscreen() {
    if (root.resizingMode) return

    var oldW = Math.max(1, root.wdt)
    var oldH = Math.max(1, root.hgt)
    var savedPipes = []
    for (var i = 0; i < root.pipes.length; i++) {
      var p = root.pipes[i]
      savedPipes.push({
        offsetX: p.x - root.botX,
        gapRatio: p.gapY / oldH,
        scored: p.scored
      })
    }

    root.modeSnapshot = {
      oldH: oldH,
      botRatio: root.botY / oldH,
      velocityRatio: root.botV / oldH,
      pipes: savedPipes
    }
    root.resizingMode = true
    root.fullscreenMode = !root.fullscreenMode
    modeResizeSettle.restart()
  }

  function applyModeGeometry() {
    var snapshot = root.modeSnapshot
    if (!snapshot) {
      root.resizingMode = false
      return
    }

    var newH = Math.max(1, root.hgt)
    var heightScale = newH / snapshot.oldH
    root.botY = snapshot.botRatio * newH
    root.botV = snapshot.velocityRatio * newH

    var resizedPipes = []
    for (var i = 0; i < snapshot.pipes.length; i++) {
      var p = snapshot.pipes[i]
      resizedPipes.push({
        x: root.botX + p.offsetX * heightScale,
        gapY: p.gapRatio * newH,
        scored: p.scored
      })
    }
    root.pipes = resizedPipes
    root.modeSnapshot = null
    root.resizingMode = false
    loop.last = 0
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function levelForScore(value) {
    var safeScore = Math.max(0, Number(value) || 0)
    return Math.min(root.maxDifficultyLevel,
                    Math.floor(safeScore / root.scorePerLevel) + 1)
  }

  function pmod(a, b) { return ((a % b) + b) % b }

  function randGap() {
    var margin = root.pipeGap / 2 + root.hgt * 0.06
    var minY = margin
    var maxY = Math.max(minY + 1, root.groundTop - margin)
    return minY + Math.random() * (maxY - minY)
  }

  function circleRect(cx, cy, r, rx, ry, rw, rh) {
    var nx = Math.max(rx, Math.min(cx, rx + rw))
    var ny = Math.max(ry, Math.min(cy, ry + rh))
    var dx = cx - nx
    var dy = cy - ny
    return dx * dx + dy * dy <= r * r
  }

  function hitPipe(p) {
    var topH = p.gapY - root.pipeGap / 2
    var botTop = p.gapY + root.pipeGap / 2
    var r = root.botR * 0.86 // slightly forgiving hitbox
    if (root.circleRect(root.botX, root.botY, r, p.x, 0, root.pipeW, topH)) return true
    if (root.circleRect(root.botX, root.botY, r, p.x, botTop, root.pipeW, root.groundTop - botTop)) return true
    return false
  }

  function step(dt) {
    root.t += dt
    if (root.gameState === "playing") {
      root.wingPhase = (root.wingPhase + dt * 6) % 1
      root.integrateBot(dt)

      if (root.botY < root.botR) {
        root.botY = root.botR
        root.botV = Math.max(0, root.botV)
      }
      if (root.botY + root.botR > root.groundTop) {
        root.botY = root.groundTop - root.botR
        root.die()
        return
      }

      // Advance pipes, score, spawn, cull.
      var next = []
      for (var i = 0; i < root.pipes.length; i++) {
        var p = root.pipes[i]
        var nx = p.x - root.pipeSpeed * dt
        var scored = p.scored
        if (!scored && nx + root.pipeW < root.botX) {
          scored = true
          var nextScore = root.score + 1
          if (root.levelForScore(nextScore) > root.levelForScore(root.score))
            root.levelUpTime = root.t
          root.score = nextScore
        }
        next.push({ x: nx, gapY: p.gapY, scored: scored })
      }
      var maxX = -1
      for (var j = 0; j < next.length; j++) if (next[j].x > maxX) maxX = next[j].x
      if (next.length === 0 || maxX < root.wdt - root.pipeSpacing) {
        next.push({ x: root.wdt + root.pipeW, gapY: root.randGap(), scored: false })
      }
      var kept = []
      for (var k = 0; k < next.length; k++) if (next[k].x > -root.pipeW - 12) kept.push(next[k])
      root.pipes = kept

      for (var m = 0; m < root.pipes.length; m++) {
        if (root.hitPipe(root.pipes[m])) { root.die(); return }
      }

      root.updateFlightRotation(dt)
      root.groundScroll = (root.groundScroll + root.pipeSpeed * dt) % 34
    } else if (root.gameState === "over") {
      root.wingPhase = (root.wingPhase + dt * 2) % 1
      if (root.botY + root.botR < root.groundTop) {
        root.integrateBot(dt)
        if (root.botY + root.botR > root.groundTop) root.botY = root.groundTop - root.botR
      }
      root.botRot += (82 - root.botRot) * (1 - Math.exp(-5.5 * dt))
    } else if (root.gameState === "ready") {
      root.wingPhase = (root.wingPhase + dt * 0.8) % 1
      root.botY = root.hgt * 0.45 + Math.sin(root.t * 1.65) * root.hgt * 0.006
      root.botRot = 0
      root.groundScroll = (root.groundScroll + root.pipeSpeed * 0.4 * dt) % 34
    }
  }

  // ---- Game loop ------------------------------------------------------------
  Timer {
    id: loop
    interval: 16
    repeat: true
    running: root.opened && !root.resizingMode
    property real last: 0
    onTriggered: {
      var now = Date.now()
      if (loop.last === 0) loop.last = now
      var dt = (now - loop.last) / 1000
      loop.last = now
      if (dt > 0.05) dt = 0.05
      if (dt <= 0) dt = 0.016
      root.step(dt)
    }
  }
  onOpenedChanged: { if (root.opened) loop.last = 0 }

  Timer {
    id: modeResizeSettle
    interval: 90
    repeat: false
    onTriggered: root.applyModeGeometry()
  }

  PanelWindow {
    id: panel
    visible: root.opened
    color: "transparent"
    implicitWidth: root.compactW
    implicitHeight: root.compactH

    // With no edges anchored, layer-shell centers the requested implicit size.
    // Anchoring all four edges is the optional full-screen mode.
    anchors {
      top: root.fullscreenMode
      bottom: root.fullscreenMode
      left: root.fullscreenMode
      right: root.fullscreenMode
    }

    onWidthChanged: if (root.resizingMode) modeResizeSettle.restart()
    onHeightChanged: if (root.resizingMode) modeResizeSettle.restart()

    WlrLayershell.namespace: "omarchy-flappy-bot"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    // ---- Input --------------------------------------------------------------
    Item {
      id: keyCatcher
      anchors.fill: parent
      focus: true
      z: 100

      MouseArea {
        anchors.fill: parent
        onClicked: root.action()
      }

      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Up ||
            event.key === Qt.Key_Return || event.key === Qt.Key_Enter ||
            event.key === Qt.Key_W) {
          root.action()
          event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
          root.dismiss()
          event.accepted = true
        } else if (event.key === Qt.Key_F) {
          if (!event.isAutoRepeat) root.toggleFullscreen()
          event.accepted = true
        }
      }
    }

    // ---- Sky ----------------------------------------------------------------
    Rectangle {
      anchors.fill: parent
      gradient: Gradient {
        orientation: Gradient.Vertical
        GradientStop { position: 0.0; color: root.skyTop }
        GradientStop { position: 1.0; color: root.skyBottom }
      }

      // Drifting clouds (parallax).
      Repeater {
        model: 4
        delegate: Rectangle {
          readonly property real cw: root.wdt * (0.10 + index * 0.02)
          readonly property real speed: 12 + index * 6
          width: cw
          height: cw * 0.34
          radius: width / 2
          color: root.cloudCol
          y: root.hgt * (0.12 + index * 0.07)
          x: root.pmod(root.cw * index * 1.7 - root.t * speed, root.wdt + cw) - cw
          opacity: 0.5 + (index % 2) * 0.3
        }
      }
    }

    // ---- Pipes ----------------------------------------------------------------
    Repeater {
      model: root.pipePool
      delegate: Pipe {
        x: (root.pipes[index] ? root.pipes[index].x : -9999)
        y: 0
        width: root.pipeW
        height: root.groundTop
        gapCenterY: (root.pipes[index] ? root.pipes[index].gapY : 0)
        gapHeight: root.pipeGap
        pipeColor: root.pipeCol
        capColor: root.pipeCapCol
        visible: (root.pipes[index] !== undefined) &&
                 (root.gameState === "playing" || root.gameState === "over")
      }
    }

    // ---- Ground ---------------------------------------------------------------
    Rectangle {
      x: 0
      y: root.groundTop
      width: root.wdt
      height: root.groundH
      color: root.groundCol

      Rectangle {
        // Grass strip.
        width: parent.width
        height: parent.height * 0.4
        color: root.grassCol
        anchors.top: parent.top

        // Moving notches to convey motion.
        Repeater {
          model: Math.ceil(root.wdt / 34) + 2
          delegate: Rectangle {
            width: 10
            height: parent.parent.height * 0.45
            color: Qt.lighter(root.grassCol, 1.25)
            radius: 2
            x: (index * 34) - (root.groundScroll % 34)
            y: 2
          }
        }
      }
    }

    // ---- Bot -----------------------------------------------------------------
    Bot {
      readonly property real s: (root.botR * 2) / baseW
      scale: s
      x: root.botX - (baseW * s) / 2
      y: root.botY - (baseH * s) / 2
      rotation: root.botRot
      wingPhase: root.wingPhase
      boostPulse: root.boostPulse
      bodyColor: root.botBody
      highlightColor: root.botHighlight
      panelColor: root.botPanel
      visorColor: root.botVisor
      displayColor: root.botDisplay
      accentColor: root.botStatus
      z: 50
    }

    // ---- Score HUD -------------------------------------------------------------
    // Pipes traverse every horizontal position, so naked fixed-position text
    // will eventually collide visually with one. This opaque capsule keeps the
    // HUD readable while letting the obstacle continue behind it unchanged.
    Rectangle {
      id: scoreHud
      readonly property real levelAge: root.t - root.levelUpTime
      readonly property bool levelChanged: levelAge >= 0 && levelAge < 1.25
      anchors.top: parent.top
      anchors.topMargin: Style.spacing.md
      anchors.horizontalCenter: parent.horizontalCenter
      width: Math.min(root.wdt - Style.spacing.lg * 2,
                      Math.max(420, scoreLine.implicitWidth + Style.spacing.xl * 2))
      height: scoreLine.implicitHeight + Style.spacing.sm * 2
      radius: height / 2
      color: Qt.rgba(root.skyBottom.r, root.skyBottom.g, root.skyBottom.b, 1)
      border.color: levelChanged ? root.botBody : root.panelBorder
      border.width: levelChanged ? 2 : 1
      clip: true
      visible: root.gameState === "playing"
      z: 55

      Text {
        id: scoreLine
        anchors.centerIn: parent
        width: parent.width - Style.spacing.lg * 2
        height: parent.height - Style.spacing.xxs * 2
        text: "SCORE " + String(root.score)
          + "  ·  HIGH SCORE " + String(root.best)
          + "  ·  " + root.difficultyLabel
        color: root.textCol
        font.pixelSize: Style.fontPx(1.05)
        fontSizeMode: Text.Fit
        minimumPixelSize: 8
        font.bold: true
        font.family: Style.fontFamily
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.NoWrap
      }
    }

    // ---- Ready overlay --------------------------------------------------------
    Item {
      anchors.fill: parent
      visible: root.gameState === "ready"
      z: 60

      Rectangle {
        id: readyCard
        readonly property real contentPadding: Style.spacing.xl
        anchors.centerIn: parent
        width: Math.min(root.wdt - Style.spacing.xl * 2, 480)
        height: readyContent.implicitHeight + contentPadding * 2
        radius: Style.cornerRadius
        color: root.panelCol
        border.color: root.panelBorder
        border.width: 1

        Column {
          id: readyContent
          anchors.centerIn: parent
          width: parent.width - readyCard.contentPadding * 2
          spacing: Style.spacing.md

          Text {
            width: parent.width
            text: "FLAPPY BOT"
            color: root.textCol
            font.pixelSize: Style.fontPx(3)
            font.bold: true
            font.letterSpacing: 3
            font.family: Style.fontFamily
            horizontalAlignment: Text.AlignHCenter
          }
          Text {
            width: parent.width
            text: "Click, tap, or press Space / Up to fly"
            color: Qt.lighter(root.textCol, 1.25)
            opacity: 0.85
            font.pixelSize: Style.fontPx(1.4)
            font.family: Style.fontFamily
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
          }
          Text {
            width: parent.width
            text: "Difficulty rises as your score climbs"
            color: root.botBody
            opacity: 0.85
            font.pixelSize: Style.fontPx(1.15)
            font.family: Style.fontFamily
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
          }
          Text {
            width: parent.width
            text: root.fullscreenMode
              ? "F returns to centered mode"
              : "F toggles fullscreen"
            color: Qt.lighter(root.textCol, 1.25)
            opacity: 0.6
            font.pixelSize: Style.fontPx(1.1)
            font.family: Style.fontFamily
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
          }
          Text {
            width: parent.width
            text: "Esc to close"
            color: Qt.lighter(root.textCol, 1.25)
            opacity: 0.6
            font.pixelSize: Style.fontPx(1.1)
            font.family: Style.fontFamily
            horizontalAlignment: Text.AlignHCenter
          }
        }
      }
    }

    // ---- Game over overlay ----------------------------------------------------
    Item {
      anchors.fill: parent
      visible: root.gameState === "over"
      z: 60

      Rectangle {
        id: gameOverCard
        readonly property real contentPadding: Style.spacing.xl
        anchors.centerIn: parent
        width: Math.min(root.wdt - Style.spacing.xl * 2, 480)
        height: gameOverContent.implicitHeight + contentPadding * 2
        radius: Style.cornerRadius
        color: root.panelCol
        border.color: root.panelBorder
        border.width: 1

        Column {
          id: gameOverContent
          anchors.centerIn: parent
          width: parent.width - gameOverCard.contentPadding * 2
          spacing: Style.spacing.md

          Text {
            width: parent.width
            text: "GAME OVER"
            color: root.textCol
            font.pixelSize: Style.fontPx(3)
            font.bold: true
            font.letterSpacing: 3
            font.family: Style.fontFamily
            horizontalAlignment: Text.AlignHCenter
          }
          Row {
            id: scoreRow
            width: parent.width
            spacing: Style.spacing.lg

            Column {
              width: (scoreRow.width - scoreRow.spacing) / 2
              spacing: Style.spacing.xxs
              Text {
                width: parent.width
                text: String(root.score)
                color: root.textCol
                font.pixelSize: Style.fontPx(4)
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                font.family: Style.fontFamily
              }
              Text {
                width: parent.width
                text: "score"
                color: Qt.lighter(root.textCol, 1.25)
                opacity: 0.7
                font.pixelSize: Style.fontPx(1.1)
                horizontalAlignment: Text.AlignHCenter
                font.family: Style.fontFamily
              }
            }
            Column {
              width: (scoreRow.width - scoreRow.spacing) / 2
              spacing: Style.spacing.xxs
              Text {
                width: parent.width
                text: String(root.best)
                color: root.textCol
                font.pixelSize: Style.fontPx(4)
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                font.family: Style.fontFamily
              }
              Text {
                width: parent.width
                text: "high score"
                color: Qt.lighter(root.textCol, 1.25)
                opacity: 0.7
                font.pixelSize: Style.fontPx(1.1)
                horizontalAlignment: Text.AlignHCenter
                font.family: Style.fontFamily
                wrapMode: Text.WordWrap
              }
            }
          }
          Text {
            width: parent.width
            text: root.difficultyLabel
            color: root.botBody
            opacity: 0.9
            font.pixelSize: Style.fontPx(1.15)
            font.bold: true
            font.family: Style.fontFamily
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
          }
          Text {
            width: parent.width
            text: "Tap or Space to retry"
            color: Qt.lighter(root.textCol, 1.25)
            opacity: (root.t - root.deathTime > 0.45) ? 0.85 : 0
            font.pixelSize: Style.fontPx(1.4)
            font.family: Style.fontFamily
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
          }
          Text {
            width: parent.width
            text: root.fullscreenMode
              ? "F returns to centered mode"
              : "F toggles fullscreen"
            color: Qt.lighter(root.textCol, 1.25)
            opacity: 0.7
            font.pixelSize: Style.fontPx(1.1)
            font.family: Style.fontFamily
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
          }
        }
      }
    }

    Rectangle {
      anchors.fill: parent
      color: "transparent"
      border.color: root.panelBorder
      border.width: 1
      visible: !root.fullscreenMode
      z: 90
    }
  }
}
