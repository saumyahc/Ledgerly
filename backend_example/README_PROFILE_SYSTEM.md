# User Profile System Documentation

## Overview
This document describes the user profile system implementation for the Ledgerly cryptocurrency payment app.

## User Flow

### 1. User Registration & Verification
1. User signs up with email, name, phone, and password
2. Email verification is sent
3. User verifies OTP
4. **User ID is maintained throughout the entire flow**

### 2. Profile Setup
After OTP verification, the user is directed to the Account Info page where they can:
- Set preferred currency (USD, EUR, GBP, etc.)
- Enter date of birth
- Provide address information (address, city, country, postal code)
- Save profile data to database

### 3. Dashboard Access
After profile setup, users can:
- View their profile information
- Edit profile details
- Access other app features

## Database Schema

### Users Table
```sql
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL,
    password VARCHAR(255) NOT NULL,
    email_verified BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMP NULL,
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### User Profiles Table
```sql
CREATE TABLE user_profiles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    preferred_currency VARCHAR(3) DEFAULT 'USD',
    date_of_birth DATE NULL,
    address TEXT NULL,
    city VARCHAR(100) NULL,
    country VARCHAR(100) NULL,
    postal_code VARCHAR(20) NULL,
    profile_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

## API Endpoints

### 1. Save Profile (`save_profile.php`)
- **Method**: POST
- **URL**: `http://192.168.29.61/Ledgerly/backend_example/save_profile.php`
- **Parameters**:
  - `user_id` (required): User ID
  - `preferred_currency` (optional): Currency code (default: USD)
  - `date_of_birth` (optional): Date in DD/MM/YYYY format
  - `address` (required): User's address
  - `city` (required): User's city
  - `country` (required): User's country
  - `postal_code` (optional): Postal code

### 2. Get Profile (`get_profile.php`)
- **Method**: GET
- **URL**: `http://192.168.29.61/Ledgerly/backend_example/get_profile.php?user_id={user_id}`
- **Parameters**:
  - `user_id` (required): User ID

## Flutter App Flow

### 1. OTP Verification Page
- Receives user data from verification response
- Passes user ID, name, and email to Account Info page

### 2. Account Info Page
- Accepts user parameters (userId, userName, userEmail)
- Loads existing profile data on initialization
- Saves profile data to backend
- Navigates to Home page after successful save

### 3. Home Page
- Displays personalized welcome message
- Includes "My Profile" option
- Navigates to User Profile View

### 4. User Profile View
- Displays all profile information
- Shows profile completion status
- Provides "Edit Profile" option
- Reloads data after editing

## Key Features

### User ID Consistency
- User ID is maintained throughout the entire application flow
- All profile operations are tied to the specific user ID
- No user data mixing between different users

### Profile Completion Tracking
- Database tracks whether profile is complete
- UI shows completion status
- Profile completion affects user experience

### Data Validation
- Server-side validation for all required fields
- Date format validation (DD/MM/YYYY)
- Currency code validation
- Address completeness validation

### Error Handling
- Comprehensive error messages
- Network error handling
- Database error handling
- User-friendly error display

## Usage Examples

### From Dashboard to Profile
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => UserProfileView(
      userId: userId,
      userName: userName,
      userEmail: userEmail,
    ),
  ),
);
```

### From Profile to Edit
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AccountInfoPage(
      userId: userId,
      userName: userName,
      userEmail: userEmail,
    ),
  ),
).then((_) {
  // Reload profile data when returning from edit
  _loadUserProfile();
});
```

### From OTP Verification to Account Info
```dart
Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => AccountInfoPage(
      userId: userId,
      userName: userName,
      userEmail: userEmail,
    ),
  ),
);
```

### From Account Info to Home Page
```dart
Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => HomePage(
      userId: userId,
      userName: userName,
      userEmail: userEmail,
    ),
  ),
);
```

### Using Onboarding Checklist Page
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => OnboardingChecklistPage(
      userId: userId,
      userName: userName,
      userEmail: userEmail,
    ),
  ),
);
```

## Updated Page Parameters

All pages that require user context now accept these parameters:
- `userId` (int): The user's unique identifier
- `userName` (String): The user's display name
- `userEmail` (String): The user's email address

### Updated Pages:
1. **AccountInfoPage** - Requires user parameters
2. **HomePage** - Requires user parameters
3. **UserProfileView** - Requires user parameters
4. **OnboardingChecklistPage** - Requires user parameters

## Security Considerations

1. **User ID Validation**: All API calls validate that the user exists
2. **Data Sanitization**: Input data is properly sanitized
3. **SQL Injection Prevention**: Using prepared statements
4. **CORS Headers**: Proper CORS configuration for API access

## Future Enhancements

1. **Profile Picture Upload**
2. **Additional KYC Fields**
3. **Profile Privacy Settings**
4. **Profile Export/Import**
5. **Profile Completion Progress Bar** 