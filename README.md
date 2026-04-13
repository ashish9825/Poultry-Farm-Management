# Poultry Farm Management System

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/sqlite-%2307405e.svg?style=for-the-badge&logo=sqlite&logoColor=white)

A comprehensive, offline-first mobile application designed to streamline the operational and financial management of poultry farms. Built with **Flutter** and **Dart**, this app replaces manual ledger tracking with a digital dashboard, offering real-time insights into farm metrics, expenses, and overall profitability.

## 🌟 Key Features

*   **Financial Dashboard & Analytics:** Real-time visualization of business metrics, net profit, total expenses (feed, medicine, wages), and livestock inventory using interactive charts (`fl_chart`).
*   **Comprehensive Inventory Tracking:** Track and manage daily farm inputs including chicken feed, medicines, and livestock (chick additions and mortality rates).
*   **Sales & Customer Management:** Keep records of customer transactions, sales volume, and outstanding balances. Automatically calculate profit margins based on expenditures vs. sales.
*   **Labor & Wage Management:** Track employee information, daily wages, total days worked, and remaining payments.
*   **Robust Local Database:** Highly optimized `SQLite` database architecture designed for complex relational queries and totally offline usage. No internet connection required!
*   **Export & Reporting:** Generate and share comprehensive financial and operational reports as **CSV, Excel, and PDF** files for data-driven decision-making.
*   **Secure Access:** Local PIN-based authentication ensures that sensitive financial records and business setup data remain protected under an Admin profile.
*   **Data Backup & Restore:** Built-in tools for safely backing up the local database to the device storage to prevent data loss.

## 🛠️ Technology Stack

*   **Frontend / UI:** Flutter (Material Design)
*   **Programming Language:** Dart
*   **Local Database:** `sqflite` (SQLite)
*   **Data Visualization:** `fl_chart`
*   **File Management & Exporting:** `path_provider`, `csv`, `pdf`, `excel`, `share_plus`
*   **Security / Auth:** `crypto`, `shared_preferences`

## 🚀 Getting Started

### Prerequisites

*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (version >=3.0.0 <4.0.0)
*   [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/) for development
*   An Android or iOS Emulator, or a physical device for testing.

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/ashish9825/Poultry-Farm-Management.git
    ```

2.  **Navigate to the project directory:**
    ```bash
    cd Poultry-Farm-Management
    ```

3.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

4.  **Run the application:**
    ```bash
    flutter run
    ```

## 📸 Screenshots
*(You can add screenshots of your app here to make the README more engaging! Create an `assets/screenshots` folder and link them here.)*

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! 
Feel free to check the [issues page](https://github.com/ashish9825/Poultry-Farm-Management/issues).

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
