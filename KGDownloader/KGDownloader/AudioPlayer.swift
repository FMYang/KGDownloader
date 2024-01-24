//
//  AudioPlayer.swift
//  KGDownloader
//
//  Created by yfm on 2024/1/24.
//

import Foundation
import AVKit

class AudioPlayer {
    static let shared = AudioPlayer()
    private init() {}
    
    var player: AVPlayer?
    var songvm: SongViewModel?
    
    func play(songVM: SongViewModel) {
        songvm = songVM
        guard let playUrl = URL(string: songVM.song.play_url) else { return }
        let asset = AVAsset(url: playUrl)
        let item = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: item)
        player?.play()
        songvm?.isPlaying = true
    }
    
    func pause() {
        songvm?.isPlaying = false
        player?.pause()
    }
}
