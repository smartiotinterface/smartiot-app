/**********************************************************************************
 * SmartIoT_v15.ino — SMART WATER LEVEL CONTROL BD
 * Firmware v15.0.1  |  Production Edition
 * ─────────────────────────────────────────────────────────────────────────────
 * DEVELOPER  : Sobuj Billah  |  IoT Systems Architect
 * COMPANY    : SMART IoT Interface
 * CONTACT    : smartiotinterface@gmail.com
 * WEBSITE    : smartiotinterface.blogspot.com
 * YOUTUBE    : @smartiotinterface
 * BUILD DATE : 30-05-2026
 * Made with  : 💙 in Bangladesh 🇧🇩
 *
 * ════════════════════════════════════════════════════════════════════════════
 * v15.0.1 — BLE PROVISIONING SESSION FIX
 * ════════════════════════════════════════════════════════════════════════════
 * [FIX-PROV-SESSION] WiFiProv.endProvision() called before beginProvision()
 *   Root cause of "Failed to create session" (E1): second call to
 *   beginProvision() left IDF BLE stack half-initialized. endProvision() +
 *   200ms settle delay forces clean teardown before every beginProvision().
 *
 * [FIX-PROV-TIMEOUT]  Added provFailMs field to SystemState.
 *   Root cause of infinite provisioning loop: ARDUINO_EVENT_PROV_CRED_FAIL
 *   was resetting provStartMs, which reset the 5-minute overall timeout clock
 *   on every failed attempt. Now provFailMs tracks the 1.5s retry delay
 *   separately; provStartMs is set ONCE in startProvisioning() and never
 *   touched again, so the overall timeout works correctly.
 *
 * ════════════════════════════════════════════════════════════════════════════
 * v15.0.1 — OLED COMPLETE FIX + PRODUCTION HARDENING
 * ════════════════════════════════════════════════════════════════════════════
 * OLED DISPLAY FIXES (v15):
 * [DISP-FIX-1]  draw3DTank: pipe pipeY clamped to y+1 (was y-3 → off-screen flicker)
 * [DISP-FIX-2]  drawMainScreen: waterPct% text moved to y=4, lvlStr to y=22,
 *               pump row y=32, mode row y=42, WiFi row y=52 — no more row overlaps
 * [DISP-FIX-3]  drawMainScreen: time row removed from right panel (overlapped alarm bar);
 *               time now shown in tank label area at bottom-left
 * [DISP-FIX-4]  draw3DTank: pct% label drawn ONLY when textY < y+h (inside tank),
 *               eliminated overlap with main-screen bottom rows
 * [DISP-FIX-5]  drawMainScreen: notification overlay raised to y=0..8 (not y=0..10)
 *               and content rows offset by 10px when notification active
 * [DISP-FIX-6]  drawStatusScreen: WiFi dBm line split onto two rows to prevent
 *               overflow beyond 128px (size=1 → 6px/char)
 * [DISP-FIX-7]  drawInfoScreen: Heap and Temp split onto separate rows
 * [DISP-FIX-8]  drawProvisioningScreen: BLE name truncated to 21 chars max
 * [DISP-FIX-9]  animFrame incremented in separate 100ms timer (not tied to
 *               300ms display update) → smooth wave/bubble animation
 * [DISP-FIX-10] drawSignalBars: bounds-checked, X mark uses safe coordinates
 * [DISP-FIX-11] drawMainScreen: alarm bar at y=56 (was y=55) avoids partial pixel
 * [DISP-FIX-12] getShortSSID: off-by-one buffer write fixed (copyLen+1 safety)
 * [BUG-FIX-BEEP]  checkFactoryReset(): beep is now edge-triggered via lastBeepPct
 *                 (was firing every loop tick while progress%20==0 → continuous tone).
 * [BUG-FIX-ALARM] drawMainScreen(): alarm blink now millis()/500%2 (50% duty, 500ms),
 *                 was animFrame%6==0 (17% duty, 100ms flash → rapid flicker).
 * [BUG-FIX-NOTIF] drawMainScreen(): notification bar is now steady for its full
 *                 10-second lifetime (was animFrame%4<3 → 100ms gap every 400ms).
 * [BUG-FIX-MARKS] draw3DTank(): level ticks now use right-wall notches when x<4
 *                 (was max(0,x-4)=0 → ticks drawn over tank left outline at x=0).
 *
 * OTHER BUG FIXES (v15):
 * [BUG-FIX-13]  pinMajority: was passing pin number instead of correct buffer
 *               (LOW/MID/FULL buffers were all reading from sensors.lowSamples)
 * [BUG-FIX-14]  evaluateAutomations: no longer early-returns after fetch; rules
 *               evaluated in same cycle after re-fetch
 * [BUG-FIX-15]  GPIO summary comment corrected: PUMP_RELAY = GPIO16 (was GPIO2)
 * [BUG-FIX-16]  Splash: setCursor y=48 clipped on 64px display; adjusted to y=46
 * ════════════════════════════════════════════════════════════════════════════
 * Merges ALL best practices from SMART_WATER_TANK_BD1_v8.8.4 into the
 * SmartIoT_v12 Firebase + BLE-Provisioning architecture.
 *
 * ARCHITECTURE IMPROVEMENTS (from BD1 v8.8.4):
 * [ARCH-1] isTimeout() — rollover-safe helper, replaces raw millis() subtraction
 * [ARCH-2] PRODUCTION_MODE — Serial output compiled out in prod builds
 * [ARCH-3] RELAY_ACTIVE_HIGH — single define controls relay polarity
 * [ARCH-4] WIFI_CB_PAUSE — named constant, replaces magic 5*60*1000
 * [ARCH-5] calculateCRC32() — struct-layout-safe CRC over data
 *
 * SENSOR IMPROVEMENTS:
 * [SENS-1] SensorBuffer struct — per-pin 5-sample circular buffer
 * [SENS-2] Full sensor wins unconditionally (BD1 BUG-05)
 * [SENS-3] Sensor loops use SENSOR_SAMPLES constant (SMELL-04)
 *
 * BUTTON IMPROVEMENTS:
 * [BTN-1]  ButtonState struct — 50ms stable debounce state machine
 * [BTN-2]  BUTTON_STABLE_TIME = 50ms (was 20ms — too noisy)
 *
 * BUZZER IMPROVEMENTS:
 * [BUZZ-1] BuzzerJob multi-step sequencer with freq+dur+gap arrays
 * [BUZZ-2] All tones route through sequencer (no raw tone() conflicts)
 * [BUZZ-3] playStartup / playSuccess / playAlert / playTone helpers
 *
 * STATE PERSISTENCE IMPROVEMENTS:
 * [SAVE-1] PersistentState CRC32-validated NVS backup
 * [SAVE-2] Flash wear protection: memcmp + 5-min minimum interval
 * [SAVE-3] offsetof(PersistentState, crc32) for layout-safe CRC (BUG-09)
 *
 * WIFI IMPROVEMENTS:
 * [WIFI-1] Circuit breaker: 5 retries → 5-min pause (WIFI_CB_PAUSE)
 * [WIFI-2] WDT fed in WiFi + Prov event callbacks (SEC-FIX-5)
 * [WIFI-3] timeSyncNeeded flag — NTP deferred from WiFi ISR (BUG-06)
 * [WIFI-4] WiFi.setAutoConnect() removed (deprecated)
 *
 * SECURITY IMPROVEMENTS:
 * [SEC-1]  Factory reset blocked: WiFi connected AND uptime > 60s (SEC-FIX-2)
 * [SEC-2]  PRODUCTION_MODE hides firmware/heap info on Serial (SEC-FIX-3)
 * [SEC-3]  PoP NOT shown on OLED or Serial (already in v12)
 *
 * PUMP IMPROVEMENTS:
 * [PUMP-1] levelAtPumpStart set ONCE in setPump(ON), never mutated
 * [PUMP-2] Dry-run checks waterLevel==EMPTY directly (BD1 BUG-02)
 * [PUMP-3] Min-ON guard uses pumpStartMs (BD1 BUG-05)
 * [PUMP-4] lastReportedMode typed as PumpMode, not bool (BUG-08)
 * [PUMP-5] Max-run and dry-run use isTimeout() (rollover-safe, BUG-03)
 *
 * OLED DISPLAY — COMPLETE UI (6 SCREENS):
 * [OLED-1] Screen 0: Splash — SMART IoT branding, "Made in Bangladesh"
 * [OLED-2] Screen 1: Main — 3D animated tank + real-time status
 * [OLED-3] Screen 2: Status — WiFi, pump stats, sensor mode
 * [OLED-4] Screen 3: Info — IP, uptime, firmware, heap, temp
 * [OLED-5] Screen 4: Provisioning — BLE setup with animated dots
 * [OLED-6] Overlays — Factory reset bar, OTA bar, Deep sleep, Alarm flash
 * [OLED-7] 3D tank: wave animation + shine lines + pump bubbles
 * [OLED-8] BD time (GMT+6) on main screen bottom row
 * [OLED-9] WiFi signal-strength bars
 * [OLED-10] Pixel bounds checked before drawPixel (BUG-03/DISP-3)
 * [OLED-11] displayInitialized set BEFORE first draw (DISP-1)
 * [OLED-12] Auto re-init on display failure (retryDisplayInit)
 *
 * PRESERVED FROM SmartIoT_v12 / v13.1.0:
 * — Firebase RTDB push/pull (HTTPS + GTS Root CA)
 * — BLE WiFi provisioning (Espressif WiFiProv.h)
 * — Ultrasonic HC-SR04 (interrupt-driven, GPIO 27/14)
 * — TOGGLE_MODE_PIN (GPIO 33) — float / ultrasonic runtime switching
 * — EMERGENCY_WAKEUP_PIN (GPIO 34) — GPIO deep sleep wakeup
 * — AES-256-CBC NVS pump stat backup
 * — OTA with SHA-256 verification
 * — Deep sleep (30 min idle, pump off, no alarm)
 * — Firebase command polling
 * — All v13.1.0 BUG-1 through BUG-8 fixes
 *
 * PARTITION SCHEME (Arduino IDE):
 *   Tools → Partition Scheme → "No OTA (2MB APP/2MB SPIFFS)"
 *   (BLE stack is large — default partition too small)
 *
 * LIBRARIES:
 *   ArduinoJson ≥ 7.0  (Benoit Blanchon)
 *   Adafruit SSD1306 + Adafruit GFX  (Adafruit)
 *   Built-in with ESP32 Arduino ≥ 2.0.14:
 *     WiFi, HTTPClient, WiFiClientSecure, WiFiProv, Preferences,
 *     esp_sleep, esp_task_wdt, Update, mbedtls
 **********************************************************************************/

#include <Arduino.h>
#include <WiFi.h>
#include <WiFiProv.h>
#include <wifi_provisioning/manager.h>  // wifi_prov_mgr_deinit()
#include "esp_wifi.h"
#include "esp_coexist.h"               // [FIX-BLE-WIFI-COEX] esp_coex_preference_set()
#include "esp_gap_ble_api.h"            // [FIX-PAIRING-DIALOG] esp_ble_gap_set_security_param()
#include <HTTPClient.h>
#include <WiFiClientSecure.h>
#include <Preferences.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <ArduinoJson.h>
#include <mbedtls/aes.h>
#include <mbedtls/sha256.h>
#include <esp_sleep.h>
#include <esp_task_wdt.h>
#include <Update.h>
#include <time.h>
#include "secrets.h"

// ============================================================================
// VERSION
// ============================================================================
#define FIRMWARE_VER    "v15.0.1"
#define FIRMWARE_NAME   "SmartIoT Production Edition"
#define BUILD_DATE      __DATE__
#define BUILD_TIME      __TIME__
#define STATE_VERSION   3   // Increment when PersistentState changes

// ============================================================================
// PRODUCTION MODE
// 0 = development: all Serial output enabled
// 1 = production:  ALL Serial.* compiled out — smaller + no info leak
// [SEC-2] Prevents firmware version, heap, timing info leaking over UART
// ============================================================================
#define PRODUCTION_MODE 1  // [SEC-FIX] Production: all Serial output disabled

#if PRODUCTION_MODE
  #define DBG(...)     do {} while(0)
  #define DBGF(...)    do {} while(0)
  #define DBGLN(s)     do {} while(0)
#else
  #define DBG(x)       Serial.print(x)
  #define DBGF(...)    Serial.printf(__VA_ARGS__)
  #define DBGLN(s)     Serial.println(s)
#endif

// ============================================================================
// PIN DEFINITIONS — v12 hardware layout preserved
// ============================================================================
constexpr uint8_t FLOAT_LOW_PIN        =  4;
constexpr uint8_t FLOAT_MID_PIN        = 15;   // INPUT_PULLUP (has internal pull-up)
constexpr uint8_t FLOAT_FULL_PIN       =  5;
constexpr uint8_t PUMP_RELAY_PIN       =  16;
constexpr uint8_t BUZZER_PIN           = 18;
constexpr uint8_t LED_WIFI_PIN         = 2;
constexpr uint8_t LED_PUMP_PIN         = 17;
constexpr uint8_t BTN_MODE_PIN         = 23;
constexpr uint8_t BTN_PUMP_PIN         = 25;
constexpr uint8_t BTN_MUTE_PIN         = 26;
constexpr uint8_t BTN_RESET_PIN        =  0;   // GPIO0/BOOT — factory reset
constexpr uint8_t I2C_SDA_PIN          = 21;
constexpr uint8_t I2C_SCL_PIN          = 22;
constexpr uint8_t TRIG_PIN             = 27;   // Ultrasonic TRIG
constexpr uint8_t ECHO_PIN             = 14;   // Ultrasonic ECHO (interrupt)
constexpr uint8_t TOGGLE_MODE_PIN      = 33;   // LOW=Float, HIGH=Ultrasonic
constexpr uint8_t EMERGENCY_WAKEUP_PIN = 34;   // GPIO34 = input-only; needs ext 10kΩ pull-up

// ── Relay polarity abstraction (ARCH-3) ────────────────────────────────────
// RELAY_ACTIVE_HIGH 1 → HIGH turns pump ON  (most solid-state relays)
// RELAY_ACTIVE_HIGH 0 → LOW  turns pump ON  (active-LOW relay modules)
#define RELAY_ACTIVE_HIGH  1
#if RELAY_ACTIVE_HIGH
  #define RELAY_ON   HIGH
  #define RELAY_OFF  LOW
#else
  #define RELAY_ON   LOW
  #define RELAY_OFF  HIGH
#endif

// ============================================================================
// OLED DISPLAY
// ============================================================================
#define DISPLAY_W    128
#define DISPLAY_H     64
#define DISPLAY_ADDR  0x3C
Adafruit_SSD1306 display(DISPLAY_W, DISPLAY_H, &Wire, -1);

// ============================================================================
// TIMING CONSTANTS (ms)
// ============================================================================
constexpr uint32_t SENSOR_READ_MS        =    200;
constexpr uint32_t DISPLAY_UPDATE_MS     =    300;  // ~3fps screen refresh
constexpr uint32_t ANIM_FRAME_MS         =    100;  // [DISP-FIX-9] 10fps animation tick
constexpr uint32_t DISPLAY_RETRY_MS      =  30000;
constexpr uint32_t FB_PUSH_MS            =  15000;
constexpr uint32_t FB_CMD_MS             =   2000;
constexpr uint32_t IOT_METRICS_MS        =  60000;  // [SMELL-05] 60s not 5s
constexpr uint32_t TIME_SYNC_MS          = 3600000; // 1 hour
constexpr uint32_t PUMP_MIN_ON_MS        =   5000;
constexpr uint32_t PUMP_MIN_OFF_MS       =  10000;
constexpr uint32_t PUMP_MAX_RUN_MS       = 1800000; // 30 min
constexpr uint32_t DRY_RUN_TIMEOUT_MS   =  180000;  // 3 min
constexpr uint32_t DRY_RUN_COOLDOWN_MS  =  300000;  // 5 min
constexpr uint32_t FACTORY_RESET_HOLD_MS=  10000;
constexpr uint32_t STATE_SAVE_MIN_MS     =  300000; // 5 min
constexpr uint32_t WIFI_RETRY_BASE_MS    =  10000;
constexpr uint32_t WIFI_RETRY_MAX_MS     =  60000;
constexpr uint32_t WIFI_CB_PAUSE         = 300000UL; // [ARCH-4] 5-min circuit breaker
constexpr uint32_t DEEP_SLEEP_IDLE_MS    = 1800000;  // 30 min
constexpr uint32_t SPLASH_SCREEN_MS      =   2500;
constexpr uint32_t NOTIFICATION_CLEAR_MS =  10000;
constexpr uint32_t PROV_TIMEOUT_MS       =  300000;
constexpr uint8_t  WATCHDOG_TIMEOUT_S    =     30;
constexpr uint32_t BUTTON_STABLE_TIME    =     50;  // [BTN-2] 50ms debounce

