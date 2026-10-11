/**
 * Hostel Mess Management - Super Admin Security Console
 * 32-Bit Master Secret Key + Dynamic RBAC Console
 * Hardened Security: Direct 32-bit Key Auth + Full Staff/Committee Member CRUD
 */

// ==================== FIREBASE INITIALIZATION ====================
const firebaseConfig = {
  apiKey: "AIzaSyCJ2ebzZpVt3rQKMSSRkuH-zh13xu3N6rw",
  authDomain: "hostel-mess-21845.firebaseapp.com",
  databaseURL: "https://hostel-mess-21845-default-rtdb.firebaseio.com",
  projectId: "hostel-mess-21845",
  storageBucket: "hostel-mess-21845.appspot.com",
  messagingSenderId: "947094039187",
  appId: "1:947094039187:android:6c2a8906468742c8bdbb66"
};

firebase.initializeApp(firebaseConfig);
const db = firebase.database();

// ==================== STATE MANAGEMENT ====================
let currentScope = 'all'; // 'all', 'boys', 'girls'
let currentAdminRoleFilter = 'all'; // 'all', 'admin', 'mess_committee', 'professor'
let currentAdminSearchQuery = '';
let activeTab = 'tabOverview';
let cachedRoles = {};
let cachedAdmins = { boys: [], girls: [] };
let cachedStudents = { boys: [], girls: [] };
let sessionTimeoutSeconds = 900; // 15 minutes
let sessionTimerInterval = null;
let currentSessionUser = null;
let isSetupPermanentlyLocked = false;
let pendingDeleteTarget = null;
let currentAttSubView = 'daily'; // 'daily' or 'monthly'
let cachedDailyList = [];
let cachedMonthlyList = [];

// ==================== SUPER ADMIN AUTHENTICATION (32-BIT MASTER KEY) ====================

// 32-Character / 32-Bit Master Secret Key (Known strictly to Super Admin)
const MASTER_SECRET_KEY = "HMMS-SUPER-ADMIN-KEY-2026-X9Y8Z7";

function togglePasswordVisibility() {
  const input = document.getElementById('loginSecretKey');
  const icon = document.getElementById('eyeIcon');
  if (!input) return;
  if (input.type === 'password') {
    input.type = 'text';
    icon?.classList.replace('fa-eye', 'fa-eye-slash');
  } else {
    input.type = 'password';
    icon?.classList.replace('fa-eye-slash', 'fa-eye');
  }
}

async function handleSuperAdminLogin() {
  const nameInput = document.getElementById('loginUsername');
  const keyInput = document.getElementById('loginSecretKey');
  const username = (nameInput?.value || '').trim();
  const secretKey = (keyInput?.value || '').trim();

  if (!username) {
    showToast('Please enter your Super Admin name', 'error');
    nameInput?.focus();
    return;
  }

  if (!secretKey) {
    showToast('Please enter the 32-bit Secret Key', 'error');
    keyInput?.focus();
    return;
  }

  if (secretKey !== MASTER_SECRET_KEY) {
    showToast('Invalid Secret Key! Access Denied.', 'error');
    keyInput?.focus();
    return;
  }

  sessionStorage.setItem('sa_active_user', username);
  showToast(`Welcome ${username}! Super Admin authenticated.`, 'success');
  startUserSession(username);
}

function checkAuthStatus() {
  const activeUser = sessionStorage.getItem('sa_active_user');
  if (activeUser) {
    startUserSession(activeUser);
  } else {
    showAuthScreen();
  }
}

function showAuthScreen() {
  document.getElementById('mainDashboard')?.classList.add('hidden');
  const authScreen = document.getElementById('authScreen');
  if (authScreen) {
    authScreen.classList.remove('hidden');
  }
  const keyInput = document.getElementById('loginSecretKey');
  if (keyInput) keyInput.value = '';
}

// ==================== SESSION & TIMEOUT ====================

function startUserSession(username) {
  currentSessionUser = username;
  const userDisplay = document.getElementById('currentSuperAdminUser');
  if (userDisplay) userDisplay.innerText = username;

  document.getElementById('authScreen')?.classList.add('hidden');
  document.getElementById('mainDashboard')?.classList.remove('hidden');

  resetSessionTimer();
  window.addEventListener('mousemove', resetSessionTimer);
  window.addEventListener('keydown', resetSessionTimer);

  initAppListeners();
}

function resetSessionTimer() {
  sessionTimeoutSeconds = 900; // 15 mins
  updateSessionTimerDisplay();
  if (sessionTimerInterval) clearInterval(sessionTimerInterval);
  sessionTimerInterval = setInterval(() => {
    sessionTimeoutSeconds--;
    updateSessionTimerDisplay();
    if (sessionTimeoutSeconds <= 0) {
      clearInterval(sessionTimerInterval);
      handleSessionTimeout();
    }
  }, 1000);
}

function updateSessionTimerDisplay() {
  const m = Math.floor(sessionTimeoutSeconds / 60).toString().padStart(2, '0');
  const s = (sessionTimeoutSeconds % 60).toString().padStart(2, '0');
  const el = document.getElementById('sessionTimerText');
  if (el) el.innerText = `${m}:${s}`;
}

function handleSessionTimeout() {
  alert("Session timed out due to 15 minutes of inactivity. For security, please sign in again.");
  logout();
}

function logout() {
  if (sessionTimerInterval) clearInterval(sessionTimerInterval);
  sessionStorage.removeItem('sa_active_user');
  currentSessionUser = null;
  showAuthScreen();
  showToast('Logged out securely.', 'info');
}

document.getElementById('btnLogout')?.addEventListener('click', logout);

// ==================== SCOPE FILTER & NAVIGATION ====================

document.getElementById('scopeAll')?.addEventListener('click', () => setScope('all'));
document.getElementById('scopeBoys')?.addEventListener('click', () => setScope('boys'));
document.getElementById('scopeGirls')?.addEventListener('click', () => setScope('girls'));

function setScope(scope) {
  currentScope = scope;
  ['scopeAll', 'scopeBoys', 'scopeGirls'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.className = "px-2 sm:px-2.5 py-1 rounded-lg transition text-orange-100 hover:text-white";
  });

  const activeEl = document.getElementById(scope === 'all' ? 'scopeAll' : (scope === 'boys' ? 'scopeBoys' : 'scopeGirls'));
  if (activeEl) {
    if (scope === 'boys') {
      activeEl.className = "px-2 sm:px-2.5 py-1 rounded-lg font-bold transition bg-blue-600 text-white shadow-xs";
    } else if (scope === 'girls') {
      activeEl.className = "px-2 sm:px-2.5 py-1 rounded-lg font-bold transition bg-pink-600 text-white shadow-xs";
    } else {
      activeEl.className = "px-2 sm:px-2.5 py-1 rounded-lg font-bold transition bg-white text-[#EA580C] shadow-xs";
    }
  }

  // Update Top Bar Scope Badge
  const headerBadge = document.getElementById('headerScopeBadge');
  if (headerBadge) {
    if (scope === 'boys') {
      headerBadge.innerText = 'BOYS HOSTEL ONLY';
      headerBadge.className = 'hidden sm:inline-block px-1.5 py-0.5 text-[9px] sm:text-[10px] uppercase font-extrabold rounded shadow-xs shrink-0 bg-blue-600 text-white border border-blue-400';
    } else if (scope === 'girls') {
      headerBadge.innerText = 'GIRLS HOSTEL ONLY';
      headerBadge.className = 'hidden sm:inline-block px-1.5 py-0.5 text-[9px] sm:text-[10px] uppercase font-extrabold rounded shadow-xs shrink-0 bg-pink-600 text-white border border-pink-400';
    } else {
      headerBadge.innerText = 'BOTH HOSTELS';
      headerBadge.className = 'hidden sm:inline-block px-1.5 py-0.5 text-[9px] sm:text-[10px] uppercase font-extrabold rounded shadow-xs shrink-0 bg-white/20 text-white border border-white/20';
    }
  }

  renderAdminsTable();
  updateOverviewStats();
  applyScopeToAttendance();

  const scopeLabel = scope === 'all' ? 'Both Hostels (Combined)' : `${scope.toUpperCase()} Hostel Only`;
  showToast(`Active View: ${scopeLabel}`, 'info');
}

