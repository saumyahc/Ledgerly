# Profile Info Page

A comprehensive user profile display page that shows user information in an attractive, modern design.

## Features

### 🎨 Design Elements
- **Gradient Header Card** - Beautiful profile header with user photo, name, and email
- **Profile Status Badge** - Visual indicator of profile completion status
- **Detailed Information Cards** - Organized display of personal information
- **Modern Material Design** - Consistent with app theme and style
- **Pull-to-Refresh** - Swipe down to refresh profile data

### 📱 User Interface
- **Profile Picture** - Circular avatar with border and shadow effects
- **User Information** - Name, email, and profile status prominently displayed
- **Information Sections** - Organized cards for different data categories
- **Action Buttons** - Easy access to edit profile and refresh data
- **Loading States** - Smooth loading indicators and error handling

### 🔧 Functionality
- **Real-time Data Loading** - Fetches latest profile information from backend
- **Session Management** - Extends user session automatically
- **Navigation** - Easy access to edit profile functionality
- **Error Handling** - Graceful error display with retry options
- **Responsive Design** - Works on different screen sizes

## Layout Structure

```
┌─────────────────────────────┐
│         App Bar             │
│  [←] My Profile      [✎]    │
├─────────────────────────────┤
│                             │
│     Profile Header Card     │
│   ┌───────────────────────┐ │
│   │   🙂 Profile Photo    │ │
│   │   John Doe            │ │
│   │   john@example.com    │ │
│   │   ✅ Profile Complete │ │
│   └───────────────────────┘ │
│                             │
│   Personal Information      │
│   ┌─ 💱 Preferred Currency ─┐ │
│   ┌─ 🎂 Date of Birth ─────┐ │
│   ┌─ 🏠 Address ───────────┐ │
│   ┌─ 🏙️ City ─────────────┐ │
│   ┌─ 🌍 Country ──────────┐ │
│   ┌─ 📬 Postal Code ──────┐ │
│                             │
│   [Edit Profile] [Refresh]  │
│                             │
└─────────────────────────────┘
```

## Navigation Access

### From Home Page
1. **Quick Actions Section** - "My Profile" card
2. **App Bar** - Profile icon (person) in top-right

### From Profile Page
- **Edit Button** - App bar edit icon
- **Edit Profile Button** - Bottom action button
- **Back Button** - Returns to previous screen

## Data Display

### Profile Header
- **Profile Picture**: Circle avatar with app primary color
- **User Name**: Large, bold display name
- **User Email**: Styled email badge
- **Profile Status**: Color-coded completion indicator

### Information Sections
Each data field displays:
- **Icon**: Relevant visual indicator
- **Label**: Field description
- **Value**: Current data or "Not set"
- **Visual Container**: Rounded card with subtle border

### Status Indicators
- **Complete Profile**: Green badge with checkmark
- **Incomplete Profile**: Orange badge with pending icon

## Backend Integration

### API Calls
- **GET** `${ApiConstants.getProfile}?user_id={userId}`
- **Response Handling** - JSON parsing with error management
- **Data Mapping** - Profile fields to UI components

### Session Integration
- **Automatic Extension** - Keeps user logged in
- **Profile Updates** - Reflects changes from edit screen
- **Refresh Capability** - Re-fetch latest data

## Error Handling

### Loading States
- **Circular Progress Indicator** - Shows during data fetch
- **Loading Message** - "Loading profile..." text

### Error States
- **Error Icon** - Red warning symbol
- **Error Message** - Descriptive error text
- **Retry Button** - Allows user to retry operation

### Empty States
- **"Not set" Labels** - For missing profile data
- **Graceful Fallbacks** - Default values where appropriate

## Accessibility Features

- **Semantic Labels** - Screen reader friendly
- **High Contrast** - Good color contrast ratios
- **Touch Targets** - Appropriate button sizes
- **Visual Hierarchy** - Clear information structure

## Integration Points

### Session Manager
```dart
SessionManager.extendSession(); // Called in build()
```

### Navigation
```dart
// From Home Page
Navigator.push(context, MaterialPageRoute(
  builder: (context) => ProfileInfoPage(
    userId: userId,
    userName: userName, 
    userEmail: userEmail,
  ),
));

// To Edit Profile
Navigator.push(context, MaterialPageRoute(
  builder: (context) => AccountInfoPage(...),
));
```

### Refresh Functionality
```dart
RefreshIndicator(
  onRefresh: _loadUserProfile,
  child: SingleChildScrollView(...),
)
```

This profile page provides a polished, professional display of user information while maintaining consistency with the app's existing design language and functionality.
