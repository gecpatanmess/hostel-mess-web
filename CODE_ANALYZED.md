# Comprehensive Code Analysis

This document provides an exhaustive, function-by-function analysis of all Dart code in the project.

## 📁 File: lib\badge_helper.dart

*(No major classes found. Likely a utility or script file.)*

## 📁 File: lib\badge_helper_stub.dart

*(No major classes found. Likely a utility or script file.)*

## 📁 File: lib\badge_helper_web.dart

*(No major classes found. Likely a utility or script file.)*

## 📁 File: lib\export_service.dart

### 📦 Class: ExportService
- **Type**: Data Model / Service Controller
- *(No explicit custom methods found)*

## 📁 File: lib\main.dart

### 📦 Class: WeeklyMenuEditorWidget
- **Type**: StatefulWidget (Maintains mutable UI state)
- *(No explicit custom methods found)*

### 📦 Class: _WeeklyMenuEditorWidgetState
- **Type**: Data Model / Service Controller
- **Methods & Functions**:
  - _saveDayMenu(): Custom logic block. Executes specific business logic or UI updates.
  - _loadDayMenu(): Custom logic block. Executes specific business logic or UI updates.
  - _build()_: Standard Flutter lifecycle method.
  - _initState()_: Standard Flutter lifecycle method.

### 📦 Class: ViewMenuTab
- **Type**: StatelessWidget (Static UI component)
- **Methods & Functions**:
  - _buildMealCard(): Custom logic block. Executes specific business logic or UI updates.
  - _build()_: Standard Flutter lifecycle method.

### 📦 Class: NoticeItem
- **Type**: Data Model / Service Controller
- *(No explicit custom methods found)*

### 📦 Class: ComplaintItem
- **Type**: Data Model / Service Controller
- **Methods & Functions**:
  - saveAdminHiddenComplaints(): Custom logic block. Executes specific business logic or UI updates.
  - saveStudentHiddenComplaints(): Custom logic block. Executes specific business logic or UI updates.

### 📦 Class: RegisteredStudent
- **Type**: Data Model / Service Controller
- **Methods & Functions**:
  - saveRegisteredStudents(): Custom logic block. Executes specific business logic or UI updates.
  - parseStr(): Custom logic block. Executes specific business logic or UI updates.

### 📦 Class: AdminUser
- **Type**: Data Model / Service Controller
- **Methods & Functions**:
  - handleForceLogout(): Custom logic block. Executes specific business logic or UI updates.

### 📦 Class: DynamicPoll
- **Type**: Data Model / Service Controller
- *(No explicit custom methods found)*

### 📦 Class: DailyRecord
- **Type**: Data Model / Service Controller
- **Methods & Functions**:
  - main(): Custom logic block. Executes specific business logic or UI updates.

### 📦 Class: ResponsiveWrapper
- **Type**: StatelessWidget (Static UI component)
- **Methods & Functions**:
  - hashPassword(): Custom logic block. Executes specific business logic or UI updates.
  - calculatePayableBill(): Custom logic block. Executes specific business logic or UI updates.
  - _loadDataFromPrefs(): Custom logic block. Executes specific business logic or UI updates.
  - _build()_: Standard Flutter lifecycle method.

### 📦 Class: SyncService
- **Type**: Data Model / Service Controller
- *(No explicit custom methods found)*

### 📦 Class: MyApp
- **Type**: StatelessWidget (Static UI component)
- **Methods & Functions**:
  - _build()_: Standard Flutter lifecycle method.

### 📦 Class: EmailOtpService
- **Type**: Data Model / Service Controller
- **Methods & Functions**:
  - showOtpVerificationDialog(): Custom logic block. Executes specific business logic or UI updates.

### 📦 Class: _OtpVerificationDialog
- **Type**: StatefulWidget (Maintains mutable UI state)
- *(No explicit custom methods found)*

