# RC Hub Documentation

## Overview
RC Hub is a comprehensive Flutter application designed for RC (Remote Control) vehicle enthusiasts. It helps users manage their RC vehicle collection, track parts inventory, view interactive parts diagrams, and get AI-assisted diagnostics for vehicle issues.

## Features
- **User Authentication**: Secure login and registration using Supabase
- **Vehicle Management**: Add, edit, view, and delete RC vehicles in your collection
- **Parts Inventory**: Track parts with quantity, status, and compatibility information
- **Interactive Parts Viewer**: Explore exploded diagrams of parts with interactive components
- **AI-Assisted Diagnostics**: Upload photos of issues and get AI-powered analysis and solutions

## Technology Stack
- **Frontend**: Flutter (Dart)
- **Backend**: Supabase (Authentication and Database)
- **Deployment**: Vercel
- **Version Control**: GitHub

## Project Structure
```
rc_hub/
├── lib/
│   ├── models/          # Data models
│   ├── screens/         # UI screens
│   ├── services/        # API and business logic
│   └── widgets/         # Reusable UI components
├── test/                # Unit and widget tests
├── web/                 # Web-specific files
├── build/               # Build output
├── pubspec.yaml         # Dependencies
└── vercel.json          # Vercel deployment configuration
```

## Setup and Installation

### Prerequisites
- Flutter SDK (3.19.0 or higher)
- Dart (3.3.0 or higher)
- Supabase account
- Git

### Local Development
1. Clone the repository:
   ```
   git clone https://github.com/stubbs41/rc_hub.git
   cd rc_hub
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Create a `.env` file with your Supabase credentials:
   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

4. Run the application:
   ```
   flutter run -d chrome
   ```

### Deployment
The application is deployed to Vercel. Any changes pushed to the main branch will automatically trigger a new deployment if you've set up GitHub-Vercel integration.

## Database Schema
The application uses the following database tables:
- `vehicles`: Stores RC vehicle information
- `parts`: Tracks parts inventory
- `vehicle_parts`: Junction table for vehicle-part relationships
- `part_diagrams`: Stores interactive part diagrams
- `diagnostics`: Stores diagnostic requests and results
- `media`: Stores images for vehicles, parts, and diagnostics

## Authentication
Authentication is handled by Supabase. The application supports:
- Email/password registration and login
- Session management
- Password reset

## Contributing
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Commit your changes: `git commit -m 'Add some feature'`
4. Push to the branch: `git push origin feature/your-feature-name`
5. Submit a pull request

## License
This project is licensed under the MIT License - see the LICENSE file for details.

## Contact
For questions or support, please open an issue on the GitHub repository.