function applyScopeToAttendance() {
  const container = document.getElementById('attFilterHostelContainer');
  const hostelSelect = document.getElementById('attFilterHostel');
  const containerMonthly = document.getElementById('attMonthlyHostelContainer');
  const hostelSelectMonthly = document.getElementById('attMonthlyHostel');
  const attTitle = document.getElementById('attTitle');
  const attSubtitle = document.getElementById('attSubtitle');

  if (currentScope === 'boys') {
    if (hostelSelect) hostelSelect.value = 'boys';
    if (container) container.classList.add('hidden');
    if (hostelSelectMonthly) hostelSelectMonthly.value = 'boys';
    if (containerMonthly) containerMonthly.classList.add('hidden');
    if (attTitle) attTitle.innerText = "Boys Hostel Attendance Monitor";
    if (attSubtitle) attSubtitle.innerText = "Daily sheets and monthly records for Boys Hostel only";
  } else if (currentScope === 'girls') {
    if (hostelSelect) hostelSelect.value = 'girls';
    if (container) container.classList.add('hidden');
    if (hostelSelectMonthly) hostelSelectMonthly.value = 'girls';
    if (containerMonthly) containerMonthly.classList.add('hidden');
    if (attTitle) attTitle.innerText = "Girls Hostel Attendance Monitor";
    if (attSubtitle) attSubtitle.innerText = "Daily sheets and monthly records for Girls Hostel only";
  } else {
    if (container) container.classList.remove('hidden');
    if (containerMonthly) containerMonthly.classList.remove('hidden');
    if (hostelSelect && (hostelSelect.value !== 'boys' && hostelSelect.value !== 'girls')) hostelSelect.value = 'both';
    if (hostelSelectMonthly && (hostelSelectMonthly.value !== 'boys' && hostelSelectMonthly.value !== 'girls')) hostelSelectMonthly.value = 'both';
    if (attTitle) attTitle.innerText = "Attendance Monitor (Both Hostels)";
    if (attSubtitle) attSubtitle.innerText = "Daily sheets and monthly records across Both Hostels";
  }

  if (activeTab === 'tabAttendance') {
    if (currentAttSubView === 'monthly') {
      loadMonthlyAttendanceRecords();
    } else {
      loadAttendanceRecords();
    }
  }
}

document.querySelectorAll('.nav-btn, .nav-tab-mobile').forEach(btn => {
  btn.addEventListener('click', () => {
    const tabId = btn.getAttribute('data-tab');
    switchTab(tabId);
  });
});

function toggleMobileSidebar() {
  const sidebar = document.getElementById('mainSidebar');
  const backdrop = document.getElementById('sidebarBackdrop');
  if (!sidebar) return;
  const isClosed = sidebar.classList.contains('-translate-x-full');
  if (isClosed) {
    sidebar.classList.remove('-translate-x-full');
    backdrop?.classList.remove('hidden');
  } else {
    sidebar.classList.add('-translate-x-full');
    backdrop?.classList.add('hidden');
  }
}

function closeMobileSidebar() {
  const sidebar = document.getElementById('mainSidebar');
  const backdrop = document.getElementById('sidebarBackdrop');
  if (sidebar) sidebar.classList.add('-translate-x-full');
  if (backdrop) backdrop.classList.add('hidden');
}

function switchTab(tabId) {
  closeMobileSidebar();
  activeTab = tabId;
  document.querySelectorAll('.tab-pane').forEach(p => p.classList.add('hidden'));
  document.getElementById(tabId)?.classList.remove('hidden');

  document.querySelectorAll('.nav-btn').forEach(btn => {
    if (btn.getAttribute('data-tab') === tabId) {
      btn.classList.add('active');
    } else {
      btn.classList.remove('active');
    }
  });

  document.querySelectorAll('.nav-tab-mobile').forEach(btn => {
    if (btn.getAttribute('data-tab') === tabId) {
      btn.classList.add('active');
      btn.classList.remove('text-orange-100/90');
      try {
        btn.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' });
      } catch (e) {}
    } else {
      btn.classList.remove('active');
      btn.classList.add('text-orange-100/90');
    }
  });

  if (tabId === 'tabAttendance') {
    const dateInput = document.getElementById('attFilterDate');
    if (dateInput && !dateInput.value) {
      dateInput.value = new Date().toISOString().split('T')[0];
    }
    const monthSelect = document.getElementById('attMonthlyMonth');
    if (monthSelect && !monthSelect.value) {
      monthSelect.value = (new Date().getMonth() + 1).toString();
    }
    const yearSelect = document.getElementById('attMonthlyYear');
    if (yearSelect && !yearSelect.value) {
      yearSelect.value = new Date().getFullYear().toString();
    }
    applyScopeToAttendance();
  } else if (tabId === 'tabAdmins') {
    renderAdminsTable();
  } else if (tabId === 'tabOverview') {
    updateOverviewStats();
  }
}

// ==================== DATA LISTENERS & INITIALIZATION ====================

function initAppListeners() {
  listenToRoles();
  listenToAdmins();
  listenToStudents();
  listenToAuditLogs();
  setScope(currentScope);
}

function refreshAllData() {
  listenToRoles();
  listenToAdmins();
  listenToStudents();
  listenToAuditLogs();
  showToast('Real-time data refreshed from Firebase.', 'success');
}

// ==================== 1. ROLES & PERMISSIONS (RBAC) ====================

const defaultRolesSeed = {
  super_admin: {
    name: "Super Admin",
    permissions: {
      can_manage_polls: true,
      can_manage_meals: true,
      can_set_menu: true,
      can_edit_timetable: true,
      can_attendance: true,
      can_attendance_edit: true,
      can_students_manage: true,
      can_complaints: true,
      can_manage_complaint_window: true,
      can_notices: true
    }
  },
  admin: {
    name: "Admin",
    permissions: {
      can_manage_polls: true,
      can_manage_meals: true,
      can_set_menu: true,
      can_edit_timetable: true,
      can_attendance: true,
      can_attendance_edit: true,
      can_students_manage: true,
      can_complaints: true,
      can_manage_complaint_window: true,
      can_notices: true
    }
  },
  mess_committee: {
    name: "Mess Committee",
    permissions: {
      can_manage_polls: true,
      can_manage_meals: false,
      can_set_menu: false,
      can_edit_timetable: false,
      can_attendance: false,
      can_attendance_edit: false,
      can_students_manage: false,
      can_complaints: true,
      can_manage_complaint_window: false,
      can_notices: true
    }
  },
  professor: {
    name: "Professor / Warden",
    permissions: {
      can_manage_polls: false,
      can_manage_meals: false,
      can_set_menu: false,
      can_edit_timetable: false,
      can_attendance: true,
      can_attendance_edit: false,
      can_students_manage: false,
      can_complaints: true,
      can_manage_complaint_window: true,
      can_notices: true
    }
  }
};

function listenToRoles() {
  db.ref('roles').on('value', snap => {
    if (!snap.exists() || !snap.val()) {
      // Seed default roles if empty
      db.ref('roles').set(defaultRolesSeed);
      cachedRoles = defaultRolesSeed;
    } else {
      cachedRoles = snap.val();

      // Ensure super_admin has all standard permissions intact and can be toggled
      if (!cachedRoles.super_admin) {
        cachedRoles.super_admin = defaultRolesSeed.super_admin;
        db.ref('roles/super_admin').set(defaultRolesSeed.super_admin);
      } else if (!cachedRoles.super_admin.permissions) {
        cachedRoles.super_admin.permissions = defaultRolesSeed.super_admin.permissions;
        db.ref('roles/super_admin/permissions').set(defaultRolesSeed.super_admin.permissions);
      } else {
        let saUpdated = false;
        Object.keys(defaultRolesSeed.super_admin.permissions).forEach(pk => {
          if (cachedRoles.super_admin.permissions[pk] === undefined || cachedRoles.super_admin.permissions[pk] === null) {
            cachedRoles.super_admin.permissions[pk] = true;
            saUpdated = true;
          }
        });
        if (saUpdated) {
          db.ref('roles/super_admin/permissions').set(cachedRoles.super_admin.permissions);
        }
      }

      // Ensure admin has all standard permissions intact
      if (!cachedRoles.admin) {
        cachedRoles.admin = defaultRolesSeed.admin;
        db.ref('roles/admin').set(defaultRolesSeed.admin);
      } else if (!cachedRoles.admin.permissions) {
        cachedRoles.admin.permissions = defaultRolesSeed.admin.permissions;
        db.ref('roles/admin/permissions').set(defaultRolesSeed.admin.permissions);
      } else {
        let adminUpdated = false;
        Object.keys(defaultRolesSeed.admin.permissions).forEach(pk => {
          if (cachedRoles.admin.permissions[pk] === undefined) {
            cachedRoles.admin.permissions[pk] = true;
            adminUpdated = true;
          }
        });
        if (adminUpdated) {
          db.ref('roles/admin/permissions').set(cachedRoles.admin.permissions);
        }
      }

      // Scrub obsolete can_manage_admins from all roles in Firebase & local cache
      Object.keys(cachedRoles).forEach(rId => {
        if (cachedRoles[rId] && cachedRoles[rId].permissions) {
          if (cachedRoles[rId].permissions.can_manage_admins !== undefined) {
            delete cachedRoles[rId].permissions.can_manage_admins;
            db.ref(`roles/${rId}/permissions/can_manage_admins`).remove();
          }
        }
      });
    }
    renderRolesGrid();
    updateRoleDropdowns();
    updateOverviewStats();
    renderAdminsTable();
  });
}

