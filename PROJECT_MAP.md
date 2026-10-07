# Project Map & Feature Tracker

This file tracks the current state of the project, all active features, and serves as a changelog for future additions.
Before adding any new feature, this map will be updated to reflect the new architecture.

## 🚀 Active Features

### 1. Authentication
- **Unified Login System**: Handles both Admin and Student logins using Firebase Auth / Supabase.
- **OTP Verification**: Email-based OTP for secure login (`EmailOtpService`).

### 2. Student Application
- **Dashboard**: Displays real-time meal timing, today's menu, and account balance.
- **Digital QR Pass**: Dynamic QR code generation for meal check-in at the mess counter.
- **Meal Booking/Cancellation**: Students can opt-out of meals for rebates.
- **Feedback & Complaints**: Forms to submit meal ratings and register complaints.
- **Polling System**: Participate in admin-generated polls (e.g., "What should we have for Sunday special?").

### 3. Admin Application
- **QR Scanner**: Scans student QR passes, verifies validity, and deducts the meal cost from their balance.
- **Menu Management**: Ability to update the daily and weekly menus.
- **Student Management**: Add new students, manually adjust balances, and approve leaves/rebates.
- **Notices & Polls**: Create announcements and dynamic polls for students.
- **Data Export**: Export attendance and billing records to CSV/PDF (`export_service.dart`).

---

## 📝 Changelog / Updates

- **[2026-10-07]**: Project Map initialized. Scripts archived. Detailed code analysis generated in `CODE_ANALYZED.md`.

*Note: Any future changes will be documented here.*

### Recent Bug Fixes (Session 2)
- **Stream Leak Fix**: Rewrote initSupabaseStreams() in main.dart to prevent multiple background streams when switching Admin modes.
- **Login Refresh Fix**: Added SyncService.switchMode() to _finalizeStudentLogin and _finalizeAdminLogin so the app connects to the correct database (boys/girls) based on the user's login.
- **Web Keyboard Enter Fix**: Added onFieldSubmitted to OTP and Login TextFormFields so users can press 'Enter' instead of clicking 'Next' on Flutter Web.
- **Web Image CORS Bypass**: Implemented memory byte fallback (globalMenuUploadBytes) for Supabase image downloads when kIsWeb == true, fixing blank menu images on CanvasKit.
- **Login UI Text Render**: Fixed a bug where Room Number was hidden for manual login, and made the top title dynamically show 'Boys Hostel Mess' or 'Girls Hostel Mess'.
- **Auto-Update Unification**: Changed update table reference to pp_updates (instead of mode-specific) for single-source updates.
