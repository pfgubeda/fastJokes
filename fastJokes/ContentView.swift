//
//  ContentView.swift
//  fastJokes
//
//  Created by Pablo Fernandez Gonzalez on 8/2/24.
//

import SwiftUI

struct JokeSentence: Identifiable, Equatable {
    let id = UUID()
    var content: String

    static func == (lhs: JokeSentence, rhs: JokeSentence) -> Bool {
        return lhs.id == rhs.id
    }
}

public enum AvailableCategories: String, CaseIterable, Identifiable {
    case All
    case Programming
    case Miscellaneous
    case Dark
    case Pun
    case Spooky
    case Christmas
    
    public var id: Self { return self }
    var title: String{
        switch self{
        case .All:
            return "All"
        case .Programming:
            return "Programming"
        case .Miscellaneous:
            return "Miscellaneous"
        case .Dark:
            return "Dark"
        case .Pun:
            return "Pun"
        case .Spooky:
            return "Spooky"
        case .Christmas:
            return "Christmas"
        }
    }
}

class JokeList: ObservableObject {
    @Published var jokeSentences = [
        JokeSentence(content: "Slide to start"),
    ]
    @Published var counter = 0

    private let jokeSentenceGenerationService = JokeSentenceService()

    func addNewSentence(category : AvailableCategories) async {
        let newJokeSentence = await jokeSentenceGenerationService.getJokeSentence(id: counter, category: category)
        // apaño para el warining : Publishing changes from background threads is not allowed; make sure to publish values from the main thread (via operators like receive(on:)) on model updates
        DispatchQueue.main.async {
            self.jokeSentences.append(newJokeSentence)
        }
    }
}

struct ContentView: View {
    @StateObject var jokeList = JokeList()
    @State private var swipeOffset: CGSize = .zero
    @State private var removedSentence: JokeSentence? = nil
    @State private var selectedCategories = AvailableCategories.All
    
    private var maxID: Int {
        return self.jokeList.jokeSentences.map { $0.id.hashValue }.max() ?? 0
    }

    var body: some View {
        VStack {
            VStack(spacing: 0){
                Text("Fast").font(.custom("DIN Condensed Bold", size: 30)).bold().lineLimit(1).padding([.top], 15).padding([.bottom], -15)
                Text("Jokes").font(.custom("AmericanTypewriter", size: 38)).lineLimit(1)
            }
            Picker("Categories", selection: $selectedCategories){
                ForEach(AvailableCategories.allCases){
                    Text($0.title).tag($0)
                }
            }.pickerStyle(.menu)
            
            GeometryReader { geometry in
                VStack(spacing: 24) {
                    ZStack {
                        ForEach(jokeList.jokeSentences.indices, id: \.self) { index in
                            let jokeSentence = jokeList.jokeSentences[index]

                            Group {
                                if (self.maxID - 3)...self.maxID ~= jokeSentence.id.hashValue {
                                    CardView(jokeSentence: jokeSentence, onRemove: { removedSentence in
                                        self.removedSentence = removedSentence
                                    })
                                    .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.25), value: UUID())
                                    .frame(width: geometry.size.width - CGFloat(index) * 10, height: 400)
                                    .offset(x: index == jokeList.jokeSentences.count - 1 ? swipeOffset.width : 0,
                                            y: index == jokeList.jokeSentences.count - 1 ? swipeOffset.height : 0)
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                self.swipeOffset.width = value.translation.width
                                            }
                                            .onEnded { value in
                                                if abs(swipeOffset.width) > 100 {
                                                    withAnimation {
                                                        removedSentence = jokeSentence
                                                        jokeList.jokeSentences.removeAll { $0.id == removedSentence?.id }
                                                        Task{
                                                            await jokeList.addNewSentence(category: selectedCategories)
                                                        }
                                                        swipeOffset = .zero
                                                    }
                                                } else {
                                                    withAnimation {
                                                        swipeOffset = .zero
                                                    }
                                                }
                                            }
                                    )
                                }
                            }
                        }
                    }
                    Spacer()
                }
            }
        }
        .padding()
    }
}


struct CardView: View {
    var jokeSentence: JokeSentence
    var onRemove: (JokeSentence) -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.blue)
                .frame(width: 300, height: 200)
                .overlay(
                    Text(jokeSentence.content)
                        .foregroundColor(.white)
                        .padding()
                )
        }
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}
