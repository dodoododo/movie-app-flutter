# 🎬 Flutter Cinema App

![Flutter Version](https://img.shields.io/badge/Flutter-3.x.x-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-2.19.x-blue?logo=dart)
![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)

Built for Mid-term Mobile Programming Class

A simple and elegant cinema app built with Flutter. It allows users to browse movies and save their favorites to a personal watchlist, which is stored locally using **SQFlite**.

---

## ✨ Features

* **Browse Movies**: Scroll through a beautifully designed list of current or popular movies.
* **View Movie Details**: Tap on any movie to see a detailed screen with its poster, synopsis, rating, and more.
* **Personal Watchlist**: Add or remove movies from your personal watchlist.
* **Offline Persistence**: Your watchlist is saved directly on your device using an **SQFlite database**. Your data persists even when you close the app.
* **Clean UI**: A modern, responsive, and user-friendly interface.

## 🛠️ Tech Stack

* **Framework**: [Flutter](https://flutter.dev/)
* **Language**: [Dart](https://dart.dev/)
* **Local Database**: [SQFlite](https://pub.dev/packages/sqflite)
* **Database Helper**: A custom service to abstract all SQFlite database operations (CRUD).

## 📱 App Demonstration

### 1. Home Screen

The main screen displays a list or grid of available movies. Users can scroll to discover new titles.

<img width="408" height="891" alt="Screenshot 2025-10-04 145403" src="https://github.com/user-attachments/assets/eb605171-85e6-46e8-b514-9b83c62f6b27" />

### 2. Movie Details

When a user taps on a movie, they are navigated to a detail screen. This screen shows more information and the "Add to Watchlist" button.

<img width="406" height="889" alt="Screenshot 2025-10-04 145448" src="https://github.com/user-attachments/assets/e444aa54-65fb-4144-9bf5-c5bcbb0162d7" />

### 3. Choose Seat and Add to Watchlist

Tapping the "Add to Watchlist" button saves the movie's ID and details into the local SQFlite database. A snackbar or toast confirms the action.

<img width="408" height="894" alt="Screenshot 2025-10-04 145537" src="https://github.com/user-attachments/assets/156e5d82-f902-4028-8a88-8a214ffd42af" />

### 4. Personal Watchlist History Screen

A dedicated screen that queries the SQFlite database and displays all the movies the user has saved. Users can also remove movies from this list.

<img width="410" height="887" alt="Screenshot 2025-10-04 145629" src="https://github.com/user-attachments/assets/a944e6de-3d5c-475c-957d-3b3d35ce1095" />


### 5. Personal Movie History Options

<img width="408" height="880" alt="Screenshot 2025-10-04 145706" src="https://github.com/user-attachments/assets/83390d76-8821-46c8-b0bc-a83a3e271f87" />

---

## 🚀 Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

* Flutter SDK (version 3.x.x or higher)
* An Android Emulator or iOS Simulator
* A code editor (like VS Code or Android Studio)

### Installation

1.  **Clone the repo:**
    ```sh
    git clone https://github.com/dodoododo/movie-app-flutter
    ```
2.  **Navigate to the project directory:**
    ```sh
    cd movie-app-flutter
    ```
3.  **Install dependencies:**
    ```sh
    flutter pub get
    ```
4.  **Run the app:**
    ```sh
    flutter run
    ```

## 🗃️ Database Structure

The app uses an SQFlite database (`cinema.db`) with three main tables to manage all data: `movies`, `showtimes`, and `tickets`.

### 1. `movies` Table
Stores the core information for each movie.

| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | INTEGER | Primary Key (Auto-incrementing) |
| `title` | TEXT | The movie's title |
| `genre` | TEXT | The genre (e.g., "Hoạt hình") |
| `duration` | INTEGER | Duration in minutes |
| `poster` | TEXT | URL to the movie poster |
| `description`| TEXT | A brief synopsis of the movie |

### 2. `showtimes` Table
Stores the available showtimes for each movie. It is linked to the `movies` table.

| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | INTEGER | Primary Key (Auto-incrementing) |
| `movieId` | INTEGER | Foreign Key linking to `movies(id)` |
| `time` | TEXT | The showtime (e.g., "19:30") |
| `room` | TEXT | The screening room (e.g., "IMAX") |
| `price` | REAL | The price for this showtime |

### 3. `tickets` Table
Stores a record of every ticket booked by the user.

| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | INTEGER | Primary Key (Auto-incrementing) |
| `movieTitle` | TEXT | The title of the movie for this ticket |
| `showtime` | TEXT | The selected showtime (e.g., "19:30 - IMAX")|
| `seat` | TEXT | The booked seat (e.g., "A1") |
| `price` | REAL | The price paid for the ticket |
| `status` | TEXT | Booking status ("đang giữ chỗ", "đã thanh toán", etc.) |
| `bookingDate`| TEXT | The date the booking was made (ISO 8601 String) |

All database operations (CRUD) are abstracted away and handled by the `DatabaseHelper` class.

## 📄 Copyright

Do whatever you want with the app i dont care

---

<p align="center">
  Made with ❤️ and Flutter
</p>