const permissionLabels = {
  can_manage_polls: { label: "Mess Polls (Create/Vote/View Results)", icon: "fa-poll" },
  can_manage_meals: { label: "Mess Entry (Lunch / Dinner Switches)", icon: "fa-utensils" },
  can_set_menu: { label: "Set Menu (Today)", icon: "fa-bowl-rice" },
  can_edit_timetable: { label: "Edit Weekly Timetable", icon: "fa-calendar-days" },
  can_attendance: { label: "View Attendance (View Monthly Sheets)", icon: "fa-calendar-check" },
  can_attendance_edit: { label: "Modify Attendance (Mark/Edit Attendance)", icon: "fa-pen-to-square" },
  can_students_manage: { label: "Student Management (Add/Delete/Rooms)", icon: "fa-user-graduate" },
  can_complaints: { label: "Complaints Access (View Complaints)", icon: "fa-triangle-exclamation" },
  can_manage_complaint_window: { label: "Complaint Schedule & Window (Open/Close Dates)", icon: "fa-calendar-check" },
  can_notices: { label: "Notice Board (Broadcast & Delete Notices)", icon: "fa-bullhorn" }
};

const defaultStandardPerms = {
  can_manage_polls: { label: "Mess Polls (Create/Vote/View Results)", icon: "fa-poll", checked: true },
  can_manage_meals: { label: "Mess Entry (Lunch / Dinner Switches)", icon: "fa-utensils", checked: true },
  can_set_menu: { label: "Set Menu (Today)", icon: "fa-bowl-rice", checked: true },
  can_edit_timetable: { label: "Edit Weekly Timetable", icon: "fa-calendar-days", checked: true },
  can_attendance: { label: "View Attendance (View Monthly Sheets)", icon: "fa-calendar-check", checked: false },
  can_attendance_edit: { label: "Modify Attendance (Mark/Edit Attendance)", icon: "fa-pen-to-square", checked: false },
  can_students_manage: { label: "Student Management (Add/Delete/Rooms)", icon: "fa-user-graduate", checked: false },
  can_complaints: { label: "Complaints Access (View Complaints)", icon: "fa-triangle-exclamation", checked: true },
  can_manage_complaint_window: { label: "Complaint Schedule & Window (Open/Close Dates)", icon: "fa-calendar-check", checked: false },
  can_notices: { label: "Notice Board (Broadcast & Delete Notices)", icon: "fa-bullhorn", checked: true }
};

let modalPermsState = JSON.parse(JSON.stringify(defaultStandardPerms));

function renderCreateRolePermsList() {
  const container = document.getElementById('createRolePermList');
  if (!container) return;
  container.innerHTML = '';
  const keys = Object.keys(modalPermsState);
  keys.forEach(key => {
    const item = modalPermsState[key];
    const row = document.createElement('div');
    row.className = "flex items-center justify-between p-2.5 bg-[#EFF3FC] rounded-xl text-xs hover:bg-slate-100 transition border border-transparent hover:border-slate-200";
    row.innerHTML = `
      <label class="flex items-center gap-2.5 cursor-pointer flex-1 select-none">
        <input type="checkbox" id="perm_cb_${key}" ${item.checked ? 'checked' : ''} onchange="modalPermsState['${key}'].checked = this.checked" class="w-4 h-4 accent-[#EA580C] rounded">
        <i class="fa-solid ${item.icon || 'fa-shield-halved'} text-[#EA580C] w-4 text-center"></i>
        <span class="font-medium text-[#0F172A]">${item.label}</span>
      </label>
    `;
    container.appendChild(row);
  });
}

function selectAllRolePerms(selectAll) {
  Object.keys(modalPermsState).forEach(k => {
    modalPermsState[k].checked = !!selectAll;
    const el = document.getElementById(`perm_cb_${k}`);
    if (el) el.checked = !!selectAll;
  });
}

function renderRolesGrid() {
  const container = document.getElementById('rolesListContainer');
  if (!container) return;
  container.innerHTML = '';

  Object.entries(cachedRoles).forEach(([roleId, roleData]) => {
    const isRoot = roleId === 'super_admin';
    const isAdmin = roleId === 'admin';
    const card = document.createElement('div');
    card.className = "app-card p-5 space-y-4 hover:shadow-md transition";

    const rolePerms = roleData.permissions || {};
    delete rolePerms.can_manage_admins;

    const allKeys = Object.keys(permissionLabels);
    let activeCount = 0;
    let togglesHtml = '';

    allKeys.forEach(permKey => {
      const permMeta = permissionLabels[permKey] || { label: permKey, icon: "fa-shield-halved" };
      const isChecked = rolePerms[permKey] === true;
      if (isChecked) activeCount++;
      togglesHtml += `
        <div class="flex items-center justify-between p-2.5 bg-[#EFF3FC] rounded-xl border border-slate-200/70 hover:border-slate-300 transition">
          <div class="flex items-center gap-2.5 flex-1 pr-2">
            <i class="fa-solid ${permMeta.icon || 'fa-shield-halved'} text-[#EA580C] text-xs w-4 text-center"></i>
            <span class="text-xs font-semibold text-[#0F172A]">${permMeta.label}</span>
          </div>
          <div class="flex items-center gap-2 shrink-0">
            <label class="switch">
              <input type="checkbox" ${isChecked ? 'checked' : ''} onchange="togglePermission('${roleId}', '${permKey}', this.checked)">
              <span class="slider"></span>
            </label>
          </div>
        </div>
      `;
    });

    const totalPerms = allKeys.length;

    card.innerHTML = `
      <div class="flex items-center justify-between pb-3 border-b border-slate-100 flex-wrap gap-2">
        <div>
          <div class="flex items-center gap-2 flex-wrap">
            <h3 class="font-extrabold text-[#0F172A] text-base">${roleData.name || roleId}</h3>
            <span class="px-2 py-0.5 text-[10px] uppercase font-mono font-bold bg-[#FFF7ED] text-[#EA580C] border border-orange-200 rounded-md">${roleId}</span>
            <span class="px-2 py-0.5 text-[10px] font-bold rounded-full ${activeCount > 0 ? 'bg-orange-100 text-[#EA580C]' : 'bg-slate-100 text-slate-500'}">
              ${activeCount} / ${totalPerms} Active
            </span>
          </div>
          <p class="text-[11px] text-[#64748B] mt-0.5">Toggle permissions update live in the mobile app</p>
        </div>
        ${!isRoot && !isAdmin ? `
          <button onclick="deleteRole('${roleId}')" class="text-xs text-red-600 hover:text-red-700 bg-red-50 hover:bg-red-100 px-2.5 py-1.5 rounded-xl border border-red-200 transition font-bold flex items-center gap-1 shrink-0">
            <i class="fa-solid fa-trash-can"></i>
            <span>Delete Role</span>
          </button>
        ` : ''}
      </div>
      <div class="space-y-2">
        ${togglesHtml}
      </div>
    `;
    container.appendChild(card);
  });
}

async function togglePermission(roleId, permKey, isChecked) {
  try {
    await db.ref(`roles/${roleId}/permissions/${permKey}`).set(isChecked);
    await logAudit('PERMISSION_CHANGE', `Toggled ${permKey} to ${isChecked ? 'ON' : 'OFF'} for role ${roleId}`);
    showToast(`Saved! Role ${roleId} -> ${permKey}: ${isChecked ? 'ON' : 'OFF'}`, 'success');
  } catch (e) {
    showToast(`Error updating permission: ${e.message}`, 'error');
  }
}

function openCreateRoleModal() {
  document.getElementById('newRoleId').value = '';
  document.getElementById('newRoleName').value = '';
  modalPermsState = JSON.parse(JSON.stringify(defaultStandardPerms));
  renderCreateRolePermsList();
  document.getElementById('modalCreateRole').classList.remove('hidden');
}

function closeCreateRoleModal() {
  document.getElementById('modalCreateRole').classList.add('hidden');
}

async function submitNewRole() {
  const roleId = document.getElementById('newRoleId').value.trim().toLowerCase().replace(/[^a-z0-9_]/g, '_');
  const roleName = document.getElementById('newRoleName').value.trim();

  if (!roleId || !roleName) return showToast('Please enter Role ID and Display Name', 'error');
  if (cachedRoles[roleId]) return showToast('Role with this ID already exists', 'error');

  const perms = {};
  Object.keys(modalPermsState).forEach(k => {
    perms[k] = modalPermsState[k].checked === true;
  });

  await db.ref(`roles/${roleId}`).set({
    name: roleName,
    permissions: perms
  });

  await logAudit('ROLE_CREATED', `Created new role '${roleName}' (${roleId}) with customized initial permissions`);
  closeCreateRoleModal();
  showToast(`Role '${roleName}' created successfully!`, 'success');
}

async function deleteRole(roleId) {
  if (roleId === 'admin' || roleId === 'super_admin') {
    return showToast(`Cannot delete system role '${roleId}'`, 'error');
  }
  if (!confirm(`Are you sure you want to permanently delete role '${roleId}'?`)) return;
  await db.ref(`roles/${roleId}`).remove();
  await logAudit('ROLE_DELETED', `Deleted custom role ${roleId}`);
  showToast(`Role ${roleId} deleted.`, 'info');
}

function updateRoleDropdowns() {
  const selectors = ['newAdminRole', 'editAdminRoleSelect'];
  selectors.forEach(selId => {
    const select = document.getElementById(selId);
    if (!select) return;
    const currentVal = select.value;
    select.innerHTML = '';
    Object.entries(cachedRoles).forEach(([id, data]) => {
      const opt = document.createElement('option');
      opt.value = id;
      opt.innerText = `${data.name || id} (${id})`;
      select.appendChild(opt);
    });
    if (currentVal) select.value = currentVal;
  });
}