// ============================================================================
// SYSTEM THRESHOLDS
// ============================================================================
constexpr int PUMP_AUTO_ON_PCT    =  10;
constexpr int PUMP_AUTO_OFF_PCT   =  90;
constexpr int US_EMPTY_CM         =  70;
constexpr int US_FULL_CM          =  10;
constexpr int SENSOR_SAMPLES      =   5;  // [SENS-1]
constexpr int SENSOR_MAJORITY     =   3;
constexpr int MAX_WIFI_RETRY      =   5;
constexpr uint32_t LOW_MEMORY     = 20000;

// Bangladesh Timezone (GMT+6)
constexpr long BD_TZ_OFFSET = 21600;
constexpr int  BD_DST       = 0;

// ============================================================================
// ENUMERATIONS
// ============================================================================
enum WaterLevel : uint8_t { LVL_EMPTY=0, LVL_LOW=1, LVL_MID=2, LVL_FULL=3 };
enum PumpMode   : uint8_t { MODE_AUTO=0, MODE_MANUAL=1 };
enum PumpState  : uint8_t { PUMP_OFF=0, PUMP_ON=1 };
enum SensorMode : uint8_t { SENSOR_FLOAT=0, SENSOR_ULTRA=1 };
enum OledScreen : uint8_t { OLED_SPLASH=0, OLED_MAIN=1, OLED_STATUS=2, OLED_INFO=3 };
enum ProvState  : uint8_t { PROV_IDLE=0, PROV_WAITING=1, PROV_SUCCESS=2, PROV_FAILED=3 };

// Ultrasonic state machine (ISR)
enum USState : uint8_t { US_IDLE=0, US_TRIGGERED=1, US_MEASURING=2, US_DONE=3 };
volatile USState  g_usState     = US_IDLE;
volatile uint32_t g_usEchoStart = 0;  // [BUG-4] volatile
volatile uint32_t g_usDuration  = 0;  // [BUG-4] volatile
volatile bool     g_usMeasDone  = false; // [BUG-4] volatile

void IRAM_ATTR echoISR() {
    if (digitalRead(ECHO_PIN) == HIGH) {
        g_usEchoStart = micros();
        g_usState     = US_MEASURING;
    } else if (g_usState == US_MEASURING) {
        g_usDuration = micros() - g_usEchoStart;
        g_usState    = US_DONE;
        g_usMeasDone = true;
    }
}

// ============================================================================
// DATA STRUCTURES
// ============================================================================

// [SENS-1] Per-pin 5-sample circular buffer (BD1 SENS pattern)
struct SensorBuffer {
    uint8_t lowSamples [SENSOR_SAMPLES];
    uint8_t midSamples [SENSOR_SAMPLES];
    uint8_t fullSamples[SENSOR_SAMPLES];
    uint8_t index;
};

// [BTN-1] Stable-state button debouncer (BD1 BTN pattern)
struct ButtonState {
    uint32_t lastChange;
    uint32_t stableTime;
    bool     currentReading;
    bool     stableState;
    bool     lastReported;
};

// [BUZZ-1] Non-blocking multi-step buzzer sequencer (BD1 BUZZ pattern)
struct BuzzerJob {
    bool     active;
    uint8_t  step;
    uint8_t  total;
    bool     inPause;
    uint32_t nextAt;
    uint16_t freqs[6];
    uint16_t durs[6];
    uint16_t gaps[6];
};

// [SAVE-1] CRC32-validated persistent state
struct PersistentState {
    uint32_t version;
    uint8_t  pumpMode;
    bool     muted;
    uint16_t pumpCycles;
    uint32_t pumpTotalS;
    uint32_t bootCount;
    uint16_t wifiReconnects;
    char     chipSerial[24];
    bool     provisioned;
    uint32_t crc32;  // MUST remain last (offsetof used in saveState)
};

// Main system state — all runtime data in one struct
struct SystemState {
    // ── Water & Sensors ──────────────────────────────────────────────────────
    WaterLevel  waterLevel;
    WaterLevel  lastReportedLevel;
    int         waterPct;
    SensorMode  sensorMode;
    uint32_t    lastSensorRead;

    // ── Pump ─────────────────────────────────────────────────────────────────
    PumpMode    pumpMode;
    PumpState   pumpState;
    bool        lastReportedPumpState;
    PumpMode    lastReportedMode;  // [PUMP-4] PumpMode type, not bool
    uint32_t    pumpStartMs;
    uint32_t    pumpStopMs;
    uint32_t    pumpRunMs;
    uint16_t    pumpCycles;
    uint32_t    pumpTotalS;
    bool        pumpStopRequested;
    WaterLevel  levelAtPumpStart;  // [PUMP-1] set once in setPump(ON)

    // ── Buzzer / User Prefs ──────────────────────────────────────────────────
    bool        muted;         // [FIX-1] was missing from SystemState (compile error)

    // ── Dry-Run Protection ───────────────────────────────────────────────────
    bool        dryRunActive;
    uint32_t    dryRunStopMs;

    // ── Alarm ────────────────────────────────────────────────────────────────
    bool        alarmActive;

    // ── Display ──────────────────────────────────────────────────────────────
    OledScreen  oledScreen;
    uint8_t     animFrame;
    uint32_t    lastDisplayUpdate;
    uint32_t    lastAnimUpdate;      // [DISP-FIX-9] separate 100ms animation tick
    uint32_t    lastDisplayRetry;
    bool        displayInitialized;
    bool        splashActive;
    uint32_t    splashStart;
    bool        displayNeedsUpdate;

    // ── Time ─────────────────────────────────────────────────────────────────
    uint32_t    lastTimeSync;
    bool        timeInitialized;
    bool        timeSyncNeeded;    // [WIFI-3] deferred NTP from WiFi ISR
    struct tm   timeInfo;

    // ── Notification ─────────────────────────────────────────────────────────
    char        notification[128];
    uint32_t    notificationMs;
    bool        notificationActive;

    // ── WiFi ─────────────────────────────────────────────────────────────────
    bool        wifiOk;
    bool        lastReportedWifi;
    uint8_t     wifiRetryCount;
    uint32_t    wifiNextRetry;
    uint32_t    wifiRetryDelay;
    bool        wifiCircuitOpen;
    int8_t      rssi;

    // ── Provisioning ─────────────────────────────────────────────────────────
    ProvState   provState;
    uint32_t    provStartMs;   // set once at startProvisioning() — used for overall 5-min timeout
    uint32_t    provFailMs;    // [FIX] reset on each CRED_FAIL — used only for 1.5s retry delay
    bool        provRunning;
    bool        provDone;

    // ── Factory Reset ────────────────────────────────────────────────────────
    uint32_t    factoryResetStart;
    bool        factoryResetTriggered;
    uint8_t     factoryResetProgress;

    // ── OTA ──────────────────────────────────────────────────────────────────
    bool        otaInProgress;

    // ── System Metrics ───────────────────────────────────────────────────────
    uint32_t    bootTime;
    uint32_t    bootCount;
    uint16_t    wifiReconnects;
    uint32_t    flashWrites;
    uint32_t    freeHeap;
    float       temperature;

    // ── Deep Sleep ───────────────────────────────────────────────────────────
    uint32_t    lastActivityMs;

    // ── Firebase ─────────────────────────────────────────────────────────────
    uint32_t    lastFBPushMs;
    uint32_t    lastFBCmdMs;
    uint32_t    lastMetricsMs;
    int         lastCmdTs;
    bool        stateDirty;
    uint32_t    lastStateSaveMs;
};

// ============================================================================
// GLOBAL OBJECTS
// ============================================================================
Preferences     prefs;
SensorBuffer    sensors = {};
BuzzerJob       buzzerJob = {};
SystemState     sys = {};
PersistentState lastSavedState = {};

char g_chipSerial[24] = "";
bool g_provisioned    = false;

// Buttons (three separate state machines)
ButtonState btnMode = {}, btnPump = {}, btnMute = {};

// ============================================================================
// GOOGLE GTS ROOT R1 CA — valid until 2036-06-22
// Required for HTTPS to Firebase RTDB
// ============================================================================
static const char GOOGLE_ROOT_CA[] PROGMEM = R"EOF(
-----BEGIN CERTIFICATE-----
MIIFVzCCAz+gAwIBAgINAgPlk28xsBNJiGuiFzANBgkqhkiG9w0BAQwFADBHMQsw
CQYDVQQGEwJVUzEiMCAGA1UEChMZR29vZ2xlIFRydXN0IFNlcnZpY2VzIExMQzEU
MBIGA1UEAxMLR1RTIFJvb3QgUjEwHhcNMTYwNjIyMDAwMDAwWhcNMzYwNjIyMDAw
MDAwWjBHMQswCQYDVQQGEwJVUzEiMCAGA1UEChMZR29vZ2xlIFRydXN0IFNlcnZp
Y2VzIExMQzEUMBIGA1UEAxMLR1RTIFJvb3QgUjEwggIiMA0GCSqGSIb3DQEBAQUA
A4ICDwAwggIKAoICAQC2EQKLHuOhd5s73L+UPreVp0A8of2C+X0yBoJx9vaMf/vo
27xqLpeXo4xL+Sv2sfnOhB2x+cWX3u+58qPpvBKJXqeqUqv4IyfLpLGcY9vXmX7
wCl7raKb0xlpHDU0QM+NOsROjyBhsS+z8CZDfnWQpJSMHobTSPS5g4M/SCYe7zUj
wTcLCeoiKu7rPWRnWr4+wB7CeMfGCwcDfLqZtbBkOtdh+JhpFAz2weaSUTXlv+16
syMaQqPMphY+9UaeIAp8BGIV6mVZoQNnLMv8Qno5/47xCjv6lBi7HqXDGdAuA6BN
QnNflDZvFMJNcVrMFE6B4TRVZSaFKqpYInmyEHGJvYH8o+6HHJoKaZDpxjcfqVCX
k1bMOe1TnFE73hgJHHBY/P8MH6oJ4dRBelOKLfh1KFJRQE+3V9EwXYkZsIcVb62N
I2mfKGJi/b5IVpM35Bpo0T0ZJgMnEVBFoV4PdCyVz0HmOKGGiCJNBxMkUdAKQoIC
nGQh8FJwuQzJbqTH03e6DKDQVQV7nRCmvdBWDLWUdlP7oG2ViXpJUWmOBKbCQqbK
JcD6ZFaFWDomqzHKWFwAnMkVe0F3nfJX5w3+nJ5mqBeDqpEIMuF41KDKqGzfnq+i
FQ9fBq/VNI8aqb+Zg0RvjJqMY7VGsFePABLJiwIDAQABo0IwQDAOBgNVHQ8BAf8E
BAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQU5K8rJnEaK0gnhS9SZizv
8IkTcT4wDQYJKoZIhvcNAQEMBQADggIBADiWCu49tJYeX++dnAsznyvgyv3SjgofQ
xmlLQDQUjNM4s3fpFCsGlFmhTWMBNqf0ZzqaJBTBXOXrLzTijPZHuevj9v5HTvB+
MYhwmhA1Hl2TDXZEK5xEjGGCdpAT9pCDDzlXJJVGHPMVPFk6N80yVo/wLPANLj8S
wJCMQECb77LJo2Vhp/cjuYD/bYhSIu3V0YPDN7TiG30/T8swm3tWpTVGG5Bkb3Nj
BFUlGKbxFJGWOEeneMJFiSJRCUjqS/Vl6mG/K/EO3JL5zJpB8aTUt5jFWN7WXBOF
kEjqr/bSmK2hUWvUHWn5cMFsqpE3MjLSjSHi3mJRxdUjS0C4fJG7rHYWP7TiBqp
9BLnj7cMz9FKMkHPvmLVREb5t6AgtMRSPTlBFgTxFqAWy2vS+q/RMvCFkCT0F5Iv
AhIDAQAB
-----END CERTIFICATE-----
)EOF";

// ============================================================================
// FUNCTION DECLARATIONS
// ============================================================================
// Utilities
inline bool    isTimeout(uint32_t start, uint32_t interval);
uint32_t       calculateCRC32(const void* data, size_t len);
void           genSerial(char* buf);
void           getBDTime(char* buf, size_t len);
void           getUptime(char* buf, size_t len);
void           getShortSSID(char* buf, size_t len);
void           sendNotification(const char* msg);
void           clearNotificationIfNeeded();
// Hardware
void           setupHardware();
void           setupWatchdog();
// Display
void           setupDisplay();
void           retryDisplayInit();
void           updateDisplay();
void           drawSplashScreen();
void           drawMainScreen();
void           drawStatusScreen();
void           drawInfoScreen();
void           drawProvisioningScreen();
void           drawFactoryResetOverlay();
void           drawOtaOverlay(int pct);
void           drawDeepSleepScreen();
void           draw3DTank(int x, int y, int w, int h, uint8_t pct);
void           drawSignalBars(int x, int y, int8_t rssi);
// Sensors
bool           pinMajority(uint8_t pin, const uint8_t* buf);
WaterLevel     readFloatSensors();
int            readUltrasonicPct();
void           readSensors();
// Pump
void           setPump(bool on);
void           updateAutoMode();
// Buzzer
void           _startBuzzerSeq(const uint16_t* f, const uint16_t* d, const uint16_t* g, uint8_t n);
void           updateBuzzer();
void           playTone(uint16_t freq, uint16_t dur);
void           playStartup();
void           playSuccess();
void           playAlert();
// Buttons
bool           checkButton(ButtonState& btn, uint8_t pin);
void           handleButtons();
// State
bool           loadState();
void           markStateDirty();
void           saveState(bool force = false);
// WiFi
void           setupWiFi();
void           onWiFiEvent(WiFiEvent_t event);
void           handleWiFiReconnect();
void           setupTime();
void           updateTime();
// Provisioning
void           SysProvEvent(arduino_event_t* evt);
void           startProvisioning(bool resetSaved = false);
void           handleProvisioning();
// Firebase
static String  fbURL(const String& path);
bool           fbGET(const String& path, DynamicJsonDocument& doc);
bool           fbPATCH(const String& path, const String& body);
void           pushStatus();
void           pollCommands();
// OTA
void           performOTA(const String& url, const String& expectedSha256);
void           monitorOTA();
// Factory reset
void           checkFactoryReset();
// Deep sleep
void           checkDeepSleep();
// AES (preserved from v12)
static bool    hexToBuf(const String& hex, uint8_t* out, size_t maxLen);
static String  bufToHex(const uint8_t* b, size_t n);
static void    deriveAESKey(uint8_t key[32]);
static String  aesEncrypt(const String& plain);
static String  aesDecrypt(const String& hex);
void           savePumpStats();
void           loadPumpStats();

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

// [ARCH-1] Rollover-safe timeout check (uses unsigned arithmetic)
inline bool isTimeout(uint32_t start, uint32_t interval) {
    return (millis() - start) >= interval;
}

// [ARCH-5] CRC32 (IEEE 802.3 polynomial, table-free)
uint32_t calculateCRC32(const void* data, size_t len) {
    uint32_t crc = 0xFFFFFFFF;
    const uint8_t* p = (const uint8_t*)data;
    for (size_t i = 0; i < len; i++) {
        crc ^= p[i];
        for (int j = 0; j < 8; j++)
            crc = (crc >> 1) ^ (crc & 1 ? 0xEDB88320UL : 0);
    }
    return ~crc;
}

// Unique device serial from eFuse MAC
void genSerial(char* buf) {
    if (!buf) return;
    uint64_t mac = ESP.getEfuseMac();
    snprintf(buf, 24, "SWT-%04X%08X",
             (unsigned)(mac >> 32), (unsigned)(uint32_t)mac);
}

// BD time string — "HH:MM:SS AM/PM"
void getBDTime(char* buf, size_t len) {
    if (!buf || len == 0) return;
    if (!sys.timeInitialized) {
        snprintf(buf, len, "--:-- --");
        return;
    }
    int h = sys.timeInfo.tm_hour;
    int m = sys.timeInfo.tm_min;
    const char* ap = (h >= 12) ? "PM" : "AM";
    if (h > 12) h -= 12;
    if (h == 0) h = 12;
    snprintf(buf, len, "%02d:%02d %s", h, m, ap);
}

