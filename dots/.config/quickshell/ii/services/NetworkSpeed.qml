pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Network speed monitor that reads /proc/net/dev to compute
 * real-time download and upload rates in bytes/s.
 */
Singleton {
    id: root

    property real downloadSpeed: 0   // bytes/s
    property real uploadSpeed: 0     // bytes/s

    readonly property int historyLength: Config?.options.resources.historyLength ?? 60

    // History values are normalised to [0, 1] relative to the peak seen so far.
    property list<real> downloadHistory: []
    property list<real> uploadHistory: []

    // Absolute history (bytes/s) for computing averages.
    property list<real> downloadRawHistory: []
    property list<real> uploadRawHistory: []

    property real peakDownload: 1   // avoid division by zero
    property real peakUpload: 1

    property real avgDownload: 0
    property real avgUpload: 0

    // Previous byte counters keyed by interface.
    property var _prevRx: ({})
    property var _prevTx: ({})
    property real _prevTime: 0
    property bool _initialized: false

    function _formatSpeed(bytesPerSec) {
        if (bytesPerSec >= 1024 * 1024)
            return (bytesPerSec / (1024 * 1024)).toFixed(1) + " MB/s"
        else if (bytesPerSec >= 1024)
            return (bytesPerSec / 1024).toFixed(1) + " KB/s"
        else
            return Math.round(bytesPerSec) + " B/s"
    }

    property string downloadSpeedString: _formatSpeed(downloadSpeed)
    property string uploadSpeedString: _formatSpeed(uploadSpeed)
    property string avgDownloadString: _formatSpeed(avgDownload)
    property string avgUploadString: _formatSpeed(avgUpload)

    function _updateAverages() {
        if (downloadRawHistory.length > 0)
            avgDownload = downloadRawHistory.reduce((a, b) => a + b, 0) / downloadRawHistory.length
        if (uploadRawHistory.length > 0)
            avgUpload = uploadRawHistory.reduce((a, b) => a + b, 0) / uploadRawHistory.length
    }

    function _pushHistory(dl, ul) {
        // Update peaks
        if (dl > peakDownload) peakDownload = dl
        if (ul > peakUpload) peakUpload = ul

        // Raw history for averages
        downloadRawHistory = [...downloadRawHistory, dl]
        if (downloadRawHistory.length > historyLength)
            downloadRawHistory.shift()

        uploadRawHistory = [...uploadRawHistory, ul]
        if (uploadRawHistory.length > historyLength)
            uploadRawHistory.shift()

        // Normalised history for graphs
        downloadHistory = downloadRawHistory.map(v => v / peakDownload)
        uploadHistory = uploadRawHistory.map(v => v / peakUpload)

        _updateAverages()
    }

    Timer {
        id: pollTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            netDevFile.reload()

            const now = Date.now() / 1000.0
            const dt = _prevTime > 0 ? (now - _prevTime) : 1.0
            _prevTime = now

            const text = netDevFile.text()
            const lines = text.trim().split("\n")

            let totalRx = 0
            let totalTx = 0

            for (let i = 2; i < lines.length; ++i) {
                const line = lines[i].trim()
                if (!line) continue

                const colonIdx = line.indexOf(":")
                if (colonIdx === -1) continue

                const iface = line.slice(0, colonIdx).trim()
                // Skip loopback
                if (iface === "lo") continue

                const fields = line.slice(colonIdx + 1).trim().split(/\s+/)
                const rx = parseFloat(fields[0]) || 0
                const tx = parseFloat(fields[8]) || 0

                if (_prevRx[iface] !== undefined) {
                    let dRx = rx - _prevRx[iface]
                    let dTx = tx - _prevTx[iface]
                    // Handle counter wrap-around
                    if (dRx < 0) dRx = 0
                    if (dTx < 0) dTx = 0
                    totalRx += dRx
                    totalTx += dTx
                }

                _prevRx[iface] = rx
                _prevTx[iface] = tx
            }
            // Reassign objects so QML detects the property change
            // (in-place mutations of JS objects are not observed by QML bindings).
            _prevRx = Object.assign({}, _prevRx)
            _prevTx = Object.assign({}, _prevTx)

            // Skip speed recording on the very first tick when we are only
            // capturing initial counter values (no diff available yet).
            if (!_initialized) {
                _initialized = true
                return
            }

            downloadSpeed = totalRx / dt
            uploadSpeed = totalTx / dt
            _pushHistory(downloadSpeed, uploadSpeed)
        }
    }

    FileView {
        id: netDevFile
        path: "/proc/net/dev"
    }
}
