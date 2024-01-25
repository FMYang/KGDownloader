//
//  Downloader.swift
//  KGDownloader
//
//  Created by yfm on 2024/1/23.
//

import Foundation
import Combine
import CommonCrypto
import Alamofire

// MARK: - 搜索结果
class SearchData: Codable {
    var error_code: Int?
    var error_msg: String?
    var data: SearchLists?
}

class SearchLists: Codable {
    var lists: [SearchItem] = []
}

class SearchItem: Codable {
    var FileHash: String?
    // album_audio_id
    var MixSongID: String?
}

// MARK: - 歌曲信息结果
class SongData: Codable {
    var data: SongInfo?
}

class SongInfo: Codable {
    var encode_album_audio_id: String = ""
}

// MARK: - 歌曲完整信息
class PlayInfo: Codable {
    var data: Song?
}

class Song: Codable, Identifiable {
    var audio_name: String = ""
    var song_name: String = ""
    var play_url: String = ""
    var timelength: Int = 0
    var filesize: Int = 0
    var author_name: String = ""
    var is_free_part: Int = 0
    var img: String = ""
    var album_audio_id: Int64 = 0
    var lyrics: String = ""
}

class SongViewModel: ObservableObject {
    var song: Song
    @Published var downloadState: DownloadState = .normal
    @Published var isPlaying: Bool = false
    
    init(song: Song) {
        self.song = song
    }
}

enum DownloadState {
    case normal
    case downloading(Double)
    case finished
    case failed
}

enum MyError: Error {
    case requestError
}

class Downloader: ObservableObject {
    var subscriptions = Set<AnyCancellable>()

    @Published var token: String = ""
    @Published var userId: String = "1562760404"
    @Published var searchText: String = ""
    @Published var result: [SongViewModel] = []
    @Published var errormsg: String = ""
    @Published var loading: Bool = false
    
    func search() {
        result = []
        // 1.获取hash
        loading = true
        APIService.request(target: ListAPI.search(searchText), type: SearchData.self)
            .tryMap { response in
                switch response.result {
                case .success(let data):
                    if data.error_code == 0 {
                        let hashs = data.data?.lists.compactMap { $0.FileHash }
                        return hashs ?? []
                    } else {
                        self.errormsg = data.error_msg ?? "搜索出错"
                        throw MyError.requestError
                    }
                case .failure(let error):
                    self.errormsg = "搜索出错"
                    throw error
                }
            }
            .flatMap { resultArr -> Publishers.Sequence<Array<String>, Error> in
                return Publishers.Sequence(sequence: resultArr)
            }
            .eraseToAnyPublisher()
            .flatMap { hash -> AnyPublisher<String?, Error> in
                // 2.根据hash获取encode_album_audio_id
                return APIService.request(target: ListAPI.songInfo(hash), type: SongData.self)
                    .tryMap { response in
                        switch response.result {
                        case .success(let song):
                            return song.data.map { $0.encode_album_audio_id }
                        case .failure(let error):
                            self.errormsg = "获取hash出错"
                            throw error
                        }
                    }
                    .eraseToAnyPublisher()
            }
            .collect()
            .eraseToAnyPublisher()
            .flatMap { resultArr -> Publishers.Sequence<Array<String?>, Error> in
                return Publishers.Sequence(sequence: resultArr)
            }
            .eraseToAnyPublisher()
            .flatMap { [unowned self] encodeId -> AnyPublisher<PlayInfo?, Error> in
                // 3.根据encode_album_audio_id获取完整的播放信息
                return APIService.request(target: ListAPI.playInfo(self.time(), self.token, encodeId ?? "", self.signature(encodeId: encodeId ?? ""), self.userId), type: PlayInfo.self)
                    .tryMap { response in
                        switch response.result {
                        case .success(let playInfo):
                            self.errormsg = ""
                            return playInfo
                        case .failure(let error):
                            self.errormsg = "获取播放地址错误: \(error.localizedDescription)"
                            throw error
                        }
                    }
                    .eraseToAnyPublisher()
            }
            .collect()
            .eraseToAnyPublisher()
            .sink(receiveCompletion: { [weak self] completion in
                self?.loading = false
            }, receiveValue: { [weak self] value in
                let data = value.compactMap { $0?.data }
                self?.result = data.map { SongViewModel(song: $0) }
            })
            .store(in: &subscriptions)
    }
    
//    func search1() {
//        // 1.获取hash
//        APIService.request(target: ListAPI.search(searchText), type: SearchData.self)
//            .tryMap { response in
//                switch response.result {
//                case .success(let data):
//                    let hashs = data.data?.lists.compactMap { $0.FileHash }
//                    return hashs ?? []
//                case .failure(let error):
//                    self.error = "搜索出错"
//                    throw error
//                }
//            }
//            .flatMap { resultArr -> Publishers.Sequence<Array<String>, Error> in
//                return Publishers.Sequence(sequence: resultArr)
//            }
//            .eraseToAnyPublisher()
//            .flatMap { hash -> AnyPublisher<Song?, Error> in
//                // 2.根据hash获取encode_album_audio_id
//                return APIService.request(target: ListAPI.songInfo(hash), type: PlayInfo.self)
//                    .tryMap { response in
//                        switch response.result {
//                        case .success(let info):
//                            return info.data
//                        case .failure(let error):
//                            self.error = "获取hash出错"
//                            throw error
//                        }
//                    }
//                    .eraseToAnyPublisher()
//            }
//            .collect()
//            .eraseToAnyPublisher()
//            .sink { completion in
//            } receiveValue: { [weak self] value in
//                if value.count > 0 {
//                    self?.error = ""
//                } else {
//                    self?.error = "获取播放地址出错"
//                }
//                let data = value.compactMap { $0 }
//                self?.result = data
//            }
//            .store(in: &subscriptions)
//    }
    
