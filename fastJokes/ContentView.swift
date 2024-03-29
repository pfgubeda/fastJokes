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

public enum AvailableLanguages: String, CaseIterable, Identifiable {
    case En
    case Es
    //case Fr not supported by api
    //case Pt not supported by api
    case De
    case Cs
    
    public var id: Self { return self }
    var title: String{
        switch self{
        case .En:
            return "English"
        case .Es:
            return "Spanish"
       /* 
        case .Fr:
            return "French"
        case .Pt:
            return "Portuguese" 
        */
        case .De:
            return "German"
        case .Cs:
            return "Czech"
        }
    }
}

class JokeList: ObservableObject {
    @Published var jokeSentences = [
        JokeSentence(content: "Slide to start"),
    ]
    @Published var counter = 0

    private let jokeSentenceGenerationService = JokeSentenceService()

    func addNewSentence(category : AvailableCategories, language: AvailableLanguages) async {
        let newJokeSentence = await jokeSentenceGenerationService.getJokeSentence(id: counter, category: category, language: language)
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
    @State private var selectedLanguage = AvailableLanguages.En
    @State private var isTitlePresented = false
    @State private var scale: CGFloat = 1.0
    @State private var offsetY: CGFloat = 0.0
    
    private var maxID: Int {
        return self.jokeList.jokeSentences.map { $0.id.hashValue }.max() ?? 0
    }

    var body: some View {
        VStack {
                VStack(spacing: 0){
                    Text("Fast").font(.custom("DIN Condensed Bold", size: 80)).bold().lineLimit(1).padding([.top], 15).padding([.bottom], -50)
                    Text("Jokes").font(.custom("AmericanTypewriter", size: 100)).lineLimit(1)
                }.scaleEffect(scale)
                    .offset(y: offsetY)
                    .onAppear {
                        self.offsetY = 400
                        withAnimation(.easeInOut(duration: 3.0)) {
                            self.scale = 0.4
                            self.offsetY = 0
                        } completion: {
                            // Animation completed, perform your action here
                            self.isTitlePresented = true
                        }
                    }
            VStack(spacing: 0){
                HStack(){
                    Text("Category: ")
                    Picker("Categories", selection: $selectedCategories){
                        ForEach(AvailableCategories.allCases){
                            Text($0.title).tag($0)
                        }
                    }.pickerStyle(.menu)
                }.frame(width: 400)
                HStack(spacing: 10){
                    Text("Language: ")
                    Picker("Languages", selection: $selectedLanguage){
                        ForEach(AvailableLanguages.allCases){
                            Text($0.title).tag($0)
                        }
                    }.pickerStyle(.menu)
                }
            }
            .scaleEffect(isTitlePresented ? 1:0)
            .animation(.smooth(duration: 1), value: UUID())
           
            
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
                                                                await jokeList.addNewSentence(category: selectedCategories, language: selectedLanguage)
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
                    }
                }.scaleEffect(isTitlePresented ? 1:0).animation(.easeInOut, value: UUID())
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
