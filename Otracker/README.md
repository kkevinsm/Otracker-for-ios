

# Otracker - Simple & Smart Finance Tracker for iOS

Otracker is a simple personal finance management app designed to make tracking expenses fast, intuitive, and intelligent. Built natively for iOS using SwiftUI and SwiftData, this app is a showcase of modern development practices and the power of generative AI.

The core philosophy behind Otracker is to minimize the friction of manual data entry. With powerful features like receipt scanning and voice input, you can log your spending in seconds, keeping your financial records always up-to-date.

## ✨ Key Features

-   **📊 Interactive Dashboard:** Get a quick overview of your spending with dynamic summaries for daily, weekly, and monthly periods. Visualize your expense distribution with a clean pie chart.
-   **🤖 AI-Powered Receipt Scanning:** Simply take a screenshot of your QRIS payment or bank transfer receipt. Otracker utilizes **Google's Gemini API** to automatically parse the image, extracting the merchant name, amount, and date, filling in the form for you.
-   **🗣️ AI-Powered Voice Input:** Log transactions on the go just by speaking. Say "Beli Kopi 25 ribu," and Otracker, with the help of the **Gemini API**, will understand and prepare the transaction details for you to save.
-   **💰 Budgeting:** Set monthly budgets for different categories and track your progress with intuitive progress bars. Get visual cues when you're approaching or exceeding your limits.
-   **🧾 Bills & Subscriptions:** Never miss a payment again. Track recurring bills and subscriptions like Spotify or monthly installments, and mark them as paid with a single tap.
-   **🔍 Advanced Filtering & Search:** Easily find any transaction with a powerful search bar and advanced filters for date ranges, categories, and sources of fund.
-   **✏️ Full CRUD Functionality:** Create, Read, Update, and Delete transactions, categories, sources of fund, and budgets.
-   **🌐 Localization:** The app is fully localized for both English and Indonesian, automatically adapting to the user's system language.

## 🛠️ Tech Stack & Architecture

-   **UI:** SwiftUI
-   **Data Persistence:** SwiftData
-   **AI & OCR:**
    -   **Apple Vision Framework** for on-device text recognition (OCR).
    -   **Google Gemini API** for natural language understanding and data extraction from both scanned text and voice commands.
-   **Speech Recognition:** Apple's `SFSpeechRecognizer` for converting voice to text.
-   **Architecture:** Follows a modern MV (Model-View) approach, leveraging property wrappers like `@State`, `@Query`, and `@Environment` for state management.


---

This project was built as a personal tool to demonstrate and practice modern iOS development techniques.