// ==================== 2. STAFF, ADMINS & COMMITTEE MEMBERS MANAGEMENT ====================

function listenToAdmins() {
  ['boys', 'girls'].forEach(hostel => {
    db.ref(`hostelData_${hostel}/admins`).on('value', snap => {
      const val = snap.val();
      cachedAdmins[hostel] = [];
      if (val) {
        const list = Array.isArray(val) ? val : Object.values(val);
        cachedAdmins[hostel] = list.filter(a => a && a.phone);
      }
      renderAdminsTable();
      updateOverviewStats();
    });
  });
}

function setAdminRoleFilter(filterRole) {
  currentAdminRoleFilter = filterRole;
  const filterMap = {
    all: 'filterRoleAll',
    admin: 'filterRoleAdmin',
    mess_committee: 'filterRoleCommittee',
    professor: 'filterRoleProfessor'
  };

  Object.values(filterMap).forEach(id => {
    const el = document.getElementById(id);
    if (el) {
      el.className = "px-3 py-1.5 rounded-xl font-medium bg-[#EFF3FC] text-slate-600 hover:text-[#0F172A] transition";
    }
  });

  const activeId = filterMap[filterRole];
  if (activeId) {
    const el = document.getElementById(activeId);
    if (el) el.className = "px-3 py-1.5 rounded-xl font-bold bg-[#EA580C] text-white shadow-xs transition";
  }

  renderAdminsTable();
}

function handleAdminSearch(val) {
  currentAdminSearchQuery = (val || '').trim().toLowerCase();
  renderAdminsTable();
}

function renderAdminsTable() {
  const tbody = document.getElementById('adminsTableBody');
  if (!tbody) return;
  tbody.innerHTML = '';

  const titleEl = document.getElementById('adminsTitle');
  const subtitleEl = document.getElementById('adminsSubtitle');
  if (currentScope === 'boys') {
    if (titleEl) titleEl.innerText = "Boys Hostel Staff & Committee";
    if (subtitleEl) subtitleEl.innerText = "Manage and edit roles for Boys Hostel staff and committee members";
  } else if (currentScope === 'girls') {
    if (titleEl) titleEl.innerText = "Girls Hostel Staff & Committee";
    if (subtitleEl) subtitleEl.innerText = "Manage and edit roles for Girls Hostel staff and committee members";
  } else {
    if (titleEl) titleEl.innerText = "Staff, Admins & Committee Members";
    if (subtitleEl) subtitleEl.innerText = "Manage, edit roles, or revoke access for Admins, Mess Committee, Wardens across Both Hostels";
  }

  let list = [];
  if (currentScope === 'all') {
    list = [...cachedAdmins.boys.map(a => ({ ...a, location: 'boys' })), ...cachedAdmins.girls.map(a => ({ ...a, location: 'girls' }))];
  } else if (currentScope === 'boys') {
    list = cachedAdmins.boys.map(a => ({ ...a, location: 'boys' }));
  } else {
    list = cachedAdmins.girls.map(a => ({ ...a, location: 'girls' }));
  }

  // Deduplicate by phone if scope is all
  const uniqueAdmins = [];
  const seenPhones = new Set();
  list.forEach(item => {
    const key = `${item.phone}_${item.location}`;
    if (!seenPhones.has(key)) {
      seenPhones.add(key);
      uniqueAdmins.push(item);
    }
  });

  // KPI summary counters
  let cntTotal = uniqueAdmins.length;
  let cntAdmin = uniqueAdmins.filter(a => a.role === 'admin' || a.role === 'super_admin').length;
  let cntCommittee = uniqueAdmins.filter(a => a.role === 'mess_committee').length;
  let cntProfessors = uniqueAdmins.filter(a => a.role === 'professor').length;

  if (document.getElementById('adminStatTotal')) document.getElementById('adminStatTotal').innerText = cntTotal;
  if (document.getElementById('adminStatAdmins')) document.getElementById('adminStatAdmins').innerText = cntAdmin;
  if (document.getElementById('adminStatCommittee')) document.getElementById('adminStatCommittee').innerText = cntCommittee;
  if (document.getElementById('adminStatProfessors')) document.getElementById('adminStatProfessors').innerText = cntProfessors;

  // Apply Role Filter
  let filteredList = uniqueAdmins;
  if (currentAdminRoleFilter !== 'all') {
    filteredList = filteredList.filter(a => a.role === currentAdminRoleFilter);
  }

  // Apply Search Query Filter
  if (currentAdminSearchQuery) {
    filteredList = filteredList.filter(a =>
      (a.name && a.name.toLowerCase().includes(currentAdminSearchQuery)) ||
      (a.phone && a.phone.includes(currentAdminSearchQuery)) ||
      (a.email && a.email.toLowerCase().includes(currentAdminSearchQuery)) ||
      (a.role && a.role.toLowerCase().includes(currentAdminSearchQuery))
    );
  }

  const countBadge = document.getElementById('adminTableCount');
  if (countBadge) countBadge.innerText = filteredList.length;

  if (filteredList.length === 0) {
    tbody.innerHTML = `<tr><td colspan="6" class="text-center py-8 text-[#64748B] italic">No staff or committee members found matching criteria.</td></tr>`;
    return;
  }

  filteredList.forEach(admin => {
    const isRoot = admin.phone === '9427329977' || admin.phone === '9313279977' || admin.phone === '9586401483';
    const roleTitle = cachedRoles[admin.role]?.name || admin.role || 'Admin';
    const scopeLabel = admin.hostelScope === 'boys' ? 'Boys Only' : (admin.hostelScope === 'girls' ? 'Girls Only' : 'Both Hostels');
    const scopeColor = admin.hostelScope === 'boys' ? 'text-blue-700 bg-blue-50 border-blue-200' : (admin.hostelScope === 'girls' ? 'text-pink-700 bg-pink-50 border-pink-200' : 'text-[#EA580C] bg-[#FFF7ED] border-orange-200');

    let roleBadgeColor = 'bg-slate-100 text-[#0F172A] border-slate-200';
    if (admin.role === 'admin') roleBadgeColor = 'bg-[#FFF7ED] text-[#EA580C] border-orange-300';
    if (admin.role === 'mess_committee') roleBadgeColor = 'bg-teal-50 text-teal-700 border-teal-200';
    if (admin.role === 'professor') roleBadgeColor = 'bg-purple-50 text-purple-700 border-purple-200';

    const tr = document.createElement('tr');
    tr.className = "hover:bg-[#FFF7ED]/25 transition";
    tr.innerHTML = `
      <td class="py-3 px-4 font-bold text-[#0F172A] flex items-center gap-3">
        <div class="w-8 h-8 rounded-full bg-[#FFF7ED] text-[#EA580C] flex items-center justify-center font-bold text-xs shadow-sm">
          <i class="fa-solid fa-user"></i>
        </div>
        <div>
          <div>${admin.name || 'Unnamed User'}</div>
          <div class="text-[11px] text-[#64748B] font-normal">${admin.email || 'No email registered'}</div>
        </div>
      </td>
      <td class="py-3 px-4 font-mono font-bold text-[#EA580C]">${admin.phone}</td>
      <td class="py-3 px-4">
        <span class="px-2.5 py-0.5 rounded-full text-[10px] font-bold border ${roleBadgeColor}">${roleTitle}</span>
      </td>
      <td class="py-3 px-4">
        <span class="px-2.5 py-0.5 rounded-full text-[10px] font-bold border ${scopeColor}">${scopeLabel}</span>
      </td>
      <td class="py-3 px-4 text-[#64748B] capitalize">${admin.location} Hostel DB</td>
      <td class="py-3 px-4 text-right space-x-1.5 whitespace-nowrap">
        <button onclick="openEditAdminModal('${admin.phone}', '${encodeURIComponent(admin.name || '')}', '${admin.role}', '${admin.hostelScope || 'both'}', '${admin.location}', '${encodeURIComponent(admin.email || '')}')" class="px-2.5 py-1 text-xs font-bold text-slate-700 bg-slate-100 hover:bg-slate-200 border border-slate-200 rounded-lg transition" title="Edit Role & Scope">
          <i class="fa-solid fa-pen-to-square mr-1 text-[#EA580C]"></i>Edit
        </button>
        <button onclick="openDeleteConfirmModal('${admin.phone}', '${encodeURIComponent(admin.name || '')}', '${admin.role}', '${admin.location}')" class="px-2.5 py-1 text-xs font-bold text-red-600 bg-red-50 hover:bg-red-100 border border-red-200 rounded-lg transition" title="Revoke & Delete">
          <i class="fa-solid fa-trash-can mr-1"></i>Delete
        </button>
      </td>
    `;
    tbody.appendChild(tr);
  });
}

