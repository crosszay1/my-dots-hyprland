pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Simple polled resource usage service with RAM, Swap, and CPU usage.
 */
Singleton {
    id: root

    property real memoryTotal: 1
    property real memoryFree: 0
    property real memoryUsed: memoryTotal - memoryFree
    property real memoryUsedPercentage: memoryUsed / memoryTotal

    property real swapTotal: 1
    property real swapFree: 0
    property real swapUsed: swapTotal - swapFree
    property real swapUsedPercentage: swapTotal > 0 ? (swapUsed / swapTotal) : 0

    property real cpuUsage: 0
    property double cpuFrequency: 0
    property double cpuTemperature: 0
    property var previousCpuStats

    property string maxAvailableMemoryString: kbToGbString(memoryTotal)
    property string maxAvailableSwapString: kbToGbString(swapTotal)
    property string maxAvailableCpuString: "--"

    readonly property int historyLength: Config?.options.resources.historyLength ?? 60

    property list<real> cpuUsageHistory: []
    property list<real> memoryUsageHistory: []
    property list<real> swapUsageHistory: []

    function kbToGbString(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB"
    }

    function updateMemoryUsageHistory() {
        memoryUsageHistory = [...memoryUsageHistory, memoryUsedPercentage]
        if (memoryUsageHistory.length > historyLength)
            memoryUsageHistory.shift()
    }

    function updateSwapUsageHistory() {
        swapUsageHistory = [...swapUsageHistory, swapUsedPercentage]
        if (swapUsageHistory.length > historyLength)
            swapUsageHistory.shift()
    }

    function updateCpuUsageHistory() {
        cpuUsageHistory = [...cpuUsageHistory, cpuUsage]
        if (cpuUsageHistory.length > historyLength)
            cpuUsageHistory.shift()
    }

    function updateHistories() {
        updateMemoryUsageHistory()
        updateSwapUsageHistory()
        updateCpuUsageHistory()
    }

    Timer {
        interval: 1
        running: true
        repeat: true

        onTriggered: {
            fileMeminfo.reload()
            fileStat.reload()
            fileCpuinfo.reload()

            // Memory + Swap
            const textMeminfo = fileMeminfo.text()
            memoryTotal = Number(textMeminfo.match(/MemTotal: *(\d+)/)?.[1] ?? 1)
            memoryFree = Number(textMeminfo.match(/MemAvailable: *(\d+)/)?.[1] ?? 0)
            swapTotal = Number(textMeminfo.match(/SwapTotal: *(\d+)/)?.[1] ?? 1)
            swapFree = Number(textMeminfo.match(/SwapFree: *(\d+)/)?.[1] ?? 0)

            // CPU usage
            const textStat = fileStat.text()
            const cpuLine = textStat.match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)

            if (cpuLine) {
                const stats = cpuLine.slice(1).map(Number)
                const total = stats.reduce((a, b) => a + b, 0)
                const idle = stats[3]

                if (previousCpuStats) {
                    const totalDiff = total - previousCpuStats.total
                    const idleDiff = idle - previousCpuStats.idle
                    cpuUsage = totalDiff > 0 ? (1 - idleDiff / totalDiff) : 0
                }

                previousCpuStats = { total, idle }
            }

            // CPU frequency (average of cores)
            const cpuInfo = fileCpuinfo.text()
            const matches = cpuInfo.match(/cpu MHz\s+:\s+(\d+\.\d+)/g) ?? []

            if (matches.length > 0) {
                const freqs = matches.map(x =>
                    Number(x.match(/\d+\.\d+/)[0])
                )
                const avg = freqs.reduce((a, b) => a + b, 0) / freqs.length
                cpuFrequency = avg / 1000
            }

            // Refresh temp file
            tempProc.running = true

            updateHistories()
            interval = Config?.options?.resources?.updateInterval ?? 3000
        }
    }

    FileView { id: fileMeminfo; path: "/proc/meminfo" }
    FileView { id: fileStat; path: "/proc/stat" }
    FileView { id: fileCpuinfo; path: "/proc/cpuinfo" }

    // Get CPU max frequency once
    Process {
        id: findCpuMaxFreqProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        command: ["bash", "-c", "lscpu | grep 'CPU max MHz' | awk '{print $4}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const val = parseFloat(this.text)
                if (!isNaN(val))
                    maxAvailableCpuString = (val / 1000).toFixed(0) + " GHz"
            }
        }
    }

    // Create temp monitoring script once
    Process {
        id: fileCreationTempProc
        running: true
        command: ["bash", "-c",
            `${Directories.scriptPath}/cpu/coretemp.sh`.replace(/file:\/\//, "")
        ]
    }

    // Read CPU temperature
    Process {
        id: tempProc
        running: true
        command: ["bash", "-c", "cat /tmp/quickshell/coretemp"]
        stdout: StdioCollector {
            onStreamFinished: {
                const val = Number(this.text)
                if (!isNaN(val))
                    cpuTemperature = val / 1000
            }
        }
    }
}