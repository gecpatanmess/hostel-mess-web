/**
 * Hostel Mess Management - Super Admin Security Console
 * 2FA (Google Authenticator TOTP RFC 6238) + Linux-style RBAC Engine
 * Hardened Security: One-Time Permanent Setup Lock + Full Staff/Committee Member CRUD
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

// ==================== CRYPTOGRAPHIC & TOTP ENGINE (RFC 6238) ====================

// SHA-256 Hash helper
async function sha256(str) {
  const buf = new TextEncoder().encode(str);
  const hashBuf = await window.crypto.subtle.digest('SHA-256', buf);
  const hashArray = Array.from(new Uint8Array(hashBuf));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

// Base32 Decode for Google Authenticator TOTP
function base32ToBytes(base32) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  let clean = base32.toUpperCase().replace(/=+$/, '').replace(/[^A-Z2-7]/g, '');
  let bits = '';
  for (let i = 0; i < clean.length; i++) {
    let val = alphabet.indexOf(clean[i]);
    if (val === -1) continue;
    bits += val.toString(2).padStart(5, '0');
  }
  let bytes = [];
  for (let i = 0; i + 8 <= bits.length; i += 8) {
    bytes.push(parseInt(bits.substr(i, 8), 2));
  }
  return new Uint8Array(bytes);
}

// Generate random Base32 secret (16 chars = 80 bits standard)
function generateRandomBase32Secret(length = 16) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  let secret = '';
  const randomBytes = new Uint8Array(length);
  window.crypto.getRandomValues(randomBytes);
  for (let i = 0; i < length; i++) {
    secret += alphabet[randomBytes[i] % alphabet.length];
  }
  return secret;
}

// HOTP calculation (RFC 4226)
async function generateHOTP(secretBase32, counter) {
  const keyBytes = base32ToBytes(secretBase32);
  const cryptoKey = await window.crypto.subtle.importKey(
    'raw',
    keyBytes,
    { name: 'HMAC', hash: 'SHA-1' },
    false,
    ['sign']
  );
  const counterBuffer = new ArrayBuffer(8);
  const counterView = new DataView(counterBuffer);
  counterView.setUint32(4, counter, false); // 64-bit integer big-endian
  const signature = await window.crypto.subtle.sign('HMAC', cryptoKey, counterBuffer);
  const hmac = new Uint8Array(signature);
  const offset = hmac[hmac.length - 1] & 0x0f;
  const binary =
    ((hmac[offset] & 0x7f) << 24) |
    ((hmac[offset + 1] & 0xff) << 16) |
    ((hmac[offset + 2] & 0xff) << 8) |
    (hmac[offset + 3] & 0xff);
  const otp = (binary % 1000000).toString().padStart(6, '0');
  return otp;
}

// TOTP verify with 1 time-step tolerance (prevents small device clock drifts)
async function verifyTOTP(secretBase32, inputCode) {
  const cleanCode = inputCode.trim();
  const epoch = Math.floor(Date.now() / 1000);
  const counter = Math.floor(epoch / 30);
  for (let offset = -1; offset <= 1; offset++) {
    const expected = await generateHOTP(secretBase32, counter + offset);
    if (expected === cleanCode) return true;
  }
  return false;
}

// ==================== AUTHENTICATION & ONE-TIME SETUP LOCK ====================

let pendingSetupSecret = null;

async function checkAuthStatus() {
  try {
    const snap = await db.ref('super_admin_config/auth').get();
    const authData = snap.val();

    // Check lockout
    if (authData && authData.locked_until && authData.locked_until > Date.now()) {
      const remainingMin = Math.ceil((authData.locked_until - Date.now()) / 60000);
      showLockout(`Too many failed attempts. Console locked for ${remainingMin} more minutes.`);
      document.getElementById('btnLogin').disabled = true;
      return;
    } else {
      hideLockout();
      document.getElementById('btnLogin').disabled = false;
    }

    if (!authData || !authData.setup_completed) {
      // First time setup required
      initSetupMode();
    } else {
      // Setup is already completed: LOCK DOWN PERMANENTLY
      lockDownSetupPermanently();
      showLoginView();
    }
  } catch (e) {
    console.error("Auth check error:", e);
    showLoginView();
  }
}

// Permanently eliminates the "First time setup" button and disables setup mode
function lockDownSetupPermanently() {
  isSetupPermanentlyLocked = true;
  const switchContainer = document.getElementById('setupSwitchContainer');
  if (switchContainer) {
    switchContainer.remove(); // Obliterated completely from DOM
  }
  const setupView = document.getElementById('setupView');
  if (setupView) {
    setupView.remove(); // Remove setup form entirely from DOM for security
  }
}

async function initSetupMode() {
  if (isSetupPermanentlyLocked) {
    showToast('Setup is already permanently completed and locked.', 'error');
    showLoginView();
    return;
  }

  // Direct check to ensure no overwrite
  const snap = await db.ref('super_admin_config/auth').get();
  const authData = snap.val();
  if (authData && authData.setup_completed) {
    lockDownSetupPermanently();
    showLoginView();
    return;
  }

  const setupEl = document.getElementById('setupView');
  const loginEl = document.getElementById('loginView');
  if (!setupEl || !loginEl) return;

  setupEl.classList.remove('hidden');
  loginEl.classList.add('hidden');

  pendingSetupSecret = generateRandomBase32Secret(16);
  document.getElementById('setupManualSecret').innerText = pendingSetupSecret;

  const username = document.getElementById('setupUsername')?.value.trim() || 'superadmin';
  const otpauthUrl = `otpauth://totp/HostelMess:${encodeURIComponent(username)}?secret=${pendingSetupSecret}&issuer=HostelMessSystem`;

  // Generate QR code using QR server API
  const qrImg = document.getElementById('qrImage');
  if (qrImg) {
    qrImg.src = `https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=${encodeURIComponent(otpauthUrl)}`;
  }
}

function showLoginView() {
  const setupEl = document.getElementById('setupView');
  if (setupEl) setupEl.classList.add('hidden');
  const loginEl = document.getElementById('loginView');
  if (loginEl) loginEl.classList.remove('hidden');
}

function showLockout(msg) {
  const banner = document.getElementById('lockoutBanner');
  banner.classList.remove('hidden');
  document.getElementById('lockoutMsg').innerText = msg;
}

function hideLockout() {
  document.getElementById('lockoutBanner').classList.add('hidden');
}

// Setup completion handler (Strictly guarded against re-initialization)
document.getElementById('btnCompleteSetup')?.addEventListener('click', async () => {
  if (isSetupPermanentlyLocked) {
    return showToast('Forbidden: Super Admin setup is already permanently locked!', 'error');
  }

  // Pre-check Firebase directly
  const checkSnap = await db.ref('super_admin_config/auth').get();
  const existingAuth = checkSnap.val();
  if (existingAuth && existingAuth.setup_completed) {
    lockDownSetupPermanently();
    showLoginView();
    return showToast('Forbidden: Master account is already initialized and locked!', 'error');
  }

  const username = document.getElementById('setupUsername').value.trim();
  const passphrase = document.getElementById('setupPassphrase').value.trim();
  const verifyCode = document.getElementById('setupVerifyCode').value.trim();

  if (!username) return showToast('Please enter a master username', 'error');
  if (passphrase.length < 8) return showToast('Master passphrase must be at least 8 characters', 'error');
  if (!verifyCode || verifyCode.length !== 6) return showToast('Please enter the 6-digit code from Google Authenticator', 'error');

  const isValid = await verifyTOTP(pendingSetupSecret, verifyCode);
  if (!isValid) {
    return showToast('Invalid code! Check Google Authenticator and try again.', 'error');
  }

  const passHash = await sha256(passphrase);

  await db.ref('super_admin_config/auth').set({
    username: username,
    passphrase_hash: passHash,
    totp_secret: pendingSetupSecret,
    setup_completed: true,
    failed_attempts: 0,
    locked_until: 0,
    created_at: new Date().toISOString()
  });

  await logAudit('SUPER_ADMIN_SETUP', `Super admin account initialized for ${username}`);

  lockDownSetupPermanently();
  showToast('Setup complete & permanently locked! Welcome.', 'success');
  startUserSession(username);
});

// Login submit handler
document.getElementById('btnLogin')?.addEventListener('click', async () => {
  const username = document.getElementById('loginUsername').value.trim();
  const password = document.getElementById('loginPassword').value.trim();
  const totpCode = document.getElementById('loginTotp').value.trim();

  if (!username || !password || !totpCode) {
    return showToast('Please enter username, master secret key, and 6-digit code', 'error');
  }

  const snap = await db.ref('super_admin_config/auth').get();
  const authData = snap.val();

  if (!authData || !authData.setup_completed) {
    initSetupMode();
    return;
  }

  // Check lockout
  if (authData.locked_until && authData.locked_until > Date.now()) {
    const remainingMin = Math.ceil((authData.locked_until - Date.now()) / 60000);
    return showToast(`Account locked. Please wait ${remainingMin} minutes.`, 'error');
  }

  const inputHash = await sha256(password);
  const passValid = (inputHash === authData.passphrase_hash) && (username === authData.username);
  const totpValid = await verifyTOTP(authData.totp_secret, totpCode);

  if (!passValid || !totpValid) {
    let failed = (authData.failed_attempts || 0) + 1;
    let updates = { failed_attempts: failed };

    if (failed >= 3) {
      updates.locked_until = Date.now() + (30 * 60 * 1000); // 30 mins lockout
      updates.failed_attempts = 0;
      await db.ref('super_admin_config/auth').update(updates);
      await logAudit('SECURITY_LOCKOUT', `Account locked out for 30 minutes after 3 failed attempts`);
      showLockout('Account locked for 30 minutes due to 3 failed attempts.');
      return;
    }

    await db.ref('super_admin_config/auth').update(updates);
    const left = 3 - failed;
    showToast(`Invalid credentials or TOTP! (${left} attempt${left > 1 ? 's' : ''} remaining before lockout)`, 'error');
    return;
  }

  // Reset failed attempts on success
  await db.ref('super_admin_config/auth').update({
    failed_attempts: 0,
    locked_until: 0,
    last_login: new Date().toISOString()
  });

  await logAudit('SUPER_ADMIN_LOGIN', `Super admin logged in successfully (${username})`);
  showToast('Authentication verified! Session started.', 'success');
  startUserSession(username);
});

document.getElementById('btnSwitchToSetup')?.addEventListener('click', () => {
  if (isSetupPermanentlyLocked) {
    showToast('Setup is already permanently completed and locked.', 'error');
    return;
  }
  initSetupMode();
});

// ==================== SESSION & TIMEOUT ====================

function startUserSession(username) {
  currentSessionUser = username;
  document.getElementById('currentSuperAdminUser').innerText = username;
  document.getElementById('authScreen').classList.add('hidden');
  document.getElementById('mainDashboard').classList.remove('hidden');

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
  currentSessionUser = null;
  document.getElementById('mainDashboard').classList.add('hidden');
  document.getElementById('authScreen').classList.remove('hidden');
  document.getElementById('loginPassword').value = '';
  document.getElementById('loginTotp').value = '';
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
    el.className = "px-3 py-1 rounded-lg font-medium transition text-emerald-100 hover:text-white";
  });
  const activeEl = document.getElementById(scope === 'all' ? 'scopeAll' : (scope === 'boys' ? 'scopeBoys' : 'scopeGirls'));
  activeEl.className = "px-3 py-1 rounded-lg font-bold transition bg-white text-[#135B26] shadow-sm";

  renderAdminsTable();
  updateOverviewStats();
  showToast(`Active Scope: ${scope.toUpperCase()} HOSTELS`, 'info');
}

document.querySelectorAll('.nav-btn').forEach(btn => {
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

  if (tabId === 'tabAttendance') {
    const today = new Date().toISOString().split('T')[0];
    document.getElementById('attFilterDate').value = today;
    loadAttendanceRecords();
  }
}

// ==================== DATA LISTENERS & INITIALIZATION ====================

function initAppListeners() {
  listenToRoles();
  listenToAdmins();
  listenToStudents();
  listenToAuditLogs();
  listenToNotices();
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
      can_attendance: true,
      can_attendance_edit: true,
      can_students_manage: true,
      can_complaints: true,
      can_notices: true,
      can_manage_admins: true
    }
  },
  admin: {
    name: "Admin",
    permissions: {
      can_manage_polls: true,
      can_manage_meals: true,
      can_attendance: true,
      can_attendance_edit: true,
      can_students_manage: true,
      can_complaints: true,
      can_notices: true,
      can_manage_admins: true
    }
  },
  mess_committee: {
    name: "Mess Committee",
    permissions: {
      can_manage_polls: true,
      can_manage_meals: false,
      can_attendance: false,
      can_attendance_edit: false,
      can_students_manage: false,
      can_complaints: true,
      can_notices: true,
      can_manage_admins: false
    }
  },
  professor: {
    name: "Professor / Warden",
    permissions: {
      can_manage_polls: false,
      can_manage_meals: false,
      can_attendance: true,
      can_attendance_edit: false,
      can_students_manage: false,
      can_complaints: true,
      can_notices: true,
      can_manage_admins: false
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
    }
    renderRolesGrid();
    updateRoleDropdowns();
    updateOverviewStats();
    renderAdminsTable();
  });
}

const permissionLabels = {
  can_manage_polls: { label: "Mess Polls (Create/Vote/View Results)", icon: "fa-poll" },
  can_manage_meals: { label: "Meal Management (Meal Switches & Menus)", icon: "fa-utensils" },
  can_attendance: { label: "View Attendance (View Monthly Sheets)", icon: "fa-calendar-check" },
  can_attendance_edit: { label: "Modify Attendance (Mark/Edit Attendance)", icon: "fa-pen-to-square" },
  can_students_manage: { label: "Student Management (Add/Delete/Rooms)", icon: "fa-user-graduate" },
  can_complaints: { label: "Complaints Access (View Complaints)", icon: "fa-triangle-exclamation" },
  can_notices: { label: "Notice Board (Broadcast & Delete Notices)", icon: "fa-bullhorn" },
  can_manage_admins: { label: "Admin Management (Add/Manage Staff)", icon: "fa-user-shield" }
};

const defaultStandardPerms = {
  can_manage_polls: { label: "Mess Polls (Create/Vote/View Results)", icon: "fa-poll", checked: true },
  can_manage_meals: { label: "Meal Management (Meal Switches & Menus)", icon: "fa-utensils", checked: true },
  can_attendance: { label: "View Attendance (View Monthly Sheets)", icon: "fa-calendar-check", checked: false },
  can_attendance_edit: { label: "Modify Attendance (Mark/Edit Attendance)", icon: "fa-pen-to-square", checked: false },
  can_students_manage: { label: "Student Management (Add/Delete/Rooms)", icon: "fa-user-graduate", checked: false },
  can_complaints: { label: "Complaints Access (View Complaints)", icon: "fa-triangle-exclamation", checked: true },
  can_notices: { label: "Notice Board (Broadcast & Delete Notices)", icon: "fa-bullhorn", checked: true },
  can_manage_admins: { label: "Admin Management (Add/Manage Staff)", icon: "fa-user-shield", checked: false }
};

let modalPermsState = JSON.parse(JSON.stringify(defaultStandardPerms));

function renderCreateRolePermsList() {
  const container = document.getElementById('createRolePermList');
  if (!container) return;
  container.innerHTML = '';
  const keys = Object.keys(modalPermsState);
  if (keys.length === 0) {
    container.innerHTML = `
      <div class="p-4 text-center text-xs text-slate-400 italic bg-slate-50 rounded-xl border border-dashed border-slate-200">
        No permissions in list. Click <strong>+ Add</strong> above to add initial permissions.
      </div>`;
    return;
  }
  keys.forEach(key => {
    const item = modalPermsState[key];
    const row = document.createElement('div');
    row.className = "flex items-center justify-between p-2.5 bg-[#EFF3FC] rounded-xl text-xs hover:bg-slate-100 transition border border-transparent hover:border-slate-200";
    row.innerHTML = `
      <label class="flex items-center gap-2 cursor-pointer flex-1 mr-2 select-none">
        <input type="checkbox" id="perm_cb_${key}" ${item.checked ? 'checked' : ''} onchange="modalPermsState['${key}'].checked = this.checked" class="w-4 h-4 accent-[#135B26] rounded">
        <i class="fa-solid ${item.icon || 'fa-shield-halved'} text-[#135B26] w-4 text-center"></i>
        <span class="font-medium text-[#0F172A]">${item.label}</span>
      </label>
      <button type="button" onclick="deleteSinglePermFromModal('${key}')" class="text-slate-400 hover:text-red-600 p-1 rounded transition" title="Delete this permission">
        <i class="fa-solid fa-trash-can text-xs"></i>
      </button>
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

function deleteAllRolePerms() {
  if (Object.keys(modalPermsState).length === 0) return;
  if (!confirm("Are you sure you want to delete all initial permissions from this list?")) return;
  modalPermsState = {};
  renderCreateRolePermsList();
  showToast("All initial permissions removed from list.", "info");
}

function deleteSinglePermFromModal(key) {
  delete modalPermsState[key];
  renderCreateRolePermsList();
}

function toggleInlineAddPermBox(show) {
  const box = document.getElementById('inlineAddPermBox');
  if (!box) return;
  if (show) {
    box.classList.remove('hidden');
    document.getElementById('customPermKeyInput').value = '';
    document.getElementById('customPermLabelInput').value = '';
    document.getElementById('customPermKeyInput').focus();
  } else {
    box.classList.add('hidden');
  }
}

function confirmAddCustomPerm() {
  const rawKey = document.getElementById('customPermKeyInput').value.trim();
  const label = document.getElementById('customPermLabelInput').value.trim();
  if (!rawKey || !label) {
    showToast("Please enter both Key and Label", "error");
    return;
  }
  const key = rawKey.toLowerCase().replace(/[^a-z0-9_]/g, '_');
  modalPermsState[key] = {
    label: label,
    icon: "fa-shield-halved",
    checked: true
  };
  if (!permissionLabels[key]) {
    permissionLabels[key] = { label: label, icon: "fa-shield-halved" };
  }
  toggleInlineAddPermBox(false);
  renderCreateRolePermsList();
  showToast(`Added '${label}'!`, "success");
}

function renderRolesGrid() {
  const container = document.getElementById('rolesListContainer');
  if (!container) return;
  container.innerHTML = '';

  Object.entries(cachedRoles).forEach(([roleId, roleData]) => {
    const isRoot = roleId === 'super_admin';
    const card = document.createElement('div');
    card.className = "app-card p-5 space-y-4 hover:shadow-md transition";

    const rolePerms = roleData.permissions || {};
    Object.keys(rolePerms).forEach(k => {
      if (!permissionLabels[k]) {
        permissionLabels[k] = { label: k.replace(/_/g, ' ').toUpperCase(), icon: "fa-shield-halved" };
      }
    });

    const allKeys = Array.from(new Set([...Object.keys(rolePerms), ...Object.keys(permissionLabels)]));
    let activeCount = 0;
    let togglesHtml = '';

    allKeys.forEach(permKey => {
      const permMeta = permissionLabels[permKey] || { label: permKey, icon: "fa-shield-halved" };
      const isChecked = rolePerms[permKey] === true;
      if (isChecked) activeCount++;
      togglesHtml += `
        <div class="flex items-center justify-between p-2.5 bg-[#EFF3FC] rounded-xl border border-slate-200/70 hover:border-slate-300 transition">
          <div class="flex items-center gap-2.5 flex-1 pr-2">
            <i class="fa-solid ${permMeta.icon || 'fa-shield-halved'} text-[#135B26] text-xs w-4 text-center"></i>
            <span class="text-xs font-semibold text-[#0F172A]">${permMeta.label}</span>
          </div>
          <div class="flex items-center gap-2 shrink-0">
            <label class="switch">
              <input type="checkbox" ${isChecked ? 'checked' : ''} ${isRoot ? 'disabled' : ''} onchange="togglePermission('${roleId}', '${permKey}', this.checked)">
              <span class="slider"></span>
            </label>
            ${!isRoot ? `
              <button onclick="deletePermissionFromRole('${roleId}', '${permKey}')" class="text-slate-400 hover:text-red-600 p-1 transition" title="Delete permission from role">
                <i class="fa-solid fa-trash-can text-[11px]"></i>
              </button>
            ` : ''}
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
            <span class="px-2 py-0.5 text-[10px] uppercase font-mono font-bold bg-[#E8F5E9] text-[#135B26] border border-emerald-200 rounded-md">${roleId}</span>
            <span class="px-2 py-0.5 text-[10px] font-bold rounded-full ${activeCount > 0 ? 'bg-emerald-100 text-[#135B26]' : 'bg-slate-100 text-slate-500'}">
              ${activeCount} / ${totalPerms} Active
            </span>
          </div>
          <p class="text-[11px] text-[#64748B] mt-0.5">Toggle permissions update live in the mobile app</p>
        </div>
        ${!isRoot && roleId !== 'admin' ? `
          <button onclick="deleteRole('${roleId}')" class="text-xs text-red-600 hover:text-red-700 bg-red-50 hover:bg-red-100 px-2.5 py-1.5 rounded-xl border border-red-200 transition font-bold flex items-center gap-1 shrink-0">
            <i class="fa-solid fa-trash-can"></i>
            <span>Delete Role</span>
          </button>
        ` : ''}
      </div>
      <div class="space-y-2">
        ${togglesHtml}
      </div>
      ${!isRoot ? `
        <div class="pt-2 border-t border-slate-100 flex justify-end">
          <button onclick="addPermissionToRole('${roleId}')" class="text-xs text-[#135B26] hover:text-[#0E441C] font-bold flex items-center gap-1.5 bg-emerald-50 hover:bg-emerald-100 border border-emerald-200 px-3 py-1.5 rounded-xl transition">
            <i class="fa-solid fa-plus text-[11px]"></i>
            <span>Add Permission</span>
          </button>
        </div>
      ` : ''}
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

async function deletePermissionFromRole(roleId, permKey) {
  if (roleId === 'super_admin') return showToast("Cannot delete permissions from Super Admin", "error");
  if (!confirm(`Are you sure you want to permanently delete permission '${permKey}' from role '${roleId}'?`)) return;
  try {
    await db.ref(`roles/${roleId}/permissions/${permKey}`).remove();
    await logAudit('PERMISSION_DELETED', `Deleted permission ${permKey} from role ${roleId}`);
    showToast(`Permission '${permKey}' removed from role '${roleId}'`, 'info');
  } catch (e) {
    showToast(`Error: ${e.message}`, 'error');
  }
}

async function addPermissionToRole(roleId) {
  const permKeyRaw = prompt("Enter Permission Identifier Key (e.g. food_check, gate_pass):");
  if (!permKeyRaw) return;
  const permKey = permKeyRaw.trim().toLowerCase().replace(/[^a-z0-9_]/g, '_');
  const permLabel = prompt("Enter Permission Display Label (e.g. Food Quality Testing):") || permKey;
  
  if (!permissionLabels[permKey]) {
    permissionLabels[permKey] = { label: permLabel, icon: "fa-shield-halved" };
  }
  try {
    await db.ref(`roles/${roleId}/permissions/${permKey}`).set(true);
    await logAudit('PERMISSION_ADDED', `Added permission ${permKey} to role ${roleId}`);
    showToast(`Added '${permLabel}' to role '${roleId}' (set to ON)!`, 'success');
  } catch (e) {
    showToast(`Error: ${e.message}`, 'error');
  }
}

function openCreateRoleModal() {
  document.getElementById('newRoleId').value = '';
  document.getElementById('newRoleName').value = '';
  modalPermsState = JSON.parse(JSON.stringify(defaultStandardPerms));
  toggleInlineAddPermBox(false);
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
    if (el) el.className = "px-3 py-1.5 rounded-xl font-bold bg-[#135B26] text-white shadow-xs transition";
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
    const scopeColor = admin.hostelScope === 'boys' ? 'text-blue-700 bg-blue-50 border-blue-200' : (admin.hostelScope === 'girls' ? 'text-pink-700 bg-pink-50 border-pink-200' : 'text-[#135B26] bg-[#E8F5E9] border-emerald-200');

    let roleBadgeColor = 'bg-slate-100 text-[#0F172A] border-slate-200';
    if (admin.role === 'admin') roleBadgeColor = 'bg-[#E8F5E9] text-[#135B26] border-emerald-300';
    if (admin.role === 'mess_committee') roleBadgeColor = 'bg-teal-50 text-teal-700 border-teal-200';
    if (admin.role === 'professor') roleBadgeColor = 'bg-purple-50 text-purple-700 border-purple-200';

    const tr = document.createElement('tr');
    tr.className = "hover:bg-[#E8F5E9]/25 transition";
    tr.innerHTML = `
      <td class="py-3 px-4 font-bold text-[#0F172A] flex items-center gap-3">
        <div class="w-8 h-8 rounded-full bg-[#E8F5E9] text-[#135B26] flex items-center justify-center font-bold text-xs shadow-sm">
          <i class="fa-solid fa-user"></i>
        </div>
        <div>
          <div>${admin.name || 'Unnamed User'}</div>
          <div class="text-[11px] text-[#64748B] font-normal">${admin.email || 'No email registered'}</div>
        </div>
      </td>
      <td class="py-3 px-4 font-mono font-bold text-[#135B26]">${admin.phone}</td>
      <td class="py-3 px-4">
        <span class="px-2.5 py-0.5 rounded-full text-[10px] font-bold border ${roleBadgeColor}">${roleTitle}</span>
      </td>
      <td class="py-3 px-4">
        <span class="px-2.5 py-0.5 rounded-full text-[10px] font-bold border ${scopeColor}">${scopeLabel}</span>
      </td>
      <td class="py-3 px-4 text-[#64748B] capitalize">${admin.location} Hostel DB</td>
      <td class="py-3 px-4 text-right space-x-1.5 whitespace-nowrap">
        <button onclick="openEditAdminModal('${admin.phone}', '${encodeURIComponent(admin.name || '')}', '${admin.role}', '${admin.hostelScope || 'both'}', '${admin.location}')" class="px-2.5 py-1 text-xs font-bold text-slate-700 bg-slate-100 hover:bg-slate-200 border border-slate-200 rounded-lg transition" title="Edit Role & Scope">
          <i class="fa-solid fa-pen-to-square mr-1 text-[#135B26]"></i>Edit
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
  document.getElementById('newAdminPin').value = '';
  updateRoleDropdowns();
  document.getElementById('modalAddAdmin').classList.remove('hidden');
}

function closeAddAdminModal() {
  document.getElementById('modalAddAdmin').classList.add('hidden');
}

async function submitNewAdmin() {
  const phone = document.getElementById('newAdminPhone').value.trim();
  const name = document.getElementById('newAdminName').value.trim();
  const email = document.getElementById('newAdminEmail').value.trim();
  const pin = document.getElementById('newAdminPin').value.trim();
  const role = document.getElementById('newAdminRole').value;
  const scope = document.getElementById('newAdminScope').value;

  if (phone.length !== 10 || !/^\d+$/.test(phone)) return showToast('Please enter a valid 10-digit mobile number', 'error');
  if (!name) return showToast('Please enter user name', 'error');
  if (pin.length < 8) return showToast('PIN / Password must be at least 8 characters', 'error');

  const hashedPin = await sha256(pin);

  const adminObj = {
    phone: phone,
    name: name,
    email: email,
    pin: hashedPin,
    role: role,
    hostelScope: scope,
    photoUrl: ""
  };

  const targets = scope === 'both' ? ['boys', 'girls'] : [scope];

  for (const h of targets) {
    const snap = await db.ref(`hostelData_${h}/admins`).get();
    let currentList = [];
    if (snap.exists() && snap.val()) {
      currentList = Array.isArray(snap.val()) ? snap.val() : Object.values(snap.val());
    }
    // Remove if already exists with same phone
    currentList = currentList.filter(a => a && a.phone !== phone);
    currentList.push(adminObj);
    await db.ref(`hostelData_${h}/admins`).set(currentList);
  }

  await logAudit('STAFF_CREATED', `Added new ${role} ${name} (${phone}) with scope '${scope}'`);
  closeAddAdminModal();
  showToast(`User ${name} added successfully as ${role}!`, 'success');
}

// Edit Admin / Committee Member Modal
function openEditAdminModal(phone, encodedName, role, scope, location) {
  const name = decodeURIComponent(encodedName);
  document.getElementById('editAdminPhone').value = phone;
  document.getElementById('editAdminOldLocation').value = location;
  document.getElementById('editAdminDisplayName').innerText = name || phone;
  document.getElementById('editAdminDisplayPhone').innerText = phone;

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
  document.getElementById('statBoysCount').innerText = cachedStudents.boys.length;
  document.getElementById('statGirlsCount').innerText = cachedStudents.girls.length;

  const totalAdmins = (cachedAdmins.boys.length + cachedAdmins.girls.length);
  document.getElementById('statAdminsCount').innerText = totalAdmins;
  document.getElementById('statRolesCount').innerText = Object.keys(cachedRoles).length;
}

// ==================== 4. LIVE ATTENDANCE VIEWER & MODIFIER ====================

async function loadAttendanceRecords() {
  const date = document.getElementById('attFilterDate').value;
  const meal = document.getElementById('attFilterMeal').value;
  const hostel = document.getElementById('attFilterHostel').value;
  const tbody = document.getElementById('attendanceTableBody');

  if (!date) return showToast('Please select a date', 'error');

  tbody.innerHTML = `<tr><td colspan="4" class="text-center py-8 text-[#64748B] italic"><i class="fa-solid fa-spinner animate-spin mr-2 text-[#135B26]"></i>Loading live attendance sheet...</td></tr>`;

  try {
    // 1. Get students for selected hostel
    const snapStudents = await db.ref(`hostelData_${hostel}/students`).get();
    const studentsVal = snapStudents.val() || [];
    const students = Array.isArray(studentsVal) ? studentsVal : Object.values(studentsVal);

    // 2. Get attendance data for selected hostel
    const snapAtt = await db.ref(`hostelData_${hostel}/attendance`).get();
    const attMap = snapAtt.val() || {};

    let presentCount = 0;
    let absentCount = 0;

    tbody.innerHTML = '';
    document.getElementById('attTotalStudents').innerText = students.length;

    students.sort((a, b) => (a.roomNo || '').localeCompare(b.roomNo || '', undefined, { numeric: true }));

    students.forEach(st => {
      const key = `${date}_${st.roomNo}_${st.name}`;
      const rec = attMap[key] || {};
      const status = meal === 'l' ? (rec.l || '-') : (rec.d || '-');

      if (status === 'P') presentCount++;
      if (status === 'A') absentCount++;

      let statusBadge = '<span class="px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-slate-100 text-slate-500 border border-slate-200">Unmarked (-)</span>';
      if (status === 'P') statusBadge = '<span class="px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-[#E8F5E9] text-[#135B26] border border-emerald-200">Present (P)</span>';
      if (status === 'A') statusBadge = '<span class="px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-red-50 text-red-700 border border-red-200">Absent (A)</span>';

      const tr = document.createElement('tr');
      tr.className = "hover:bg-[#E8F5E9]/25 transition";
      tr.innerHTML = `
        <td class="py-3 px-4 font-mono font-bold text-[#0F172A]">${st.roomNo || '-'}</td>
        <td class="py-3 px-4 font-semibold text-[#0F172A]">${st.name}</td>
        <td class="py-3 px-4">${statusBadge}</td>
        <td class="py-3 px-4 text-right space-x-1.5">
          <button onclick="modifyAttendanceStatus('${hostel}', '${date}', '${st.roomNo}', '${st.name}', '${meal}', 'P')" class="px-2.5 py-1 text-xs font-bold rounded-lg bg-[#135B26] hover:bg-[#0E441C] text-white transition shadow-sm">
            Mark P
          </button>
          <button onclick="modifyAttendanceStatus('${hostel}', '${date}', '${st.roomNo}', '${st.name}', '${meal}', 'A')" class="px-2.5 py-1 text-xs font-bold rounded-lg bg-red-600 hover:bg-red-700 text-white transition shadow-sm">
            Mark A
          </button>
          <button onclick="modifyAttendanceStatus('${hostel}', '${date}', '${st.roomNo}', '${st.name}', '${meal}', '-')" class="px-2 py-1 text-xs font-semibold rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 transition">
            Clear
          </button>
        </td>
      `;
      tbody.appendChild(tr);
    });

    document.getElementById('attPresentCount').innerText = presentCount;
    document.getElementById('attAbsentCount').innerText = absentCount;

  } catch (e) {
    tbody.innerHTML = `<tr><td colspan="4" class="text-center py-8 text-red-600">Error loading attendance: ${e.message}</td></tr>`;
  }
}

async function modifyAttendanceStatus(hostel, date, room, name, meal, newStatus) {
  const key = `${date}_${room}_${name}`;
  try {
    const mealField = meal === 'l' ? 'l' : 'd';
    await db.ref(`hostelData_${hostel}/attendance/${key}/${mealField}`).set(newStatus);
    await logAudit('ATTENDANCE_MODIFIED', `Super Admin modified ${hostel} hostel ${date} ${meal === 'l' ? 'Lunch' : 'Dinner'} for ${name} (Room ${room}) -> ${newStatus}`);
    showToast(`Updated ${name} -> ${newStatus}`, 'success');
    loadAttendanceRecords();
  } catch (e) {
    showToast(`Failed to update attendance: ${e.message}`, 'error');
  }
}

// ==================== 5. GLOBAL NOTICES ====================

function listenToNotices() {
  db.ref('super_admin_config/notices').on('value', snap => {
    const notices = snap.val() || {};
    renderNoticesList(notices);
  });
}

function renderNoticesList(noticesObj) {
  const container = document.getElementById('noticesListContainer');
  const countEl = document.getElementById('noticesCount');
  container.innerHTML = '';

  const list = Object.entries(noticesObj).map(([id, n]) => ({ id, ...n }));
  list.sort((a, b) => new Date(b.date || 0) - new Date(a.date || 0));

  countEl.innerText = `${list.length} notices`;

  if (list.length === 0) {
    container.innerHTML = `<div class="text-xs text-[#64748B] italic p-6 text-center">No notices published yet.</div>`;
    return;
  }

  list.forEach(n => {
    const div = document.createElement('div');
    div.className = "p-4 bg-white border border-slate-200 rounded-2xl relative group hover:border-[#135B26] transition shadow-sm";
    div.innerHTML = `
      <div class="flex items-start justify-between">
        <div>
          <div class="flex items-center gap-2">
            <h4 class="font-bold text-[#0F172A] text-sm">${n.title}</h4>
            <span class="px-2 py-0.5 rounded-full text-[10px] font-bold uppercase bg-amber-50 text-amber-700 border border-amber-200">${n.target || 'Both'}</span>
          </div>
          <p class="text-xs text-[#64748B] mt-1.5 leading-relaxed">${n.message}</p>
          <div class="text-[10px] text-slate-400 mt-2 flex items-center gap-2 font-medium">
            <i class="fa-regular fa-calendar text-[#135B26]"></i>
            <span>${n.date ? new Date(n.date).toLocaleString() : ''}</span>
            <span>•</span>
            <span>By ${n.author || 'Super Admin'}</span>
          </div>
        </div>
        <button onclick="deleteNotice('${n.id}')" class="text-slate-400 hover:text-red-500 p-1.5 rounded-lg hover:bg-red-50 transition" title="Delete notice">
          <i class="fa-solid fa-trash-can text-sm"></i>
        </button>
      </div>
    `;
    container.appendChild(div);
  });
}

async function publishNotice() {
  const title = document.getElementById('noticeTitle').value.trim();
  const message = document.getElementById('noticeMessage').value.trim();
  const target = document.getElementById('noticeTarget').value;

  if (!title || !message) return showToast('Please enter notice title and message', 'error');

  const noticeId = `notice_${Date.now()}`;
  const noticeData = {
    title: title,
    message: message,
    target: target,
    date: new Date().toISOString(),
    author: currentSessionUser || 'Super Admin'
  };

  await db.ref(`super_admin_config/notices/${noticeId}`).set(noticeData);

  // Sync to hostel specific nodes
  const targets = target === 'both' ? ['boys', 'girls'] : [target];
  for (const h of targets) {
    await db.ref(`hostelData_${h}/notices_trigger`).set(Date.now());
  }

  await logAudit('NOTICE_PUBLISHED', `Broadcast notice "${title}" to ${target} hostels`);

  document.getElementById('noticeTitle').value = '';
  document.getElementById('noticeMessage').value = '';
  showToast('Notice published successfully!', 'success');
}

async function deleteNotice(id) {
  if (!confirm('Are you sure you want to delete this notice?')) return;
  await db.ref(`super_admin_config/notices/${id}`).remove();
  await logAudit('NOTICE_DELETED', `Deleted notice ${id}`);
  showToast('Notice removed.', 'info');
}

// ==================== 6. AUDIT LOGGING ====================

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
      tr.className = "hover:bg-[#E8F5E9]/25 transition";
      tr.innerHTML = `
        <td class="py-3 px-4 font-mono text-[11px] text-[#64748B]">${dateFormatted}</td>
        <td class="py-3 px-4 font-bold text-[#0F172A]">${l.actor}</td>
        <td class="py-3 px-4">
          <span class="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-[#EFF3FC] text-[#135B26] border border-slate-200">${l.action}</span>
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
        <span class="px-2 py-0.5 text-[9px] font-bold uppercase rounded-full bg-white text-[#135B26] border border-slate-200 shadow-xs">${l.action}</span>
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
    success: 'bg-white border-emerald-300 text-[#135B26] shadow-emerald-900/10',
    error: 'bg-white border-red-300 text-red-700 shadow-red-900/10',
    info: 'bg-white border-slate-300 text-[#0F172A] shadow-slate-900/10'
  };
  const icon = {
    success: 'fa-circle-check text-[#135B26]',
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
