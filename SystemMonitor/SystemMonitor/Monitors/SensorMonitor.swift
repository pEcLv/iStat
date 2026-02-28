import Foundation
import IOKit

@MainActor
class SensorMonitor: ObservableObject {
    @Published var cpuTemperature: Double = 0
    @Published var gpuTemperature: Double = 0
    @Published var fanSpeeds: [FanInfo] = []

    struct FanInfo: Identifiable {
        let id: Int
        let name: String
        let rpm: Int
    }

    private var smcConnection: io_connect_t = 0

    func update() {
        openSMC()
        cpuTemperature = readTemperature(key: "TC0P") ?? readTemperature(key: "TC0D") ?? 0
        gpuTemperature = readTemperature(key: "TG0P") ?? readTemperature(key: "TG0D") ?? 0
        fanSpeeds = readFans()
    }

    private func openSMC() {
        guard smcConnection == 0 else { return }
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        guard service != 0 else { return }
        IOServiceOpen(service, mach_task_self_, 0, &smcConnection)
        IOObjectRelease(service)
    }

    private func readTemperature(key: String) -> Double? {
        guard smcConnection != 0 else { return nil }
        var inputStruct = SMCKeyData()
        var outputStruct = SMCKeyData()

        inputStruct.key = fourCharCode(key)
        inputStruct.data8 = 5 // kSMCReadKey

        var outputSize = MemoryLayout<SMCKeyData>.size
        let result = IOConnectCallStructMethod(
            smcConnection, 2,
            &inputStruct, MemoryLayout<SMCKeyData>.size,
            &outputStruct, &outputSize
        )

        guard result == kIOReturnSuccess else { return nil }

        let value = Double(Int16(outputStruct.bytes.0) << 8 | Int16(outputStruct.bytes.1)) / 256.0
        return value > 0 && value < 150 ? value : nil
    }

    private func readFans() -> [FanInfo] {
        guard smcConnection != 0 else { return [] }
        var fans: [FanInfo] = []

        for i in 0..<4 {
            if let rpm = readFanRPM(index: i), rpm > 0 {
                fans.append(FanInfo(id: i, name: "Fan \(i)", rpm: rpm))
            }
        }
        return fans
    }

    private func readFanRPM(index: Int) -> Int? {
        let key = "F\(index)Ac"
        guard smcConnection != 0 else { return nil }

        var inputStruct = SMCKeyData()
        var outputStruct = SMCKeyData()

        inputStruct.key = fourCharCode(key)
        inputStruct.data8 = 5

        var outputSize = MemoryLayout<SMCKeyData>.size
        let result = IOConnectCallStructMethod(
            smcConnection, 2,
            &inputStruct, MemoryLayout<SMCKeyData>.size,
            &outputStruct, &outputSize
        )

        guard result == kIOReturnSuccess else { return nil }

        let value = (Int(outputStruct.bytes.0) << 6) + (Int(outputStruct.bytes.1) >> 2)
        return value > 0 ? value : nil
    }

    private func fourCharCode(_ str: String) -> UInt32 {
        var result: UInt32 = 0
        for char in str.utf8.prefix(4) {
            result = (result << 8) | UInt32(char)
        }
        return result
    }

    deinit {
        if smcConnection != 0 {
            IOServiceClose(smcConnection)
        }
    }
}

private struct SMCKeyData {
    var key: UInt32 = 0
    var vers: (UInt8, UInt8, UInt8, UInt8) = (0, 0, 0, 0)
    var pLimitData: (UInt16, UInt16, UInt32, UInt32, UInt32) = (0, 0, 0, 0, 0)
    var keyInfo: (UInt32, UInt32, UInt8) = (0, 0, 0)
    var padding: UInt8 = 0
    var result: UInt8 = 0
    var status: UInt8 = 0
    var data8: UInt8 = 0
    var data32: UInt32 = 0
    var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) =
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
}
