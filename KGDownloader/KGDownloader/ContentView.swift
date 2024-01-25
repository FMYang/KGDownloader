//
//  ContentView.swift
//  KGDownloader
//
//  Created by yfm on 2024/1/23.
//

import SwiftUI

struct CustomCell: View {
    @ObservedObject var downloader: Downloader
    @ObservedObject var songVM: SongViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(content: {
                Text(songVM.song.audio_name)
                Text("\((songVM.song.is_free_part == 1) ? "(vip)" : "")")
                    .foregroundColor(.red)
                Spacer()
                Button(action: {
                    if songVM.isPlaying {
                        AudioPlayer.shared.pause()
                    } else {
                        downloader.result.forEach { $0.isPlaying = false }
                        AudioPlayer.shared.play(songVM: songVM)
                    }
                }, label: {
                    Text(songVM.isPlaying ? "停止" : "播放")
                        .frame(width: 40)
                })
                switch songVM.downloadState {
                case .normal:
                    Button {
                        downloader.download(song: songVM)
                    } label: {
                        Text("下载")
                            .frame(width: 40)
                    }
                case .downloading(let progress):
                    Text("\(Int(progress * 100))%")
                        .frame(width: 60, alignment: .center)
                        .foregroundColor(.blue)
                case .finished:
                    Text("下载成功")
                        .frame(width: 60, alignment: .center)
                        .foregroundColor(.blue)
                case .failed:
                    Text("下载失败")
                        .frame(width: 60, alignment: .center)
                        .foregroundColor(.red)
                }
            })
        }
        .padding(.vertical, 4)
    }
}

struct ContentView: View {
    @ObservedObject var downloader = Downloader()
    var body: some View {
        VStack {
            HStack(content: {
                Text("token: ")
                    .frame(width: 60)
                TextField("请输入Token(下载VIP完整歌曲需要token，不填写下载试听版本)", text: $downloader.token)
            })
            HStack(content: {
                Text("userId: ")
                    .frame(width: 60)
                TextField("请输入酷狗的用户id", text: $downloader.userId)
            })
            HStack(content: {
                Button("搜索") {
                    downloader.search()
                }
                .frame(width: 60)
                TextField("输出歌手名或歌曲名搜索", text: $downloader.searchText)
            })
            HStack(content: {
                Text("result: ")
                    .frame(width: 60, alignment: .center)
                Text(downloader.errormsg)
                    .foregroundColor(.red)
                Spacer()
            })
            ZStack {
                if downloader.loading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.5)
                        .padding()
                        .zIndex(1)
                }
                List(downloader.result, id: \.song.album_audio_id) { item in
                    CustomCell(downloader: downloader, songVM: item)
                }
            }
            HStack {
                Button("上一页") {
                    downloader.searchPrevious()
                }
                Button("下一页") {
                    downloader.searchNext()
                }
                Spacer()
                Text("文件默认保存在下载文件夹")
                Button {
                    let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
                    NSWorkspace.shared.open(downloadsURL)
                } label: {
                    Text("打开")
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
