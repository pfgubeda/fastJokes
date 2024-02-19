//
//  JokeSentenceGenerationService.swift
//  fastJokes
//
//  Created by Pablo Fernandez Gonzalez on 8/2/24.
//

import Foundation
protocol JokeGenerationService {
    func getJokeSentence(id: Int, category: AvailableCategories, language: AvailableLanguages) async -> JokeSentence
}

class JokeSentenceService : JokeGenerationService{
    
    func getJokeSentence(id: Int, category: AvailableCategories, language: AvailableLanguages) async -> JokeSentence {
        do{
            let response = try await obtainJokeFromAPI(category: category.title, language: language.rawValue)
            return JokeSentence(content: response)
        }catch{
            return JokeSentence(content: error.localizedDescription)
        }
    }
    
    func obtainJokeFromAPI(category: String, language: String) async throws -> String {
        guard var url = URL(string: "https://v2.jokeapi.dev/joke/Any?lang="+language+"&format=txt&type=single") else {
            throw NSError(domain: "Error al construir la URL", code: 0, userInfo: nil)
        }
        
        if(!category.contains("All")){
            url = URL(string: "https://v2.jokeapi.dev/joke/"+category+"?lang="+language+"&format=txt&type=single")!
        }
        
        let session = URLSession.shared
        
        let (data, _) = try await session.data(from: url)
        
        guard let cadena = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "Error al convertir los datos a cadena", code: 0, userInfo: nil)
        }
        
        return cadena
    }    
}
    
