# Comprehensive Project Analysis & Codebase Update Plan

**Project Title:** Adaptive Mobile Learning App for Rural Students Using Offline-First AI Tutoring  
**Student:** Sultan Mahmud Ibra (Roll: 250621, Contact: 01609469431)  
**Supervisor:** Tarun Debnath, Assistant Professor, Dept. of ICE, PUST  
**Duration:** 8-Week Roadmap  

---

## 1. Executive Summary of the Project Guide

### 1.1 Core Mission & Novelty
The project addresses a critical barrier in rural Bangladesh: the assumption of constant, high-speed internet connectivity in modern educational technology. The application is built around an **offline-first philosophy**, ensuring that students can practice curriculum-aligned math/science questions, receive AI-driven explanations/hints on-device, and have their progress automatically synchronized to the cloud only when connectivity becomes available.

### 1.2 The 8-Week Milestone Breakdown
1. **Week 1: Orientation, Literature Review & Setup** — Setup environment, examine on-device AI runtimes (e.g., llama.cpp/MLC-LLM/GGUF/quantized models), define NCTB Class 6–8 Mathematics scope.
2. **Week 2: App Skeleton & Local Database** — Basic navigation (Home → Subject → Topic → Quiz), SQLite schema with sample questions.
3. **Week 3: Curriculum-Aligned Question Bank & Quiz UI** — Expand question bank to 60–100+ NCTB-aligned questions with difficulty tagging; robust quiz interface.
4. **Week 4: On-Device AI Model Integration** — Integrate local AI explanation/hint generation without internet access via platform channel or native plugin.
5. **Week 5: Adaptive Difficulty Logic** — Dynamic difficulty adjustment rules (e.g., 3 correct in a row → level up; 2 wrong in a row → level down).
6. **Week 6: Sync-When-Available Progress Tracking** — Background internet detection (`connectivity_plus`) and automated sync to Firebase Firestore.
7. **Week 7: Usability Testing & Performance Optimization** — Usability evaluation (3–5 users), UI feedback improvements, memory and latency optimizations.
8. **Week 8: Final Integration, Testing & Report** — End-to-end bug fixing, comprehensive architecture documentation, and demonstration preparation.

---

## 2. In-Depth Analysis of Current Flutter Codebase

### 2.1 Current File Structure
```
c:\dev\
├── pubspec.yaml
├── lib/
│   └── main.dart (447 lines - monolithic file)
└── test/
    └── widget_test.dart (outdated boilerplate)
```

### 2.2 Detailed Audit of Current Code (`lib/main.dart` & `pubspec.yaml`)

| File / Component | Current State | Critical Limitations & Deficiencies |
| :--- | :--- | :--- |
| **`pubspec.yaml`** | Contains only `sqflite: ^2.3.0`, `path: ^1.8.0`, `cupertino_icons: ^1.0.8`. | Missing dependencies required by Guide: `connectivity_plus`, `firebase_core`, `cloud_firestore`, and AI runtime packages / interop tools. |
| **Monolithic Architecture** | All classes (`DBHelper`, `MyApp`, `HomeScreen`, `TopicSelectionScreen`, `QuizScreen`) reside in `lib/main.dart`. | Violates Flutter clean architecture and separation of concerns; hard to scale, test, or maintain across the 8-week milestones. |
| **Database (`DBHelper`)** | Has tables `questions` and `progress`. Only 15 hardcoded sample questions in `onCreate`. | 1. Hardcoded in Dart rather than imported/seeded from JSON/CSV assets.<br>2. Missing sync status flags (`is_synced`, `updated_at`) for offline-first sync.<br>3. Does not support tracking granular attempt history or streak data. |
| **Question Bank** | Only 15 questions across 3 topics (5 for Fractions, 5 for Algebra, 5 for Geometry). | Does not meet Week 3 requirement (60–100+ NCTB curriculum-aligned questions). Lacks detailed solution steps or hint metadata for AI context. |
| **Quiz Execution (`QuizScreen`)** | Fetches all questions for a topic and iterates sequentially (`currentIndex++`). | No adaptive difficulty engine (Week 5 requirement). Does not adjust difficulty based on student performance in real time. |
| **AI Tutoring Component** | Completely absent. | No "Ask AI Tutor" or "Explain Concept" feature (Week 4 requirement). No on-device inference bridge or fallback rule-based explanation engine. |
| **Sync Mechanism** | Completely absent. | No Firebase connection, no connectivity detection, no background upload queue (Week 6 requirement). |
| **Unit & Widget Tests** | `widget_test.dart` contains default Flutter counter test. | Fails `flutter test` because the default counter app was replaced with `HomeScreen`. |