### 📦 Class: _OtpVerificationDialogState
- **Type**: Data Model / Service Controller
- **Methods & Functions**:
  - _build()_: Standard Flutter lifecycle method.
  - _sendOtp(): Custom logic block. Executes specific business logic or UI updates.
  - _verifyOtp(): Custom logic block. Executes specific business logic or UI updates.
  - _startCooldown(): Custom logic block. Executes specific business logic or UI updates.
  - _initState()_: Standard Flutter lifecycle method.
  - _dispose()_: Standard Flutter lifecycle method.

### 📦 Class: LoginScreen
- **Type**: StatefulWidget (Maintains mutable UI state)
- *(No explicit custom methods found)*

### 📦 Class: _LoginScreenState
- **Type**: Data Model / Service Controller
- **Methods & Functions**:
  - _buildBackButton(): Custom logic block. Executes specific business logic or UI updates.
  - _build()_: Standard Flutter lifecycle method.
  - _verifyEmailAndOtp(): Custom logic block. Executes specific business logic or UI updates.
  - _buildAdminPortal(): Custom logic block. Executes specific business logic or UI updates.
  - _initState()_: Standard Flutter lifecycle method.
  - _buildStudentPortal(): Custom logic block. Executes specific business logic or UI updates.
  - _buildPasswordHints(): Custom logic block. Executes specific business logic or UI updates.
  - _clearSavedAdmin(): Custom logic block. Executes specific business logic or UI updates.
  - _pickImage(): Custom logic block. Executes specific business logic or UI updates.
  - _handleAdminLogin(): Custom logic block. Executes specific business logic or UI updates.
  - _buildDropdownField(): Custom logic block. Executes specific business logic or UI updates.
  - Center(): Custom logic block. Executes specific business logic or UI updates.
  - _buildActionButton(): Custom logic block. Executes specific business logic or UI updates.
  - _handleUnifiedAction(): Custom logic block. Executes specific business logic or UI updates.
  - _handleForgotPassword(): Custom logic block. Executes specific business logic or UI updates.
  - _buildPasswordField(): Custom logic block. Executes specific business logic or UI updates.
  - _finalizeAdminLogin(): Custom logic block. Executes specific business logic or UI updates.
  - _verifyIdentifierStage(): Custom logic block. Executes specific business logic or UI updates.
  - _buildInputField(): Custom logic block. Executes specific business logic or UI updates.
  - _finalizeStudentLogin(): Custom logic block. Executes specific business logic or UI updates.
  - _handleStudentLogin(): Custom logic block. Executes specific business logic or UI updates.
  - _loadSavedCredentials(): Custom logic block. Executes specific business logic or UI updates.
  - _clearSavedStudent(): Custom logic block. Executes specific business logic or UI updates.

### 📦 Class: StudentDashboardScreen
- **Type**: StatefulWidget (Maintains mutable UI state)
- *(No explicit custom methods found)*

### 📦 Class: _StudentDashboardScreenState
- **Type**: Data Model / Service Controller
- **Methods & Functions**:
  - _buildHomeTab(): Custom logic block. Executes specific business logic or UI updates.
  - _onLogout(): Custom logic block. Executes specific business logic or UI updates.
  - _build()_: Standard Flutter lifecycle method.
  - _buildAttendanceCard(): Custom logic block. Executes specific business logic or UI updates.
  - _onSync(): Custom logic block. Executes specific business logic or UI updates.
  - _buildStatBox(): Custom logic block. Executes specific business logic or UI updates.
  - _buildDynamicPolls(): Custom logic block. Executes specific business logic or UI updates.
  - InkWell(): Custom logic block. Executes specific business logic or UI updates.
  - _buildNoticeTab(): Custom logic block. Executes specific business logic or UI updates.
  - _initState()_: Standard Flutter lifecycle method.
  - Column(): Custom logic block. Executes specific business logic or UI updates.
  - _dispose()_: Standard Flutter lifecycle method.

### 📦 Class: LongLeaveScreen
- **Type**: StatelessWidget (Static UI component)
- **Methods & Functions**:
  - _build()_: Standard Flutter lifecycle method.

