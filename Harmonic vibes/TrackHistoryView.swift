import SwiftUI
import WebKit

struct TrackHistoryView: View {
    var body: some View {
        WebView(url: URL(string: "https://widget.radioking.io/played-tracks/build/script.min.js")!)
            .navigationBarTitle("Track History", displayMode: .inline)
            .edgesIgnoringSafeArea(.all) // Make the WebView take up the full screen
    }
}

// Custom WebView for displaying HTML content
struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        let htmlString = """
        <html>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
            </head>
            <body style="margin: 0; padding: 0;">
                <div id="rk-played-tracks-widget" data-id="harmonicvibes" data-count="10" data-date="0" data-buy="1"></div>
                <script type="text/javascript" src="https://widget.radioking.io/played-tracks/build/script.min.js"></script>
            </body>
        </html>
        """
        
        webView.loadHTMLString(htmlString, baseURL: nil)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
