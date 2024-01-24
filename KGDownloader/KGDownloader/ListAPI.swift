//
//  ListTarget.swift
//  zhihu
//
//  Created by yfm on 2023/10/10.
//

import Foundation
import Alamofire

enum ListAPI {
    case search(String)
    case songInfo(String)
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
        case .search(let text):
            return "/song_search_v2?keyword=\(text)&page=1&pagesize=10&filter=2&platform=WebFilter".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        case .songInfo(let hash):
            return "/yy/index.php?r=play/getdata&hash=\(hash)&album_audio_id=".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        case let .playInfo(time, token, encode_album_audio_id, signature, userId):
            return "/play/songinfo?srcappid=2919&clientver=20000&clienttime=\(time)&mid=c3c3374152df945246969fee3f15f108&uuid=c3c3374152df945246969fee3f15f108&dfid=1Jcfej3YdDZy2atfXD11pFRw&appid=1014&platid=4&encode_album_audio_id=\(encode_album_audio_id)&token=\(token)&userid=\(userId)&signature=\(signature)"
        }
    }
    
    var headers: [String : String]? {
        switch self {
        case .search, .songInfo:
            return [
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:107.0) Gecko/20100101 Firefox/107.0",
                "cookie": "kg_mid=\(time)",
            ]
        default:
            return nil
        }
    }
    
    var time: String {
        String(format: "%.0f", Date().timeIntervalSince1970)
    }
}
