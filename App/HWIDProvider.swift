import IOKit

class HWIDProvider {
    static func getHWID() -> String {
        var hwid = "unknown"
        let platformExpert = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))

        if platformExpert != 0 {
            if let cfUUID = IORegistryEntryCreateCFProperty(
                platformExpert,
                "IOPlatformUUID" as CFString,
                kCFAllocatorDefault,
                0
            )?.takeUnretainedValue() as? String {
                hwid = cfUUID
            }
            IOObjectRelease(platformExpert)
        }

        return hwid
    }
}
