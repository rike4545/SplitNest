import SwiftUI

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds

struct BannerAdContainerView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sponsored")
                .font(.caption)
                .foregroundStyle(.secondary)

            GeometryReader { proxy in
                let width = max(1, proxy.size.width)
                let adSize = currentOrientationAnchoredAdaptiveBanner(width: width)

                BannerAdView(adUnitID: AdMobConfig.bannerAdUnitID, width: width)
                    .frame(width: width, height: adSize.size.height)
            }
            .frame(height: 60)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct BannerAdView: UIViewRepresentable {
    let adUnitID: String
    let width: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView()
        banner.adUnitID = adUnitID
        banner.delegate = context.coordinator
        loadAd(into: banner, width: width)
        context.coordinator.lastLoadedWidth = width
        return banner
    }

    func updateUIView(_ banner: BannerView, context: Context) {
        guard abs(context.coordinator.lastLoadedWidth - width) > 1 else { return }
        loadAd(into: banner, width: width)
        context.coordinator.lastLoadedWidth = width
    }

    private func loadAd(into banner: BannerView, width: CGFloat) {
        let adSize = currentOrientationAnchoredAdaptiveBanner(width: width)
        banner.adSize = adSize
        banner.load(Request())
    }

    final class Coordinator: NSObject, BannerViewDelegate {
        var lastLoadedWidth: CGFloat = 0
    }
}
#else
struct BannerAdContainerView: View {
    var body: some View {
        EmptyView()
    }
}
#endif