---

## 3. Gap Analysis Matrix

| Feature / Milestone | Project Guide Requirement | Current Code Status | Required Action |
| :--- | :--- | :--- | :--- |
| **Architecture** | Scalable, modular codebase | ❌ 1 single file (`main.dart`) | Split into `models/`, `services/`, `screens/`, `database/`, `widgets/` |
| **Local Database** | SQLite with sync metadata | ⚠️ Basic table without sync tracking | Add `sync_status`, `mastery_level`, `attempt_logs` |
| **Question Bank** | 60–100+ NCTB Class 6–8 questions | ❌ Only 15 sample questions | Create structured JSON asset dataset (100+ questions) & DB loader |
| **AI Tutor / Hints** | Offline on-device explanation/hints | ❌ Not implemented | Create `AITutorService` (on-device LLM bridge / offline reasoning engine) |
| **Adaptive Logic** | Dynamic 3-correct / 2-wrong rule engine | ❌ Static linear list | Implement `AdaptiveEngine` managing dynamic difficulty queues |
| **Cloud Sync** | Sync-when-available with Firebase | ❌ Not implemented | Add `connectivity_plus`, `SyncService`, and Firebase integration |
| **UI / Usability** | Offline indicator, clean quiz UI, review | ⚠️ Basic UI | Add Online/Offline sync status banner, hint modal, quiz summary |
| **Automated Tests** | Unit & Widget testing | ❌ Failing default test | Write tests for DB, AdaptiveEngine, and UI widgets |

---

## 4. Comprehensive Codebase Restructuring & Update Blueprint

### 4.1 Target Project Architecture
```
lib/
├── main.dart                          # App initialization, Firebase init, theme configuration
├── constants/
│   ├── app_colors.dart                # Design system colors and styles
│   └── app_constants.dart             # NCTB curriculum topics, difficulty tiers
├── models/
│   ├── question_model.dart            # Question entity with options, hint, explanation
│   ├── progress_model.dart            # Topic progress and mastery tracking
│   └── sync_log_model.dart            # Offline sync queue items
├── database/
│   ├── db_helper.dart                 # Database lifecycle, migrations, query helpers
│   ├── question_dao.dart              # Question CRUD and difficulty-filtered queries
│   └── progress_dao.dart              # Local student statistics and streak logging
├── services/
│   ├── adaptive_engine.dart           # Dynamic difficulty calculation (Rule-based 3-up/2-down)
│   ├── ai_tutor_service.dart          # On-device AI hint & explanation inference engine
│   ├── connectivity_service.dart      # Real-time network state monitoring
│   └── sync_service.dart              # Two-way sync queue between SQLite and Firebase
├── screens/
│   ├── home_screen.dart               # Dashboard with subject list, mastery cards, sync status
│   ├── topic_selection_screen.dart    # NCTB topic selection with difficulty indicators
│   ├── quiz_screen.dart               # Adaptive quiz UI with AI tutor hint button
│   └── quiz_result_screen.dart        # Performance summary, review, and AI study tips
└── widgets/
    ├── ai_hint_dialog.dart            # Bottom sheet / modal displaying offline AI tutor response
    ├── connectivity_banner.dart       # "Offline Mode" / "Synced" status indicator
    └── progress_card.dart             # Topic mastery visual indicator
assets/
└── data/
    └── nctb_math_questions.json       # 100+ NCTB Class 6-8 categorized math questions
```