// Add Admin / Committee Member Modal
function openAddAdminModal() {
  document.getElementById('newAdminPhone').value = '';
  document.getElementById('newAdminName').value = '';
  document.getElementById('newAdminEmail').value = '';
  updateRoleDropdowns();

  const scopeSelect = document.getElementById('newAdminScope');
  if (scopeSelect) {
    if (currentScope === 'boys') {
      scopeSelect.value = 'boys';
    } else if (currentScope === 'girls') {
      scopeSelect.value = 'girls';
    } else {
      scopeSelect.value = 'both';
    }
  }

  document.getElementById('modalAddAdmin').classList.remove('hidden');
}

function closeAddAdminModal() {
  document.getElementById('modalAddAdmin').classList.add('hidden');
}

async function submitNewAdmin() {
  const phone = document.getElementById('newAdminPhone').value.trim();
  const name = document.getElementById('newAdminName').value.trim();
  const email = document.getElementById('newAdminEmail').value.trim();
  const role = document.getElementById('newAdminRole').value;
  const scope = document.getElementById('newAdminScope').value;

  if (phone.length !== 10 || !/^\d+$/.test(phone)) return showToast('Please enter a valid 10-digit mobile number', 'error');
  if (!name) return showToast('Please enter user name', 'error');
  if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return showToast('Email is compulsory! Please enter a valid email address.', 'error');

  const adminObj = {
    phone: phone,
    name: name,
    email: email,
    pin: "",
    role: role,
    hostelScope: scope,
    isVerified: false,
    photoUrl: ""
  };

  const targets = scope === 'both' ? ['boys', 'girls'] : [scope];

  // Remove if already exists with same phone from BOTH hostels first to avoid stale copies
  for (const h of ['boys', 'girls']) {
    const snap = await db.ref(`hostelData_${h}/admins`).get();
    if (snap.exists() && snap.val()) {
      let list = Array.isArray(snap.val()) ? snap.val() : Object.values(snap.val());
      list = list.filter(a => a && a.phone !== phone);
      await db.ref(`hostelData_${h}/admins`).set(list);
    }
  }

  // Re-insert into target hostels
  for (const h of targets) {
    const snap = await db.ref(`hostelData_${h}/admins`).get();
    let currentList = [];
    if (snap.exists() && snap.val()) {
      currentList = Array.isArray(snap.val()) ? snap.val() : Object.values(snap.val());
    }
    currentList = currentList.filter(a => a && a.phone !== phone);
    currentList.push(adminObj);
    await db.ref(`hostelData_${h}/admins`).set(currentList);
  }

  await logAudit('STAFF_CREATED', `Added new ${role} ${name} (${phone}) with scope '${scope}'`);
  closeAddAdminModal();
  showToast(`User ${name} added successfully as ${role}!`, 'success');
}

// Edit Admin / Committee Member Modal
function openEditAdminModal(phone, encodedName, role, scope, location, encodedEmail) {
  const name = decodeURIComponent(encodedName || '');
  const email = decodeURIComponent(encodedEmail || '');
  document.getElementById('editAdminPhone').value = phone;
  document.getElementById('editAdminOldLocation').value = location;
  document.getElementById('editAdminDisplayName').innerText = name || phone;
  document.getElementById('editAdminDisplayPhone').innerText = phone;
  const emailEl = document.getElementById('editAdminEmail');
  if (emailEl) emailEl.value = email;

  updateRoleDropdowns();
  document.getElementById('editAdminRoleSelect').value = role || 'admin';
  document.getElementById('editAdminScopeSelect').value = scope || 'both';

  document.getElementById('modalEditAdmin').classList.remove('hidden');
}

function closeEditAdminModal() {
  document.getElementById('modalEditAdmin').classList.add('hidden');
}

async function submitEditAdmin() {
  const phone = document.getElementById('editAdminPhone').value;
  const newRole = document.getElementById('editAdminRoleSelect').value;
  const newScope = document.getElementById('editAdminScopeSelect').value;
  const emailEl = document.getElementById('editAdminEmail');

  if (!phone) return;

  // Fetch existing admin object to preserve name, pin, email, etc.
  let existingObj = null;
  for (const h of ['boys', 'girls']) {
    const snap = await db.ref(`hostelData_${h}/admins`).get();
    if (snap.exists() && snap.val()) {
      const list = Array.isArray(snap.val()) ? snap.val() : Object.values(snap.val());
      const match = list.find(a => a && a.phone === phone);
      if (match) {
        existingObj = { ...match };
        break;
      }
    }
  }

  if (!existingObj) {
    return showToast('Admin record not found!', 'error');
  }

  if (emailEl) {
    const emailVal = emailEl.value.trim();
    if (!emailVal || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(emailVal)) {
      return showToast('Valid email is compulsory!', 'error');
    }
    existingObj.email = emailVal;
  }

  existingObj.role = newRole;
  existingObj.hostelScope = newScope;

  // Clear from both first
  for (const h of ['boys', 'girls']) {
    const snap = await db.ref(`hostelData_${h}/admins`).get();
    if (snap.exists() && snap.val()) {
      let list = Array.isArray(snap.val()) ? snap.val() : Object.values(snap.val());
      list = list.filter(a => a && a.phone !== phone);
      await db.ref(`hostelData_${h}/admins`).set(list);
    }
  }

  // Re-insert into targets
  const targets = newScope === 'both' ? ['boys', 'girls'] : [newScope];
  for (const h of targets) {
    const snap = await db.ref(`hostelData_${h}/admins`).get();
    let currentList = [];
    if (snap.exists() && snap.val()) {
      currentList = Array.isArray(snap.val()) ? snap.val() : Object.values(snap.val());
    }
    currentList.push(existingObj);
    await db.ref(`hostelData_${h}/admins`).set(currentList);
  }

  await logAudit('STAFF_UPDATED', `Updated ${existingObj.name} (${phone}) to role '${newRole}', scope '${newScope}'`);
  closeEditAdminModal();
  showToast(`Updated ${existingObj.name} successfully!`, 'success');
}

// Delete Confirmation Modal
function openDeleteConfirmModal(phone, encodedName, role, location) {
  const name = decodeURIComponent(encodedName);
  pendingDeleteTarget = { phone, name, role, location };

  document.getElementById('deleteTargetName').innerText = name || phone;
  document.getElementById('deleteTargetRole').innerText = role;

  const btnConfirm = document.getElementById('btnConfirmDeleteExec');
  btnConfirm.onclick = executeDeleteAdmin;

  document.getElementById('modalConfirmDelete').classList.remove('hidden');
}

function closeDeleteModal() {
  pendingDeleteTarget = null;
  document.getElementById('modalConfirmDelete').classList.add('hidden');
}

async function executeDeleteAdmin() {
  if (!pendingDeleteTarget) return;
  const { phone, name, role } = pendingDeleteTarget;

  // Remove from both hostels database completely
  for (const h of ['boys', 'girls']) {
    const snap = await db.ref(`hostelData_${h}/admins`).get();
    if (snap.exists() && snap.val()) {
      let list = Array.isArray(snap.val()) ? snap.val() : Object.values(snap.val());
      list = list.filter(a => a && a.phone !== phone);
      await db.ref(`hostelData_${h}/admins`).set(list);
    }
  }

  await logAudit('STAFF_EVICTED', `Revoked all access and deleted ${role} ${name} (${phone})`);
  closeDeleteModal();
  showToast(`Revoked access and deleted ${name || phone}!`, 'info');
}

// ==================== 3. STUDENTS & STATS ====================

function listenToStudents() {
  ['boys', 'girls'].forEach(hostel => {
    db.ref(`hostelData_${hostel}/students`).on('value', snap => {
      const val = snap.val();
      cachedStudents[hostel] = [];
      if (val) {
        cachedStudents[hostel] = Array.isArray(val) ? val : Object.values(val);
      }
      updateOverviewStats();
    });
  });
}

function updateOverviewStats() {
  const cardBoys = document.getElementById('cardBoysStudents');
  const cardGirls = document.getElementById('cardGirlsStudents');
  const overviewGrid = document.getElementById('overviewStatsGrid');
  const overviewSubtitle = document.getElementById('overviewSubtitle');
  const labelStaff = document.getElementById('labelActiveStaff');
  const sublabelStaff = document.getElementById('sublabelActiveStaff');
  const statStaff = document.getElementById('statAdminsCount');

  if (document.getElementById('statBoysCount')) {
    document.getElementById('statBoysCount').innerText = cachedStudents.boys.length;
  }
  if (document.getElementById('statGirlsCount')) {
    document.getElementById('statGirlsCount').innerText = cachedStudents.girls.length;
  }
  if (document.getElementById('statRolesCount')) {
    document.getElementById('statRolesCount').innerText = Object.keys(cachedRoles).length;
  }

  if (currentScope === 'boys') {
    if (cardBoys) cardBoys.classList.remove('hidden');
    if (cardGirls) cardGirls.classList.add('hidden');
    if (overviewGrid) overviewGrid.className = "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 sm:gap-4";
    if (overviewSubtitle) overviewSubtitle.innerText = "Real-time statistics for Boys Hostel only";
    if (labelStaff) labelStaff.innerText = "Boys Hostel Staff";
    if (sublabelStaff) sublabelStaff.innerText = "Boys Staff & Committee";
    if (statStaff) statStaff.innerText = cachedAdmins.boys.length;
  } else if (currentScope === 'girls') {
    if (cardBoys) cardBoys.classList.add('hidden');
    if (cardGirls) cardGirls.classList.remove('hidden');
    if (overviewGrid) overviewGrid.className = "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 sm:gap-4";
    if (overviewSubtitle) overviewSubtitle.innerText = "Real-time statistics for Girls Hostel only";
    if (labelStaff) labelStaff.innerText = "Girls Hostel Staff";
    if (sublabelStaff) sublabelStaff.innerText = "Girls Staff & Committee";
    if (statStaff) statStaff.innerText = cachedAdmins.girls.length;
  } else {
    // Both Hostels ('all')
    if (cardBoys) cardBoys.classList.remove('hidden');
    if (cardGirls) cardGirls.classList.remove('hidden');
    if (overviewGrid) overviewGrid.className = "grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4";
    if (overviewSubtitle) overviewSubtitle.innerText = "Real-time statistics across Both Hostels (Boys & Girls)";
    if (labelStaff) labelStaff.innerText = "Total Active Staff";
    if (sublabelStaff) sublabelStaff.innerText = "Across Both Hostels";
    if (statStaff) statStaff.innerText = (cachedAdmins.boys.length + cachedAdmins.girls.length);
  }
}

