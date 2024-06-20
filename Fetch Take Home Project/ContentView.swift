//
//  ContentView.swift
//  Fetch Take Home Project
//
//

import SwiftUI

let dessertUrl = URL(string: "https://themealdb.com/api/json/v1/1/filter.php?c=Dessert")!

struct Dessert: Identifiable, Codable, Hashable{
    var strMeal: String
    var strMealThumb: String
    var idMeal: String
    var id : String {idMeal}
    }
//TODO: Super Low Prio: Find a way to get rid of this struct since it feels like a pointless encapsulation and is only necessary in order to decode the Json object from the above Api call
struct Desserts: Codable{
     
    var meals: [Dessert]
    
}

enum NetworkError: Error {
    case badUrl
    case invalidRequest
    case badResponse
    case badStatus
    case failedToDecodeResponse
}
//TODO: Low Prio. Refactor/Rewrite this to be mroe readable if possible
//Handles the http requests. Bit verbose and I feel like I could find a better way to do this
class WebService: Codable {
    func downloadData<T: Codable>(fromUrl: String )async -> T?{
        do {
            guard let url = URL(string: fromUrl ) else { throw NetworkError.badUrl }
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let response = response as? HTTPURLResponse else { throw NetworkError.badResponse }
            guard response.statusCode >= 200 && response.statusCode < 300 else { throw NetworkError.badStatus }
            guard let decodedResponse = try? JSONDecoder().decode(T.self, from: data) else { throw NetworkError.failedToDecodeResponse }
            
            return decodedResponse
        } catch NetworkError.badUrl {
            print("There was an error creating the URL")
        } catch NetworkError.badResponse {
            print("Did not get a valid response")
        } catch NetworkError.badStatus {
            print("Did not get a 2xx status code from the response")
        } catch NetworkError.failedToDecodeResponse {
            print("Failed to decode response into the given type")
        } catch {
            print("An error occured downloading the data")
        }
        
        return nil
    }
}
//Handler to manage data fetching and State syncronization
@MainActor class DessertViewModel: ObservableObject {
    @Published var dessertData = [Dessert]()
    func fetchData() async {
        print("called")
        guard let downloadedDesserts: Desserts = await WebService().downloadData(fromUrl:"https://themealdb.com/api/json/v1/1/filter.php?c=Dessert") else {return}
        dessertData = downloadedDesserts.meals
    }
}
//TODO: Bug Odd line below text of card that changes width with size of text
struct RecipePreview: View{
    let id: String
    let name: String
    let imgSrc: String
    
    init(id: String, name: String, imgSrc: String) {
        self.id = id
        self.name = name
        self.imgSrc = imgSrc
    }
    var body: some View {
        //TODO: Low Prio Implement Image Cacheing
        //Apperntly AsyncImage() doesn't automatically cache images so it lazy loads everytime
        HStack{
        AsyncImage(url: URL(string: imgSrc),
                   content: { image in
            image.resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 100, maxHeight: 100)
        },
        placeholder: {
            ProgressView().frame(width: 100, height: 100)
        })
            Text(name).bold().frame(maxWidth: .infinity).multilineTextAlignment(.center)
        }
    }
    
}

struct ContentView: View {

    @StateObject var dessertVM = DessertViewModel()
    var body: some View {
        NavigationStack{
            List(dessertVM.dessertData){
                dessert in VStack(spacing: 20){
                    NavigationLink(value: dessert){
                        
                    RecipePreview(id: dessert.idMeal, name: dessert.strMeal, imgSrc: dessert.strMealThumb)
                    }
                                
                }
            }.onAppear {
                if dessertVM.dessertData.isEmpty {
                    Task {
                        await dessertVM.fetchData()
                    }
                }
            }.navigationTitle("Desserts")
             .navigationDestination(for: Dessert.self)  { dessert in
                 DessertRecipeView(dessert: dessert.idMeal)
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
