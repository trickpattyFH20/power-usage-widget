import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasma5support 2.0 as PlasmaSupport
import org.kde.plasma.components 3.0 as PlasmaComponents

PlasmoidItem {
  id: root
  preferredRepresentation: Plasmoid.compactRepresentation

  property string displayText: "… W"
  property bool onBattery: false
  property var sampleBuffer: []
  property url githubUrl: "https://github.com/trickpattyFH20/power-usage-widget"
  property bool showDonate: false
  property string btcAddress: "bc1quw0mt6lmrh4saz7tlqt5298207nd432zvqx0g8"
  property int donationQrSize: 160

  // Persisted settings (backed by contents/config/main.xml)
  readonly property int fontPointSize: Plasmoid.configuration.fontPointSize
  readonly property int horizontalPadding: Plasmoid.configuration.horizontalPadding
  readonly property int sampleIntervalSeconds: Plasmoid.configuration.sampleIntervalSeconds
  readonly property int refreshSeconds: Plasmoid.configuration.refreshSeconds
  readonly property bool hideOnAC: Plasmoid.configuration.hideOnAC

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
    topPadding: 0
    bottomPadding: 0
    flat: true
    hoverEnabled: true
    visible: root.onBattery || !root.hideOnAC
    // Fill panel height and reserve width equal to content + both paddings
    Layout.preferredWidth: compactLabel.implicitWidth + leftPadding + rightPadding
    Layout.minimumWidth: compactLabel.implicitWidth + leftPadding + rightPadding
    contentItem: Text {
      id: compactLabel
      text: root.displayText
      color: PlasmaCore.Theme.textColor
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
      font.pointSize: root.fontPointSize
    }
    // Ensure the hover/click area spans the full widget width including padding
    implicitWidth: compactLabel.implicitWidth + leftPadding + rightPadding
    implicitHeight: Math.max(compactLabel.implicitHeight, compactLabel.font.pixelSize, Plasmoid.availableHeight)
    onClicked: root.expanded = !root.expanded
  }

  fullRepresentation: Item {
    id: popupRoot
    // Make the popup grow to fit content
    implicitWidth: contentLayout.implicitWidth + 24
    implicitHeight: contentLayout.implicitHeight + 24
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    ColumnLayout {
      id: contentLayout
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.margins: 12
      spacing: 10

      PlasmaComponents.Label {
        text: root.displayText
        Layout.alignment: Qt.AlignHCenter
        font.pointSize: root.fontPointSize
      }

      Rectangle { height: 1; color: PlasmaCore.Theme.highlightColor; opacity: 0.2; Layout.fillWidth: true }

      RowLayout {
        Layout.fillWidth: true
        spacing: 8
        PlasmaComponents.Label { text: "Font size"; Layout.alignment: Qt.AlignLeft }
        SpinBox {
          from: 8; to: 48; stepSize: 1
          value: Plasmoid.configuration.fontPointSize
          onValueModified: Plasmoid.configuration.fontPointSize = value
          Layout.fillWidth: true
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: 8
        PlasmaComponents.Label { text: "Side padding"; Layout.alignment: Qt.AlignLeft }
        SpinBox {
          from: 0; to: 48; stepSize: 1
          value: Plasmoid.configuration.horizontalPadding
          onValueModified: Plasmoid.configuration.horizontalPadding = value
          Layout.fillWidth: true
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: 8
        PlasmaComponents.Label { text: "Sample rate (s)"; Layout.alignment: Qt.AlignLeft }
        SpinBox {
          from: 1; to: 60; stepSize: 1
          value: Plasmoid.configuration.sampleIntervalSeconds
          onValueModified: Plasmoid.configuration.sampleIntervalSeconds = value
          Layout.fillWidth: true
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: 8
        PlasmaComponents.Label { text: "Refresh rate (s)"; Layout.alignment: Qt.AlignLeft }
        SpinBox {
          from: Math.max(2, root.sampleIntervalSeconds * 2); to: 300; stepSize: 1
          value: Plasmoid.configuration.refreshSeconds
          onValueModified: Plasmoid.configuration.refreshSeconds = value
          Layout.fillWidth: true
        }
      }

      CheckBox {
        text: "Hide while plugged in"
        checked: Plasmoid.configuration.hideOnAC
        onToggled: Plasmoid.configuration.hideOnAC = checked
        Layout.alignment: Qt.AlignLeft
      }

      RowLayout {
        Layout.alignment: Qt.AlignRight
        spacing: 8
        PlasmaComponents.Button {
          text: "GitHub"
          onClicked: Qt.openUrlExternally(root.githubUrl)
        }
        PlasmaComponents.Button {
          text: "Donate"
          onClicked: {
            root.showDonate = !root.showDonate
            if (contentLayout && contentLayout.forceLayout) contentLayout.forceLayout()
          }
        }
      }

      // Donation section (toggles open)
      ColumnLayout {
        visible: root.showDonate
        spacing: 8
        Layout.fillWidth: true
        id: donationSection

        PlasmaComponents.Label {
          text: "Donate via Bitcoin"
          font.bold: true
        }

        RowLayout {
          Layout.fillWidth: true
          TextEdit {
            id: btcField
            text: root.btcAddress
            readOnly: true
            selectByMouse: true
            wrapMode: TextEdit.NoWrap
            color: PlasmaCore.Theme.textColor
            Layout.fillWidth: true
          }
          PlasmaComponents.Button {
            text: "Copy"
            onClicked: {
              btcField.selectAll()
              btcField.copy()
            }
          }
        }

        // QR code image (wallet.png in contents/ui)
        Image {
          source: "wallet.png"
          fillMode: Image.PreserveAspectFit
          asynchronous: true
          cache: true
          Layout.alignment: Qt.AlignHCenter
          Layout.preferredWidth: root.donationQrSize
          Layout.preferredHeight: root.donationQrSize
        }

        RowLayout {
          Layout.alignment: Qt.AlignRight
          PlasmaComponents.Button {
            text: "Hide"
            onClicked: {
              root.showDonate = false
              if (contentLayout && contentLayout.forceLayout) contentLayout.forceLayout()
            }
          }
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