// ==================== 4. ATTENDANCE MONITOR (VIEW-ONLY DAILY & MONTHLY) ====================

function setAttendanceSubView(view) {
  currentAttSubView = view;
  const btnDaily = document.getElementById('btnAttViewDaily');
  const btnMonthly = document.getElementById('btnAttViewMonthly');
  const secDaily = document.getElementById('attDailySection');
  const secMonthly = document.getElementById('attMonthlySection');

  if (view === 'daily') {
    if (secDaily) secDaily.classList.remove('hidden');
    if (secMonthly) secMonthly.classList.add('hidden');

    if (btnDaily) {
      btnDaily.className = "px-4 py-2 rounded-xl text-xs font-bold transition bg-[#EA580C] text-white shadow-xs flex items-center gap-2";
    }
    if (btnMonthly) {
      btnMonthly.className = "px-4 py-2 rounded-xl text-xs font-semibold transition text-[#64748B] hover:text-[#0F172A] flex items-center gap-2";
    }

    const dateInput = document.getElementById('attFilterDate');
    if (dateInput && !dateInput.value) {
      dateInput.value = new Date().toISOString().split('T')[0];
    }
    loadAttendanceRecords();
  } else {
    if (secDaily) secDaily.classList.add('hidden');
    if (secMonthly) secMonthly.classList.remove('hidden');

    if (btnMonthly) {
      btnMonthly.className = "px-4 py-2 rounded-xl text-xs font-bold transition bg-[#EA580C] text-white shadow-xs flex items-center gap-2";
    }
    if (btnDaily) {
      btnDaily.className = "px-4 py-2 rounded-xl text-xs font-semibold transition text-[#64748B] hover:text-[#0F172A] flex items-center gap-2";
    }

    const monthSelect = document.getElementById('attMonthlyMonth');
    if (monthSelect && !monthSelect.value) {
      monthSelect.value = (new Date().getMonth() + 1).toString();
    }
    const yearSelect = document.getElementById('attMonthlyYear');
    if (yearSelect && !yearSelect.value) {
      yearSelect.value = new Date().getFullYear().toString();
    }
    loadMonthlyAttendanceRecords();
  }
}

// ==================== TIDB CLOUD ATTENDANCE INTEGRATION ====================
const RENDER_API_URL = "https://hostel-backend-pdph.onrender.com";
let tidbAttendanceCache = {};

/**
 * Fetches historical attendance records from TiDB Cloud via Render Backend API
 * @param {number} year 
 * @param {number} month 
 * @param {string} mode 'boys' | 'girls'
 * @param {boolean} forceRefresh whether to bypass memory cache
 * @returns {Promise<Object>} Map of "YYYY-M-D_Room_Name" -> { l, d }
 */
async function fetchTiDBAttendance(year, month, mode, forceRefresh = false) {
  const cacheKey = `${mode}_${year}_${month}`;
  if (!forceRefresh && tidbAttendanceCache[cacheKey]) {
    return tidbAttendanceCache[cacheKey];
  }
  try {
    const res = await fetch(`${RENDER_API_URL}/attendance-history?year=${year}&month=${month}&mode=${mode}`, {
      headers: { 'Accept': 'application/json' }
    });
    if (!res.ok) {
      console.warn(`[TiDB API] Server returned status ${res.status} for ${cacheKey}`);
      return {};
    }
    const json = await res.json();
    const map = {};
    if (json && json.success && Array.isArray(json.data)) {
      json.data.forEach(item => {
        if (!item.attendance_date) return;
        const dStr = String(item.attendance_date).split('T')[0];
        const [yStr, mStr, dStrPart] = dStr.split('-');
        const y = Number(yStr);
        const m = Number(mStr);
        const d = Number(dStrPart);
        const room = String(item.room_no || '').trim();
        const name = String(item.student_name || '').trim();
        
        const key = `${y}-${m}-${d}_${room}_${name}`;
        map[key] = {
          l: item.lunch_status || '',
          d: item.dinner_status || ''
        };
      });
      console.log(`[TiDB API] Loaded ${json.data.length} historical records for ${cacheKey}`);
    }
    tidbAttendanceCache[cacheKey] = map;
    return map;
  } catch (err) {
    console.warn(`[TiDB API] Network error loading history for ${cacheKey}:`, err);
    return {};
  }
}

// Attendance Record lookup helper to handle both padded and unpadded date keys
function getStudentAttRecord(attMap, year, month, day, roomNo, studentName) {
  if (!attMap) return null;
  const y = Number(year);
  const m = Number(month);
  const d = Number(day);
  const mPad = String(m).padStart(2, '0');
  const dPad = String(d).padStart(2, '0');
  const room = roomNo ? String(roomNo).trim() : '';
  const name = studentName ? String(studentName).trim() : '';

  const keys = [
    `${y}-${m}-${d}_${room}_${name}`,
    `${y}-${mPad}-${dPad}_${room}_${name}`,
    `${y}-${mPad}-${d}_${room}_${name}`,
    `${y}-${m}-${dPad}_${room}_${name}`
  ];

  for (const k of keys) {
    if (attMap[k] !== undefined && attMap[k] !== null) {
      return attMap[k];
    }
  }
  return null;
}

// --- DAILY ATTENDANCE ---

async function loadAttendanceRecords(forceRefresh = false) {
  const dateInput = document.getElementById('attFilterDate');
  const date = dateInput ? dateInput.value : '';
  let hostel = document.getElementById('attFilterHostel')?.value || 'both';
  if (currentScope === 'boys') hostel = 'boys';
  if (currentScope === 'girls') hostel = 'girls';

  const tbody = document.getElementById('attDailyTableBody');
  if (!tbody) return;

  if (!date) return showToast('Please select a date', 'error');

  const [yearStr, monthStr, dayStr] = date.split('-');
  const year = Number(yearStr);
  const month = Number(monthStr);
  const day = Number(dayStr);

  tbody.innerHTML = `<tr><td colspan="5" class="text-center py-8 text-[#64748B] italic"><i class="fa-solid fa-spinner animate-spin mr-2 text-[#EA580C]"></i>Loading daily attendance (Firebase & TiDB Cloud)...</td></tr>`;

  try {
    const hostelsToFetch = hostel === 'both' ? ['boys', 'girls'] : [hostel];
    let combinedStudents = [];
    let combinedAttMaps = {};

    for (const h of hostelsToFetch) {
      const snapStudents = await db.ref(`hostelData_${h}/students`).get();
      const val = snapStudents.val() || [];
      const stList = Array.isArray(val) ? val : Object.values(val);
      stList.forEach(s => {
        if (s && s.name) {
          combinedStudents.push({ ...s, hostelKey: h });
        }
      });

      // 1. Fetch live attendance from Firebase
      const snapAtt = await db.ref(`hostelData_${h}/attendance`).get();
      const fbAtt = snapAtt.val() || {};

      // 2. Fetch historical archived attendance from TiDB Cloud via Render API
      const tidbAtt = await fetchTiDBAttendance(year, month, h, forceRefresh);

      // 3. Merge: Firebase has highest priority for live day, TiDB supplies archive
      combinedAttMaps[h] = { ...tidbAtt, ...fbAtt };
    }

    // Sort room number numerically
    combinedStudents.sort((a, b) => {
      const rA = a.roomNo || '';
      const rB = b.roomNo || '';
      return rA.localeCompare(rB, undefined, { numeric: true });
    });

    let lunchP = 0;
    let dinnerP = 0;
    let absent = 0;

    cachedDailyList = combinedStudents.map(st => {
      const attMap = combinedAttMaps[st.hostelKey] || {};
      const rec = getStudentAttRecord(attMap, year, month, day, st.roomNo, st.name) || {};
      const l = rec.l || '-';
      const d = rec.d || '-';

      if (l === 'P') lunchP++;
      if (d === 'P') dinnerP++;
      if (l === 'A' || d === 'A') absent++;

      return {
        roomNo: st.roomNo || '-',
        name: st.name || '-',
        hostel: st.hostelKey,
        l: l,
        d: d
      };
    });

    if (document.getElementById('attDailyTotal')) {
      document.getElementById('attDailyTotal').innerText = cachedDailyList.length;
    }
    if (document.getElementById('attDailyLunchP')) {
      document.getElementById('attDailyLunchP').innerText = lunchP;
    }
    if (document.getElementById('attDailyDinnerP')) {
      document.getElementById('attDailyDinnerP').innerText = dinnerP;
    }
    if (document.getElementById('attDailyAbsent')) {
      document.getElementById('attDailyAbsent').innerText = absent;
    }

    const searchVal = document.getElementById('attDailySearch')?.value || '';
    handleDailyAttSearch(searchVal);

  } catch (e) {
    tbody.innerHTML = `<tr><td colspan="5" class="text-center py-8 text-red-600 font-semibold">Error loading attendance: ${e.message}</td></tr>`;
  }
}