// Uptime string — "Xh Ym" or "Xd Yh"
void getUptime(char* buf, size_t len) {
    if (!buf || len == 0) return;
    uint32_t sec = (millis() - sys.bootTime) / 1000UL;
    uint32_t d = sec / 86400;
    uint32_t h = (sec % 86400) / 3600;
    uint32_t m = (sec % 3600) / 60;
    if (d > 0)
        snprintf(buf, len, "%ud %02uh%02um", (unsigned)d, (unsigned)h, (unsigned)m);
    else
        snprintf(buf, len, "%02uh %02um", (unsigned)h, (unsigned)m);
}

// Truncated SSID for display (≤7 chars)
void getShortSSID(char* buf, size_t len) {
    if (!buf || len < 2) return;
    if (!sys.wifiOk) { snprintf(buf, len, "---"); return; }
    String ssid = WiFi.SSID();
    if (ssid.length() == 0) { snprintf(buf, len, "?"); return; }
    // [DISP-FIX-12] safe copy: never write beyond len-1
    size_t maxCopy = len - 1;                       // leave room for NUL
    if (ssid.length() <= maxCopy) {
        strncpy(buf, ssid.c_str(), maxCopy);
    } else {
        size_t trunc = (maxCopy > 1) ? maxCopy - 1 : 0;  // room for '.'
        strncpy(buf, ssid.c_str(), trunc);
        buf[trunc] = '.';
        buf[trunc + 1] = '\0';
    }
    buf[len - 1] = '\0';
}

// Active notification (shown on display, pushed to Firebase)
void sendNotification(const char* msg) {
    if (!msg) return;
    strncpy(sys.notification, msg, sizeof(sys.notification) - 1);
    sys.notification[sizeof(sys.notification) - 1] = '\0';
    sys.notificationMs     = millis();
    sys.notificationActive = true;
    sys.displayNeedsUpdate = true;
    DBGF("[NOTIF] %s\n", msg);
}

void clearNotificationIfNeeded() {
    if (!sys.notificationActive) return;
    if (isTimeout(sys.notificationMs, NOTIFICATION_CLEAR_MS))
        sys.notificationActive = false;
}

// ============================================================================
// AES-256-CBC — NVS pump-stat backup (preserved from v12/v13.1.0)
// ============================================================================
static bool hexToBuf(const String& hex, uint8_t* out, size_t maxLen) {
    if (hex.length() == 0 || hex.length() % 2 != 0) return false;
    size_t bytes = hex.length() / 2;
    if (bytes > maxLen) return false;
    for (size_t i = 0; i < bytes; i++) {
        auto hv = [](char c) -> int {
            if (c>='0'&&c<='9') return c-'0';
            if (c>='a'&&c<='f') return c-'a'+10;
            if (c>='A'&&c<='F') return c-'A'+10;
            return -1;
        };
        int hi = hv(hex[i*2]), lo = hv(hex[i*2+1]);
        if (hi < 0 || lo < 0) return false;
        out[i] = (uint8_t)((hi<<4)|lo);
    }
    return true;
}

static String bufToHex(const uint8_t* b, size_t n) {
    String s; s.reserve(n*2);
    for (size_t i = 0; i < n; i++) { char t[3]; snprintf(t, 3, "%02x", b[i]); s += t; }
    return s;
}

static void deriveAESKey(uint8_t key[32]) {
    uint8_t base[32];
    if (!hexToBuf(AES_BACKUP_KEY_HEX, base, 32)) memset(base, 0xA5, 32);
    uint64_t mac = ESP.getEfuseMac();
    uint8_t  macB[8]; memcpy(macB, &mac, 8);
    for (int i = 0; i < 32; i++) key[i] = base[i] ^ macB[i%8];
}

static String aesEncrypt(const String& plain) {
    uint8_t key[32]; deriveAESKey(key);
    size_t ptLen = plain.length(), pad = 16 - (ptLen % 16), total = ptLen + pad;
    uint8_t* inB  = (uint8_t*)malloc(total);
    uint8_t* outB = (uint8_t*)malloc(total);
    if (!inB || !outB) { free(inB); free(outB); return ""; }
    memcpy(inB, plain.c_str(), ptLen);
    for (size_t i = ptLen; i < total; i++) inB[i] = (uint8_t)pad;
    // [SEC-NOTE] Static IV (0x37 × 16) used for AES-CBC. This IV is consistent
    // across encrypt/decrypt cycles — changing it would corrupt existing NVS data.
    // Risk: low (NVS is local device storage, not network-transmitted ciphertext).
    // If upgrading, add a STATE_VERSION bump + NVS clear to migrate.
    uint8_t iv[16]; memset(iv, 0x37, 16);
    mbedtls_aes_context ctx;
    mbedtls_aes_init(&ctx);
    mbedtls_aes_setkey_enc(&ctx, key, 256);
    mbedtls_aes_crypt_cbc(&ctx, MBEDTLS_AES_ENCRYPT, total, iv, inB, outB);
    mbedtls_aes_free(&ctx);
    String r = bufToHex(outB, total);
    free(inB); free(outB);
    return r;
}

static String aesDecrypt(const String& hex) {
    if (hex.length() == 0 || hex.length() % 2 != 0) return "";
    size_t cLen = hex.length() / 2;
    if (cLen == 0 || cLen % 16 != 0) return "";
    uint8_t key[32]; deriveAESKey(key);
    uint8_t* cBuf = (uint8_t*)malloc(cLen);
    uint8_t* pBuf = (uint8_t*)malloc(cLen);
    if (!cBuf || !pBuf) { free(cBuf); free(pBuf); return ""; }
    if (!hexToBuf(hex, cBuf, cLen)) { free(cBuf); free(pBuf); return ""; }
    uint8_t iv[16]; memset(iv, 0x37, 16);
    mbedtls_aes_context ctx;
    mbedtls_aes_init(&ctx);
    mbedtls_aes_setkey_dec(&ctx, key, 256);
    mbedtls_aes_crypt_cbc(&ctx, MBEDTLS_AES_DECRYPT, cLen, iv, cBuf, pBuf);
    mbedtls_aes_free(&ctx);
    uint8_t pad = pBuf[cLen-1];
    if (pad == 0 || pad > 16) pad = 0;
    String r = String((char*)pBuf).substring(0, (int)(cLen - pad));
    free(cBuf); free(pBuf);
    return r;
}

void savePumpStats() {
    String d = String(sys.pumpCycles) + "," + String(sys.pumpTotalS);
    String enc = aesEncrypt(d);
    prefs.begin("stats", false);
    prefs.putString("enc", enc);
    prefs.end();
}

void loadPumpStats() {
    prefs.begin("stats", true);
    String enc = prefs.getString("enc", "");
    prefs.end();
    if (enc.isEmpty()) return;
    String dec = aesDecrypt(enc);
    if (dec.isEmpty()) return;
    int comma = dec.indexOf(',');
    if (comma > 0) {
        sys.pumpCycles  = dec.substring(0, comma).toInt();
        sys.pumpTotalS  = dec.substring(comma + 1).toInt();
        DBGF("[NVS] stats: cycles=%u totalS=%u\n", sys.pumpCycles, sys.pumpTotalS);
    }
}

// ============================================================================
// HARDWARE SETUP
// ============================================================================
void setupHardware() {
    DBGLN("[HW] Configuring pins...");

    // Sensor inputs
    pinMode(FLOAT_LOW_PIN,  INPUT_PULLUP);
    pinMode(FLOAT_MID_PIN,  INPUT_PULLUP);  // GPIO15 has internal pull-up
    pinMode(FLOAT_FULL_PIN, INPUT_PULLUP);
    pinMode(BTN_MODE_PIN,   INPUT_PULLUP);
    pinMode(BTN_PUMP_PIN,   INPUT_PULLUP);
    pinMode(BTN_MUTE_PIN,   INPUT_PULLUP);
    pinMode(BTN_RESET_PIN,  INPUT_PULLUP);  // GPIO0 — factory reset
    pinMode(TOGGLE_MODE_PIN,INPUT);         // Float/Ultrasonic toggle
    pinMode(EMERGENCY_WAKEUP_PIN, INPUT);   // GPIO34 — ext 10kΩ pull-up needed

    // Outputs — all start in safe OFF state
    pinMode(PUMP_RELAY_PIN, OUTPUT); digitalWrite(PUMP_RELAY_PIN, RELAY_OFF);
    pinMode(BUZZER_PIN,     OUTPUT); digitalWrite(BUZZER_PIN,     LOW);
    pinMode(LED_WIFI_PIN,   OUTPUT); digitalWrite(LED_WIFI_PIN,   LOW);
    pinMode(LED_PUMP_PIN,   OUTPUT); digitalWrite(LED_PUMP_PIN,   LOW);
    pinMode(TRIG_PIN,       OUTPUT); digitalWrite(TRIG_PIN,       LOW);

    // Ultrasonic echo interrupt
    pinMode(ECHO_PIN, INPUT);
    attachInterrupt(digitalPinToInterrupt(ECHO_PIN), echoISR, CHANGE);

    DBGF("[HW] ✅ OK — Relay: active=%s  MID: GPIO15 INPUT_PULLUP\n",
         RELAY_ACTIVE_HIGH ? "HIGH" : "LOW");
}

// ============================================================================
// WATCHDOG SETUP
// ============================================================================
void setupWatchdog() {
    DBGLN("[WDT] Enabling...");
    esp_task_wdt_init(WATCHDOG_TIMEOUT_S, true);
    esp_task_wdt_add(NULL);
    esp_task_wdt_reset();
    DBGF("[WDT] ✅ Timeout=%ds\n", WATCHDOG_TIMEOUT_S);
}

// ============================================================================
// DISPLAY SETUP — with auto-retry on failure
// [OLED-7] sys.displayInitialized set BEFORE first draw (DISP-1)
// [OLED-8] 400kHz I2C
// ============================================================================
void setupDisplay() {
    DBGLN("[DISP] Initializing SSD1306...");

    Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);
    Wire.setClock(400000);

    // Probe I2C address before init
    Wire.beginTransmission(DISPLAY_ADDR);
    if (Wire.endTransmission() != 0) {
        DBGLN("[DISP] ❌ Not found at 0x3C — headless mode");
        sys.displayInitialized = false;
        sys.lastDisplayRetry   = millis();
        return;
    }

    if (!display.begin(SSD1306_SWITCHCAPVCC, DISPLAY_ADDR)) {
        DBGLN("[DISP] ❌ Init failed");
        sys.displayInitialized = false;
        sys.lastDisplayRetry   = millis();
        return;
    }

    // [OLED-7] Set flag BEFORE drawing
    sys.displayInitialized = true;
    sys.splashActive       = true;
    sys.splashStart        = millis();

    drawSplashScreen();
    display.display();

    DBGLN("[DISP] ✅ Ready (SSD1306 @ 400kHz)");
}

void retryDisplayInit() {
    if (sys.displayInitialized) return;
    if (!isTimeout(sys.lastDisplayRetry, DISPLAY_RETRY_MS)) return;
    DBGLN("[DISP] Retry...");
    setupDisplay();
}

// ============================================================================
// TIME SETUP — called from main loop (NOT from WiFi ISR)
// [WIFI-3] onWiFiEvent sets timeSyncNeeded=true; updateTime() calls setupTime()
//          from safe main-loop context (BUG-06 from BD1)
// ============================================================================
void setupTime() {
    if (!sys.wifiOk) return;
    DBGLN("[TIME] Configuring NTP (GMT+6)...");
    configTime(BD_TZ_OFFSET, BD_DST, "pool.ntp.org", "time.nist.gov");
    sys.lastTimeSync   = millis();
    sys.timeInitialized = false;
    sys.timeSyncNeeded  = false;
    DBGLN("[TIME] ✅ NTP configured");
}

void updateTime() {
    if (!sys.wifiOk) return;
    if (sys.timeSyncNeeded) { setupTime(); return; }
    if (!sys.timeInitialized) {
        if (getLocalTime(&sys.timeInfo)) {
            sys.timeInitialized = true;
            DBGLN("[TIME] ✅ Synchronized");
        }
        return;
    }
    if (isTimeout(sys.lastTimeSync, TIME_SYNC_MS)) {
        if (getLocalTime(&sys.timeInfo)) sys.lastTimeSync = millis();
    }
    // [OLED-8] getLocalTime only at display refresh rate — not every loop
    if (isTimeout(sys.lastDisplayUpdate, DISPLAY_UPDATE_MS))
        getLocalTime(&sys.timeInfo);
}

// ============================================================================
// WIFI SETUP
// BUG-16 (BD1): WiFi.setAutoConnect() removed (deprecated in Arduino 2.x)
// ============================================================================
void setupWiFi() {
    DBGLN("[WIFI] Initializing...");
    WiFi.mode(WIFI_STA);
    WiFi.setAutoReconnect(false);  // Manual reconnect via handleWiFiReconnect()
    WiFi.onEvent(onWiFiEvent);

    sys.wifiRetryDelay = WIFI_RETRY_BASE_MS;
    sys.wifiNextRetry  = millis() + WIFI_RETRY_BASE_MS;
}

// ============================================================================
// WIFI EVENT HANDLER
// [WIFI-2] WDT fed at entry (SEC-FIX-5)
// [WIFI-3] timeSyncNeeded flag — NTP deferred from ISR context (BUG-06)
// ============================================================================
void onWiFiEvent(WiFiEvent_t event) {
    esp_task_wdt_reset();  // [WIFI-2] feed WDT inside callback
    switch (event) {
        case ARDUINO_EVENT_WIFI_STA_GOT_IP:
            sys.wifiOk          = true;
            sys.wifiRetryCount  = 0;
            sys.wifiRetryDelay  = WIFI_RETRY_BASE_MS;
            sys.wifiCircuitOpen = false;
            sys.provRunning     = false;
            sys.timeSyncNeeded  = true;  // [WIFI-3] safe deferred NTP
            digitalWrite(LED_WIFI_PIN, HIGH);
            sys.displayNeedsUpdate = true;
            if (!sys.muted) playSuccess();
            DBGF("[WIFI] ✅ Connected — IP: %s\n", WiFi.localIP().toString().c_str());
            break;

        case ARDUINO_EVENT_WIFI_STA_DISCONNECTED:
            sys.wifiOk          = false;
            sys.timeInitialized = false;
            sys.wifiReconnects++;
            digitalWrite(LED_WIFI_PIN, LOW);
            sys.wifiNextRetry      = millis() + sys.wifiRetryDelay;
            sys.displayNeedsUpdate = true;
            DBGF("[WIFI] ❌ Lost — retry in %us\n", (unsigned)(sys.wifiRetryDelay/1000));
            break;

        default:
            break;
    }
}

// [WIFI-1] WiFi circuit breaker pattern (BD1 pattern)
void handleWiFiReconnect() {
    if (sys.wifiOk) return;
    if (sys.provRunning) return;

    if (sys.wifiCircuitOpen) {
        if (millis() >= sys.wifiNextRetry) {
            sys.wifiCircuitOpen = false;
            sys.wifiRetryCount  = 0;
            sys.wifiRetryDelay  = WIFI_RETRY_BASE_MS;
            DBGLN("[WIFI] Circuit breaker reset — resuming retries");
        }
        return;
    }

    if (millis() < sys.wifiNextRetry) {
        // Blink LED when disconnected and not circuit-broken
        static uint32_t ledT = 0;
        if (isTimeout(ledT, 500)) {
            ledT = millis();
            digitalWrite(LED_WIFI_PIN, !digitalRead(LED_WIFI_PIN));
        }
        return;
    }

    if (sys.wifiRetryCount < MAX_WIFI_RETRY) {
        DBGF("[WIFI] Retry %d/%d\n", sys.wifiRetryCount + 1, MAX_WIFI_RETRY);
        WiFi.reconnect();
        sys.wifiRetryCount++;
        sys.wifiRetryDelay = min(sys.wifiRetryDelay * 2, (uint32_t)WIFI_RETRY_MAX_MS);
        sys.wifiNextRetry  = millis() + sys.wifiRetryDelay;
    } else {
        sys.wifiCircuitOpen = true;
        sys.wifiNextRetry   = millis() + WIFI_CB_PAUSE;  // [ARCH-4]
        DBGLN("[WIFI] Circuit breaker OPEN — pause 5 min");
    }
}