    func download(song: SongViewModel) {
        song.downloadState = .downloading(0.0)
        let destination: DownloadRequest.Destination = { url, response in
            let savePath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0].appendingPathComponent(song.song.audio_name + ".mp3")
            return (savePath, [.createIntermediateDirectories, .removePreviousFile])
        }
        print(song.song.play_url)
        APIService.alamofire.download(song.song.play_url, headers: nil, to: destination)
            .downloadProgress(closure: { progress in
                let downloadProgress = progress.fractionCompleted
                song.downloadState = .downloading(downloadProgress)
//                print(downloadProgress)
            })
            .response { response in
                switch response.result {
                case .success(let url):
                    song.downloadState = .finished
                    print("下载完成 \(url?.absoluteString ?? "")")
//                    if let local = url {
//                        let savePanel = NSOpenPanel()
//                        savePanel.canCreateDirectories = true
//                        savePanel.canChooseDirectories = true
//                        savePanel.canChooseFiles = false
//                        
//                        savePanel.begin { (result) in
//                            if result.rawValue == NSApplication.ModalResponse.OK.rawValue, let destinationURL = savePanel.url?.appendingPathComponent(response.response?.suggestedFilename ?? local.lastPathComponent) {
//                                do {
//                                    try FileManager.default.moveItem(at: local, to: destinationURL)
//                                    print("文件已下载到：\(destinationURL.path)")
//                                } catch {
//                                    print("移动文件失败: \(error.localizedDescription)")
//                                }
//                            }
//                        }
//                    }
                case .failure(let error):
                    print(error)
                    song.downloadState = .failed
                }
        }
    }
    
    func signature(encodeId: String) -> String {
        print("fm \(userId)")
        let ts = String(Int(Date().timeIntervalSince1970 * 1000))
        let mid = "c3c3374152df945246969fee3f15f108"
        let uuid = mid
        let dfid = "1Jcfej3YdDZy2atfXD11pFRw"
        let signTemplate = "NVPh5oo715z5DIWAeQlhMDsWXXQV4hwtappid=1014clienttime=%@clientver=20000dfid=%@encode_album_audio_id=%@mid=%@platid=4srcappid=2919token=\(token)userid=\(userId)uuid=%@NVPh5oo715z5DIWAeQlhMDsWXXQV4hwt"
        let signStr = String(format: signTemplate, ts, dfid, encodeId, mid, uuid)
        let signature = signStr.md5()
        return signature
    }
    
    func time() -> String {
        return String(Int(Date().timeIntervalSince1970 * 1000))
    }
}

extension String {
    func md5() -> String {
        let messageData = self.data(using:.utf8)!
        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        
        _ = digestData.withUnsafeMutableBytes { digestBytes in
            messageData.withUnsafeBytes { messageBytes in
                CC_MD5(messageBytes.baseAddress, CC_LONG(messageData.count), digestBytes.bindMemory(to: UInt8.self).baseAddress)
            }
        }
        
        var md5String = ""
        for byte in digestData {
            md5String += String(format: "%02x", byte)
        }
        
        return md5String
    }
}