function handleDailyAttSearch(val) {
  const q = (val || '').trim().toLowerCase();
  if (!q) {
    renderDailyAttendanceTable(cachedDailyList);
    return;
  }
  const filtered = cachedDailyList.filter(item => 
    (item.roomNo || '').toLowerCase().includes(q) || 
    (item.name || '').toLowerCase().includes(q)
  );
  renderDailyAttendanceTable(filtered);
}

function renderDailyAttendanceTable(list) {
  const tbody = document.getElementById('attDailyTableBody');
  if (!tbody) return;
  tbody.innerHTML = '';

  if (!list || list.length === 0) {
    tbody.innerHTML = `<tr><td colspan="5" class="text-center py-8 text-[#64748B] italic">No attendance records found.</td></tr>`;
    return;
  }

  const isBothScope = (currentScope === 'all');

  list.forEach(item => {
    // Lunch Badge
    let lunchBadge = '<span class="px-2.5 py-1 rounded-full text-[11px] font-medium bg-slate-100 text-slate-500 border border-slate-200">Unmarked (-)</span>';
    if (item.l === 'P') {
      lunchBadge = '<span class="px-2.5 py-1 rounded-full text-[11px] font-bold bg-[#FFF7ED] text-[#EA580C] border border-orange-200 inline-flex items-center gap-1"><i class="fa-solid fa-circle-check text-[10px]"></i> Present</span>';
    } else if (item.l === 'A') {
      lunchBadge = '<span class="px-2.5 py-1 rounded-full text-[11px] font-bold bg-rose-50 text-rose-700 border border-rose-200 inline-flex items-center gap-1"><i class="fa-solid fa-circle-xmark text-[10px]"></i> Absent</span>';
    }

    // Dinner Badge
    let dinnerBadge = '<span class="px-2.5 py-1 rounded-full text-[11px] font-medium bg-slate-100 text-slate-500 border border-slate-200">Unmarked (-)</span>';
    if (item.d === 'P') {
      dinnerBadge = '<span class="px-2.5 py-1 rounded-full text-[11px] font-bold bg-[#FFF7ED] text-[#EA580C] border border-orange-200 inline-flex items-center gap-1"><i class="fa-solid fa-circle-check text-[10px]"></i> Present</span>';
    } else if (item.d === 'A') {
      dinnerBadge = '<span class="px-2.5 py-1 rounded-full text-[11px] font-bold bg-rose-50 text-rose-700 border border-rose-200 inline-flex items-center gap-1"><i class="fa-solid fa-circle-xmark text-[10px]"></i> Absent</span>';
    }

    // Daily Summary Badge
    let summaryBadge = '<span class="px-2.5 py-1 rounded-lg text-xs font-medium bg-slate-100 text-slate-500 border border-slate-200">—</span>';
    if (item.l === 'P' && item.d === 'P') {
      summaryBadge = '<span class="px-2.5 py-1 rounded-lg text-xs font-bold bg-orange-100 text-orange-800 border border-orange-300 inline-flex items-center gap-1"><i class="fa-solid fa-utensils"></i> Full Day (L+D)</span>';
    } else if (item.l === 'P') {
      summaryBadge = '<span class="px-2.5 py-1 rounded-lg text-xs font-bold bg-blue-50 text-blue-700 border border-blue-200 inline-flex items-center gap-1"><i class="fa-solid fa-sun"></i> Lunch Only</span>';
    } else if (item.d === 'P') {
      summaryBadge = '<span class="px-2.5 py-1 rounded-lg text-xs font-bold bg-teal-50 text-teal-700 border border-teal-200 inline-flex items-center gap-1"><i class="fa-solid fa-moon"></i> Dinner Only</span>';
    } else if (item.l === 'A' || item.d === 'A') {
      summaryBadge = '<span class="px-2.5 py-1 rounded-lg text-xs font-bold bg-rose-50 text-rose-700 border border-rose-200 inline-flex items-center gap-1"><i class="fa-solid fa-ban"></i> Absent</span>';
    }

    const hostelTag = isBothScope ? `<span class="ml-1.5 px-1.5 py-0.5 rounded text-[10px] font-bold ${item.hostel === 'boys' ? 'bg-blue-100 text-blue-700' : 'bg-pink-100 text-pink-700'}">${item.hostel === 'boys' ? 'Boys' : 'Girls'}</span>` : '';

    const tr = document.createElement('tr');
    tr.className = "hover:bg-[#FFF7ED]/25 transition";
    tr.innerHTML = `
      <td class="py-3 px-4 font-mono font-bold text-[#0F172A] whitespace-nowrap">
        ${item.roomNo}
        ${hostelTag}
      </td>
      <td class="py-3 px-4 font-semibold text-[#0F172A]">${item.name}</td>
      <td class="py-3 px-4 text-center">${lunchBadge}</td>
      <td class="py-3 px-4 text-center">${dinnerBadge}</td>
      <td class="py-3 px-4 text-right">${summaryBadge}</td>
    `;
    tbody.appendChild(tr);
  });
}

// --- MONTHLY ATTENDANCE ---

async function loadMonthlyAttendanceRecords(forceRefresh = false) {
  const monthSelect = document.getElementById('attMonthlyMonth');
  const yearSelect = document.getElementById('attMonthlyYear');
  const month = Number(monthSelect ? monthSelect.value : (new Date().getMonth() + 1));
  const year = Number(yearSelect ? yearSelect.value : new Date().getFullYear());

  let hostel = document.getElementById('attMonthlyHostel')?.value || 'both';
  if (currentScope === 'boys') hostel = 'boys';
  if (currentScope === 'girls') hostel = 'girls';

  const tbody = document.getElementById('attMonthlyTableBody');
  if (!tbody) return;

  tbody.innerHTML = `<tr><td colspan="7" class="text-center py-8 text-[#64748B] italic"><i class="fa-solid fa-spinner animate-spin mr-2 text-[#EA580C]"></i>Aggregating monthly attendance (Firebase & TiDB Cloud) for ${month}/${year}...</td></tr>`;

  try {
    const daysInMonth = new Date(year, month, 0).getDate();
    const hostelsToFetch = hostel === 'both' ? ['boys', 'girls'] : [hostel];
    let combinedStudents = [];
    let combinedAttMaps = {};

    for (const h of hostelsToFetch) {
      const snapStudents = await db.ref(`hostelData_${h}/students`).get();
      const val = snapStudents.val() || [];
      const stList = Array.isArray(val) ? val : Object.values(val);
      stList.forEach(s => {
        if (s && s.name) {
          combinedStudents.push({ ...s, hostelKey: h });
        }
      });

      // 1. Fetch live attendance from Firebase
      const snapAtt = await db.ref(`hostelData_${h}/attendance`).get();
      const fbAtt = snapAtt.val() || {};

      // 2. Fetch historical archived attendance from TiDB Cloud via Render API
      const tidbAtt = await fetchTiDBAttendance(year, month, h, forceRefresh);

      // 3. Merge: Firebase has highest priority for live day, TiDB supplies archive
      combinedAttMaps[h] = { ...tidbAtt, ...fbAtt };
    }

    combinedStudents.sort((a, b) => {
      const rA = a.roomNo || '';
      const rB = b.roomNo || '';
      return rA.localeCompare(rB, undefined, { numeric: true });
    });

    let totalAttRateSum = 0;
    let studentsWithDataCount = 0;

    cachedMonthlyList = combinedStudents.map(st => {
      const attMap = combinedAttMaps[st.hostelKey] || {};
      let lunchPCount = 0;
      let dinnerPCount = 0;
      let presentDays = 0;
      let absentDays = 0;

      for (let d = 1; d <= daysInMonth; d++) {
        const rec = getStudentAttRecord(attMap, year, month, d, st.roomNo, st.name);
        if (rec) {
          const isLP = rec.l === 'P';
          const isDP = rec.d === 'P';
          const isLA = rec.l === 'A';
          const isDA = rec.d === 'A';

          if (isLP) lunchPCount++;
          if (isDP) dinnerPCount++;

          if (isLP || isDP) {
            presentDays++;
          } else if (isLA || isDA) {
            absentDays++;
          }
        }
      }

      const totalMarkedDays = presentDays + absentDays;
      const rate = totalMarkedDays > 0 ? Math.round((presentDays / totalMarkedDays) * 100) : 0;

      if (totalMarkedDays > 0) {
        totalAttRateSum += rate;
        studentsWithDataCount++;
      }

      return {
        roomNo: st.roomNo || '-',
        name: st.name || '-',
        hostel: st.hostelKey,
        lunchPCount,
        dinnerPCount,
        presentDays,
        absentDays,
        totalMarkedDays,
        attendanceRate: rate
      };
    });

    const avgRate = studentsWithDataCount > 0 ? Math.round(totalAttRateSum / studentsWithDataCount) : 0;

    if (document.getElementById('attMonthTotalStudents')) {
      document.getElementById('attMonthTotalStudents').innerText = cachedMonthlyList.length;
    }
    if (document.getElementById('attMonthTotalDays')) {
      document.getElementById('attMonthTotalDays').innerText = daysInMonth;
    }
    if (document.getElementById('attMonthAvgRate')) {
      document.getElementById('attMonthAvgRate').innerText = `${avgRate}%`;
    }

    const searchVal = document.getElementById('attMonthlySearch')?.value || '';
    handleMonthlyAttSearch(searchVal);

  } catch (e) {
    tbody.innerHTML = `<tr><td colspan="7" class="text-center py-8 text-red-600 font-semibold">Error aggregating monthly attendance: ${e.message}</td></tr>`;
  }
}

