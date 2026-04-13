# 🐔 Poultry Farm Management App

A complete Flutter mobile app for managing a poultry farm — customers, labour, expenses, and income — all stored locally on the device.

---

## 📁 Project Structure

```
lib/
├── main.dart                     # App entry point + Splash screen
├── models/
│   ├── customer_model.dart       # Customer data model
│   ├── labour_model.dart         # Labour data model
│   └── farm_data_model.dart      # Farm records model
├── services/
│   ├── database_service.dart     # SQLite database (all CRUD)
│   ├── auth_service.dart         # Login / PIN auth (SHA-256 hashed)
│   └── app_theme.dart            # Theme, colors, constants
└── screens/
    ├── login_screen.dart         # Login with Admin ID + Password
    ├── setup_screen.dart         # First-time account setup
    ├── dashboard_screen.dart     # Main menu (3 options)
    ├── admin_screen.dart         # Admin panel: finances + farm data
    ├── customer_screen.dart      # Customer CRUD + photo + auto-calc
    └── labour_screen.dart        # Labour CRUD + wage tracking
```

---

## 🚀 How to Set Up & Run

### Prerequisites
- Flutter SDK 3.0+ installed
- Android Studio or VS Code
- Android emulator or physical device

### Steps

```bash
# 1. Copy the project folder
cd poultry_farm_app

# 2. Install dependencies
flutter pub get

# 3. Run on device/emulator
flutter run
```

---

## 🔐 Security Features

| Feature | Implementation |
|---|---|
| Login | Admin ID + Password |
| Admin Panel | Separate PIN (SHA-256 hashed) |
| Password storage | SHA-256 hash via `crypto` package |
| Local persistence | `shared_preferences` (auth) + SQLite (data) |

---

## 📱 App Flow

```
App Launch → Splash Screen
    ↓
First time? → Setup Screen (create Admin ID, Password, PIN)
    ↓
Login Screen (Admin ID + Password)
    ↓
Dashboard
├── Admin Panel (PIN required)
│   ├── Financial Summary (Income, Expense, Profit, Labour Cost)
│   └── Farm Records (Add/Edit/Delete: chicks, medicine, grains)
├── Manage Customers
│   ├── Search customers
│   ├── Customer list with payment status
│   └── Add/Edit/Delete customer (with photo, auto-calculated totals)
└── Manage Labour
    ├── Search labour
    ├── Staff list with wage summary
    └── Add/Edit/Delete labour (with wage tracking)
```

---

## 💾 Data Backup Options

Since data is stored locally in SQLite:

### Option A: Manual Backup
- Copy the database file from device storage
- Path: `/data/data/com.yourapp/databases/poultry_farm.db`

### Option B: Add Firebase (Recommended for cloud backup)
Add to `pubspec.yaml`:
```yaml
firebase_core: ^2.24.2
cloud_firestore: ^4.14.0
firebase_auth: ^4.15.3
```
Then sync local SQLite data to Firestore periodically.

### Option C: Google Drive Backup
```yaml
googleapis: ^11.3.0
google_sign_in: ^6.2.1
```

---

## 📦 Dependencies Used

| Package | Purpose |
|---|---|
| `sqflite` | Local SQLite database |
| `path_provider` | Get app storage paths |
| `shared_preferences` | Store auth state |
| `crypto` | SHA-256 password hashing |
| `image_picker` | Pick customer photos |
| `intl` | Date and number formatting |
| `uuid` | Generate unique IDs |
| `fl_chart` | Charts (ready to use) |

---

## ✅ Features Checklist

- [x] Secure login (Admin ID + Password)
- [x] Separate Admin PIN for admin panel
- [x] First-time setup screen
- [x] Dashboard with 4 menu options
- [x] Admin Panel: Income/Expense/Profit summary (live bar chart)
- [x] Admin Panel: Farm data (chicks, medicine, grains) CRUD
- [x] Customer CRUD with photo support
- [x] Customer auto-calculated totals (average, remaining)
- [x] Customer payment status (Paid / Pending)
- [x] Customer search
- [x] Labour CRUD with wage tracking
- [x] Labour payment status and pending amounts
- [x] Labour search
- [x] Admin panel auto-updates from customer & labour data
- [x] **Reports screen with bar chart & pie chart**
- [x] **Top customers ranking**
- [x] **Full JSON backup (share via WhatsApp, email, etc.)**
- [x] **Export Customers to CSV spreadsheet**
- [x] **Export Labour to CSV spreadsheet**
- [x] Pull-to-refresh on all screens
- [x] Confirmation dialogs before delete
- [x] Beautiful green farm-themed UI

---

## 🔧 Customize

- **App Name**: Change in `pubspec.yaml` → `name` and `android/app/src/main/AndroidManifest.xml` → `android:label`
- **Theme Colors**: Edit `lib/services/app_theme.dart`
- **Currency**: Replace `Rs.` in screens with your currency symbol