### 📦 Class: AdminDashboardScreen
- **Type**: StatefulWidget (Maintains mutable UI state)
- *(No explicit custom methods found)*

### 📦 Class: _AdminDashboardScreenState
- **Type**: Data Model / Service Controller
- **Methods & Functions**:
  - _buildAdminHomeTab(): Custom logic block. Executes specific business logic or UI updates.
  - _onLogout(): Custom logic block. Executes specific business logic or UI updates.
  - _showSetMenuDialog(): Custom logic block. Executes specific business logic or UI updates.
  - _showCreatePollDialog(): Custom logic block. Executes specific business logic or UI updates.
  - _build()_: Standard Flutter lifecycle method.
  - _onSync(): Custom logic block. Executes specific business logic or UI updates.
  - _closeMessAndMarkAbsent(): Custom logic block. Executes specific business logic or UI updates.
  - InkWell(): Custom logic block. Executes specific business logic or UI updates.
  - _buildAdminsTab(): Custom logic block. Executes specific business logic or UI updates.
  - _buildNoticeTab(): Custom logic block. Executes specific business logic or UI updates.
  - StatefulBuilder(): Custom logic block. Executes specific business logic or UI updates.
  - _initState()_: Standard Flutter lifecycle method.
  - _dispose()_: Standard Flutter lifecycle method.
  - _showAddNoticeDialog(): Custom logic block. Executes specific business logic or UI updates.

### 📦 Class: StudentComplaintsScreen
- **Type**: StatefulWidget (Maintains mutable UI state)
- *(No explicit custom methods found)*

### 📦 Class: _StudentComplaintsScreenState
- **Type**: Data Model / Service Controller
- **Methods & Functions**:
  - _showAddDialog(): Custom logic block. Executes specific business logic or UI updates.
  - _build()_: Standard Flutter lifecycle method.

### 📦 Class: AdminComplaintsScreen
- **Type**: StatefulWidget (Maintains mutable UI state)
- *(No explicit custom methods found)*

### 📦 Class: _AdminComplaintsScreenState
- **Type**: Data Model / Service Controller
- **Methods & Functions**:
  - _build()_: Standard Flutter lifecycle method.

### 📦 Class: AdminRegisteredStudentsScreen
- **Type**: StatelessWidget (Static UI component)
- **Methods & Functions**:
  - _build()_: Standard Flutter lifecycle method.

### 📦 Class: SwipeToConfirm
- **Type**: StatefulWidget (Maintains mutable UI state)
- *(No explicit custom methods found)*

### 📦 Class: _SwipeToConfirmState
- **Type**: Data Model / Service Controller
- **Methods & Functions**:
  - LayoutBuilder(): Custom logic block. Executes specific business logic or UI updates.
  - _build()_: Standard Flutter lifecycle method.

### 📦 Class: MealPassScreen
- **Type**: StatefulWidget (Maintains mutable UI state)
- *(No explicit custom methods found)*

### 📦 Class: _MealPassScreenState
- **Type**: Data Model / Service Controller
- **Methods & Functions**:
  - _build()_: Standard Flutter lifecycle method.
  - _dispose()_: Standard Flutter lifecycle method.
  - _formatTime(): Custom logic block. Executes specific business logic or UI updates.
  - _initState()_: Standard Flutter lifecycle method.

### 📦 Class: AdminAttendanceScreen
- **Type**: StatefulWidget (Maintains mutable UI state)
- *(No explicit custom methods found)*