function handleMonthlyAttSearch(val) {
  const q = (val || '').trim().toLowerCase();
  if (!q) {
    renderMonthlyAttendanceTable(cachedMonthlyList);
    return;
  }
  const filtered = cachedMonthlyList.filter(item => 
    (item.roomNo || '').toLowerCase().includes(q) || 
    (item.name || '').toLowerCase().includes(q)
  );
  renderMonthlyAttendanceTable(filtered);
}

function renderMonthlyAttendanceTable(list) {
  const tbody = document.getElementById('attMonthlyTableBody');
  if (!tbody) return;
  tbody.innerHTML = '';

  if (!list || list.length === 0) {
    tbody.innerHTML = `<tr><td colspan="7" class="text-center py-8 text-[#64748B] italic">No student attendance records for this month.</td></tr>`;
    return;
  }

  const isBothScope = (currentScope === 'all');

  list.forEach(st => {
    const hostelTag = isBothScope ? `<span class="ml-1.5 px-1.5 py-0.5 rounded text-[10px] font-bold ${st.hostel === 'boys' ? 'bg-blue-100 text-blue-700' : 'bg-pink-100 text-pink-700'}">${st.hostel === 'boys' ? 'Boys' : 'Girls'}</span>` : '';

    let rateDisplay = '';
    if (st.totalMarkedDays === 0) {
      rateDisplay = '<span class="text-xs text-slate-400 font-medium italic">No data</span>';
    } else {
      let barColor = 'bg-[#EA580C]';
      let textColor = 'text-[#EA580C]';
      if (st.attendanceRate < 50) {
        barColor = 'bg-rose-600';
        textColor = 'text-rose-600';
      } else if (st.attendanceRate < 75) {
        barColor = 'bg-amber-600';
        textColor = 'text-amber-600';
      }

      rateDisplay = `
        <div class="flex items-center justify-end gap-2">
          <div class="w-16 bg-slate-200 rounded-full h-2 overflow-hidden">
            <div class="${barColor} h-2 rounded-full" style="width: ${st.attendanceRate}%"></div>
          </div>
          <span class="text-xs font-bold ${textColor} min-w-[38px] text-right">${st.attendanceRate}%</span>
        </div>
      `;
    }

    const tr = document.createElement('tr');
    tr.className = "hover:bg-[#FFF7ED]/25 transition";
    tr.innerHTML = `
      <td class="py-3 px-4 font-mono font-bold text-[#0F172A] whitespace-nowrap">
        ${st.roomNo}
        ${hostelTag}
      </td>
      <td class="py-3 px-4 font-semibold text-[#0F172A]">${st.name}</td>
      <td class="py-3 px-4 text-center">
        <span class="px-2 py-0.5 rounded-full text-xs font-bold bg-[#FFF7ED] text-[#EA580C] border border-orange-200">${st.lunchPCount}</span>
      </td>
      <td class="py-3 px-4 text-center">
        <span class="px-2 py-0.5 rounded-full text-xs font-bold bg-teal-50 text-teal-700 border border-teal-200">${st.dinnerPCount}</span>
      </td>
      <td class="py-3 px-4 text-center">
        <span class="px-2 py-0.5 rounded-full text-xs font-bold bg-orange-100 text-orange-800 border border-orange-300">${st.presentDays} days</span>
      </td>
      <td class="py-3 px-4 text-center">
        <span class="px-2 py-0.5 rounded-full text-xs font-bold ${st.absentDays > 0 ? 'bg-red-50 text-red-700 border border-red-200' : 'bg-slate-100 text-slate-500'}">${st.absentDays} days</span>
      </td>
      <td class="py-3 px-4 text-right">
        ${rateDisplay}
      </td>
    `;
    tbody.appendChild(tr);
  });
}

// ==================== 5. AUDIT LOGGING ====================

async function logAudit(actionType, details) {
  const entry = {
    timestamp: new Date().toISOString(),
    actor: currentSessionUser || 'root',
    action: actionType,
    details: details
  };
  try {
    await db.ref('super_admin_config/audit_logs').push(entry);
  } catch (e) {
    console.error("Audit log error:", e);
  }
}

function listenToAuditLogs() {
  db.ref('super_admin_config/audit_logs').limitToLast(50).on('value', snap => {
    const val = snap.val() || {};
    const list = Object.values(val);
    list.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
    renderAuditLogs(list);
  });
}

function renderAuditLogs(logs) {
  const tbody = document.getElementById('auditTableBody');
  const overviewList = document.getElementById('overviewAuditList');

  if (tbody) tbody.innerHTML = '';
  if (overviewList) overviewList.innerHTML = '';

  if (logs.length === 0) {
    if (tbody) tbody.innerHTML = `<tr><td colspan="4" class="text-center py-6 text-[#64748B] italic">No audit records found.</td></tr>`;
    if (overviewList) overviewList.innerHTML = `<div class="text-xs text-[#64748B] italic p-3 text-center">No recent activity.</div>`;
    return;
  }

  logs.forEach(l => {
    const dateFormatted = new Date(l.timestamp).toLocaleString();

    // Table row in Audit tab
    if (tbody) {
      const tr = document.createElement('tr');
      tr.className = "hover:bg-[#FFF7ED]/25 transition";
      tr.innerHTML = `
        <td class="py-3 px-4 font-mono text-[11px] text-[#64748B]">${dateFormatted}</td>
        <td class="py-3 px-4 font-bold text-[#0F172A]">${l.actor}</td>
        <td class="py-3 px-4">
          <span class="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-[#EFF3FC] text-[#EA580C] border border-slate-200">${l.action}</span>
        </td>
        <td class="py-3 px-4 text-[#0F172A]">${l.details}</td>
      `;
      tbody.appendChild(tr);
    }
  });

  // Overview top 5 recent activities
  if (overviewList) {
    logs.slice(0, 5).forEach(l => {
      const div = document.createElement('div');
      div.className = "p-2.5 bg-[#EFF3FC] border border-slate-200/80 rounded-xl text-xs flex items-center justify-between";
      div.innerHTML = `
        <div>
          <div class="font-semibold text-[#0F172A]">${l.details}</div>
          <div class="text-[10px] text-[#64748B] mt-0.5 font-medium">${new Date(l.timestamp).toLocaleTimeString()} • ${l.actor}</div>
        </div>
        <span class="px-2 py-0.5 text-[9px] font-bold uppercase rounded-full bg-white text-[#EA580C] border border-slate-200 shadow-xs">${l.action}</span>
      `;
      overviewList.appendChild(div);
    });
  }
}

// ==================== TOAST NOTIFICATION HELPER ====================

function showToast(message, type = 'info') {
  const container = document.getElementById('toastContainer');
  if (!container) return;
  const toast = document.createElement('div');
  const colors = {
    success: 'bg-white border-orange-300 text-[#EA580C] shadow-orange-900/10',
    error: 'bg-white border-red-300 text-red-700 shadow-red-900/10',
    info: 'bg-white border-slate-300 text-[#0F172A] shadow-slate-900/10'
  };
  const icon = {
    success: 'fa-circle-check text-[#EA580C]',
    error: 'fa-circle-xmark text-red-600',
    info: 'fa-circle-info text-blue-600'
  };

  toast.className = `toast px-4 py-3 rounded-2xl border shadow-xl text-xs font-semibold flex items-center gap-2.5 pointer-events-auto ${colors[type] || colors.info}`;
  toast.innerHTML = `<i class="fa-solid ${icon[type] || icon.info} text-sm"></i> <span>${message}</span>`;
  container.appendChild(toast);

  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transition = 'opacity 0.3s';
    setTimeout(() => toast.remove(), 300);
  }, 3500);
}

// Start application
window.addEventListener('DOMContentLoaded', () => {
  checkAuthStatus();
});