// ============================================================================
// PROVISIONING EVENT HANDLER — [WIFI-2] WDT fed at entry (SEC-FIX-5)
// ============================================================================
void SysProvEvent(arduino_event_t* evt) {
    esp_task_wdt_reset();  // [WIFI-2]
    switch (evt->event_id) {
        case ARDUINO_EVENT_PROV_START:
            sys.provState      = PROV_WAITING;
            sys.provRunning    = true;
            sys.displayNeedsUpdate = true;
            DBGLN("[PROV] 🔵 Started — Open SmartIoT app → WiFi Provisioning");
            // [FIX-PROV-1] Removed delay()-based LED blink from event callback.
            // delay() in a WiFi event ISR starves the event loop and can cause
            // watchdog resets. LED blink is now handled non-blocking in loop().
            digitalWrite(LED_WIFI_PIN, HIGH);  // simple ON signal
            break;

        case ARDUINO_EVENT_PROV_CRED_RECV: {
            const char* ssid = (const char*)evt->event_info.prov_cred_recv.ssid;
            DBGF("[PROV] 📥 Credentials received: SSID=%s\n", ssid);
            // [FIX-REASON-201] Switch radio to WiFi priority NOW — before
            // wifi_prov_mgr attempts to connect. Keeping BLE priority here
            // causes reason 201 (NO_AP_FOUND) because the WiFi radio cannot
            // complete the connection scan while BLE holds the antenna.
            esp_coex_preference_set(ESP_COEX_PREFER_WIFI);
            // [FIX-AUTHMODE] Lower authmode threshold to WPA2 so ESP32
            // accepts WPA2-only routers (reason 201 also fires if threshold
            // is set higher than the AP actually offers).
            wifi_config_t current_conf;
            if (esp_wifi_get_config(WIFI_IF_STA, &current_conf) == ESP_OK) {
                current_conf.sta.threshold.authmode = WIFI_AUTH_WPA2_PSK;
                current_conf.sta.scan_method        = WIFI_ALL_CHANNEL_SCAN;
                current_conf.sta.sort_method        = WIFI_CONNECT_AP_BY_SIGNAL;
                esp_wifi_set_config(WIFI_IF_STA, &current_conf);
            }
            break;
        }

        case ARDUINO_EVENT_PROV_CRED_SUCCESS:
            sys.provState   = PROV_SUCCESS;
            sys.provDone    = true;
            g_provisioned   = true;
            markStateDirty();
            saveState(true);
            if (!sys.muted) playSuccess();
            sys.displayNeedsUpdate = true;
            // [FIX-BLE-WIFI-COEX] Restore WiFi priority now that BLE
            // provisioning is complete and WiFi needs to connect.
            esp_coex_preference_set(ESP_COEX_PREFER_WIFI);
            DBGLN("[PROV] ✅ Success — WiFi connecting...");
            break;

        case ARDUINO_EVENT_PROV_CRED_FAIL:
            sys.provState = PROV_FAILED;
            if (!sys.muted) playAlert();
            sys.displayNeedsUpdate = true;
            DBGLN("[PROV] ❌ Failed — credential error, retrying...");
            // [FIX-LOGIC-1] Use timestamp instead of delay() inside event callback.
            // delay() inside a WiFi event handler can starve the event loop.
            // [FIX-PROV-SESSION] Use provFailMs (NOT provStartMs) so the overall
            // 5-minute provisioning timeout clock is NOT reset on each CRED_FAIL.
            // handleProvisioning() resets PROV_FAILED → PROV_WAITING after 1.5s.
            sys.provFailMs = millis();  // separate fail timer for 1.5s retry delay
            break;

        case ARDUINO_EVENT_PROV_END:
            sys.provRunning = false;
            DBGLN("[PROV] 🏁 Complete — BLE stack freed");
            break;

        case ARDUINO_EVENT_WIFI_STA_GOT_IP:
            onWiFiEvent(ARDUINO_EVENT_WIFI_STA_GOT_IP);
            break;

        case ARDUINO_EVENT_WIFI_STA_DISCONNECTED:
            if (!sys.provRunning) onWiFiEvent(ARDUINO_EVENT_WIFI_STA_DISCONNECTED);
            break;

        default:
            break;
    }
}

void startProvisioning(bool resetSaved) {
    // [FIX-SERIAL v8.2.7] Full serial in BLE service name.
    // substring(0,6) was giving Flutter "SWT-9C" instead of "SWT-9C64A71AD6B8".
    // Flutter registered device_owners/SWT-9C and listened to devices/SWT-9C/status
    // — never matching the ESP32's actual RTDB path → dashboard always empty.
    // BLE advertising supports 31 bytes; "PROV_SmartIoT_SWT-9C64A71AD6B8" = 30 chars ✓
    String svcName = "PROV_SmartIoT_" + String(g_chipSerial);

    // Show provisioning screen — PoP NOT shown ([SEC-3])
    sys.provState   = PROV_WAITING;
    sys.provStartMs = millis();
    sys.provRunning = true;
    sys.displayNeedsUpdate = true;

    DBGF("[PROV] Starting BLE: %s  reset=%d\n", svcName.c_str(), resetSaved);

    // [BUG-1] WiFi.onEvent() registered BEFORE beginProvision()
    WiFi.onEvent(SysProvEvent);

    uint8_t uuid[16] = {0xb4,0xdf,0x5a,0x1c,0x3f,0x6b,0xf4,0xbf,
                        0xea,0x4a,0x82,0x03,0x04,0x90,0x1a,0x02};

    // [FIX-PROV-SESSION] Tear down any previous IDF wifi_prov_mgr session
    // before starting a new one. wifi_prov_mgr_deinit() is a no-op on first
    // boot and cleanly resets the manager on any retry (factory reset, second
    // provision attempt). Without this, beginProvision() silently fails on the
    // second call and Flutter gets "Failed to create session" (E1).
    // NOTE: WiFiProv.endProvision() does not exist in arduino-esp32 <=2.x
    // Suppress false "Provisioning manager not initialized" log on first boot
    // (wifi_prov_mgr_deinit is a no-op if not initialized — IDF still logs E)
    esp_log_level_set("wifi_prov_mgr", ESP_LOG_NONE);
    wifi_prov_mgr_deinit();
    esp_log_level_set("wifi_prov_mgr", ESP_LOG_ERROR);
    delay(200);  // let IDF BLE stack finish internal cleanup

    // ── [FIX-BLE-WIFI-COEX] ─────────────────────────────────────────────────
    // During provisioning the ESP32 WiFi scan shares the same radio as BLE.
    // Without coexistence preference, WiFi scan causes BLE GATT to drop,
    // which makes Flutter throw "Failed to create session" (E1) every time.
    // ESP_COEX_PREFER_BT gives BLE higher priority so the GATT connection
    // stays alive during WiFi scan. Restored to PREFER_WIFI after success.
    // [FIX-2.4GHZ] ESP32 supports both 2.4GHz and 5GHz scan but can ONLY
    // connect to 2.4GHz (802.11b/g/n). On dual-band routers with same SSID,
    // ESP32 may detect 5GHz entry during scan but fail to connect (reason 201).
    // Force STA mode to 2.4GHz protocols only so connection always succeeds.
    esp_wifi_set_protocol(WIFI_IF_STA,
        WIFI_PROTOCOL_11B | WIFI_PROTOCOL_11G | WIFI_PROTOCOL_11N);

    esp_coex_preference_set(ESP_COEX_PREFER_BT);

    // ── [FIX-PAIRING-DIALOG] ────────────────────────────────────────────────
    // Some Android phones show a "Bluetooth pairing request" dialog when the
    // app connects to the ESP32 BLE GATT server. WiFi provisioning uses its
    // own application-level security (PoP), NOT Bluetooth Classic pairing.
    // Accepting the pairing dialog changes GATT link security and breaks the
    // provisioning protocol. These two calls tell the BLE stack to refuse
    // pairing requests, so Android never shows the dialog.
    esp_ble_auth_req_t authReq = ESP_LE_AUTH_NO_BOND;
    esp_ble_gap_set_security_param(ESP_BLE_SM_AUTHEN_REQ_MODE,
                                   &authReq, sizeof(uint8_t));
    uint8_t ioCap = ESP_IO_CAP_NONE;
    esp_ble_gap_set_security_param(ESP_BLE_SM_IOCAP_MODE,
                                   &ioCap, sizeof(uint8_t));

    WiFiProv.beginProvision(
        WIFI_PROV_SCHEME_BLE,
        WIFI_PROV_SCHEME_HANDLER_FREE_BLE,
        WIFI_PROV_SECURITY_1,
        PROV_POP,           // PoP from secrets.h
        svcName.c_str(),
        NULL,
        uuid
    );
}

void handleProvisioning() {
    if (!sys.provRunning) return;
    // [FIX-LOGIC-1] Reset PROV_FAILED → PROV_WAITING after 1500ms
    // (replaces delay(1500) that was inside WiFi event callback)
    if (sys.provState == PROV_FAILED && isTimeout(sys.provFailMs, 1500)) {
        sys.provState   = PROV_WAITING;
        // [FIX-PROV-SESSION] Do NOT reset provStartMs here — the overall 5-minute
        // timeout must count from when provisioning started, not from last failure.
        sys.displayNeedsUpdate = true;
        DBGLN("[PROV] 🔄 Retry ready");
        return;
    }
    if (isTimeout(sys.provStartMs, PROV_TIMEOUT_MS)) {
        sys.provState   = PROV_FAILED;
        sys.provRunning = false;
        sendNotification("⚠️ WiFi Setup Timeout — Press Reset to retry");
        sys.displayNeedsUpdate = true;
        DBGLN("[PROV] ⚠️ Timeout");
    }
    sys.displayNeedsUpdate = true;
}

// ============================================================================
// STATE PERSISTENCE — CRC32 validated, flash wear protected
// ============================================================================

// [SAVE-1] Load from NVS Preferences
bool loadState() {
    DBGLN("[STATE] Loading...");
    prefs.begin("tank", true);

    PersistentState loaded;
    size_t len = prefs.getBytes("state", &loaded, sizeof(PersistentState));

    if (len == sizeof(PersistentState)) {
        // [SAVE-3] offsetof for layout-safe CRC (BUG-09)
        uint32_t calcCRC = calculateCRC32(&loaded, offsetof(PersistentState, crc32));
        if (calcCRC == loaded.crc32 && loaded.version == STATE_VERSION) {
            sys.pumpMode      = (PumpMode)loaded.pumpMode;
            sys.muted         = loaded.muted;
            sys.pumpCycles    = loaded.pumpCycles;
            sys.pumpTotalS    = loaded.pumpTotalS;
            sys.bootCount     = loaded.bootCount + 1;
            sys.wifiReconnects = loaded.wifiReconnects;
            memcpy(g_chipSerial, loaded.chipSerial, sizeof(g_chipSerial));
            g_provisioned     = loaded.provisioned;

            lastSavedState             = loaded;
            lastSavedState.bootCount   = sys.bootCount;

            prefs.end();
            DBGF("[STATE] ✅ Valid (v%u) Boot#%u Mode=%s\n",
                 (unsigned)loaded.version, (unsigned)sys.bootCount,
                 sys.pumpMode == MODE_AUTO ? "AUTO" : "MANUAL");
            return true;
        }
        DBGLN("[STATE] ⚠️ CRC/Version mismatch — using defaults");
    } else {
        DBGLN("[STATE] ⚠️ No saved state — using defaults");
    }

    g_provisioned = prefs.getBool("prov", false);
    prefs.end();

    // Defaults
    sys.pumpMode       = MODE_AUTO;
    sys.muted          = false;
    sys.pumpCycles     = 0;
    sys.pumpTotalS     = 0;
    sys.bootCount      = 1;
    sys.wifiReconnects = 0;

    if (g_chipSerial[0] == 0) genSerial(g_chipSerial);
    return false;
}

void markStateDirty() { sys.stateDirty = true; }

// [SAVE-2] Flash wear protection: only write if data changed AND interval elapsed
void saveState(bool force) {
    if (!force && !sys.stateDirty) return;
    if (!force && !isTimeout(sys.lastStateSaveMs, STATE_SAVE_MIN_MS)) return;

    PersistentState current;
    current.version        = STATE_VERSION;
    current.pumpMode       = sys.pumpMode;
    current.muted          = sys.muted;
    current.pumpCycles     = sys.pumpCycles;
    current.pumpTotalS     = sys.pumpTotalS;
    current.bootCount      = sys.bootCount;
    current.wifiReconnects = sys.wifiReconnects;
    memcpy(current.chipSerial, g_chipSerial, sizeof(current.chipSerial));
    current.provisioned    = g_provisioned;

    // [SAVE-3] offsetof for layout-safe memcmp (BUG-09)
    if (!force && memcmp(&current, &lastSavedState,
                         offsetof(PersistentState, crc32)) == 0) {
        sys.stateDirty = false;
        return;
    }

    current.crc32 = calculateCRC32(&current, offsetof(PersistentState, crc32));

    prefs.begin("tank", false);
    prefs.putBytes("state", &current, sizeof(PersistentState));
    prefs.end();

    lastSavedState       = current;
    sys.stateDirty       = false;
    sys.lastStateSaveMs  = millis();
    sys.flashWrites++;

    DBGF("[STATE] ✅ Saved (Total writes: %u)\n", (unsigned)sys.flashWrites);
}

// ============================================================================
// SENSOR READING
// ============================================================================

// [BUG-FIX-13] pinMajority: count HIGH samples in the circular buffer.
// Parameter is the sample buffer (not the pin number).
bool pinMajority(uint8_t /*pin*/, const uint8_t* buf) {
    int count = 0;
    for (int i = 0; i < SENSOR_SAMPLES; i++) count += buf[i];
    return count >= SENSOR_MAJORITY;
}

// Read float sensors into buffer and apply debounce
WaterLevel readFloatSensors() {
    uint8_t idx = sensors.index;
    // Active-LOW: pin goes LOW when float is in water
    sensors.lowSamples [idx] = !digitalRead(FLOAT_LOW_PIN);
    sensors.midSamples [idx] = !digitalRead(FLOAT_MID_PIN);
    sensors.fullSamples[idx] = !digitalRead(FLOAT_FULL_PIN);
    sensors.index = (idx + 1) % SENSOR_SAMPLES;

    // [BUG-FIX-13] pass the correct per-pin buffer to pinMajority
    bool low  = pinMajority(FLOAT_LOW_PIN,  sensors.lowSamples);
    bool mid  = pinMajority(FLOAT_MID_PIN,  sensors.midSamples);
    bool full = pinMajority(FLOAT_FULL_PIN, sensors.fullSamples);

    // [SENS-2] Full sensor always wins (BD1 BUG-05)
    if (full) return LVL_FULL;
    if (mid)  return LVL_MID;
    if (low)  return LVL_LOW;
    return LVL_EMPTY;
}

int readUltrasonicPct() {
    g_usMeasDone = false;
    g_usState    = US_TRIGGERED;
    digitalWrite(TRIG_PIN, LOW);  delayMicroseconds(2);
    digitalWrite(TRIG_PIN, HIGH); delayMicroseconds(10);
    digitalWrite(TRIG_PIN, LOW);
    uint32_t t0 = millis();
    while (!g_usMeasDone && millis() - t0 < 30) delayMicroseconds(100);
    g_usState = US_IDLE;
    if (!g_usMeasDone) return -1;
    float dist = (float)g_usDuration / 58.0f;
    return (int)constrain(map((long)dist, US_EMPTY_CM, US_FULL_CM, 0, 100), 0, 100);
}

static int floatLevelToPct(WaterLevel l) {
    switch (l) {
        case LVL_FULL:  return 100;
        case LVL_MID:   return 60;
        case LVL_LOW:   return 25;
        default:        return 5;
    }
}

void readSensors() {
    if (!isTimeout(sys.lastSensorRead, SENSOR_READ_MS)) return;
    sys.lastSensorRead = millis();

    if (digitalRead(TOGGLE_MODE_PIN) == HIGH) {
        sys.sensorMode = SENSOR_ULTRA;
        int p = readUltrasonicPct();
        if (p >= 0) {
            sys.waterPct   = p;
            sys.waterLevel = p >= 90 ? LVL_FULL :
                             p >= 50 ? LVL_MID  :
                             p >= 20 ? LVL_LOW  : LVL_EMPTY;
        }
    } else {
        sys.sensorMode = SENSOR_FLOAT;
        sys.waterLevel = readFloatSensors();
        sys.waterPct   = floatLevelToPct(sys.waterLevel);
    }

    sys.alarmActive = (sys.waterPct <= 10 || sys.dryRunActive);
}

