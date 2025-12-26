# Project Structure Overview

## Directory Tree

```
actionapp/
├── mobile/                          # Flutter Mobile App (User-facing)
│   ├── lib/
│   │   ├── main.dart                # App entry point
│   │   ├── core/
│   │   │   ├── constants/
│   │   │   │   └── app_constants.dart
│   │   │   ├── routes/
│   │   │   │   └── app_routes.dart
│   │   │   ├── theme/
│   │   │   │   └── app_theme.dart
│   │   │   └── utils/
│   │   │       └── validators.dart
│   │   └── features/
│   │       ├── auth/
│   │       │   ├── data/
│   │       │   │   ├── models/
│   │       │   │   │   └── user_model.dart
│   │       │   │   └── repositories/
│   │       │   │       └── auth_repository.dart
│   │       │   └── presentation/
│   │       │       └── pages/
│   │       │           ├── login_page.dart
│   │       │           └── splash_page.dart
│   │       ├── profile/
│   │       │   └── presentation/
│   │       │       └── pages/
│   │       │           └── profile_page.dart
│   │       └── orders/
│   │           └── presentation/
│   │               └── pages/
│   │                   ├── orders_list_page.dart
│   │                   └── order_detail_page.dart
│   └── pubspec.yaml
│
├── web/                              # Flutter Web App (Admin)
│   ├── lib/
│   │   ├── main.dart                 # App entry point
│   │   ├── core/
│   │   │   ├── constants/
│   │   │   │   └── app_constants.dart
│   │   │   ├── routes/
│   │   │   │   └── app_routes.dart
│   │   │   ├── theme/
│   │   │   │   └── app_theme.dart
│   │   │   └── utils/
│   │   │       └── validators.dart
│   │   └── features/
│   │       ├── auth/
│   │       │   └── presentation/
│   │       │       └── pages/
│   │       │           └── login_page.dart
│   │       ├── dashboard/
│   │       │   └── presentation/
│   │       │       └── pages/
│   │       │           └── dashboard_page.dart
│   │       ├── users/
│   │       │   └── presentation/
│   │       │       └── pages/
│   │       │           └── users_list_page.dart
│   │       └── reports/
│   │           └── presentation/
│   │               └── pages/
│   │                   └── reports_page.dart
│   └── pubspec.yaml
│
├── backend/                          # Node.js Backend
│   ├── app.js                        # Express app entry point
│   ├── package.json                  # Node.js dependencies
│   ├── .env                          # Environment variables (create from .env.example)
│   ├── controllers/                  # Request handlers
│   │   ├── auth.controller.js
│   │   ├── users.controller.js
│   │   └── orders.controller.js
│   ├── routes/                       # API route definitions
│   │   ├── auth.routes.js
│   │   ├── users.routes.js
│   │   └── orders.routes.js
│   ├── services/                     # Business logic layer
│   │   └── firebase.service.js
│   └── middleware/                   # Express middleware
│       └── auth.middleware.js
│
├── firebase/                          # Firebase Configuration
│   ├── firebase.json                 # Firebase project config
│   ├── firestore.rules               # Firestore security rules
│   ├── firestore.indexes.json        # Firestore indexes
│   └── storage.rules                 # Storage security rules
│
├── .gitignore
├── README.md
└── PROJECT_STRUCTURE.md              # This file
```

## Architecture Notes

### Flutter Apps (Mobile & Web)
- **Feature-based organization**: Each feature is self-contained with its own data, domain, and presentation layers
- **Core folder**: Shared utilities, themes, constants, and routing
- **Clean Architecture**: Separation of concerns with data, domain, and presentation layers

### Node.js Backend
- **MVC Pattern**: Controllers handle requests, services contain business logic
- **RESTful API**: Standard HTTP methods for CRUD operations
- **Firebase Admin SDK**: Server-side Firebase operations
- **Middleware**: Authentication and error handling

### Firebase
- **Firestore**: NoSQL database for users and orders
- **Storage**: File storage for user profiles and order attachments
- **Security Rules**: Client-side and server-side validation

## Next Steps

1. **Setup Firebase Project**:
   - Create project at https://console.firebase.google.com
   - Enable Firestore and Storage
   - Generate service account key
   - Add credentials to `backend/.env`

2. **Install Dependencies**:
   - Mobile: `cd mobile && flutter pub get`
   - Web: `cd web && flutter pub get`
   - Backend: `cd backend && npm install`

3. **Configure Environment**:
   - Copy `backend/.env.example` to `backend/.env`
   - Fill in Firebase credentials

4. **Deploy Firebase Rules**:
   - `cd firebase && firebase deploy --only firestore:rules,storage:rules`

