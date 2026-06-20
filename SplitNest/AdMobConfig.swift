import Foundation

enum AdMobConfig {
    static let appID = "ca-app-pub-9917450718827221~1768716819"
    static let liveBannerAdUnitID = "ca-app-pub-9917450718827221/9739432523"
    static let testBannerAdUnitID = "ca-app-pub-3940256099942544/2435281174"

    static var bannerAdUnitID: String {
#if DEBUG
        return testBannerAdUnitID
#else
        return liveBannerAdUnitID
#endif
    }
}
