# Jobzshala GCC — Job Matches Mobile App

Jobzshala helps Indian blue-collar workers (drivers, electricians, welders, retail staff) find verified jobs in the Gulf. This app is specifically engineered for budget Android phones (2–3 GB RAM), patchy 4G connections, and bilingual users who prefer Hindi over English.

---

## 🏗️ Architecture & Technology Choices

### 1. Clean Architecture (Uncle Bob's Pattern)
The codebase follows **Clean Architecture** with separation of concerns into three layers:
```text
lib/
├── core/
│   ├── di/               # GetIt Dependency Injection container
│   ├── error/            # Failures & Exceptions mapping
│   ├── localization/     # English & Hindi translations & LocaleBloc
│   ├── network/          # ApiEndpoints & NetworkInfo (connectivity checker)
│   └── theme/            # Contrast-optimized colors, typography & theme
├── features/
│   └── jobs/
│       ├── domain/       # Pure Dart: Entities, Repository contracts, UseCases
│       │   ├── entities/     # Job, Benefits, PaginatedJobs
│       │   ├── repositories/ # JobsRepository interface
│       │   └── usecases/     # GetJobMatches, GetJobDetail, ApplyToJob
│       ├── data/         # Models, Remote & Local DataSources, Repo Impl
│       │   ├── models/       # JobModel, BenefitsModel, PaginationModel
│       │   ├── datasources/  # JobsRemoteDataSource, JobsLocalDataSource
│       │   └── repositories/ # JobsRepositoryImpl
│       └── presentation/ # BLoC state management, screens & custom widgets
│           ├── bloc/         # JobMatchesBloc, JobDetailBloc
│           ├── pages/        # JobMatchesPage, JobDetailPage
│           └── widgets/      # JobCard, FilterChips, Badges, Skeleton, VoiceNote
└── main.dart
```

### 2. State Management: `flutter_bloc`
- **Predictable state transitions**: Clear separation of `Event -> Bloc -> State`.
- **Optimistic UI & Rollback**: Essential for low-latency feedback when blue-collar workers tap "Apply". The state updates instantly, and cleanly rolls back if the server returns a 500 failure or network drops.
- **Testability**: Pure event-driven state transforms allow isolated unit tests (`test/apply_logic_test.dart`).

### 3. Dependency Injection: `get_it`
- Decouples interface contracts from implementations.
- Zero runtime overhead and avoids widget-tree pollution.

### 4. Offline-First & Storage: `shared_preferences` & Local Caching
- **Low-RAM friendly**: Blue-collar devices (2–3 GB RAM) require minimum memory footprint and fast startup.
- **Cache Persistence**: Cached job listings by country, and persistent `Set<String>` of applied job IDs that survive app restarts.
- **Offline Banner**: Automatically detects offline state and displays:
  > *"You're offline — showing saved jobs"* (Hindi: *"आप ऑफ़लाइन हैं — सहेजी गई नौकरियाँ दिखा रहे हैं"*)
- When offline, "Apply" is disabled with an explanatory tooltip/message.

### 5. Performance on Low-End Devices
- Pure Flutter Material 3 widgets without bloated 3rd-party UI libraries.
- Lazy-evaluated `ListView.builder` with const constructors.
- Smooth scrolling verified with 200+ jobs.

---

## 🌐 Connecting with Mock Backend API (`F:\jobzshala project\jobzshala-gcc-mock-api`)

The backend is built with Node.js/Express and located in:
`F:\jobzshala project\jobzshala-gcc-mock-api`

### Step 1: Start Mock Server
Open PowerShell in `F:\jobzshala project\jobzshala-gcc-mock-api`:
```powershell
cd "F:\jobzshala project\jobzshala-gcc-mock-api"
npm install
npm run dev
```
The server will run at `http://localhost:3000`.

### Step 2: Configure Flutter App URL
The Flutter app automatically resolves:
- **Android Emulator**: `http://10.0.2.2:3000`
- **Windows / macOS / iOS Simulator**: `http://localhost:3000`
- **Physical Device**: Tap the **Settings** icon on the top right of the Job Matches screen and enter `http://<YOUR_COMPUTER_LAN_IP>:3000`.

For a physical Android device, the phone and computer must be on the same network. You can also set the API URL when launching the app:
```powershell
flutter run -d <device_id> --dart-define=API_BASE_URL=http://<YOUR_COMPUTER_LAN_IP>:3000
```
Allow incoming connections to port `3000` in the computer's firewall if the phone cannot connect.

---

## 📱 Features Implemented

### Part A: Core Flow
1. **Job Matches List Screen**:
   - Job card displaying: title, employer display name, country & city, salary range (AED/mo), match score percentage, up to 3 skill chips, and "Applied" badge.
   - Sorted by match score (highest first).
   - Filter chips: **All / UAE / Saudi Arabia / Qatar**.
   - Pull-to-refresh (`RefreshIndicator`).
   - Infinite pagination: loads 20 items per page smoothly.
   - Designed loading skeleton, empty state, and error state with Retry.

2. **Job Detail Screen**:
   - Full job description & requirements.
   - Benefits breakdown with clear status badges: **Accommodation (आवास), Food (खाना), Visa (वीज़ा)**.
   - Highlighted AI Match Reason card with custom emerald gradient.
   - Sticky bottom Apply button.

3. **Apply Confirmation & Rollback**:
   - Tapping "Apply" updates the UI immediately (optimistic update).
   - Confirmed on backend success and saved to persistent local storage.
   - If mock API returns 500 error (simulated 20% failure), state automatically rolls back and displays clear error with retry option.
   - Applied state survives complete app restart.

4. **Language Toggle (English / Hindi)**:
   - One-tap language toggle in AppBar across all screens.
   - Translates all UI labels (filters, status, error states, buttons).

5. **Offline Handling**:
   - Persistent cache of jobs for offline browsing.
   - Clear warning banner when offline.
   - Apply button safely disabled while offline with message.

### Part B: Bonus Features
- 🎙️ **Voice Note Introduction**: Optional 30-second audio recorder on the Job Detail screen with live timer, stop, playback, and delete before submitting.
- 🧪 **Unit & Widget Tests**: Full test suite verifying optimistic apply, server error rollback, and JobCard rendering.

---

## 🧪 Running Tests & Verification

Run tests:
```powershell
flutter test
```
Result:
```text
00:01 +5: All tests passed!
```

Run static analysis:
```powershell
flutter analyze
```
Result:
```text
No issues found!
```

---

## 🚀 Running the Flutter App

```powershell
flutter run
```
Or specify target device:
```powershell
flutter run -d chrome
flutter run -d windows
flutter run -d <device_id>
```