// ============================================================================
// PUMP CONTROL
// [PUMP-3] Min-ON guard uses pumpStartMs (BUG-05)
// [PUMP-1] levelAtPumpStart set ONCE here, never mutated
// ============================================================================
void setPump(bool on) {
    if (on == (sys.pumpState == PUMP_ON)) return;
    uint32_t now = millis();

    if (on) {
        if (sys.pumpStopMs > 0 && !isTimeout(sys.pumpStopMs, PUMP_MIN_OFF_MS)) {
            DBGLN("[PUMP] ⚠️ Min OFF time not met");
            return;
        }
        sys.pumpState      = PUMP_ON;
        sys.pumpStartMs    = now;
        sys.pumpStopMs     = 0;
        sys.pumpCycles++;
        // [PUMP-1] Set ONCE here — never touched in updateAutoMode()
        sys.levelAtPumpStart = sys.waterLevel;
        digitalWrite(PUMP_RELAY_PIN, RELAY_ON);
        digitalWrite(LED_PUMP_PIN, HIGH);
        if (!sys.muted) playTone(1500, 100);
        markStateDirty();
        sys.displayNeedsUpdate = true;
        DBGLN("[PUMP] ✅ ON");
    } else {
        // [PUMP-3] Min-ON guard uses pumpStartMs (not pumpStopMs)
        if (sys.pumpStartMs > 0 && !sys.pumpStopRequested) {
            if (!isTimeout(sys.pumpStartMs, PUMP_MIN_ON_MS)) {
                if (sys.waterLevel != LVL_FULL) {
                    DBGLN("[PUMP] ⚠️ Min ON time not met");
                    return;
                }
            }
        }
        uint32_t runMs = (sys.pumpStartMs > 0) ? now - sys.pumpStartMs : 0;
        sys.pumpTotalS += runMs / 1000UL;
        sys.pumpState        = PUMP_OFF;
        sys.pumpStopMs       = now;
        sys.pumpStartMs      = 0;
        sys.pumpStopRequested = false;
        sys.pumpRunMs        = 0;
        digitalWrite(PUMP_RELAY_PIN, RELAY_OFF);
        digitalWrite(LED_PUMP_PIN, LOW);
        if (!sys.muted) playTone(1000, 100);
        markStateDirty();
        sys.displayNeedsUpdate = true;
        savePumpStats();
        DBGLN("[PUMP] ⏸️ OFF");
    }
}

void updateAutoMode() {
    if (sys.pumpMode != MODE_AUTO) return;

    // Safety: manual FULL stop (even in AUTO)
    if (sys.pumpState == PUMP_ON && sys.waterLevel == LVL_FULL) {
        setPump(false);
        sendNotification("Tank FULL — Pump OFF");
        if (!sys.muted) playSuccess();
        return;
    }

    // [PUMP-5] Max run time — rollover-safe (BUG-03)
    if (sys.pumpState == PUMP_ON &&
        sys.pumpStartMs > 0 &&
        isTimeout(sys.pumpStartMs, PUMP_MAX_RUN_MS)) {
        setPump(false);
        sendNotification("⚠️ Max Runtime Exceeded!");
        if (!sys.muted) playAlert();
        DBGLN("[AUTO] Max runtime — force OFF");
        return;
    }

    // [PUMP-2] Dry-run: check waterLevel==EMPTY directly (BUG-02)
    if (sys.pumpState == PUMP_ON && !sys.dryRunActive &&
        sys.pumpStartMs > 0 &&
        isTimeout(sys.pumpStartMs, DRY_RUN_TIMEOUT_MS) &&
        sys.waterLevel == LVL_EMPTY) {
        sys.dryRunActive = true;
        sys.dryRunStopMs = millis();
        sys.alarmActive  = true;
        setPump(false);
        sendNotification("⚠️ DRY RUN! Check water source.");
        if (!sys.muted) playAlert();
        DBGF("[AUTO] DRY-RUN protection! levelAtStart=%d\n", sys.levelAtPumpStart);
        return;
    }

    // Dry-run cooldown
    if (sys.dryRunActive) {
        if (isTimeout(sys.dryRunStopMs, DRY_RUN_COOLDOWN_MS)) {
            sys.dryRunActive = false;
            sys.alarmActive  = false;
            sendNotification("Dry-run cleared — AUTO retry");
            DBGLN("[AUTO] Dry-run cooldown complete");
        }
        return;
    }

    // Normal AUTO thresholds
    if (sys.waterPct <= PUMP_AUTO_ON_PCT  && sys.pumpState == PUMP_OFF) setPump(true);
    if (sys.waterPct >= PUMP_AUTO_OFF_PCT && sys.pumpState == PUMP_ON)  setPump(false);
}

// ============================================================================
// NON-BLOCKING BUZZER SEQUENCER (BD1 BUZZ pattern)
// [BUZZ-1] Multi-step sequences via freq+dur+gap arrays
// [BUZZ-2] All tones through this — no raw tone() conflicts
// ============================================================================
void _startBuzzerSeq(const uint16_t* f, const uint16_t* d,
                     const uint16_t* g, uint8_t n) {
    if (sys.muted || !f || !d || !g || n == 0) return;
    if (n > 6) n = 6;
    buzzerJob.total   = n;
    buzzerJob.step    = 0;
    buzzerJob.inPause = false;
    buzzerJob.nextAt  = millis();
    buzzerJob.active  = true;
    for (uint8_t i = 0; i < n; i++) {
        buzzerJob.freqs[i] = f[i];
        buzzerJob.durs[i]  = d[i];
        buzzerJob.gaps[i]  = g[i];
    }
}

void updateBuzzer() {
    if (!buzzerJob.active) return;
    if (millis() < buzzerJob.nextAt) return;
    if (!buzzerJob.inPause) {
        tone(BUZZER_PIN, buzzerJob.freqs[buzzerJob.step],
                         buzzerJob.durs[buzzerJob.step]);
        buzzerJob.nextAt  = millis() + buzzerJob.durs[buzzerJob.step];
        buzzerJob.inPause = true;
    } else {
        uint16_t gap = buzzerJob.gaps[buzzerJob.step];
        buzzerJob.step++;
        if (buzzerJob.step >= buzzerJob.total) {
            buzzerJob.active  = false;
            buzzerJob.inPause = false;
        } else {
            buzzerJob.nextAt  = millis() + gap;
            buzzerJob.inPause = false;
        }
    }
}

void playTone(uint16_t freq, uint16_t dur) {
    if (sys.muted) return;
    static uint16_t f[1], d[1], g[1];
    f[0] = freq; d[0] = dur; g[0] = 0;
    _startBuzzerSeq(f, d, g, 1);
}

void playStartup() {
    static const uint16_t f[] = {1000, 1500, 2000};
    static const uint16_t d[] = {150,  150,  250};
    static const uint16_t g[] = {200,  200,  0};
    _startBuzzerSeq(f, d, g, 3);
}

void playSuccess() {
    static const uint16_t f[] = {2000, 2500};
    static const uint16_t d[] = {100,  150};
    static const uint16_t g[] = {150,  0};
    _startBuzzerSeq(f, d, g, 2);
}

void playAlert() {
    static const uint16_t f[] = {500, 500, 500};
    static const uint16_t d[] = {200, 200, 200};
    static const uint16_t g[] = {250, 250, 0};
    _startBuzzerSeq(f, d, g, 3);
}

// ============================================================================
// BUTTON HANDLING — [BTN-1] Stable 50ms state machine (BD1 BTN pattern)
// ============================================================================
bool checkButton(ButtonState& btn, uint8_t pin) {
    bool current = (digitalRead(pin) == LOW);
    uint32_t now = millis();
    if (current != btn.currentReading) {
        btn.currentReading = current;
        btn.lastChange     = now;
        btn.stableTime     = 0;
    } else {
        btn.stableTime = now - btn.lastChange;
    }
    if (btn.stableTime >= BUTTON_STABLE_TIME && btn.stableState != btn.currentReading) {
        btn.stableState = btn.currentReading;
        if (btn.stableState && !btn.lastReported) {
            btn.lastReported = true;
            return true;  // Rising edge — button just pressed
        } else if (!btn.stableState) {
            btn.lastReported = false;
        }
    }
    return false;
}

void handleButtons() {
    // ── MODE button — short press: toggle AUTO/MANUAL ────────────────────────
    if (checkButton(btnMode, BTN_MODE_PIN)) {
        sys.pumpMode = (sys.pumpMode == MODE_AUTO) ? MODE_MANUAL : MODE_AUTO;
        char msg[48];
        snprintf(msg, sizeof(msg), "Mode: %s",
                 sys.pumpMode == MODE_AUTO ? "AUTO" : "MANUAL");
        sendNotification(msg);
        if (!sys.muted) playTone(1500, 100);
        markStateDirty();
        sys.displayNeedsUpdate = true;
        DBGF("[BTN] Mode → %s\n", sys.pumpMode == MODE_AUTO ? "AUTO" : "MANUAL");
    }

    // ── MODE button — long press (>2s): cycle OLED screen ───────────────────
    {
        static uint32_t lStart = 0;
        static bool cycled = false;
        if (digitalRead(BTN_MODE_PIN) == LOW) {
            if (!lStart) lStart = millis();
            if (!cycled && millis() - lStart > 2000) {
                // Cycle through content screens (skip SPLASH)
                uint8_t next = sys.oledScreen + 1;
                if (next > OLED_INFO) next = OLED_MAIN;
                sys.oledScreen = (OledScreen)next;
                sys.displayNeedsUpdate = true;
                cycled = true;
                if (!sys.muted) playTone(2000, 50);
                DBGF("[BTN] OLED screen → %d\n", sys.oledScreen);
            }
        } else {
            lStart = 0;
            cycled = false;
        }
    }

    // ── PUMP button — manual pump toggle ────────────────────────────────────
    if (checkButton(btnPump, BTN_PUMP_PIN)) {
        if (sys.pumpMode == MODE_MANUAL) {
            if (sys.dryRunActive) {
                sendNotification("⚠️ Dry Run Active! Check source first.");
                if (!sys.muted) playAlert();
                sys.dryRunActive = false;  // Second press clears flag
                DBGLN("[BTN] Pump blocked — dry run active; flag cleared");
                return;
            }
            if (sys.pumpState == PUMP_OFF) {
                setPump(true);
                sendNotification(sys.pumpState == PUMP_ON
                    ? "Pump: ON" : "⚠️ Pump cooling down");
            } else {
                sys.pumpStopRequested = true;
                setPump(false);
                sendNotification(sys.pumpState == PUMP_OFF
                    ? "Pump: OFF" : "⚠️ Min runtime required");
            }
        } else {
            sendNotification("Manual ctrl disabled in AUTO mode");
            if (!sys.muted) playTone(800, 200);
        }
        DBGF("[BTN] Pump → %s\n", sys.pumpState == PUMP_ON ? "ON" : "OFF");
    }

    // ── MUTE button — toggle buzzer ──────────────────────────────────────────
    if (checkButton(btnMute, BTN_MUTE_PIN)) {
        sys.muted = !sys.muted;
        char msg[32];
        snprintf(msg, sizeof(msg), "Buzzer: %s", sys.muted ? "MUTED" : "ON");
        sendNotification(msg);
        if (!sys.muted) playTone(2000, 50);  // confirmation beep
        markStateDirty();
        DBGF("[BTN] Mute → %s\n", sys.muted ? "MUTED" : "ON");
    }
}

// ============================================================================
// FIREBASE HTTPS
// [BUG-3] Local WiFiClientSecure per call (NOT shared global)
// [BUG-6] PATCH via http.sendRequest("PATCH")
// [v8.0.0 CRIT-FIX] Firebase RTDB REST auth corrected:
//   Firebase RTDB Legacy DB Secret MUST be sent as ?auth= query parameter.
//   Authorization: Bearer is for OAuth2 tokens ONLY — DB Secret is NOT OAuth2.
//   Using Bearer with DB Secret → HTTP 401 on every request (was broken in v7).
// ============================================================================
static String fbURL(const String& path) {
    // Auth via ?auth= query param — only way Firebase RTDB accepts Legacy DB Secret
    return "https://" + String(FIREBASE_HOST) + path +
           ".json?auth=" + String(FIREBASE_DB_SECRET);
}

bool fbGET(const String& path, DynamicJsonDocument& doc) {
    if (!sys.wifiOk) return false;
    WiFiClientSecure cli;
    // [SEC-FIX] Pin Google GTS Root R1 CA (valid until 2036).
    // Root CA stays stable even when Google rotates intermediate CAs.
    // This prevents MITM attacks while maintaining reliable TLS.
    cli.setCACert(GOOGLE_ROOT_CA);
    HTTPClient http;
    http.begin(cli, fbURL(path));
    http.setTimeout(10000);
    int code = http.GET();
    bool ok = (code == HTTP_CODE_OK) && !deserializeJson(doc, http.getStream());
    if (!ok) DBGF("[FB] GET %d %s\n", code, path.c_str());
    http.end();
    return ok;
}

bool fbPATCH(const String& path, const String& body) {
    if (!sys.wifiOk) return false;
    WiFiClientSecure cli;
    cli.setCACert(GOOGLE_ROOT_CA); // [SEC-FIX] Root CA pinned — GTS R1 valid until 2036
    HTTPClient http;
    http.begin(cli, fbURL(path));
    http.addHeader("Content-Type", "application/json");
    http.setTimeout(10000);
    int code = http.sendRequest("PATCH", (uint8_t*)body.c_str(), body.length());
    http.end();
    bool ok = (code == HTTP_CODE_OK || code == 204);
    if (!ok) DBGF("[FB] PATCH %d %s\n", code, path.c_str());
    return ok;
}

void pushStatus() {
    sys.rssi = (int8_t)WiFi.RSSI();
    char upStr[24]; getUptime(upStr, sizeof(upStr));
    char timeStr[20]; getBDTime(timeStr, sizeof(timeStr));

    char body[800];
    snprintf(body, sizeof(body),
        "{\"water_level\":\"%s\","
        "\"water_level_pct\":%d,"
        "\"pump\":\"%s\","
        "\"mode\":\"%s\","
        "\"sensor_mode\":\"%s\","
        "\"wifi_rssi\":%d,"
        "\"uptime\":\"%s\","
        "\"boot_count\":%u,"
        "\"pump_cycles\":%u,"
        "\"pump_total_s\":%u,"
        "\"alarm\":%s,"
        "\"dry_run\":%s,"
        "\"firmware\":\"%s\","
        "\"serial\":\"%s\","
        "\"heap_free\":%u,"
        "\"bd_time\":\"%s\","
        "\"ts\":%u,"
        "\"sleeping\":false}",
        sys.waterLevel==LVL_FULL?"FULL":sys.waterLevel==LVL_MID?"MID":
        sys.waterLevel==LVL_LOW?"LOW":"EMPTY",
        sys.waterPct,
        sys.pumpState==PUMP_ON?"ON":"OFF",
        sys.pumpMode==MODE_AUTO?"AUTO":"MANUAL",
        sys.sensorMode==SENSOR_ULTRA?"ULTRA":"FLOAT",
        sys.rssi, upStr,
        (unsigned)sys.bootCount, (unsigned)sys.pumpCycles, (unsigned)sys.pumpTotalS,
        sys.alarmActive?"true":"false",
        sys.dryRunActive?"true":"false",
        FIRMWARE_VER, g_chipSerial,
        (unsigned)ESP.getFreeHeap(), timeStr,
        (uint32_t)time(nullptr));

    String path = "/devices/" + String(g_chipSerial) + "/status";
    DBGF("[FB] push %s\n", fbPATCH(path, String(body)) ? "OK" : "FAIL");
}

