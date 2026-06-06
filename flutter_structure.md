# GoalGetter Flutter Project Structure (Targeting Flutter 3.28)

This document maps the directory structure and file layout of the Flutter frontend application for the GoalGetter project. It is structured to help evaluate architectural patterns, separation of concerns, and best practices.

---

## 1. Project Context & Environment
- **Flutter SDK Target**: `^3.28` (compatible with Dart `^3.8.1`)
- **State Management**: Riverpod (`flutter_riverpod: ^2.5.1`)
- **API Integration**: Auto-generated client SDK (`openapi`) from backend spec, located in the sibling directory `client_sdk/`
- **Storage**: `shared_preferences` for key-value local persistence (like language, tokens)
- **Localization**: Built-in Flutter localizations utilizing `.arb` files and local generated classes

---

## 2. Directory Tree (`frontend/lib`)

Below is the directory tree of the Dart source files located in the `lib` folder of the frontend application:

```text
lib/
├── main.dart                          # App initialization (SharedPreferences, locale, Riverpod entry)
├── app/                               # Root configuration and application routing
│   ├── app.dart                       # MaterialApp configuration & imperative routing (onGenerateRoute)
│   ├── home/                          # Main navigation container
│   │   └── home_shell.dart            # Layout holding bottom navigation bar / navigation rail
│   └── startup/                       # Initial guards and logic running before main app screens load
│       ├── app_start_controller.dart  # Controls initialization state sequence
│       └── auth_gate.dart             # Gate checking if user needs onboarding or is already signed in
├── config/                            # Environmental variables and keys
│   └── app_config.dart                # Configuration parameters (backend URLs, Google client IDs)
├── l10n/                              # Localization resources
│   ├── app_de.arb                     # German translations (Source)
│   ├── app_en.arb                     # English translations (Source)
│   ├── app_es.arb                     # Spanish translations (Source)
│   ├── app_fr.arb                     # French translations (Source)
│   ├── app_pt.arb                     # Portuguese translations (Source)
│   ├── l10n.dart                      # Holds supported locale declarations
│   # --- Generated files manually checked into the source tree ---
│   ├── app_localizations.dart         # Main abstract localizations class
│   ├── app_localizations_de.dart
│   ├── app_localizations_en.dart
│   ├── app_localizations_es.dart
│   ├── app_localizations_fr.dart
│   └── app_localizations_pt.dart
├── models/                            # Domain & data representation models
│   ├── chat_message.dart              # Model for Tutor chat messages
│   ├── fake_leaderboard_example.dart  # Mock data representation for leaderboard feature
│   └── lesson_question_data.dart      # Model representing lesson questions
├── services/                          # Business logic, API communication, and providers
│   ├── auth_service.dart              # Google Sign-in orchestration, token storage, and signup calls
│   ├── openapi_client_factory.dart    # Factory class creating authenticated OpenAPI clients
│   └── providers.dart                 # Centralized declaration of Riverpod providers
├── theme/                             # Visual styling variables
│   └── app_theme.dart                 # Theme data definitions (colors, fonts, text themes)
├── utils/                             # Utilities & low-level helpers
│   └── settings_storage.dart          # Local storage wrapper (wraps SharedPreferences for language preferences)
├── screens/                           # Full-screen views (Presentation Layer)
│   ├── goal_selection_screen.dart     # Select goals during onboarding
│   ├── goals_detail_screen.dart       # Detailed view of a goal
│   ├── list_goals_screen.dart         # List of active goals
│   ├── missions_screen.dart           # Daily missions / challenges list
│   ├── profile_screen.dart            # User profile and stats
│   ├── resources_screen.dart          # Resources and external links list
│   ├── tutor_screen.dart              # Chat page for interacting with the AI Tutor
│   ├── tutor_controller.dart          # State/logic controller for the Tutor chat page
│   ├── intermediate/
│   │   └── info_screen.dart           # Transitional information screen
│   ├── objective/                     # Focus-based lesson path screens
│   │   ├── finish_lesson_screen.dart  # Lesson completion screen
│   │   ├── lesson_controller.dart     # Controller for lesson step state and grading
│   │   ├── lesson_screen.dart         # Interactive lesson viewer
│   │   └── streak_screen.dart         # Streak progression display
│   ├── onboarding/                    # Onboarding specific views
│   │   ├── goal_prompt_screen.dart    # Text area screen to prompt user goals
│   │   ├── goal_questions_screen.dart # Form fields requesting extra user information
│   │   ├── start_screen.dart          # First intro / sign-in screen
│   │   ├── study_plan.dart            # Display of the generated study plan
│   │   └── tutorial_screen.dart       # Walkthrough instructions
│   # --- Mock Screens & Mock Controllers ---
│   ├── mock-resources_screen.dart     # Mockup version of resources screen
│   ├── mock-tutor_controller.dart     # Mockup controller for offline tutor interface
│   ├── objective/
│   │   └── mock-streak_screen.dart    # Mockup of streak progression display
│   └── onboarding/
│       ├── mock-goal_prompt_screen.dart
│       ├── mock-goal_questions_screen.dart
│       ├── mock-start_screen.dart
│       └── mock-study_plan.dart
└── widgets/                           # Reusable ui components (Presentation Layer)
    ├── error_retry_widget.dart        # General error container with a retry callback
    ├── info_card.dart                 # Standard styled information card
    ├── main_screen_icon.dart          # Icon helpers used in screens
    ├── progress_bar.dart              # Customizable linear progress bar
    ├── screens/                       # Widgets tightly coupled to specific screens
    │   ├── objective/
    │   │   ├── lesson/
    │   │   │   ├── stat.dart
    │   │   │   └── stat_data.dart
    │   │   └── streak/
    │   │       └── weekday_column.dart
    │   ├── onboarding/
    │   │   ├── goal_questions.dart
    │   │   └── pre_onboarding_carousel.dart
    │   └── resource/
    │       └── resource_tab.dart
    ├── sections/                      # Larger compound layouts
    │   └── notes_section.dart         # Shared notes text widget
    └── tutor/                         # Chat-specific elements
        ├── chat_input.dart            # Text composer input
        └── chat_message_bubble.dart   # Chat bubble presentation with avatar
```

---

## 3. Configuration & Metadata Files
- **`frontend/pubspec.yaml`**: Imports `flutter_riverpod` for state management, `openapi` (pointing locally to `../client_sdk`), `shared_preferences`, `introduction_screen`, `google_sign_in`, and defines localizations dependency.
- **`frontend/analysis_options.yaml`**: Uses default recommended lints via `include: package:flutter_lints/flutter.yaml`.
- **`frontend/Dockerfile` / `nginx.conf`**: Configured for containerized builds and serving via web servers (e.g. Nginx on ports).
