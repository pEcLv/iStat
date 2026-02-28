import Foundation

extension Double {
    /// 格式化为百分比字符串
    func toPercentString(decimals: Int = 1) -> String {
        String(format: "%.\(decimals)f%%", self)
    }
}

extension UInt64 {
    /// 格式化为可读的字节大小
    func toByteString() -> String {
        ByteCountFormatter.string(fromByteCount: Int64(self), countStyle: .file)
    }

    /// 格式化为内存大小
    func toMemoryString() -> String {
        ByteCountFormatter.string(fromByteCount: Int64(self), countStyle: .memory)
    }
}

extension Int {
    /// 格式化温度
    func toTemperatureString() -> String {
        "\(self)°C"
    }

    /// 格式化风扇转速
    func toRPMString() -> String {
        "\(self) RPM"
    }
}

extension Date {
    /// 格式化为时间字符串
    func toTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: self)
    }
}
