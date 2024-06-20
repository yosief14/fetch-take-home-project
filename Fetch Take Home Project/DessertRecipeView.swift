//
//  DessertRecipeView.swift
//  Fetch Take Home Project
//
//

import SwiftUI

//Grab object
//Iterate throuhg attributes I need
//Build Object
//Format View
struct Ingredient : Identifiable, Hashable {
    let id = UUID()
    var measuredIngredient = ""
}

@MainActor class RecipeViewModel : ObservableObject{
    
    @Published var dessertData = Meals()
    @Published var ingredientList = [Ingredient]()
    
    func fetchData (id: String) async {
        print("called")
        guard let downloadedDesserts : JsonMeal = await WebService().downloadData(fromUrl:"https://themealdb.com/api/json/v1/1/lookup.php?i=\(id)") else {return}
        print(downloadedDesserts)
        dessertData = downloadedDesserts.meals[0]
    }
    
    func getIngredientList() {
        let mirror = Mirror(reflecting:dessertData)
        initializeIngredients()
        for case let (attr?, value) in mirror.children{
           let formatedVal = value as? String
            if attr.hasPrefix("strIngredient") && formatedVal != "" && formatedVal != nil && formatedVal != " " {

                let indexToAppend = Int(attr.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())
                let valueToAppend = value as! String
                ingredientList[indexToAppend! - 1].measuredIngredient.append(" " + valueToAppend)
            }
            else if attr.hasPrefix("strMeasure") && formatedVal != "" && formatedVal != nil && formatedVal != " "{
                let indexToAppend = Int(attr.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())
                let valueToAppend = value as! String
                ingredientList[indexToAppend! - 1].measuredIngredient = "\(indexToAppend!).     " + valueToAppend + ingredientList[indexToAppend! - 1].measuredIngredient
            }
        }
    }
    func initializeIngredients()  {
        for _ in 0...20 {
           ingredientList.append(Ingredient())
        }
    }
}

struct DessertRecipeView: View {
    var dessert : String
    @StateObject var recipeVM = RecipeViewModel()
    var body: some View {
        List{
        VStack{
            AsyncImage(url: URL(string: recipeVM.dessertData.strMealThumb ?? "nil" ),
                   content: { image in
            image.resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width:300)
        },
        placeholder: {
            ProgressView().frame(width: 300, height: 300)
            }).padding(20)
            Text( "Instructions").bold().underline()
            Text(recipeVM.dessertData.strInstructions ?? "No Ingredients Found").padding(10)
            
            Text( "Ingredients").bold().padding(10).underline()
            ForEach(recipeVM.ingredientList, id: \.self ){
                ingredient in
                if(ingredient.measuredIngredient != ""){
                    Text(ingredient.measuredIngredient).frame(maxWidth: .infinity , alignment: .leading ).padding(10)
                }
            }
        }
        }.onAppear{
            if(recipeVM.dessertData.idMeal == nil){
            Task{
                await recipeVM.fetchData(id: dessert)
                recipeVM.getIngredientList()
                print(recipeVM.dessertData)
                print(recipeVM.ingredientList)
                }
            }
        }.navigationTitle(recipeVM.dessertData.strMeal ?? "Menu Item Not Found")
            .navigationBarTitleDisplayMode(.inline )
        }
    }

struct DessertRecipePreview: PreviewProvider {
    static var previews: some View {
        
        var exampleDessert = "53049"
        NavigationStack{
            
        DessertRecipeView(dessert: exampleDessert)
        }
    }
}


