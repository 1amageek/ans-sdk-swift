#if !hasFeature(Embedded)
#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

public enum SCITTClock {
    public static func unixTime() -> Int64 {
#if canImport(FoundationEssentials) || canImport(Foundation)
        Int64(Date().timeIntervalSince1970)
#else
        0
#endif
    }

    public static func seconds(from duration: Duration) -> Int64 {
        let components = duration.components
        if components.seconds < 0 {
            return 0
        }
        return components.seconds
    }

    public static func adding(_ lhs: Int64, _ rhs: Int64) -> Int64 {
        let (sum, overflow) = lhs.addingReportingOverflow(rhs)
        if overflow {
            return rhs >= 0 ? Int64.max : Int64.min
        }
        return sum
    }
}
#endif