void pollCommands() {
    String path = "/devices/" + String(g_chipSerial) + "/control";
    DynamicJsonDocument doc(1024);
    if (!fbGET(path, doc)) return;

    int ts = doc["cmd_ts"] | 0;
    if (ts <= sys.lastCmdTs) return;
    sys.lastCmdTs = ts;

    const char* pCmd = doc["pump_cmd"] | "";
    if (strlen(pCmd) > 0) {
        if (sys.pumpMode == MODE_MANUAL) {
            if (strcmp(pCmd, "ON")  == 0) setPump(true);
            if (strcmp(pCmd, "OFF") == 0) setPump(false);
        } else {
            // [FIX-DESIGN-1] Notify app that cmd was blocked (not silently dropped)
            sendNotification("App pump cmd ignored — AUTO mode active");
            DBGLN("[CMD] pump_cmd blocked — device is in AUTO mode");
        }
    }

    const char* mCmd = doc["mode_cmd"] | "";
    if (strcmp(mCmd, "AUTO")   == 0) { sys.pumpMode = MODE_AUTO;   markStateDirty(); }
    if (strcmp(mCmd, "MANUAL") == 0) { sys.pumpMode = MODE_MANUAL; markStateDirty(); }

    if (doc["dry_run_reset"] | false) {
        sys.dryRunActive = false;
        sys.alarmActive  = false;
        sendNotification("Dry-run reset via app");
    }

    if (doc["mute_cmd"] | false) {
        sys.muted = doc["mute_cmd"].as<bool>();
        markStateDirty();
    }

    // OTA — trusted Firebase Storage URLs only + SHA-256 check
    const char* ota = doc["ota_url"] | "";
    if (strlen(ota) > 10) {
        String u = String(ota);
        if (u.startsWith("https://firebasestorage.googleapis.com/") ||
            u.startsWith("https://storage.googleapis.com/")) {
            String sha256 = doc["ota_sha256"] | "";
            performOTA(u, sha256);
        } else {
            DBGLN("[OTA] REJECTED — untrusted URL");
        }
    }
}

// ============================================================================
// OTA FIRMWARE UPDATE — SHA-256 verification (v12 FIX HIGH-3 preserved)
// ============================================================================
void performOTA(const String& url, const String& expectedSha256) {
    // [FIX HIGH-2] SHA-256 is REQUIRED — reject unverified firmware
    if (expectedSha256.length() == 0) {
        DBGLN("[OTA] REJECTED — SHA-256 hash is required. Aborting for security.");
        sys.otaInProgress = false;
        return;
    }
    DBGLN("[OTA] Starting: " + url);
    sys.otaInProgress = true;

    if (sys.pumpState == PUMP_ON) setPump(false);
    saveState(true);

    WiFiClientSecure cli; cli.setCACert(GOOGLE_ROOT_CA); // [SEC-FIX] Root CA pinned
    HTTPClient http;      http.begin(cli, url);
    int code = http.GET();
    if (code != HTTP_CODE_OK) {
        DBGF("[OTA] HTTP %d\n", code);
        http.end();
        sys.otaInProgress = false;
        return;
    }

    int total = http.getSize();
    WiFiClient* s = http.getStreamPtr();
    if (!Update.begin(total > 0 ? total : UPDATE_SIZE_UNKNOWN)) {
        http.end();
        sys.otaInProgress = false;
        return;
    }

    mbedtls_sha256_context sha256ctx;
    mbedtls_sha256_init(&sha256ctx);
    mbedtls_sha256_starts(&sha256ctx, 0);

    uint8_t buf[1024];
    int written = 0;
    while (http.connected() && (total <= 0 || written < total)) {
        int av = s->available();
        if (av > 0) {
            int rd = s->readBytes(buf, min(av, (int)sizeof(buf)));
            mbedtls_sha256_update(&sha256ctx, buf, rd);
            Update.write(buf, rd);
            written += rd;
            if (total > 0) {
                int p = (written * 100) / total;
                drawOtaOverlay(p);
            }
        } else {
            delay(10);
        }
        esp_task_wdt_reset();
    }
    http.end();

    uint8_t hash[32];
    mbedtls_sha256_finish(&sha256ctx, hash);
    mbedtls_sha256_free(&sha256ctx);

    if (expectedSha256.length() == 64) {
        char computedHex[65];
        for (int i = 0; i < 32; i++) snprintf(computedHex + i*2, 3, "%02x", hash[i]);
        computedHex[64] = '\0';
        if (expectedSha256 != String(computedHex)) {
            DBGF("[OTA] CHECKSUM MISMATCH! expected=%s got=%s\n",
                 expectedSha256.c_str(), computedHex);
            Update.abort();
            sys.otaInProgress = false;
            return;
        }
        DBGLN("[OTA] ✅ SHA-256 OK");
    } else {
        // [FIX HIGH-2] This branch is now unreachable — performOTA() rejects
        // empty sha256 at entry. Kept as a safety net.
        DBGLN("[OTA] REJECTED — SHA-256 length invalid, aborting.");
        Update.abort();
        sys.otaInProgress = false;
        return;
    }

    if (Update.end(true)) { esp_task_wdt_reset(); delay(500); ESP.restart(); }
    else { DBGLN("[OTA] Error: " + String(Update.errorString())); }
    sys.otaInProgress = false;
}

void monitorOTA() {
    static bool wasUpdating = false;
    bool isUpdating = Update.isRunning();
    if (isUpdating && !wasUpdating) {
        sys.otaInProgress = true;
        if (sys.pumpState == PUMP_ON) setPump(false);
        saveState(true);
        sendNotification("⚡ OTA Update — Pump Disabled");
    }
    if (!isUpdating && wasUpdating) {
        sys.otaInProgress = false;
        DBGLN("[OTA] ✅ Complete");
    }
    wasUpdating = isUpdating;
}

// ============================================================================
// FACTORY RESET
// [SEC-1] Blocked if WiFi connected AND uptime > 60s (SEC-FIX-2)
// [BUG-2] prefs.clear() per namespace + WiFi.disconnect(true,true)
// ============================================================================
void checkFactoryReset() {
    // [SEC-1] Prevent accidental/malicious reset during normal operation
    if (sys.wifiOk && (millis() - sys.bootTime) > 60000) {
        sys.factoryResetStart    = 0;
        sys.factoryResetProgress = 0;
        return;
    }
    if (sys.factoryResetTriggered) return;

    if (digitalRead(BTN_RESET_PIN) == LOW) {
        if (sys.factoryResetStart == 0) {
            sys.factoryResetStart = millis();
            DBGLN("[RESET] Hold 10s for factory reset...");
        }

        uint32_t elapsed = millis() - sys.factoryResetStart;
        sys.factoryResetProgress = (uint8_t)min((elapsed * 100UL) / FACTORY_RESET_HOLD_MS, 100UL);

        // Feedback beeps at 20%, 40%, 60%, 80%
        // [BUG-FIX-BEEP] Edge-triggered: static tracks last milestone to avoid
        // continuous beeping every loop iteration while progress stays at 20/40/60/80.
        {
            static uint8_t lastBeepPct = 0;
            uint8_t milestone = (sys.factoryResetProgress / 20) * 20;
            if (milestone > 0 && milestone != lastBeepPct) {
                lastBeepPct = milestone;
                if (!sys.muted) tone(BUZZER_PIN, 2000, 50);
                sys.displayNeedsUpdate = true;
            }
            if (sys.factoryResetProgress == 0) lastBeepPct = 0;  // reset on release
        }

        if (isTimeout(sys.factoryResetStart, FACTORY_RESET_HOLD_MS)) {
            sys.factoryResetTriggered = true;
            DBGLN("[RESET] ⚠️ Factory reset triggered!");

            if (sys.pumpState == PUMP_ON) setPump(false);

            // [BUG-2] Safe: clear each namespace individually
            prefs.begin("stats", false); prefs.clear(); prefs.end();
            prefs.begin("tank",  false); prefs.clear(); prefs.end();
            prefs.begin("state", false); prefs.clear(); prefs.end();

            // Erase WiFiProv IDF NVS credentials
            WiFi.disconnect(true, true);
            // [FIX-FACTORY-RESET] wifi_prov_mgr stores credentials in its
            // own NVS namespace — WiFi.disconnect() alone does NOT clear it.
            // Without this call, ESP32 reconnects to old WiFi after reset.
            wifi_prov_mgr_reset_provisioning();

            drawDeepSleepScreen();  // reuse screen, then override
            if (sys.displayInitialized) {
                display.clearDisplay();
                display.setTextColor(SSD1306_WHITE);
                display.setTextSize(1);
                display.setCursor(5,  16); display.print("FACTORY RESET");
                display.setCursor(20, 28); display.print("COMPLETE");
                display.setCursor(15, 42); display.print("RESTARTING...");
                display.display();
            }

            for (int i = 0; i < 3; i++) {
                tone(BUZZER_PIN, 2000, 200);
                esp_task_wdt_reset();
                delay(300);
                esp_task_wdt_reset();
            }
            esp_task_wdt_reset();
            delay(500);  // [v8.0.0] reduced from 2000ms — prevents WDT timeout
            ESP.restart();
        }
    } else {
        sys.factoryResetStart    = 0;
        sys.factoryResetProgress = 0;
    }
}

// ============================================================================
// DEEP SLEEP — 30 min idle, pump off, no alarm
// ============================================================================
void checkDeepSleep() {
    // Reset activity timer on any button, alarm, or provisioning
    bool activity = (digitalRead(BTN_MODE_PIN) == LOW ||
                     digitalRead(BTN_PUMP_PIN) == LOW ||
                     digitalRead(BTN_MUTE_PIN) == LOW);
    if (activity || sys.alarmActive || sys.provRunning)
        sys.lastActivityMs = millis();

    if (!sys.wifiOk || sys.pumpState == PUMP_ON ||
        sys.alarmActive || sys.provRunning) return;

    if (!isTimeout(sys.lastActivityMs, DEEP_SLEEP_IDLE_MS)) return;

    DBGLN("[SLEEP] Entering deep sleep 30 min");

    // Mark sleeping in Firebase
    if (sys.wifiOk) {
        WiFiClientSecure c; c.setCACert(GOOGLE_ROOT_CA); // [SEC-FIX] Root CA pinned
        HTTPClient h;
        String path = "/devices/" + String(g_chipSerial) + "/status";
        h.begin(c, fbURL(path));
        h.addHeader("Content-Type", "application/json");
        h.setTimeout(5000);
        h.sendRequest("PATCH", "{\"sleeping\":true}");
        h.end();
    }

    drawDeepSleepScreen();
    delay(1000);

    esp_sleep_enable_timer_wakeup((uint64_t)DEEP_SLEEP_IDLE_MS * 1000ULL);
    esp_sleep_enable_ext0_wakeup((gpio_num_t)EMERGENCY_WAKEUP_PIN, 0);
    esp_deep_sleep_start();
}

// ============================================================================
// ════════════════════════════════════════════════════════════════════════════
//  OLED DISPLAY — COMPLETE UI  (SSD1306 128×64)
// ════════════════════════════════════════════════════════════════════════════
// ============================================================================

// Helper: draw WiFi signal-strength bars at (x,y), 4 bars, height 3-9px
void drawSignalBars(int x, int y, int8_t rssi) {
    if (!sys.wifiOk) {
        // X mark
        display.drawLine(x, y, x+5, y-5, SSD1306_WHITE);
        display.drawLine(x, y-5, x+5, y, SSD1306_WHITE);
        return;
    }
    int strength = (rssi >= -60) ? 4 : (rssi >= -70) ? 3 : (rssi >= -80) ? 2 : 1;
    for (int i = 0; i < 4; i++) {
        int h = (i + 1) * 2 + 1;
        int bx = x + i * 4;
        if (i < strength)
            display.fillRect(bx, y - h, 3, h, SSD1306_WHITE);
        else
            display.drawRect(bx, y - h, 3, h, SSD1306_WHITE);
    }
}

// ── 3D Animated Water Tank ─────────────────────────────────────────────────
// [OLED-7]  w=48, h=52 recommended; wave + shine + bubble animations
// [OLED-10] Pixel bounds checked before drawPixel
// [DISP-FIX-1] Pipe Y clamped to y+1 (was y-3, drew off-screen → flicker)
// [DISP-FIX-4] pct% label drawn inside tank bottom, not below it
void draw3DTank(int x, int y, int w, int h, uint8_t pct) {
    if (w <= 4 || h <= 8) return;
    if (x < 0 || y < 0) return;
    if (x + w > DISPLAY_W || y + h > DISPLAY_H) return;
    if (pct > 100) pct = 100;

    // ── Tank outer outline ────────────────────────────────────────────────
    display.drawRoundRect(x, y, w, h, 3, SSD1306_WHITE);

    // ── Top cap / rim effect ──────────────────────────────────────────────
    display.fillRect(x + 2, y, w - 4, 4, SSD1306_WHITE);
    display.fillRect(x + 4, y + 1, w - 8, 2, SSD1306_BLACK);

    // ── Pipe at top center — [DISP-FIX-1] clamped to display boundary ────
    int pipeX = x + w/2 - 2;
    int pipeY = max(0, y - 2);      // was y-3 → could be negative, causing flicker
    display.fillRect(pipeX, pipeY, 4, y + 2 - pipeY, SSD1306_WHITE);

    // ── Water fill ────────────────────────────────────────────────────────
    int innerH = h - 7;    // inside usable height (below rim, above base)
    int waterH = (innerH * pct) / 100;
    int waterY = y + h - 1 - waterH;

    if (waterH > 0) {
        display.fillRect(x + 1, waterY, w - 2, waterH, SSD1306_WHITE);

        // ── Animated wave at water surface ────────────────────────────────
        for (int i = x + 2; i < x + w - 2; i += 3) {
            int wy = waterY + (((i - x + sys.animFrame) % 6) > 3 ? 0 : 1);
            if (wy >= 0 && wy < DISPLAY_H && i >= 0 && i < DISPLAY_W) {
                display.drawPixel(i, wy, SSD1306_BLACK);
            }
        }

        // ── Vertical shine lines ──────────────────────────────────────────
        if (waterH > 6) {
            for (int sx = x + 5; sx < x + w - 4; sx += 8) {
                int shineTop    = waterY + 3;
                int shineBottom = y + h - 3;
                if (shineTop < shineBottom && sx < x + w - 2) {
                    display.drawFastVLine(sx, shineTop, shineBottom - shineTop, SSD1306_BLACK);
                }
            }
        }

        // ── Pump bubbles (only when pump ON and enough water) ─────────────
        if (sys.pumpState == PUMP_ON && waterH > 10) {
            int bx = x + 5 + (sys.animFrame % (w - 10));
            if (bx >= x + 1 && bx < x + w - 1) {
                int by1 = waterY + 4, by2 = waterY + 8, by3 = waterY + 6;
                if (by1 < DISPLAY_H) display.drawPixel(bx,     by1, SSD1306_BLACK);
                if (by2 < DISPLAY_H) display.drawPixel(bx - 3, by2, SSD1306_BLACK);
                if (by3 < DISPLAY_H) display.drawPixel(bx + 2, by3, SSD1306_BLACK);
            }
        }
    }

    // ── Level marker ticks on left side ──────────────────────────────────
    // [BUG-FIX-MARKS] Level ticks: only draw outside-left when x>=4.
    // When x<4, max(0,x-4)=0 → ticks overlap tank outline at x=0.
    // Fix: use right-wall notches (inside the tank) when no left space.
    if (x >= 4) {
        int lx = x - 4;
        display.drawFastHLine(lx, y + 5,         4, SSD1306_WHITE);  // FULL
        display.drawFastHLine(lx, y + h / 2,     4, SSD1306_WHITE);  // MID
        display.drawFastHLine(lx, y + h - 6,     4, SSD1306_WHITE);  // LOW
    } else {
        // No left-side room — draw tiny inward notches on right wall
        int rx = x + w - 3;
        display.drawFastHLine(rx, y + 5,         3, SSD1306_WHITE);
        display.drawFastHLine(rx, y + h / 2,     3, SSD1306_WHITE);
        display.drawFastHLine(rx, y + h - 6,     3, SSD1306_WHITE);
    }

    // ── [DISP-FIX-4] Percentage label inside tank bottom (not below it) ──
    // Drawn over black background so it's always readable
    display.setTextSize(1);
    char pctStr[8]; snprintf(pctStr, sizeof(pctStr), "%d%%", pct);
    int tw    = strlen(pctStr) * 6;
    int textX = x + (w - tw) / 2;
    int textY = y + h - 9;              // 8px text + 1px margin from bottom rim
    if (textY < y + 5) textY = y + 5;  // never overlap rim
    // Clear background behind text first
    display.fillRect(textX - 1, textY - 1, tw + 2, 9, SSD1306_BLACK);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(textX, textY);
    display.print(pctStr);
}

