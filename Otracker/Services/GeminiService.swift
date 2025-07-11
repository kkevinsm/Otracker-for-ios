import Foundation
import UIKit

struct ReceiptInfo: Decodable {
    let merchant_name: String?
    let amount: Double?
    let transaction_date: String?
}

struct SpokenInfo: Decodable {
    let description: String?
    let amount: Double?
}

private struct GeminiResponse: Decodable {
    struct Candidate: Decodable {
        struct Content: Decodable {
            struct Part: Decodable { let text: String }
            let parts: [Part]
        }
        let content: Content
    }
    let candidates: [Candidate]
}


class GeminiService {
    private let apiKey: String
    private let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"
    private let visionService = VisionService()
    
    init?() {
        guard let key = KeyManager.getAPIKey() else {
            print("FATAL ERROR: Gemini API Key tidak ditemukan di APIKeys.plist.")
            return nil
        }
        self.apiKey = key
    }
    
    
    func analyzeReceipt(image: UIImage, completion: @escaping (Result<ReceiptInfo, Error>) -> Void) {
        visionService.extractText(from: image) { ocrResult in
            switch ocrResult {
            case .failure(let error): completion(.failure(error))
            case .success(let text):
                guard !text.isEmpty else {
                    completion(.failure(VisionError.ocrFailed))
                    return
                }
                self.sendTextToGemini(forReceipt: text, completion: completion)
            }
        }
    }
    
    private func sendTextToGemini(forReceipt text: String, completion: @escaping (Result<ReceiptInfo, Error>) -> Void) {
        let prompt = """
        You are an expert financial data extractor for Indonesian digital receipts.
        Analyze the following text from a QRIS or bank transfer receipt.
        Your task is to extract three key pieces of information: the merchant's name, the total transaction amount, and the transaction date.

        Instructions:
        1.  **Merchant Name (`merchant_name`):** Find the store or recipient's name. It's often below "Pembayaran QR" or near the amount. It might include a location, like "nata's store, PAKUHAJI". Extract the full name.
        2.  **Amount (`amount`):** Find the amount, which is often prefixed with "Rp". Ignore the "Rp" prefix and any dots used as thousands separators (e.g., "Rp 5.000" should be 5000). It MUST be a number (Double).
        3.  **Date (`transaction_date`):** Find the date. It is often in "DD/MM" or "DD/MM/YYYY" format. Extract only the date part and format it as "YYYY-MM-DD". If the year is missing, assume the current year.

        Respond ONLY in a valid JSON format with the keys "merchant_name", "amount", and "transaction_date".
        If a value isn't found, use null for that key. Do not add any explanation, comments, or markdown formatting like ```json.

        Receipt Text:
        "\(text)"
        """
        self.performGeminiRequest(prompt: prompt, completion: completion)
    }
    
    
    func analyzeSpokenTransaction(text: String, completion: @escaping (Result<SpokenInfo, Error>) -> Void) {
        let prompt = """
        You are an expert financial data extractor for Indonesian spoken language.
        Analyze the following spoken text and extract the transaction amount and a brief description of the activity.

        Instructions:
        1.  **Description (`description`):** Identify the core activity or item purchased. For example, in "beli kopi dua puluh ribu", the description is "Beli Kopi".
        2.  **Amount (`amount`):** Extract the numerical value. Convert spoken numbers like "dua puluh ribu" into a number (e.g., 20000). It MUST be a number (Double).

        Respond ONLY in a valid JSON format with the keys "description" and "amount".
        If a value isn't found, use null for that key. Do not add any explanation or markdown.

        Spoken Text:
        "\(text)"
        """
        self.performGeminiRequest(prompt: prompt, completion: completion)
    }
    
    
    private func performGeminiRequest<T: Decodable>(prompt: String, completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = URL(string: "\(urlString)?key=\(apiKey)") else { return }
        
        let requestBody: [String: Any] = ["contents": [["parts": [["text": prompt]]]]]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            func complete(onMainThreadWith result: Result<T, Error>) {
                DispatchQueue.main.async { completion(result) }
            }
            
            if let error = error {
                complete(onMainThreadWith: .failure(error))
                return
            }
            guard let data = data else {
                complete(onMainThreadWith: .failure(URLError(.badServerResponse)))
                return
            }
            
            let rawResponse = String(data: data, encoding: .utf8) ?? "No response string"
            print("--- Gemini Raw Response ---\n\(rawResponse)\n---------------------------")
            
            do {
                let responsePayload = try JSONDecoder().decode(GeminiResponse.self, from: data)
                
                guard var jsonText = responsePayload.candidates.first?.content.parts.first?.text else {
                    throw URLError(.cannotParseResponse)
                }
                
                jsonText = jsonText.replacingOccurrences(of: "```json\n", with: "")
                jsonText = jsonText.replacingOccurrences(of: "```", with: "")
                jsonText = jsonText.trimmingCharacters(in: .whitespacesAndNewlines)
                
                guard let jsonData = jsonText.data(using: .utf8) else {
                    throw URLError(.cannotParseResponse)
                }
                
                let decodedInfo = try JSONDecoder().decode(T.self, from: jsonData)
                complete(onMainThreadWith: .success(decodedInfo))
                
            } catch {
                complete(onMainThreadWith: .failure(error))
            }
        }.resume()
    }
}
