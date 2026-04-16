import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasma5support 2.0 as PlasmaSupport
import org.kde.kquickcontrols 2.0 as KQuickControls
import org.kde.plasma.components 3.0 as PlasmaComponents

PlasmoidItem {
  id: root
  preferredRepresentation: Plasmoid.compactRepresentation

  property string displayText: "… W"
  property bool onBattery: false
  property var sampleBuffer: []
  property url githubUrl: "https://github.com/trickpattyFH20/power-usage-widget"

  // Persisted settings (backed by contents/config/main.xml)
  readonly property int fontPointSize: Plasmoid.configuration.fontPointSize
  readonly property int horizontalPadding: Plasmoid.configuration.horizontalPadding
  readonly property int sampleIntervalSeconds: Plasmoid.configuration.sampleIntervalSeconds
  readonly property int refreshSeconds: Plasmoid.configuration.refreshSeconds
  readonly property bool hideOnAC: Plasmoid.configuration.hideOnAC
  property bool suppressColorSave: false
  readonly property color effectiveTextColor: {
    var fc = Plasmoid.configuration.fontColor
    return (fc && fc.length > 0) ? fc : Kirigami.Theme.textColor
  }

  onSampleIntervalSecondsChanged: {
    if (sampleIntervalSeconds < 1) Plasmoid.configuration.sampleIntervalSeconds = 1
    sampleTimer.interval = sampleIntervalSeconds * 1000
    sampleBuffer = []
    if (refreshSeconds < sampleIntervalSeconds * 2) {
      Plasmoid.configuration.refreshSeconds = Math.max(2, sampleIntervalSeconds * 2)
    }
  }
  onRefreshSecondsChanged: {
    if (refreshSeconds < 1) Plasmoid.configuration.refreshSeconds = 1
    sampleBuffer = []
    if (refreshSeconds < sampleIntervalSeconds * 2) {
      Plasmoid.configuration.refreshSeconds = Math.max(2, sampleIntervalSeconds * 2)
    }
  }
  // Commands to query sysfs directly (native, no extra dependencies)
  property string sampleCommand: "BAT=; for d in /sys/class/power_supply/*; do if [ -f \"$d/type\" ] && grep -qx Battery \"$d/type\"; then BAT=\"$d\"; break; fi; done; if [ -z \"$BAT\" ]; then echo NA; exit 1; fi; if [ -r \"$BAT/power_now\" ]; then cat \"$BAT/power_now\"; elif [ -r \"$BAT/current_now\" ] && [ -r \"$BAT/voltage_now\" ]; then echo \"$(cat \"$BAT/current_now\") $(cat \"$BAT/voltage_now\")\"; else echo NA; fi"
  property string statusCommand: "BAT=; for d in /sys/class/power_supply/*; do if [ -f \"$d/type\" ] && grep -qx Battery \"$d/type\"; then BAT=\"$d\"; break; fi; done; AC_ONLINE=; for a in /sys/class/power_supply/*; do if [ -f \"$a/type\" ] && grep -qx Mains \"$a/type\"; then if [ -r \"$a/online\" ] && [ \"$(cat \"$a/online\")\" = \"1\" ]; then AC_ONLINE=1; fi; fi; done; if [ -n \"$BAT\" ] && [ -r \"$BAT/status\" ] && grep -qx Discharging \"$BAT/status\"; then echo Discharging; elif [ \"$AC_ONLINE\" = \"1\" ]; then echo AC; else echo Battery; fi"

  // Shown in panels (compact) and in popup/preview (full)
  compactRepresentation: PlasmaComponents.ToolButton {
    id: compactRoot
    leftPadding: root.horizontalPadding
    rightPadding: root.horizontalPadding
    topPadding: 4
    bottomPadding: 4
    flat: true
    hoverEnabled: true
    visible: root.onBattery || !root.hideOnAC

    TextMetrics {
      id: widthMetrics
      font.pointSize: root.fontPointSize
      text: "000.0 W"
    }

    Layout.preferredWidth: widthMetrics.width + leftPadding + rightPadding
    Layout.minimumWidth: widthMetrics.width + leftPadding + rightPadding
    Layout.preferredHeight: widthMetrics.height + topPadding + bottomPadding
    contentItem: Text {
      id: compactLabel
      text: root.displayText
      color: root.effectiveTextColor
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
      font.pointSize: root.fontPointSize
    }
    implicitWidth: widthMetrics.width + leftPadding + rightPadding
    implicitHeight: widthMetrics.height + topPadding + bottomPadding
    onClicked: root.expanded = !root.expanded
  }

  fullRepresentation: Item {
    id: popupRoot
    implicitWidth: contentLayout.implicitWidth + 24
    implicitHeight: contentLayout.implicitHeight + 24
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.minimumWidth: implicitWidth
    Layout.maximumWidth: implicitWidth
    Layout.minimumHeight: implicitHeight
    Layout.maximumHeight: implicitHeight
    ColumnLayout {
      id: contentLayout
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.margins: 12
      spacing: 10

      RowLayout {
        Layout.fillWidth: true
        spacing: 8
        PlasmaComponents.Label { text: "Refresh rate (s)"; Layout.fillWidth: true }
        SpinBox {
          from: Math.max(2, root.sampleIntervalSeconds * 2); to: 300; stepSize: 1
          value: Plasmoid.configuration.refreshSeconds
          onValueModified: Plasmoid.configuration.refreshSeconds = value
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: 8
        PlasmaComponents.Label { text: "Sample rate (s)"; Layout.fillWidth: true }
        SpinBox {
          from: 1; to: 60; stepSize: 1
          value: Plasmoid.configuration.sampleIntervalSeconds
          onValueModified: Plasmoid.configuration.sampleIntervalSeconds = value
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: 8
        PlasmaComponents.Label { text: "Font size"; Layout.fillWidth: true }
        SpinBox {
          from: 8; to: 48; stepSize: 1
          value: Plasmoid.configuration.fontPointSize
          onValueModified: Plasmoid.configuration.fontPointSize = value
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: 8
        PlasmaComponents.Label { text: "Side padding"; Layout.fillWidth: true }
        SpinBox {
          from: 0; to: 48; stepSize: 1
          value: Plasmoid.configuration.horizontalPadding
          onValueModified: Plasmoid.configuration.horizontalPadding = value
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: 8
        PlasmaComponents.Label { text: "Font color"; Layout.alignment: Qt.AlignLeft }

        KQuickControls.ColorButton {
          id: colorButton
          color: root.effectiveTextColor
          showAlphaChannel: false
          onColorChanged: {
            if (!root.suppressColorSave) {
              var hex = color.toString()
              if (hex.length === 9) hex = "#" + hex.substring(3)
              Plasmoid.configuration.fontColor = hex
              colorField.text = hex
            }
          }
        }

        TextField {
          id: colorField
          placeholderText: "theme default"
          text: Plasmoid.configuration.fontColor
          Layout.preferredWidth: fontMetrics.advanceWidth("theme default") + leftPadding + rightPadding
          validator: RegularExpressionValidator { regularExpression: /^(#[0-9A-Fa-f]{6})?$/ }
          FontMetrics { id: fontMetrics; font: colorField.font }
          onEditingFinished: {
            Plasmoid.configuration.fontColor = text
            if (text.length > 0) {
              root.suppressColorSave = true
              colorButton.color = text
              root.suppressColorSave = false
            }
          }
        }
      }

      CheckBox {
        text: "Hide while plugged in"
        checked: Plasmoid.configuration.hideOnAC
        onToggled: Plasmoid.configuration.hideOnAC = checked
        Layout.alignment: Qt.AlignLeft
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: 8
        PlasmaComponents.Button {
          text: "Reset defaults"
          onClicked: {
            root.suppressColorSave = true
            Plasmoid.configuration.fontPointSize = 12
            Plasmoid.configuration.horizontalPadding = 8
            Plasmoid.configuration.sampleIntervalSeconds = 1
            Plasmoid.configuration.refreshSeconds = 15
            Plasmoid.configuration.hideOnAC = false
            Plasmoid.configuration.fontColor = ""
            colorField.text = ""
            colorButton.color = root.effectiveTextColor
            root.suppressColorSave = false
          }
        }
        Item { Layout.fillWidth: true }
        PlasmaComponents.Button {
          text: "GitHub"
          onClicked: Qt.openUrlExternally(root.githubUrl)
        }
      }
    }

  }

  // Executes per-second sampling of battery power from sysfs
  PlasmaSupport.DataSource {
    id: execSample
    engine: "executable"
    connectedSources: []
    property var buffers: ({})
    onNewData: function(source, data) {
      var chunk = data["stdout"] || ""
      buffers[source] = (buffers[source] || "") + chunk
      if (data["exit code"] !== undefined) {
        var output = buffers[source] || ""
        delete buffers[source]
        disconnectSource(source)
        var watts = parseWattsFromSysfs(output)
        if (!isNaN(watts)) {
          root.sampleBuffer.push(watts)
          var targetSamples = Math.max(1, Math.round(root.refreshSeconds / root.sampleIntervalSeconds))
          if (root.sampleBuffer.length >= targetSamples) {
            var sum = 0
            for (var i = 0; i < root.sampleBuffer.length; ++i) sum += root.sampleBuffer[i]
            var avg = sum / root.sampleBuffer.length
            root.displayText = avg.toFixed(1) + " W"
            root.sampleBuffer = []
          }
        }
      }
    }
  }

  // Checks whether the battery is discharging (on battery power)
  PlasmaSupport.DataSource {
    id: execStatus
    engine: "executable"
    connectedSources: []
    property var buffers: ({})
    onNewData: function(source, data) {
      var chunk = data["stdout"] || ""
      buffers[source] = (buffers[source] || "") + chunk
      if (data["exit code"] !== undefined) {
        var output = (buffers[source] || "").trim()
        delete buffers[source]
        disconnectSource(source)
        var discharging = /^Discharging$/i.test(output)
        root.onBattery = discharging
        Plasmoid.status = discharging ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus
        if (!discharging) {
          root.sampleBuffer = []
          if (root.hideOnAC) {
            root.displayText = ""
          } else {
            root.displayText = "— W"
          }
        }
      }
    }
  }

  // Poll battery status every 5 seconds
  Timer {
    id: statusTimer
    interval: 5000
    running: true
    repeat: true
    onTriggered: checkStatus()
  }

  // Take a sample every second; only processed when on battery
  Timer {
    id: sampleTimer
    interval: root.sampleIntervalSeconds * 1000
    running: true
    repeat: true
    onTriggered: sampleOnce()
  }

  function parseWattsFromSysfs(output) {
    // output is either: "<power_now>" (microWatts) OR two numbers: current_now (microAmps) and voltage_now (microVolts)
    var txt = (output || "").trim()
    if (!txt || txt === "NA") return NaN
    var tokens = txt.split(/\s+/)
    if (tokens.length === 1) {
      var microWatts = parseFloat(tokens[0])
      if (isNaN(microWatts)) return NaN
      return microWatts / 1000000.0
    }
    if (tokens.length >= 2) {
      var microAmps = parseFloat(tokens[0])
      var microVolts = parseFloat(tokens[1])
      if (isNaN(microAmps) || isNaN(microVolts)) return NaN
      var prod = Math.abs(microAmps) * Math.abs(microVolts)
      return prod / 1000000000000.0 // convert µA*µV to W
    }
    return NaN
  }

  function sampleOnce() {
    if (!root.onBattery) {
      // Not on battery; ensure buffer cleared
      root.sampleBuffer = []
      return
    }
    execSample.connectSource("sh -c '" + root.sampleCommand + "'")
  }

  function checkStatus() {
    execStatus.connectSource("sh -c '" + root.statusCommand + "'")
  }

  Component.onCompleted: {
    checkStatus()
  }
}