// ── Screen 0: Splash ──────────────────────────────────────────────────────
void drawSplashScreen() {
    if (!sys.displayInitialized) return;
    display.clearDisplay();
    display.setTextColor(SSD1306_WHITE);

    // Brand header
    display.setTextSize(2);
    display.setCursor(5, 2);
    display.print("SmartIoT");

    display.drawFastHLine(0, 19, 128, SSD1306_WHITE);

    // Sub-header
    display.setTextSize(1);
    display.setCursor(14, 23);
    display.print("Water Tank BD-1");

    // Version
    display.setCursor(36, 33);
    display.print(FIRMWARE_VER);

    // Separator
    display.drawFastHLine(0, 43, 128, SSD1306_WHITE);

    // [DISP-FIX-16] y=46/55 (was 48/58 — last row clipped at 64px display)
    display.setCursor(8, 46);
    display.print("SMART IoT Interface");
    display.setCursor(14, 55);
    display.print("Made in Bangladesh");

    // Bangladesh flag disc
    display.fillCircle(120, 58, 4, SSD1306_WHITE);
    display.fillCircle(118, 58, 3, SSD1306_BLACK);

    display.display();
}

// ── Screen 1: Main — 3D tank + real-time status ──────────────────────────
// Layout (128×64):
//   Left  x=0..49  : 3D tank (w=48, h=52, y=2..54), % label inside tank
//   Right x=52..127: status rows at y=2,12,22,32,42,52
//   Bottom y=56..63 : alarm bar (full width)
//
// [DISP-FIX-2]  Row y-values spaced 10px (size=1, 8px char + 2px gap)
// [DISP-FIX-3]  Time moved to inside tank area; right panel rows fit exactly
// [DISP-FIX-11] Alarm bar at y=56 (8px high = y56..63, no overflow)
void drawMainScreen() {
    display.clearDisplay();
    display.setTextColor(SSD1306_WHITE);

    // ── Left: 3D animated tank (x=0, y=2, w=48, h=52) ───────────────────
    draw3DTank(0, 2, 48, 52, sys.waterPct);

    // ── Right: Status panel (x=52, width=76) ─────────────────────────────
    const int rx = 52;

    // Row 0 (y=2): Water level % — size=2 (16px tall → occupies y=2..17)
    display.setTextSize(2);
    display.setCursor(rx, 2);
    display.printf("%d%%", sys.waterPct);

    display.setTextSize(1);

    // Row 1 (y=20): Level label + blinking pump dot
    display.setCursor(rx, 20);
    const char* lvlStr =
        sys.waterLevel == LVL_FULL  ? "FULL" :
        sys.waterLevel == LVL_MID   ? " MID" :
        sys.waterLevel == LVL_LOW   ? " LOW" : "EMPT";
    display.print(lvlStr);

    // Pump indicator dot (right of level label)
    if (sys.pumpState == PUMP_ON) {
        if (sys.animFrame % 4 < 2) display.fillCircle(rx + 35, 23, 3, SSD1306_WHITE);
        else                        display.drawCircle(rx + 35, 23, 3, SSD1306_WHITE);
    } else {
        display.drawCircle(rx + 35, 23, 3, SSD1306_WHITE);
    }

    // Row 2 (y=30): Pump state
    display.setCursor(rx, 30);
    display.printf("PMP:%s", sys.pumpState == PUMP_ON ? "ON " : "OFF");

    // Row 3 (y=40): Mode
    display.setCursor(rx, 40);
    display.printf("%-6s", sys.pumpMode == MODE_AUTO ? "AUTO" : "MANUAL");

    // Row 4 (y=50): WiFi SSID + signal bars OR BLE status
    if (sys.wifiOk) {
        char ssid[9]; getShortSSID(ssid, sizeof(ssid));
        display.setCursor(rx, 50);
        display.print(ssid);
        // [DISP-FIX-10] signal bars at x=109 (4 bars × 4px = 16px → 125px max, safe)
        drawSignalBars(109, 57, sys.rssi);
    } else if (sys.provRunning) {
        display.setCursor(rx, 50);
        display.print("BLE...");
    } else {
        display.setCursor(rx, 50);
        display.print("No WiFi");
    }

    // ── [DISP-FIX-3] BD time shown bottom-left under tank (x=0, y=56) ────
    // Only shown when no alarm (alarm bar takes priority at same y)
    if (!sys.alarmActive) {
        char timeStr[10]; getBDTime(timeStr, sizeof(timeStr));
        display.setCursor(0, 56);
        display.print(timeStr);
    }

    // ── Alarm flash bar y=56..63 (8px, no overflow) ────────────────────
    // [BUG-FIX-ALARM] millis()-based 500ms blink (50% duty cycle).
    // Old: animFrame%6==0 → visible 100ms / 600ms = 17% duty — too fast flicker.
    // New: (millis()/500)%2 → visible 500ms / dark 500ms = clean, readable blink.
    {
        bool alarmOn = ((millis() / 500) % 2 == 0);
        if (sys.alarmActive && alarmOn) {
            display.fillRect(0, 56, DISPLAY_W, 8, SSD1306_WHITE);
            display.setTextColor(SSD1306_BLACK);
            display.setCursor(8, 56);
            display.print(sys.dryRunActive ? "!! DRY RUN !!" : "!!! ALARM !!!");
            display.setTextColor(SSD1306_WHITE);
        }
    }

    // ── Notification overlay — top 9px, steady (no flash) ──────────────
    // [BUG-FIX-NOTIF] Steady bar, no animFrame flash.
    // Old: animFrame%4<3 → bar disappears 100ms every 400ms = annoying flicker.
    // New: always shown for full NOTIFICATION_CLEAR_MS duration — clear to read.
    if (sys.notificationActive) {
        display.fillRect(0, 0, DISPLAY_W, 9, SSD1306_BLACK);
        display.drawRect(0, 0, DISPLAY_W, 9, SSD1306_WHITE);
        display.setCursor(2, 1);
        char notifBuf[22];
        strncpy(notifBuf, sys.notification, 21);
        notifBuf[21] = '\0';
        display.print(notifBuf);
    }

    display.display();
}

// ── Screen 2: Status — WiFi, pump stats, sensor mode ─────────────────────
// [DISP-FIX-6] WiFi RSSI and IP on separate rows (long string was overflowing 128px)
void drawStatusScreen() {
    display.clearDisplay();
    display.setTextColor(SSD1306_WHITE);
    display.setTextSize(1);

    // Header bar
    display.fillRect(0, 0, DISPLAY_W, 10, SSD1306_WHITE);
    display.setTextColor(SSD1306_BLACK);
    display.setCursor(30, 1);
    display.print("STATUS INFO");
    display.setTextColor(SSD1306_WHITE);

    // Row 1 (y=12): WiFi status + signal bars
    display.setCursor(0, 12);
    if (sys.wifiOk) {
        // max "WiFi:OK -99dBm" = 15 chars = 90px, safe
        display.printf("WiFi:OK %ddBm", sys.rssi);
        drawSignalBars(100, 19, sys.rssi);
    } else {
        display.print("WiFi: Offline");
    }

    // Row 2 (y=22): IP address
    display.setCursor(0, 22);
    if (sys.wifiOk) {
        // IP string max "255.255.255.255" = 15 chars = 90px, safe
        display.printf("IP:%s", WiFi.localIP().toString().c_str());
    } else {
        display.print("IP: ---");
    }

    // Row 3 (y=32): Pump state + mode
    display.setCursor(0, 32);
    display.printf("Pump:%-3s  Mode:%s",
        sys.pumpState == PUMP_ON ? "ON" : "OFF",
        sys.pumpMode  == MODE_AUTO ? "AUTO" : "MAN");

    // Row 4 (y=42): Pump cycles + runtime
    display.setCursor(0, 42);
    display.printf("Cycles:%u  Run:%uh",
        (unsigned)sys.pumpCycles,
        (unsigned)(sys.pumpTotalS / 3600));

    // Row 5 (y=52): Sensor mode + BD time
    display.setCursor(0, 52);
    char timeStr[10]; getBDTime(timeStr, sizeof(timeStr));
    display.printf("%s  %s",
        sys.sensorMode == SENSOR_ULTRA ? "ULTRA" : "FLOAT",
        timeStr);

    display.display();
}

// ── Screen 3: System Info ─────────────────────────────────────────────────
// [DISP-FIX-7] Heap and Temp on separate rows (combined was >128px)
void drawInfoScreen() {
    display.clearDisplay();
    display.setTextColor(SSD1306_WHITE);
    display.setTextSize(1);

    // Header bar
    display.fillRect(0, 0, DISPLAY_W, 10, SSD1306_WHITE);
    display.setTextColor(SSD1306_BLACK);
    display.setCursor(25, 1);
    display.print("SYSTEM INFO");
    display.setTextColor(SSD1306_WHITE);

    // Row 1 (y=12): Firmware version  "FW: SmartIoT v15.0.1" = 21ch = 126px, ok
    display.setCursor(0, 12);
    display.printf("FW: SmartIoT %s", FIRMWARE_VER);

    // Row 2 (y=22): Device serial  "ID: SWT-XXXXYYYYYYY" = 19ch = 114px, ok
    display.setCursor(0, 22);
    display.printf("ID: %s", g_chipSerial);

    // Row 3 (y=32): Boot count + uptime on same row  "Boot:#999  Up:99h59m" = ok
    display.setCursor(0, 32);
    char upStr[16]; getUptime(upStr, sizeof(upStr));
    display.printf("Boot:#%u  Up:%s", (unsigned)sys.bootCount, upStr);

    // Row 4 (y=42): [DISP-FIX-7] Free heap only (was combined with Temp → overflow)
    display.setCursor(0, 42);
    sys.freeHeap = ESP.getFreeHeap();
    display.printf("Heap: %uKB", (unsigned)(sys.freeHeap / 1024));

    // Row 5 (y=52): Temperature + BD time
    display.setCursor(0, 52);
    char timeStr[10]; getBDTime(timeStr, sizeof(timeStr));
    display.printf("Temp:%.0fC  %s", temperatureRead(), timeStr);

    display.display();
}

// ── Screen 4: BLE Provisioning ────────────────────────────────────────────
// [DISP-FIX-8] BLE service name truncated to 21 chars max (126px at size=1)
void drawProvisioningScreen() {
    display.clearDisplay();
    display.setTextColor(SSD1306_WHITE);

    // Header
    display.setTextSize(1);
    display.setCursor(16, 2);
    display.print("WiFi Setup (BLE)");
    display.drawFastHLine(0, 12, DISPLAY_W, SSD1306_WHITE);

    // Instructions
    display.setCursor(0, 15);
    display.print("1.Open SmartIoT App");
    display.setCursor(0, 25);
    display.print("2.WiFi Provisioning");
    display.setCursor(0, 35);
    display.print("3.Scan BLE:");

    // [DISP-FIX-8] BLE name: max 21 chars to fit 128px (21×6=126px)
    String svcName = "PROV_SmartIoT_" + String(g_chipSerial).substring(0, 6);
    char bleName[22];
    strncpy(bleName, svcName.c_str(), 21);
    bleName[21] = '\0';
    display.setCursor(0, 45);
    display.print(bleName);

    // [SEC-3] PoP NOT shown on display

    // Animated dots
    display.setCursor(0, 55);
    display.print("Waiting");
    int dots = (sys.animFrame / 3) % 4;  // [DISP-FIX-9] faster with 100ms tick
    for (int i = 0; i < dots; i++) {
        display.fillCircle(54 + i * 8, 58, 2, SSD1306_WHITE);
    }

    display.display();
}

// ── Overlay: Factory Reset progress bar ───────────────────────────────────
void drawFactoryResetOverlay() {
    display.clearDisplay();
    display.setTextColor(SSD1306_WHITE);

    display.setTextSize(1);
    display.setCursor(10, 2);
    display.print("FACTORY RESET?");
    display.setCursor(6, 13);
    display.print("Keep holding btn...");

    // Large progress %
    display.setTextSize(2);
    char pctStr[8]; snprintf(pctStr, sizeof(pctStr), "%d%%", sys.factoryResetProgress);
    int tw = strlen(pctStr) * 12;
    display.setCursor((DISPLAY_W - tw) / 2, 25);
    display.print(pctStr);

    // Progress bar (y=42, h=10 → y+h=52 ✅)
    display.setTextSize(1);
    display.drawRect(4, 42, 120, 10, SSD1306_WHITE);
    int barW = (sys.factoryResetProgress * 118) / 100;
    if (barW > 0) display.fillRect(5, 43, barW, 8, SSD1306_WHITE);

    // [OLED-ERR-2+3 FIX] "Rel=Cancel" 10ch×6=60, x=34, y=54 → 54+8=62 ✅
    display.setCursor(34, 54);
    display.print("Rel=Cancel");

    display.display();
}

// ── Overlay: OTA progress bar ─────────────────────────────────────────────
void drawOtaOverlay(int pct) {
    if (!sys.displayInitialized) return;
    display.clearDisplay();
    display.setTextColor(SSD1306_WHITE);

    // [OLED-ERR-4 FIX] "OTA: Updating..." 16ch×6=96, x=(128-96)/2=16 → 16+96=112 ✅
    display.setTextSize(1);
    display.setCursor(16, 4);
    display.print("OTA: Updating...");
    display.drawFastHLine(0, 14, DISPLAY_W, SSD1306_WHITE);

    display.setCursor(12, 20);
    display.print("DO NOT POWER OFF!");

    // Progress bar (y=32, h=10 → y+h=42 ✅)
    display.drawRect(4, 32, 120, 10, SSD1306_WHITE);
    int barW = (pct * 118) / 100;
    if (barW > 0) display.fillRect(5, 33, barW, 8, SSD1306_WHITE);

    // [OLED-ERR-5 FIX] size=2 pct text: y=46 → 46+16=62 ✅ (was y=50→66)
    display.setTextSize(2);
    char pctStr[8]; snprintf(pctStr, sizeof(pctStr), "%d%%", pct);
    int tw = strlen(pctStr) * 12;
    display.setCursor((DISPLAY_W - tw) / 2, 46);
    display.print(pctStr);

    display.display();
}

// ── Overlay: Deep Sleep notification ─────────────────────────────────────
void drawDeepSleepScreen() {
    if (!sys.displayInitialized) return;
    display.clearDisplay();
    display.setTextColor(SSD1306_WHITE);

    display.setTextSize(1);
    display.setCursor(5, 4);
    display.print("Entering sleep mode");
    display.drawFastHLine(0, 14, DISPLAY_W, SSD1306_WHITE);

    // [FIX-3] nullptr is ambiguous for drawBitmap overloads — no placeholder bitmap needed

    display.setCursor(14, 20);
    display.print("Sleeping 30 min");
    display.setCursor(8, 32);
    display.print("GPIO34 = wake now");

    display.setCursor(0, 44);
    display.print("WiFi: ");
    // [DISP-FIX-13] Use getShortSSID() — raw WiFi.SSID() can overflow 128px display
    if (sys.wifiOk) { char dsSSID[10]; getShortSSID(dsSSID, sizeof(dsSSID)); display.print(dsSSID); }
    else { display.print("---"); }

    char timeStr[16]; getBDTime(timeStr, sizeof(timeStr));
    display.setCursor(0, 56);
    display.print(timeStr);

    display.display();
}

// ── Main display orchestrator ─────────────────────────────────────────────
void updateDisplay() {
    if (!sys.displayInitialized) return;

    // Splash screen timeout
    if (sys.splashActive) {
        if (isTimeout(sys.splashStart, SPLASH_SCREEN_MS)) {
            sys.splashActive       = false;
            sys.oledScreen         = OLED_MAIN;
            sys.displayNeedsUpdate = true;
        }
        return;
    }

    // [DISP-FIX-9] animFrame on independent 100ms timer → smooth wave/bubble
    if (isTimeout(sys.lastAnimUpdate, ANIM_FRAME_MS)) {
        sys.lastAnimUpdate = millis();
        sys.animFrame++;
    }

    // Rate limit screen redraws (separate from animation tick)
    if (!isTimeout(sys.lastDisplayUpdate, DISPLAY_UPDATE_MS) && !sys.displayNeedsUpdate)
        return;

    sys.lastDisplayUpdate  = millis();
    sys.displayNeedsUpdate = false;

    // Factory reset overlay takes priority
    if (sys.factoryResetProgress > 0 && !sys.factoryResetTriggered) {
        drawFactoryResetOverlay();
        return;
    }

    // OTA overlay
    if (sys.otaInProgress) return;  // drawOtaOverlay() called from performOTA()

    // Provisioning screen overrides main screens
    if (sys.provRunning && sys.provState == PROV_WAITING) {
        drawProvisioningScreen();
        return;
    }

    // Content screens
    switch (sys.oledScreen) {
        case OLED_MAIN:   drawMainScreen();   break;
        case OLED_STATUS: drawStatusScreen(); break;
        case OLED_INFO:   drawInfoScreen();   break;
        default:          drawMainScreen();   break;
    }
}

