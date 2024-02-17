//
//  JokeSentenceGenerationService.swift
//  fastJokes
//
//  Created by Pablo Fernandez Gonzalez on 8/2/24.
//

import Foundation
protocol JokeGenerationService {
    func getJokeSentence(id: Int, category: AvailableCategories) async -> JokeSentence
}

class JokeSentenceService : JokeGenerationService{
    
    func getJokeSentence(id: Int, category: AvailableCategories) async -> JokeSentence {
        do{
            
            let response = try await obtainJokeFromAPI(category: category.title)
            return JokeSentence(content: response)
        }catch{
            return JokeSentence(content: error.localizedDescription)
        }
    }
    
    func obtainJokeFromAPI(category: String) async throws -> String {
        
        // URL del endpoint
        guard var url = URL(string: "https://v2.jokeapi.dev/joke/Any?lang=en&format=txt&type=single") else {
            throw NSError(domain: "Error al construir la URL", code: 0, userInfo: nil)
        }
        
        if(!category.contains("All")){
            url = URL(string: "https://v2.jokeapi.dev/joke/"+category+"?lang=en&format=txt&type=single")!
        }
        
        // Crear una sesión de URLSession
        let session = URLSession.shared
        
        // Realizar la solicitud de manera asíncrona y esperar la respuesta
        let (data, _) = try await session.data(from: url)
        
        // Convertir los datos a cadena
        guard let cadena = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "Error al convertir los datos a cadena", code: 0, userInfo: nil)
        }
        
        // Devolver la cadena de respuesta
        return cadena
    }    
}
    