### 📦 Class: _AdminAttendanceScreenState
- **Type**: Data Model / Service Controller
- **Methods & Functions**:
  - buildCell(): Custom logic block. Executes specific business logic or UI updates.
  - _build()_: Standard Flutter lifecycle method.
  - _promptEditPassword(): Custom logic block. Executes specific business logic or UI updates.
  - _onSync(): Custom logic block. Executes specific business logic or UI updates.
  - _buildExportRow(): Custom logic block. Executes specific business logic or UI updates.
  - _buildDailyView(): Custom logic block. Executes specific business logic or UI updates.
  - InkWell(): Custom logic block. Executes specific business logic or UI updates.
  - StatefulBuilder(): Custom logic block. Executes specific business logic or UI updates.
  - _showStudentHistoryDialog(): Custom logic block. Executes specific business logic or UI updates.
  - _performReset(): Custom logic block. Executes specific business logic or UI updates.
  - _initState()_: Standard Flutter lifecycle method.
  - _promptResetPassword(): Custom logic block. Executes specific business logic or UI updates.
  - _addDailyRoomSlots(): Custom logic block. Executes specific business logic or UI updates.
  - _dispose()_: Standard Flutter lifecycle method.
  - export(): Custom logic block. Executes specific business logic or UI updates.
  - _buildMonthlyView(): Custom logic block. Executes specific business logic or UI updates.

### 📦 Class: StudentAttendanceScreen
- **Type**: StatefulWidget (Maintains mutable UI state)
- *(No explicit custom methods found)*

### 📦 Class: _StudentAttendanceScreenState
- **Type**: Data Model / Service Controller
- **Methods & Functions**:
  - Expanded(): Custom logic block. Executes specific business logic or UI updates.
  - buildCell(): Custom logic block. Executes specific business logic or UI updates.
  - _build()_: Standard Flutter lifecycle method.

### 📦 Class: UpdateCheckerWrapper
- **Type**: StatefulWidget (Maintains mutable UI state)
- *(No explicit custom methods found)*

### 📦 Class: _UpdateCheckerWrapperState
- **Type**: Data Model / Service Controller
- **Methods & Functions**:
  - _build()_: Standard Flutter lifecycle method.
  - _initState()_: Standard Flutter lifecycle method.

### 📦 Class: AboutDevelopersScreen
- **Type**: StatelessWidget (Static UI component)
- **Methods & Functions**:
  - _build()_: Standard Flutter lifecycle method.

### 📦 Class: ManageStudentsScreen
- **Type**: StatefulWidget (Maintains mutable UI state)
- *(No explicit custom methods found)*

### 📦 Class: _ManageStudentsScreenState
- **Type**: Data Model / Service Controller
- **Methods & Functions**:
  - _build()_: Standard Flutter lifecycle method.
  - _showAddEditDialog(): Custom logic block. Executes specific business logic or UI updates.
  - _onSync(): Custom logic block. Executes specific business logic or UI updates.
  - StatefulBuilder(): Custom logic block. Executes specific business logic or UI updates.
  - _initState()_: Standard Flutter lifecycle method.
  - _dispose()_: Standard Flutter lifecycle method.

## 📁 File: lib\notification_service.dart

### 📦 Class: NotificationService
- **Type**: Data Model / Service Controller
- *(No explicit custom methods found)*

## 📁 File: lib\splash_screen.dart

### 📦 Class: SplashScreen
- **Type**: StatefulWidget (Maintains mutable UI state)
- *(No explicit custom methods found)*

### 📦 Class: _SplashScreenState
- **Type**: Data Model / Service Controller
- **Methods & Functions**:
  - _onNextClicked(): Custom logic block. Executes specific business logic or UI updates.
  - _checkFirstTime(): Custom logic block. Executes specific business logic or UI updates.
  - _build()_: Standard Flutter lifecycle method.
  - _initState()_: Standard Flutter lifecycle method.

## 📁 File: lib\update_service.dart

### 📦 Class: AppUpdateService
- **Type**: Data Model / Service Controller
- *(No explicit custom methods found)*

### 📦 Class: UpdateDialogWidget
- **Type**: StatefulWidget (Maintains mutable UI state)
- *(No explicit custom methods found)*

### 📦 Class: _UpdateDialogWidgetState
- **Type**: Data Model / Service Controller
- **Methods & Functions**:
  - _downloadAndInstallAndroid(): Custom logic block. Executes specific business logic or UI updates.
  - _handleUpdate(): Custom logic block. Executes specific business logic or UI updates.
  - _build()_: Standard Flutter lifecycle method.

