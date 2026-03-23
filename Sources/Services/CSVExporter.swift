import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// Generates CSV data from hydration logs for export
struct CSVExporter {
    /// Generate CSV string from water logs
    static func generateCSV(from logs: [WaterLog], unit: MeasurementUnit) -> String {
        var csv = "Date,Time,Drink Type,Amount (\(unit.displayName)),Effective Hydration (\(unit.displayName)),Hydration Ratio\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none

        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short

        for log in logs.sorted(by: { $0.timestamp < $1.timestamp }) {
            let date = dateFormatter.string(from: log.timestamp)
            let time = timeFormatter.string(from: log.timestamp)
            let drinkName = log.drink.displayName
            let amount = unit.fromMl(log.amount)
            let effective = unit.fromMl(log.effectiveAmount)
            let ratio = log.hydrationRatio

            let amountStr = unit == .ml ? "\(Int(amount))" : String(format: "%.1f", amount)
            let effectiveStr = unit == .ml ? "\(Int(effective))" : String(format: "%.1f", effective)

            csv += "\(date),\(time),\(drinkName),\(amountStr),\(effectiveStr),\(String(format: "%.2f", ratio))\n"
        }

        return csv
    }

    /// Create a temporary file URL for sharing
    static func createTempFile(csv: String) -> URL? {
        let fileName = "AquaFaste_History_\(formattedDate()).csv"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("[AquaFaste] Failed to write CSV: \(error)")
            return nil
        }
    }

    private static func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

/// Document type for CSV file sharing
struct CSVDocument: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { document in
            SentTransferredFile(document.url)
        }
    }
}
