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
        NotificationCenter.default.removeObserver(self)
        songvm = songVM
        guard let playUrl = URL(string: songVM.song.play_url) else { return }
        let asset = AVAsset(url: playUrl)
        let item = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: item)
        player?.play()
        songvm?.isPlaying = true
        NotificationCenter.default.addObserver(self, selector: #selector(didPlayToEndNoti), name: AVPlayerItem.didPlayToEndTimeNotification, object: item)
    }
    
    func pause() {
        songvm?.isPlaying = false
        player?.pause()
    }
    
    @objc func didPlayToEndNoti() {
        songvm?.isPlaying = false
    }
}
