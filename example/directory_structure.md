# Flutist Project Structure Example

This document visualizes a Flutter project structure using Flutist with Microfeature Architecture.

## 📂 Complete Project Structure

```
my_flutter_project/
├── pubspec.yaml                 # Root workspace configuration
├── project.dart                 # Project configuration
├── package.dart                 # Centralized dependency management
├── analysis_options.yaml        # Linting rules
├── README.md                    # Project documentation
│
├── app/                         # Main application module (Simple)
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart
│       └── app.dart
│
├── features/                    # Feature modules directory
│   └── authentication/         # Clean module (3-layer)
│       ├── authentication_domain/
│       │   ├── pubspec.yaml
│       │   └── lib/
│       │       ├── entities/
│       │       │   └── user.dart
│       │       └── repositories/
│       │           └── auth_repository.dart
│       │
│       ├── authentication_data/
│       │   ├── pubspec.yaml
│       │   └── lib/
│       │       ├── data_sources/
│       │       │   └── auth_remote_data_source.dart
│       │       └── repositories/
│       │           └── auth_repository_impl.dart
│       │
│       └── authentication_presentation/
│           ├── pubspec.yaml
│           └── lib/
│               ├── screens/
│               │   ├── login_screen.dart
│               │   └── register_screen.dart
│               └── widgets/
│                   └── login_form.dart
│
├── lib/                         # Library modules directory
│   └── network/                 # Micro module (5-layer)
│       ├── network_example/
│       │   ├── pubspec.yaml
│       │   └── lib/
│       │       └── main.dart
│       │
│       ├── network_interface/
│       │   ├── pubspec.yaml
│       │   └── lib/
│       │       └── network_client.dart
│       │
│       ├── network_implementation/
│       │   ├── pubspec.yaml
│       │   └── lib/
│       │       └── http_client.dart
│       │
│       ├── network_testing/
│       │   ├── pubspec.yaml
│       │   └── lib/
│       │       └── mock_network_client.dart
│       │
│       └── network_tests/
│           ├── pubspec.yaml
│           └── lib/
│               └── network_client_test.dart
│
├── core/                        # Core modules directory
│   ├── models/                  # Lite module (4-layer)
│   │   ├── models_interface/
│   │   │   ├── pubspec.yaml
│   │   │   └── lib/
│   │   │       └── models.dart
│   │   │
│   │   ├── models_implementation/
│   │   │   ├── pubspec.yaml
│   │   │   └── lib/
│   │   │       ├── user_model.dart
│   │   │       └── product_model.dart
│   │   │
│   │   ├── models_tests/
│   │   │   ├── pubspec.yaml
│   │   │   └── lib/
│   │   │       └── user_model_test.dart
│   │   │
│   │   └── models_testing/
│   │       ├── pubspec.yaml
│   │       └── lib/
│   │           └── test_helpers.dart
│   │
│   └── utils/                   # Simple module
│       ├── pubspec.yaml
│       └── lib/
│           ├── string_utils.dart
│           └── date_utils.dart
│
└── flutist/                     # Flutist generated files
    ├── flutist_gen.dart         # Auto-generated code helpers
    └── templates/               # Scaffold templates
        └── feature/
            ├── template.yaml
            ├── bloc.dart.template
            ├── state.dart.template
            ├── event.dart.template
            └── screen.dart.template
```

## 🏗️ Module Type Breakdown

### 1. Simple Module: `app/`
```
app/
└── lib/
    ├── main.dart
    └── app.dart
```
- Single layer structure
- Main application entry point
- Typically depends on feature modules

### 2. Clean Module: `features/authentication/`
```
authentication/
├── authentication_domain/       # Business logic
│   └── lib/
│       ├── entities/
│       └── repositories/
│
├── authentication_data/          # Data layer
│   └── lib/
│       ├── data_sources/
│       └── repositories/
│
└── authentication_presentation/  # UI layer
    └── lib/
        ├── screens/
        └── widgets/
```
- 3-layer architecture
- Domain → Data → Presentation dependency flow
- Use for user-facing features

### 3. Micro Module: `lib/network/`
```
network/
├── network_example/             # Example usage
│   └── lib/
│
├── network_interface/           # Public API
│   └── lib/
│
├── network_implementation/      # Core implementation
│   └── lib/
│
├── network_testing/             # Test utilities
│   └── lib/
│
└── network_tests/               # Unit tests
    └── lib/
```
- 5-layer architecture
- Interface → Implementation dependency
- Use for reusable libraries

### 4. Lite Module: `core/models/`
```
models/
├── models_interface/            # Public API
│   └── lib/
│
├── models_implementation/       # Core functionality
│   └── lib/
│
├── models_tests/                # Unit tests
│   └── lib/
│
└── models_testing/              # Test utilities
    └── lib/
```
- 4-layer architecture
- Use for internal modules with clear API boundaries

### 5. Simple Module: `core/utils/`
```
utils/
└── lib/
    ├── string_utils.dart
    └── date_utils.dart
```
- Single layer structure
- Use for simple utility functions

## 🔗 Dependency Flow

```
app
  └── depends on → authentication (clean)
      └── depends on → network (micro)
          └── depends on → models (lite)
              └── depends on → utils (simple)
```

## 📦 Workspace Configuration

All modules are registered in the root `pubspec.yaml`:

```yaml
workspace:
  - app
  - features/authentication/authentication_domain
  - features/authentication/authentication_data
  - features/authentication/authentication_presentation
  - lib/network/network_example
  - lib/network/network_interface
  - lib/network/network_implementation
  - lib/network/network_testing
  - lib/network/network_tests
  - core/models/models_interface
  - core/models/models_implementation
  - core/models/models_tests
  - core/models/models_testing
  - core/utils
```

## 🎯 Benefits of This Structure

1. **Modularity**: Each feature is self-contained
2. **Testability**: Each layer can be tested independently
3. **Reusability**: Libraries can be shared across features
4. **Scalability**: Easy to add new features without affecting existing code
5. **Type Safety**: Centralized dependency management with IDE support