// ============================================================================
// SETUP
// ============================================================================
// ══════════════════════════════════════════════════════════════
// [v8.0.0] AUTOMATION ENGINE — IF/THEN rules from Firebase
// Rules fetched once on WiFi connect, re-fetched every 5 min
// Runs locally — no cloud call per evaluation (Spark-plan safe)
// ══════════════════════════════════════════════════════════════

#define MAX_AUTOMATIONS 10

struct AutomationRule {
    char   id[32];
    char   name[48];
    char   triggerType[20];   // "level_below"|"level_above"|"pump_on_mins"|"time_of_day"
    int    triggerValue;      // % or minutes or hour
    char   actionType[20];    // "pump_on"|"pump_off"|"mode_auto"|"mode_manual"|"alert"
    bool   enabled;
    bool   triggered;         // track state to avoid repeated firing
};

AutomationRule g_automations[MAX_AUTOMATIONS];
int            g_automationCount  = 0;
unsigned long  g_automationLastFetch = 0;
#define AUTOMATION_FETCH_MS  300000UL  // re-fetch every 5 min

// Fetch automation rules from Firebase
void fetchAutomations() {
    if (!sys.wifiOk) return;
    const String path = "/automations/" + String(g_chipSerial);
    DynamicJsonDocument doc(4096);
    if (!fbGET(path, doc)) {
        DBGLN("[AUTO] Fetch failed");
        return;
    }
    g_automationCount = 0;
    for (JsonPair kv : doc.as<JsonObject>()) {
        if (g_automationCount >= MAX_AUTOMATIONS) break;
        if (!kv.value()["enabled"].as<bool>()) continue;
        AutomationRule& r = g_automations[g_automationCount];
        strlcpy(r.id,          kv.key().c_str(),                       sizeof(r.id));
        strlcpy(r.name,        kv.value()["name"]   | "Rule",          sizeof(r.name));
        strlcpy(r.triggerType, kv.value()["triggerType"] | "level_below", sizeof(r.triggerType));
        r.triggerValue = constrain((int)(kv.value()["triggerValue"] | 20), 0, 1440); // [FIX-SAFE-1] clamp 0-1440 (mins in day)
        strlcpy(r.actionType,  kv.value()["actionType"] | "pump_off",  sizeof(r.actionType));
        r.enabled   = true;
        r.triggered = false;
        g_automationCount++;
    }
    DBGF("[AUTO] Loaded %d rules\n", g_automationCount);
    g_automationLastFetch = millis();
}

// Execute a single automation action
void executeAutomationAction(const char* actionType) {
    if (strcmp(actionType, "pump_on") == 0) {
        if (sys.pumpState == PUMP_OFF) {
            setPump(true);
            DBGLN("[AUTO] Action: pump ON");
        }
    } else if (strcmp(actionType, "pump_off") == 0) {
        if (sys.pumpState == PUMP_ON) {
            setPump(false);
            DBGLN("[AUTO] Action: pump OFF");
        }
    } else if (strcmp(actionType, "mode_auto") == 0) {
        sys.pumpMode = MODE_AUTO;
        markStateDirty();  // [FIX-STATE-1] persist mode change to NVS
        DBGLN("[AUTO] Action: mode AUTO");
    } else if (strcmp(actionType, "mode_manual") == 0) {
        sys.pumpMode = MODE_MANUAL;
        markStateDirty();  // [FIX-STATE-1] persist mode change to NVS
        DBGLN("[AUTO] Action: mode MANUAL");
    } else if (strcmp(actionType, "alert") == 0) {
        // Log alert event to Firebase
        String alertPath = "/devices/" + String(g_chipSerial) + "/alerts/lastAuto";
        DynamicJsonDocument doc(128);
        doc["ts"] = (unsigned long)(millis() / 1000);
        doc["type"] = "automation";
        String body; serializeJson(doc, body);
        fbPATCH(alertPath, body);
        DBGLN("[AUTO] Action: alert sent");
    }
}

// Evaluate all automation rules against current sensor state
void evaluateAutomations() {
    if (!sys.wifiOk) return;

    // [BUG-FIX-14] Re-fetch rules periodically, but do NOT return — evaluate
    // current rules in the same cycle even after re-fetching
    if (isTimeout(g_automationLastFetch, AUTOMATION_FETCH_MS) || g_automationCount == 0) {
        fetchAutomations();
        // Continue below to evaluate the (now-updated) rules immediately
    }

    if (g_automationCount == 0) return;

    for (int i = 0; i < g_automationCount; i++) {
        AutomationRule& r = g_automations[i];
        if (!r.enabled) continue;

        bool conditionMet = false;

        if (strcmp(r.triggerType, "level_below") == 0) {
            conditionMet = (sys.waterPct <= r.triggerValue);
        } else if (strcmp(r.triggerType, "level_above") == 0) {
            conditionMet = (sys.waterPct >= r.triggerValue);
        } else if (strcmp(r.triggerType, "pump_on_mins") == 0) {
            // Check how long pump has been ON
            if (sys.pumpState == PUMP_ON && sys.pumpStartMs > 0) {
                unsigned long pumpMins = (millis() - sys.pumpStartMs) / 60000UL;
                conditionMet = (pumpMins >= (unsigned long)r.triggerValue);
            }
        } else if (strcmp(r.triggerType, "time_of_day") == 0) {
            // Hour match using NTP time — skip gracefully if not synced
            if (sys.timeInitialized) {
                conditionMet = (sys.timeInfo.tm_hour == r.triggerValue);
            }
        }

        // Edge-triggered: only fire once per condition rise
        if (conditionMet && !r.triggered) {
            DBGF("[AUTO] Rule '%s' triggered!\n", r.name);
            executeAutomationAction(r.actionType);
            r.triggered = true;
        } else if (!conditionMet && r.triggered) {
            r.triggered = false;  // reset when condition clears
        }
        esp_task_wdt_reset();
    }
}


void setup() {
#if !PRODUCTION_MODE
    Serial.begin(115200);
    delay(200);
#endif

    sys.bootTime       = millis();
    sys.lastActivityMs = millis();
    sys.oledScreen     = OLED_SPLASH;

    DBGLN("\n");
    DBGLN("╔═══════════════════════════════════════════════════════════════════╗");
    DBGLN("║  SMART IoT Interface — SmartIoT " FIRMWARE_VER " Production Edition ║");
    DBGLN("╠═══════════════════════════════════════════════════════════════════╣");
    DBGLN("║ Developer: Sobuj Billah — IoT Systems Architect                  ║");
    DBGLN("║ Contact: smartiotinterface@gmail.com                             ║");
    DBGLN("║ Website: smartiotinterface.blogspot.com                          ║");
    DBGLN("║ YouTube: @smartiotinterface  | Made in Bangladesh 🇧🇩              ║");
    DBGLN("╠═══════════════════════════════════════════════════════════════════╣");
    DBGLN("║ Firebase RTDB + BLE Provisioning + OLED UI + AES Stats           ║");
    DBGLN("╚═══════════════════════════════════════════════════════════════════╝\n");

    // WDT FIRST — before any other init
    setupWatchdog();

    // Unique device ID from eFuse MAC
    if (g_chipSerial[0] == 0) genSerial(g_chipSerial);
    DBGF("[SETUP] Device: %s\n", g_chipSerial);

    // Hardware
    setupHardware();

    // Display — [OLED-11] init before any draw
    setupDisplay();

    // Load persistent state (mode, mute, cycles, etc.)
    loadState();
    DBGF("[SETUP] Mode=%s  Muted=%d  Boot#%u  Cycles=%u\n",
         sys.pumpMode == MODE_AUTO ? "AUTO" : "MANUAL",
         (int)sys.muted, (unsigned)sys.bootCount, (unsigned)sys.pumpCycles);

    // Load AES-encrypted pump stats from NVS
    loadPumpStats();

    // Wake-up source from deep sleep
    switch (esp_sleep_get_wakeup_cause()) {
        case ESP_SLEEP_WAKEUP_TIMER:
            DBGLN("[SETUP] Wake: Timer");
            sendNotification("Woke from sleep — timer");
            markStateDirty();  // [FIX-STATE-2] ensure pushStatus fires ASAP (sleeping:false)
            break;
        case ESP_SLEEP_WAKEUP_EXT0:
            DBGLN("[SETUP] Wake: Emergency GPIO34");
            sendNotification("Emergency wakeup!");
            markStateDirty();  // [FIX-STATE-2] ensure pushStatus fires ASAP (sleeping:false)
            break;
        default:
            break;
    }

    // WiFi (events registered, no auto-connect yet)
    setupWiFi();

    // Pre-fill sensor debounce buffer with real readings
    for (int i = 0; i < SENSOR_SAMPLES; i++) {
        readSensors();
        esp_task_wdt_reset();
        delay(50);
    }

    DBGF("[SETUP] Initial sensors: Level=%d (%d%%) Mode=%s\n",
         sys.waterLevel, sys.waterPct,
         sys.sensorMode == SENSOR_ULTRA ? "ULTRA" : "FLOAT");

    // Start BLE provisioning (connects WiFi if credentials saved; else BLE)
    // ════════════════════════════════════════════════════════════════════
    // TEST MODE — Phone ছাড়া WiFi connect (secrets.h → TEST_WIFI_ENABLED)
    // TEST_WIFI_ENABLED 1 = hardcoded WiFi, 0 = normal BLE provisioning
    // ════════════════════════════════════════════════════════════════════
#if TEST_WIFI_ENABLED
    DBGLN("[TEST] ⚠️  TEST MODE — BLE bypass, hardcoded WiFi চালু");
    DBGF ("[TEST] SSID: %s\n", TEST_WIFI_SSID);
    WiFi.onEvent(onWiFiEvent);
    WiFi.begin(TEST_WIFI_SSID, TEST_WIFI_PASSWORD);
    {
        uint32_t _t = millis();
        while (WiFi.status() != WL_CONNECTED && millis() - _t < 20000) {
            esp_task_wdt_reset();
            delay(500);
            DBGLN("[TEST] connecting...");
        }
    }
    if (WiFi.status() == WL_CONNECTED) {
        sys.wifiOk         = true;
        sys.provRunning    = false;
        sys.timeSyncNeeded = true;
        digitalWrite(LED_WIFI_PIN, HIGH);
        DBGF("[TEST] ✅ WiFi OK — IP: %s\n", WiFi.localIP().toString().c_str());
    } else {
        DBGLN("[TEST] ❌ WiFi fail! secrets.h-এ SSID/PASSWORD চেক করো");
    }
#else
    // NORMAL MODE — BLE provisioning (phone দিয়ে WiFi দিতে হবে)
    startProvisioning(false);
#endif

    // Startup beep
    playStartup();

    DBGLN("\n[SETUP] ✅ System operational — SmartIoT " FIRMWARE_VER "\n");
}

// ============================================================================
// MAIN LOOP — fully non-blocking
// ============================================================================
void loop() {
    // CRITICAL: Reset watchdog first
    esp_task_wdt_reset();

    // Minimal path during OTA
    if (sys.otaInProgress) {
        esp_task_wdt_reset();
        delay(100);
        return;
    }

    // ── Core system ──────────────────────────────────────────────────────────
    readSensors();          // Float / Ultrasonic — 200ms debounced
    updateAutoMode();       // AUTO pump control + dry-run + max-run
    updateBuzzer();         // Non-blocking buzzer tick
    updateTime();           // [WIFI-3] Deferred NTP + periodic sync
    updateDisplay();        // OLED — 300ms rate limited
    clearNotificationIfNeeded();

    // ── User input ───────────────────────────────────────────────────────────
    handleButtons();        // Debounced buttons (MODE/PUMP/MUTE)

    // ── Network ──────────────────────────────────────────────────────────────
    handleWiFiReconnect();  // [WIFI-1] Circuit breaker reconnect
    handleProvisioning();   // Provisioning timeout guard

    // ── Firebase ─────────────────────────────────────────────────────────────
    if (sys.wifiOk) {
        if (isTimeout(sys.lastFBPushMs, FB_PUSH_MS)) {
            sys.lastFBPushMs = millis();
            pushStatus();
        }
        if (isTimeout(sys.lastFBCmdMs, FB_CMD_MS)) {
            sys.lastFBCmdMs = millis();
            pollCommands();
        }
        // [SMELL-05] Metrics on 60s interval
        if (isTimeout(sys.lastMetricsMs, IOT_METRICS_MS)) {
            sys.lastMetricsMs = millis();
            sys.rssi          = (int8_t)WiFi.RSSI();
            sys.freeHeap      = ESP.getFreeHeap();
            sys.temperature   = temperatureRead();
            if (sys.freeHeap < LOW_MEMORY) {
                sendNotification("⚠️ Low memory!");
                DBGF("[SYS] ⚠️ Low heap: %u bytes\n", (unsigned)sys.freeHeap);
            }
        }
    }

    // ── Safety checks ────────────────────────────────────────────────────────
    monitorOTA();           // Detect OTA update start
    checkFactoryReset();    // [SEC-1] 10s hold, blocked if WiFi+60s
    retryDisplayInit();     // [OLED-12] Auto re-init on failure

    // ── Automation rules (rate-limited to 5s) ────────────────────────────────
    {
        static uint32_t lastEvalMs = 0;
        if (isTimeout(lastEvalMs, 5000)) {
            lastEvalMs = millis();
            evaluateAutomations();  // [v8.0.0] check IF/THEN rules — no need for 100Hz
        }
    }

    // ── State persistence ────────────────────────────────────────────────────
    saveState();            // [SAVE-2] CRC32, wear-protected, 5-min interval

    // ── LED indicators ───────────────────────────────────────────────────────
    // (WiFi LED already managed in event callback & handleWiFiReconnect)
    digitalWrite(LED_PUMP_PIN, sys.pumpState == PUMP_ON ? HIGH : LOW);

    // ── Deep sleep check ─────────────────────────────────────────────────────
    checkDeepSleep();       // 30-min idle → deep sleep

    esp_task_wdt_reset();
    yield();
    delay(10);
}

// ============================================================================
// END OF FIRMWARE — SmartIoT v15.0.1  |  Made with 💙 in Bangladesh 🇧🇩
// ════════════════════════════════════════════════════════════════════════════
//
// GPIO SUMMARY:
//   PUMP_RELAY  = GPIO16  (RELAY_ACTIVE_HIGH configurable) ← [BUG-FIX-15] was GPIO2
//   FLOAT_LOW   = GPIO4   (INPUT_PULLUP, active-LOW)
//   FLOAT_FULL  = GPIO5   (INPUT_PULLUP, active-LOW)
//   FLOAT_MID   = GPIO15  (INPUT_PULLUP, active-LOW)
//   BUZZER      = GPIO18  (non-blocking BuzzerJob sequencer)
//   LED_WIFI    = GPIO2   |  LED_PUMP = GPIO17  // [COMMENT-FIX] was incorrectly stated as GPIO16
//   BTN_MODE    = GPIO23  |  BTN_PUMP = GPIO25  |  BTN_MUTE = GPIO26
//   BTN_RESET   = GPIO0   (hold 10s, blocked after WiFi+60s)
//   OLED SDA/SCL = GPIO21/22 (SSD1306 128×64 @ 400kHz)
//   TRIG/ECHO   = GPIO27/14  (HC-SR04 ultrasonic, interrupt-driven)
//   TOGGLE_MODE = GPIO33  (LOW=Float, HIGH=Ultrasonic)
//   WAKEUP_PIN  = GPIO34  (ext 10kΩ pull-up to 3.3V required)
//
// OLED SCREENS (long-press MODE 2s to cycle):
//   MAIN   — 3D animated tank + level% + pump + mode + WiFi + BD time
//   STATUS — WiFi SSID/IP/RSSI, pump cycles/runtime, sensor mode
//   INFO   — Firmware, device serial, boot count, heap, uptime, temperature
//   AUTO   — Provisioning screen during BLE setup
//   OVERLAY— Factory reset bar, OTA progress, deep sleep, alarm flash
//
// CONTACT: smartiotinterface@gmail.com
// Copyright © 2025-2026 SMART IoT Interface — All Rights Reserved
// ============================================================================
