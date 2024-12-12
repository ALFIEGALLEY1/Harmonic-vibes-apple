import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var isPlaying = false
    @State private var player: AVPlayer?
    @State private var trackInfo: TrackInfo = TrackInfo(name: "Unknown Song", artist: "Unknown Artist", artwork: nil)
    @State private var timer: Timer?
    @State private var currentTime: CMTime = .zero
    @State private var totalTime: CMTime = .zero

    let streamURL = "https://play.radioking.io/harmonicvibes" // Your radio stream link
    let radiokingAPIURL = "https://api.radioking.io/widget/radio/harmonicvibes/track/current?format=text" // API for current track info

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient (Dark theme)
                LinearGradient(gradient: Gradient(colors: [Color.black, Color.gray]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    // Title of your app
                    Text("Harmonic Vibes")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 40)
                        .shadow(color: Color.black.opacity(0.7), radius: 5, x: 0, y: 5)

                    // Display current track information
                    VStack(spacing: 16) {
                        if let artworkURL = trackInfo.artwork, let url = URL(string: artworkURL) {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Color.gray.opacity(0.5) // Placeholder while loading
                            }
                            .frame(width: 280, height: 280)
                            .clipShape(Circle()) // Circular artwork
                            .shadow(radius: 12)
                        }

                        Text(trackInfo.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.top, 10)

                        Text(trackInfo.artist)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.bottom, 20)

                        // Progress bar (current time vs. total time)
                        ProgressView(value: currentTime.seconds, total: totalTime.seconds)
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                            .padding(.top, 20)
                            .frame(width: 280)
                    }
                    .padding(.top, 40)

                    Spacer()

                    // Play/Pause button with modern styling
                    Button(action: togglePlayPause) {
                        Text(isPlaying ? "Pause" : "Play Live")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 250, height: 70)
                            .background(isPlaying ? Color.red : Color.green)
                            .cornerRadius(35)
                            .shadow(radius: 12)
                            .padding(.bottom, 20)
                    }

                    // Navigation to Track History (Recent Played Tracks)
                    NavigationLink(destination: TrackHistoryView()) {
                        Text("View Played Tracks")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 250, height: 60)
                            .background(Color.blue)
                            .cornerRadius(30)
                            .shadow(radius: 10)
                    }

                    // Settings Button
                    NavigationLink(destination: SettingsView()) {
                        Text("Settings")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 250, height: 60)
                            .background(Color.gray)
                            .cornerRadius(30)
                            .shadow(radius: 10)
                    }

                    Spacer()
                }
                .padding()
                .onAppear {
                    setupPlayer()
                    fetchTrackInfoFromRadioking()
                    startTrackInfoTimer() // Start periodic track info fetching
                    setupNowPlayingUpdates()
                }
                .onDisappear {
                    stopTrackInfoTimer() // Stop timer when view disappears
                }
            }
            .navigationBarHidden(true) // Hide default navigation bar
        }
    }

    // Initialize the AVPlayer for streaming
    func setupPlayer() {
        guard let url = URL(string: streamURL) else { return }
        player = AVPlayer(url: url)
    }

    // Fetch track info from Radioking API
    func fetchTrackInfoFromRadioking() {
        guard let url = URL(string: radiokingAPIURL) else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Error fetching track info: \(error.localizedDescription)")
                return
            }

            if let data = data {
                if let trackString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    let components = trackString.split(separator: "-")
                    if components.count >= 2 {
                        let artist = String(components[0]).trimmingCharacters(in: .whitespaces)
                        let name = String(components[1]).trimmingCharacters(in: .whitespaces)

                        DispatchQueue.main.async {
                            // Only update if track info has changed
                            if self.trackInfo.name != name || self.trackInfo.artist != artist {
                                self.trackInfo.name = name
                                self.trackInfo.artist = artist
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.trackInfo.name = trackString
                            self.trackInfo.artist = "Unknown Artist"
                        }
                    }
                }
            }
        }.resume()
    }

    // Setup updates for Now Playing Info (ID3 Tags)
    func setupNowPlayingUpdates() {
        NotificationCenter.default.addObserver(forName: .AVPlayerItemNewAccessLogEntry, object: nil, queue: .main) { _ in
            guard let player = player,
                  let currentItem = player.currentItem,
                  let metadata = currentItem.asset.commonMetadata as? [AVMetadataItem] else {
                return
            }

            // Parse ID3 tags
            var newTrackInfo = TrackInfo(name: "Unknown Song", artist: "Unknown Artist", artwork: nil)

            for item in metadata {
                if let key = item.commonKey?.rawValue {
                    switch key {
                    case "title":
                        newTrackInfo.name = item.value as? String ?? "Unknown Song"
                    case "artist":
                        newTrackInfo.artist = item.value as? String ?? "Unknown Artist"
                    case "artwork":
                        if let imageData = item.dataValue,
                           let artworkURL = saveImageToTemporaryDirectory(data: imageData) {
                            newTrackInfo.artwork = artworkURL.absoluteString
                        }
                    default:
                        break
                    }
                }
            }

            DispatchQueue.main.async {
                self.trackInfo = newTrackInfo
            }
        }
    }

    // Save artwork to temporary directory and return its URL
    func saveImageToTemporaryDirectory(data: Data) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let artworkURL = tempDir.appendingPathComponent("artwork.jpg")
        do {
            try data.write(to: artworkURL)
            return artworkURL
        } catch {
            print("Error saving artwork: \(error.localizedDescription)")
            return nil
        }
    }

    // Toggle play/pause state
    func togglePlayPause() {
        if isPlaying {
            player?.pause()
        } else {
            restartStream()
        }
        isPlaying.toggle()
    }

    // Restart the stream to ensure it always starts live
    func restartStream() {
        player?.pause() // Stop current playback
        guard let url = URL(string: streamURL) else { return }
        player = AVPlayer(url: url) // Reinitialize the player
        player?.play() // Start live playback
    }

    // Start periodic track info fetching
    func startTrackInfoTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            fetchTrackInfoFromRadioking()  // Refresh track info every 30 seconds
        }
    }

    // Stop periodic track info fetching
    func stopTrackInfoTimer() {
        timer?.invalidate()
    }
}

struct TrackInfo {
    var name: String
    var artist: String
    var artwork: String?
}
