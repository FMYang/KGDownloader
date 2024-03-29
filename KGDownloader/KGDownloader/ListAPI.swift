//
//  ListTarget.swift
//  zhihu
//
//  Created by yfm on 2023/10/10.
//

import Foundation
import Alamofire

enum ListAPI {
    case search(String, Int)
    case songInfo(String, String)
    case playInfo(String, String, String, String, String)
}

extension ListAPI: APITarget {
    var host: String {
        switch self {
        case .search:
            return "https://songsearch.kugou.com"
        case .songInfo:
            return "https://www.kugou.com"
        case .playInfo:
            return "https://wwwapi.kugou.com"
        }
    }
    
    var path: String {
        switch self {
        case .search(let text, let page):
            return "/song_search_v2?keyword=\(text)&page=\(page)&pagesize=10&filter=2&platform=WebFilter".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        case .songInfo(let hash, let mixSongId):
            return "/yy/index.php?r=play/getdata&hash=\(hash)&album_audio_id=\(mixSongId)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        case let .playInfo(time, token, encode_album_audio_id, signature, userId):
            return "/play/songinfo?srcappid=2919&clientver=20000&clienttime=\(time)&mid=c3c3374152df945246969fee3f15f108&uuid=c3c3374152df945246969fee3f15f108&dfid=1Jcfej3YdDZy2atfXD11pFRw&appid=1014&platid=4&encode_album_audio_id=\(encode_album_audio_id)&token=\(token)&userid=\(userId)&signature=\(signature)"
        }
    }
    
    var headers: [String : String]? {
        switch self {
        case .search, .songInfo:
            return [
                "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
//                "cookie": "kg_mid=\(time)",
                "cookie": "kg_mid=\(time)"
            ]
        default:
            return nil
        }
    }
    
    var time: String {
        //        String(format: "%.0f", Date().timeIntervalSince1970)
        let currentDate = Date()
        let timestamp = Int64(currentDate.timeIntervalSince1970 * 1000)
        let timestampString = String(timestamp)
        
        return timestampString
    }
}