---

## 5. Detailed Breakdown: Why and Where Code is Updating

### 5.1 Package Dependencies (`pubspec.yaml`)
- **Where:** `pubspec.yaml`
- **Why:** 
  - Add `connectivity_plus` to listen to Wi-Fi/mobile data changes.
  - Add `firebase_core` and `cloud_firestore` for cloud synchronization.
  - Add `shared_preferences` for quick user setting cache.
  - Register `assets/data/nctb_math_questions.json` under the Flutter assets section.

### 5.2 Data Layer & Database (`lib/database/` & `lib/models/`)
- **Where:** `lib/models/question_model.dart`, `lib/models/progress_model.dart`, `lib/database/db_helper.dart`, `lib/database/question_dao.dart`
- **Why:**
  - Decouple raw SQLite maps into type-safe Dart models.
  - Add fields `hint`, `explanation`, `grade_level`, and `is_synced`.
  - Provide an automatic bulk-importer from JSON to populate 100+ questions on first launch without blocking the UI thread.

### 5.3 Adaptive Difficulty Engine (`lib/services/adaptive_engine.dart`)
- **Where:** New service `AdaptiveEngine`
- **Why:**
  - The guide specifies: "3 correct answers in a row → move to next difficulty level; 2 wrong answers in a row → move down a level."
  - Instead of loading a fixed list of questions, `AdaptiveEngine` maintains the student's streak and requests the next question matching the computed difficulty (`easy`, `medium`, `hard`) from `QuestionDao`.

### 5.4 On-Device AI Tutoring Service (`lib/services/ai_tutor_service.dart`)
- **Where:** New service `AITutorService` & `lib/widgets/ai_hint_dialog.dart`
- **Why:**
  - Core novelty of the project is offline AI assistance without incurring internet data costs for rural students.
  - Provides step-by-step guidance, formula explanations, and hints using structured prompt engineering adapted for on-device execution with low latency.

### 5.5 Sync-When-Available Service (`lib/services/sync_service.dart` & `connectivity_service.dart`)
- **Where:** `lib/services/connectivity_service.dart`, `lib/services/sync_service.dart`, `lib/widgets/connectivity_banner.dart`
- **Why:**
  - Automatically detect when the device gains Wi-Fi or mobile data.
  - Reads un-synced progress records from SQLite, batches them to Firebase Firestore, and marks local records as `is_synced = 1`.
  - Shows real-time sync status ("Offline - Ready", "Syncing...", "Synced") to reassure rural users.

### 5.6 UI/UX & Screens Refactoring (`lib/screens/` & `lib/widgets/`)
- **Where:** Modularized screen files
- **Why:**
  - Clean separation of UI logic, responsive layout across different Android screen densities, animated progress indicators, and intuitive "Ask AI" interactive dialogs during quizzes.

### 5.7 Test Suite (`test/`)
- **Where:** `test/adaptive_engine_test.dart`, `test/db_test.dart`, `test/widget_test.dart`
- **Why:**
  - Guarantee that the streak algorithm transitions difficulty correctly (e.g. verifying 3 consecutive correct triggers level up).
  - Verify SQLite insertion, retrieval, and progress calculations.

---

## 6. Execution Roadmap for Upcoming Development

```
Phase 1: Architecture & Data Foundation (Refactor main.dart, setup models, DAOs, JSON seed)
Phase 2: NCTB Question Bank Expansion (100+ curriculum questions with hints & explanations)
Phase 3: Adaptive Difficulty Engine Implementation & Unit Testing
Phase 4: On-Device AI Tutor Module Integration & UI Hint Modal
Phase 5: Connectivity & Firebase Sync-When-Available Pipeline
Phase 6: Usability Optimization, Offline Banner, & Final Polish
```
