# 📱 Enterprise Kiosk Solution – Architecture & Context Brief

**Prosjekt:** Enterprise Kiosk System for Flutter  
**Versjon:** 1.0.0 (POC - Proof of Concept)  
**Plattform:** Android (Samsung Galaxy Tab) / iOS (iPad)  
**Teknologi:** Flutter (Dart) + Native Android (Kotlin)  
**Utvikler:** Martin ([@martingit2](https://github.com/martingit2))

---

## 1. Sammendrag (Executive Summary)
Dette er en **Enterprise Kiosk-applikasjon** utviklet for bruk på dedikerte nettbrett montert i fellesområder. Løsningen kan tilpasses ulike formål som oppgavehåndtering, registrering, informasjonsskjermer eller selvbetjeningsportaler.

Systemet er bygget for å være **"Always-On"** (alltid på), sikkert låst til enheten, og strømbesparende uten å slå av skjermen. Løsningen demonstrerer hvordan moderne hybridteknologi (Flutter) kan kombineres med lavnivå systemstyring (Native Android) for å møte strenge bedriftskrav.

---

## 2. Kjernefunksjonalitet

### 🔒 Enterprise Kiosk Mode
Appen tar full kontroll over enheten ved oppstart:
*   **System UI Skjult:** Statuslinje, navigasjonsknapper og hjem-knapp er fjernet.
*   **Låst Navigasjon:** Brukeren kan ikke avslutte appen eller bytte program.
*   **Device Owner:** Appen kjører med forhøyede rettigheter (Device Owner) for å kunne aktivere `LockTaskMode` uten brukerbekreftelse.

### 🔋 Intelligent Strømstyring (Smart Dimming)
For å hindre innbrenning og spare strøm, men beholde synlighet:
1.  **Wakelock:** Systemet nektes å gå i dvale (Sleep Mode).
2.  **Idle Detection:** Etter konfigurerbar tid (f.eks. 10 sekunder i demo) uten berøring, aktiveres hvilemodus.
3.  **Physical Dimming:** Bakgrunnsbelysningen senkes fysisk til **15%** (konfigurerbart).
4.  **Instant Wake:** Ved første berøring gjenopprettes 100% lysstyrke umiddelbart. Det første trykket utfører ingen handling i UI-et (sikkerhetsmekanisme).

### 🛡️ Admin Gatekeeper ("Secret Handshake")
Administrasjonstilgang er usynlig for vanlige brukere:
*   **Trigger:** 5 raske trykk på app-logoen (øverst til venstre).
*   **Sikkerhet:** Krever PIN-kode (Standard: `1234`) for å låse opp enheten og avslutte appen.

---

## 3. Teknisk Arkitektur
Prosjektet følger **Clean Architecture**-prinsipper med tydelig separasjon av ansvar (Separation of Concerns).

### Mappestruktur
```text
lib/
├── config/           # Sentralisert konfigurasjon
│   └── theme.dart    # Fargepalett, Tidsavbrudd, PIN, Lysstyrke-nivåer
├── core/             # Systemkjerne (Ingen UI-logikk her)
│   ├── kiosk_controller.dart  # MethodChannel mot Android (LockTask)
│   └── kiosk_wrapper.dart     # Håndterer Idle Timer og Dimming-logikk
├── models/           # Datamodeller
│   └── task_model.dart        # Type-definisjon for oppgaver
├── widgets/          # Gjenbrukbare UI-komponenter
│   ├── task_card.dart         # Responsivt kort for rutenettet
│   └── sidebar.dart           # Venstremeny (hvis skilt ut)
└── screens/          # Hovedskjermer
    └── dashboard_screen.dart  # Selve Dashboardet med logikk
```

### Native Integrasjon (Android / Kotlin)
**Fil:** `android/app/src/main/kotlin/.../MainActivity.kt`

Vi bruker en MethodChannel (`com.yourcompany.kiosk/control`) for å kalle funksjoner som Flutter ikke har tilgang til alene:
- `startLockTask()`: Låser appen til skjermen.
- `stopLockTask()`: Frigjør appen.

---

## 4. Konfigurasjon og Tilpasning
Alle innstillinger styres fra `lib/config/theme.dart`. Dette gjør det enkelt å endre oppførsel uten å røre logikken.

```dart
class AppConfig {
  static const String appTitle = 'Enterprise Kiosk';
  static const String adminPin = '1234'; 
  
  // Hvor lenge skal den stå før den dimmer?
  // I DEV/DEMO: Sett til Duration(seconds: 10)
  // I PROD: Sett til Duration(minutes: 5)
  static const Duration idleTimeout = Duration(seconds: 10); 
  
  // Hvor mørk skal skjermen bli? (0.0 - 1.0)
  // 0.15 = 15% lysstyrke (Anbefalt for kontor)
  static const double dimmedBrightness = 0.15; 
}
```

---

## 5. Instruksjoner for Kjøring og Utvikling

### Krav
- Flutter SDK
- Android Studio / VS Code
- Samsung Tablet (Android 10+) med Developer Mode aktivert.

### Første gangs oppsett (Viktig!)
For at appen skal kunne låse skjermen uten spørsmål, må den settes som Device Owner. Dette gjøres via ADB mens appen kjører:

1. Koble til nettbrett via USB.
2. Kjør appen: `flutter run`
3. Kjør følgende kommando i terminalen:

```bash
adb shell dpm set-device-owner com.yourcompany.kioskapp/.MainActivity
```

*(Merk: Erstatt `com.yourcompany.kioskapp` med ditt eget applicationId fra `build.gradle`).*

### Hvordan demonstrere appen
1. **Start:** Appen laster inn og låser seg umiddelbart.
2. **Demo Dimming:** La enheten stå urørt i 10 sekunder. Observer at lyset dempes fysisk (ikke svart skjerm, men mørk).
3. **Demo Wake:** Trykk lett på skjermen. Lyset går til 100%.
4. **Demo Admin:** Trykk 5 ganger på logo → Tast 1234 → Trykk "Unlock".

---

## 6. Roadmap (Videre arbeid)
Dette er en Proof of Concept (POC). Følgende steg kreves for produksjon:

- **Backend:** Erstatte lokal state (`_myPoints`) med API-kall.
- **Autentisering:** Implementere bruker-ID ved registrering av oppgaver (RFID/PIN for ansatte).
- **iPad Støtte:** Konfigurere MDM-profil for "Single App Mode" (da iOS ikke støtter startLockTask programmatisk).
- **Distribusjon:** Sette opp CI/CD pipelines for utrulling til bedriftens enheter.

---

*Dokumentasjon utarbeidet av Martin ([@martingit2](https://github.com/martingit2))*
