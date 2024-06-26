//
//  RepoListWidget.swift
//  RepoListWidget
//
//  Created by jiyeon on 5/21/24.
//

import WidgetKit
import SwiftUI

import GitodoShared

struct Provider: TimelineProvider {
    let service = RepoListWidgetService()
    
    func placeholder(in context: Context) -> RepoListEntry {
        RepoListEntry(date: Date(), repos: [])
    }
    
    func getSnapshot(in context: Context, completion: @escaping (RepoListEntry) -> Void) {
        let repos = (try? service.fetchTopPublicRepos()) ?? []
        let entry = RepoListEntry(date: Date(), repos: repos)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<RepoListEntry>) -> Void) {
        let repos = (try? service.fetchTopPublicRepos()) ?? []
        let entry = RepoListEntry(date: Date(), repos: repos)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct RepoListWidget: Widget {
    let kind: String = "RepoListWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                RepoListWidgetEntryView(entry: entry)
                    .containerBackground(.background, for: .widget)
            } else {
                RepoListWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("레포지토리 할 일 현황")
        .description("각 레포지토리의 할 일 현황을 볼 수 있습니다.")
        .supportedFamilies([.systemSmall]) // Small 크기만 지원
    }
}

#Preview(as: .systemSmall) {
    RepoListWidget()
} timeline: {
    RepoListEntry(date: .now, repos: [])
}
