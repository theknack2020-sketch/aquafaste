import SwiftUI
import TipKit

// MARK: - Tips

struct CaffeineTrackingTip: Tip {
    static let drinkLogged = Event(id: "drinkLogged")

    var title: Text { Text("Track Caffeine Too") }
    var message: Text? { Text("Switch to Coffee or Tea to log caffeine alongside hydration.") }
    var image: Image? { Image(systemName: "cup.and.saucer.fill") }

    var rules: [Rule] {
        #Rule(Self.drinkLogged) { $0.donations.count >= 3 }
    }
}

struct StreakTip: Tip {
    static let goalReached = Event(id: "goalReached")

    var title: Text { Text("Build Your Streak") }
    var message: Text? { Text("Hit your daily goal to start a streak. Consistency is everything!") }
    var image: Image? { Image(systemName: "flame.fill") }

    var rules: [Rule] {
        #Rule(Self.goalReached) { $0.donations.count >= 1 }
    }
}

struct FavoriteDrinkTip: Tip {
    static let drinkLogged = Event(id: "favDrinkLogged")

    var title: Text { Text("Save Your Favorites") }
    var message: Text? { Text("Long-press a drink button to save it as a favorite for quick access.") }
    var image: Image? { Image(systemName: "star.fill") }

    var rules: [Rule] {
        #Rule(Self.drinkLogged) { $0.donations.count >= 5 }
    }
}

struct HistoryInsightTip: Tip {
    var title: Text { Text("Check Your History") }
    var message: Text? { Text("Swipe to the History tab to see your weekly and monthly trends.") }
    var image: Image? { Image(systemName: "chart.bar.fill") }

    var options: [TipOption] {
        MaxDisplayCount(1)
    }
}

struct ExportTip: Tip {
    var title: Text { Text("Export Your Data") }
    var message: Text? { Text("Pro users can export hydration data as CSV for health tracking.") }
    var image: Image? { Image(systemName: "arrow.down.doc.fill") }

    var options: [TipOption] {
        MaxDisplayCount(1)
    }
}
