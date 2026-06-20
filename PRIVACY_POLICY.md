# Privacy Policy — SMART Water Level Control BD

**Effective Date:** June 1, 2026  
**Developer:** Sobuj Billah | SMART IoT Interface  
**Contact:** smartiotinterface@gmail.com  
**App:** SMART Water Level Control BD (com.smartiot.smart_iot_interface)

---

## 1. Introduction

SMART Water Level Control BD ("the App") is developed by SMART IoT Interface ("we", "us"). This Privacy Policy explains what data we collect, how we use it, and your rights.

By using the App, you agree to this Privacy Policy.

---

## 2. Data We Collect

### 2.1 Account Information
- **Email address** and **display name** — collected when you register or sign in with Google.
- **Google profile photo URL** — if you use Google Sign-In.

### 2.2 Device Data
- **Device ID** (auto-generated unique identifier for your water tank monitor).
- **Water tank status** — water level percentage, pump state (ON/OFF), pump mode (AUTO/MANUAL), sensor mode (FLOAT/ULTRASONIC).
- **Device diagnostics** — Wi-Fi signal strength (RSSI), uptime, firmware version, free heap memory, boot count.
- **Historical events** — pump start/stop events, alerts, dry-run events (stored locally on your phone and optionally in Firebase).

### 2.3 Usage Data (Firebase)
- **FCM token** — a device-specific token used to deliver push notifications. Stored in Firebase Realtime Database under your account.
- **Schedules, Automations, Scenes** — pump control rules you create, stored in Firebase under your account.

### 2.4 Crash Reports (Firebase Crashlytics)
- Anonymous crash logs and error reports (collected in release builds only). Does **not** include personally identifiable information.

### 2.5 Local Storage
- **Hive database** (on your device) — recent device history (up to 5,000 events), offline cache of last-known device status, pending command queue.
- **Shared Preferences** — app settings (dark mode preference, last selected device, language choice).

---

## 3. How We Use Your Data

| Data | Purpose |
|------|---------|
| Email / Display name | Account identification; login authentication |
| Device status | Real-time water tank monitoring dashboard |
| Historical events | History screen, analytics, water usage charts |
| FCM token | Push notifications (water level alerts, pump status) |
| Crash reports | Improving app stability |
| Schedules / Automations | Automating your pump according to your rules |

We do **not** sell, rent, or share your personal data with third parties for advertising or marketing purposes.

---

## 4. Third-Party Services

The App uses the following third-party services. Each has its own Privacy Policy:

| Service | Purpose | Privacy Policy |
|---------|---------|---------------|
| Firebase Auth (Google) | Authentication | https://firebase.google.com/support/privacy |
| Firebase Realtime Database | Cloud data storage | https://firebase.google.com/support/privacy |
| Firebase Crashlytics | Crash reporting | https://firebase.google.com/support/privacy |
| Firebase Cloud Messaging | Push notifications | https://firebase.google.com/support/privacy |
| Google Sign-In | Social login | https://policies.google.com/privacy |

---

## 5. Data Retention

- **Account data**: Retained until you delete your account.
- **Device history (local)**: Auto-trimmed to 5,000 entries on your device. You can clear it from the History screen.
- **Firebase data**: Retained until you delete the device from the app.
- **FCM tokens**: Removed from Firebase when you log out.
- **Crash reports**: Retained by Firebase Crashlytics per Google's retention policy.

---

## 6. Data Security

- All Firebase data is transmitted over HTTPS (TLS 1.2+).
- Firebase Security Rules enforce that each user can only access their own devices and data.
- Device sharing is explicit — you must enter another user's email address to share your device.
- Sensitive credentials (Firebase keys, AES keys) are stored only on the ESP32 device hardware, never in the app.

---

## 7. Children's Privacy

The App is not directed at children under 13 years of age. We do not knowingly collect personal information from children under 13. If you believe a child has provided us personal data, please contact us at smartiotinterface@gmail.com.

---

## 8. Your Rights

You have the right to:
- **Access** — request a copy of your data stored in Firebase.
- **Delete** — delete your account and all associated data by contacting us.
- **Correct** — update your display name from the Settings screen.
- **Withdraw consent** — uninstall the App; your local data (Hive, SharedPreferences) is deleted with the app.

To exercise these rights, contact: **smartiotinterface@gmail.com**

---

## 9. Changes to This Policy

We may update this Privacy Policy. The effective date at the top will be updated. Continued use of the App after changes constitutes acceptance.

---

## 10. Contact

**SMART IoT Interface**  
Developer: Sobuj Billah  
Email: smartiotinterface@gmail.com  
Phone: +8801680603444  
Website: https://smartiotinterface.blogspot.com

---

*This Privacy Policy was last updated on June 1, 2026.*
