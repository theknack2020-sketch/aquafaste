import Foundation
import SwiftUI

enum DrinkType: String, Codable, CaseIterable, Identifiable {
    case water
    case coffee
    case tea
    case juice
    case milk
    case soda
    case sparklingWater
    case coconutWater
    case smoothie
    case soup
    case beer
    case wine

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .water: "Water"
        case .coffee: "Coffee"
        case .tea: "Tea"
        case .juice: "Juice"
        case .milk: "Milk"
        case .soda: "Soda"
        case .sparklingWater: "Sparkling Water"
        case .coconutWater: "Coconut Water"
        case .smoothie: "Smoothie"
        case .soup: "Soup"
        case .beer: "Beer"
        case .wine: "Wine"
        }
    }

    /// Hydration ratio — how much of this drink counts as water
    /// Based on research: hydration-science.md
    var hydrationRatio: Double {
        switch self {
        case .water: 1.0
        case .coffee: 0.85 // mild diuretic at moderate doses
        case .tea: 0.90 // less caffeine than coffee
        case .juice: 1.3 // high water content + electrolytes
        case .milk: 1.5 // research shows superior hydration
        case .soda: 0.70 // sugar + caffeine
        case .sparklingWater: 1.0
        case .coconutWater: 1.1 // natural electrolytes
        case .smoothie: 0.90
        case .soup: 0.80
        case .beer: 0.40 // alcohol is dehydrating
        case .wine: 0.30 // higher alcohol content
        }
    }

    var iconName: String {
        switch self {
        case .water: "drop.fill"
        case .coffee: "cup.and.saucer.fill"
        case .tea: "leaf.fill"
        case .juice: "carrot.fill"
        case .milk: "mug.fill"
        case .soda: "bubbles.and.sparkles.fill"
        case .sparklingWater: "bubbles.and.sparkles"
        case .coconutWater: "laurel.leading"
        case .smoothie: "blender.fill"
        case .soup: "flame.fill"
        case .beer: "wineglass.fill"
        case .wine: "wineglass"
        }
    }

    var color: Color {
        switch self {
        case .water: .drinkWater
        case .coffee: .drinkCoffee
        case .tea: .drinkTea
        case .juice: .drinkJuice
        case .milk: .drinkMilk
        case .soda: .drinkSoda
        case .sparklingWater: .drinkSparkling
        case .coconutWater: .drinkCoconut
        case .smoothie: .drinkSmoothie
        case .soup: .drinkSoup
        case .beer: .drinkBeer
        case .wine: .drinkWine
        }
    }

    /// Caffeine content in mg per 250ml serving
    /// Based on USDA and published nutrition data
    var caffeinePer250ml: Double {
        switch self {
        case .water: 0
        case .coffee: 95 // brewed coffee ~95mg per 8oz
        case .tea: 47 // brewed black tea ~47mg per 8oz
        case .juice: 0
        case .milk: 0
        case .soda: 24 // cola ~24mg per 8oz
        case .sparklingWater: 0
        case .coconutWater: 0
        case .smoothie: 0
        case .soup: 0
        case .beer: 0
        case .wine: 0
        }
    }

    /// Whether this drink contains caffeine
    var hasCaffeine: Bool {
        caffeinePer250ml > 0
    }

    /// Category for grouped display
    var category: DrinkCategory {
        switch self {
        case .water, .sparklingWater, .coconutWater: .water
        case .coffee, .tea: .hotDrinks
        case .juice, .smoothie, .milk: .healthy
        case .soda: .other
        case .soup: .other
        case .beer, .wine: .alcohol
        }
    }
}

enum DrinkCategory: String, CaseIterable, Identifiable {
    case water = "Water"
    case hotDrinks = "Hot Drinks"
    case healthy = "Healthy"
    case alcohol = "Alcohol"
    case other = "Other"

    var id: String {
        rawValue
    }
}
