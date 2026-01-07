# 📱 Enterprise Kiosk Solution for Flutter

**Versjon:** 1.0.0  
**Plattform:** Android (Samsung Galaxy Tab) / iOS (iPad)  
**Teknologi:** Flutter (Dart) + Native Android (Kotlin)  
**Utvikler:** Martin ([@martingit2](https://github.com/martingit2))

---

## Oversikt

En enterprise-grade kiosk-applikasjon bygget med Flutter, designet for dedikerte nettbrett montert i fellesområder. Løsningen kombinerer moderne cross-platform teknologi med lavnivå systemstyring for å skape en robust, alltid-på applikasjon med intelligent strømstyring.

### Kjernefunksjoner

- 🔒 **Kiosk Mode** - Låser appen til skjermen via Android Lock Task API
- 🔋 **Smart Power Management** - Wakelock + intelligent dimming for strømsparing
- 🛡️ **Admin Access Control** - Skjult PIN-beskyttet administratortilgang
- 💤 **Idle Detection** - Automatisk dimming ved inaktivitet
- ⚡ **Instant Wake** - Umiddelbar respons ved brukerinteraksjon

---

## Teknisk Implementasjon

### Arkitektur

Prosjektet følger **Clean Architecture** prinsipper:

```
lib/
├── config/           # Konfigurasjon (timeout, PIN, lysstyrke)
├── core/             # Systemkjerne (kiosk controller, idle detection)
├── models/           # Datamodeller
├── widgets/          # Gjenbrukbare UI-komponenter
└── screens/          # Applikasjonsskjermer
```

### Native Integration

**Flutter → Kotlin MethodChannel**

```kotlin
// MainActivity.kt
class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.company.kiosk/control"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startLockTask" -> {
                        startLockTask()
                        result.success(true)
                    }
                    "stopLockTask" -> {
                        stopLockTask()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
```

### Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  wakelock_plus: ^1.2.8          # Prevents device sleep
  screen_brightness: ^2.1.7      # Hardware brightness control
```

---

## Funksjonalitet

### 1. Kiosk Mode 🔒

Appen bruker Androids **Lock Task Mode** for å låse seg til skjermen:

- ✅ Skjuler system UI (statusbar, navigasjonsknapper)
- ✅ Forhindrer app-bytte og home-knapp
- ✅ Persistent låsing (overlever app-restart)

**Første gangs oppsett:**
Ved første kjøring viser Android en "Pin this app?" dialog. Brukeren godkjenner én gang, og Android husker valget permanent.

**Device Owner (Valgfritt):**
For organisasjoner som ønsker å fjerne første gangs dialog helt, kan enheten settes opp som Device Owner via MDM eller manuelt via ADB. Dette er *ikke påkrevd* for normal drift.

### 2. Smart Power Management 🔋

**Wakelock:**
```dart
import 'package:wakelock_plus/wakelock_plus.dart';

@override
void initState() {
  super.initState();
  WakelockPlus.enable();  // Prevents screen from turning off
}
```

**Idle Detection & Dimming:**
```dart
import 'package:screen_brightness/screen_brightness.dart';

Timer _idleTimer;

void _resetIdleTimer() {
  _idleTimer?.cancel();
  _idleTimer = Timer(AppConfig.idleTimeout, () async {
    // Dim to 15% after idle timeout
    await ScreenBrightness().setScreenBrightness(0.15);
  });
}

void _onUserInteraction() async {
  // Restore full brightness on touch
  await ScreenBrightness().setScreenBrightness(1.0);
  _resetIdleTimer();
}
```

**Resultat:**
- Skjermen forblir alltid på (ingen dvale-modus)
- Automatisk dimming til 15% etter konfigurerbar tid (default: 15 sekunder demo, 5 minutter prod)
- Umiddelbar oppvåkning ved touch
- Første touch utfører ingen UI-handling (sikkerhetsmekanisme)

### 3. Admin Access Control 🛡️

Administrasjonstilgang er skjult for vanlige brukere:

**Aktivering:**
- 5 raske klikk på app-logoen (øverst til venstre)
- PIN-prompt vises
- Standard PIN: `1234` (konfigurerbart)

**Funksjonalitet:**
- Låser opp device fra kiosk-mode
- Tillater app-exit
- Tilgang til system-innstillinger

---

## Konfigurasjon

All konfigurasjon samlet i `lib/config/theme.dart`:

```dart
class AppConfig {
  // App metadata
  static const String appTitle = 'Enterprise Kiosk';
  static const String adminPin = '1234';
  
  // Idle timeout
  // DEV/DEMO: Duration(seconds: 10-15)
  // PRODUCTION: Duration(minutes: 5)
  static const Duration idleTimeout = Duration(seconds: 15);
  
  // Dimmed brightness level (0.0 - 1.0)
  // 0.15 = 15% brightness (recommended for office environments)
  static const double dimmedBrightness = 0.15;
}
```

---

## Oppsett og Installasjon

### Krav

- Flutter SDK (3.0.0+)
- Android Studio / VS Code
- Android device (API 21+) med Developer Mode aktivert

### Standard Oppsett (Anbefalt)

1. **Koble til enhet:**
   ```bash
   adb devices
   ```

2. **Installer og kjør:**
   ```bash
   flutter run
   ```

3. **Første gangs aktivering:**
    - Appen starter og ber om å "Pin this app?"
    - Trykk "Start" eller "I understand"
    - Android husker valget permanent

4. **Ferdig!** Appen kjører nå i kiosk-mode

### Testing

**Demo idle detection:**
```bash
# La enheten stå urørt i 15 sekunder
# Observer: Skjermen dimmes til 15%

# Touch skjermen
# Observer: Full lysstyrke gjenopprettes umiddelbart
```

**Demo admin access:**
```bash
# Trykk 5x raskt på app-logoen (øverst til venstre)
# Tast PIN: 1234
# Trykk "Unlock"
# Appen frigjøres fra kiosk-mode
```

### Device Owner Oppsett (Valgfritt)

**⚠️ Kun nødvendig hvis:**
- Du distribuerer til 50+ enheter
- Du vil fjerne første gangs dialog helt
- Du har en MDM-løsning

**⚠️ IKKE nødvendig hvis:**
- Enheten monteres fysisk (vegg/stativ)
- Én gangs godkjenning er akseptabelt
- Du har <10 enheter

**Fremgangsmåte:**
```bash
# Krever factory reset og ingen Google-konto
adb shell dpm set-device-owner com.yourcompany.kioskapp/.MainActivity
```

**OBS:** Kommandoen over vil feile med nåværende implementasjon (mangler DeviceAdminReceiver). Se "Roadmap" for full Device Owner støtte.

---

## Verifisert Funksjonalitet

### ✅ Fullstendig Implementert

| Funksjon | Status | Krever Device Owner? |
|----------|--------|---------------------|
| Wakelock | ✅ 100% | ❌ Nei |
| Smart Dimming | ✅ 100% | ❌ Nei |
| Idle Detection | ✅ 100% | ❌ Nei |
| Instant Wake | ✅ 100% | ❌ Nei |
| Kiosk Mode | ✅ 100% | ⚠️ Én gangs godkjenning |
| Admin PIN Gate | ✅ 100% | ❌ Nei |

### ⚠️ Krever Første Gangs Oppsett

- **Kiosk Mode aktivering:** Bruker må godkjenne "Pin this app?" én gang ved installasjon (huskes deretter)

### 💡 Valgfrie Forbedringer

- **Full Device Owner:** Fjerner første gangs dialog (krever DeviceAdminReceiver implementasjon)
- **MDM Integration:** For massedistribusjon til mange enheter

---

## Testing og Verifisering

**Stabil drift verifisert:**
- ✅ Kjørt kontinuerlig i 3+ timer uten problemer
- ✅ Wakelock forhindrer dvale-modus
- ✅ Smart dimming aktiveres ved idle timeout (15 sek)
- ✅ Umiddelbar respons ved touch
- ✅ Ingen minnelekkasjer observert

**Test-scenario:**
```
1. Start app
2. Godkjenn kiosk-mode (første gang)
3. La stå urørt i 15 sekunder
   → Resultat: Skjermen dimmes til 15%
4. Touch skjerm
   → Resultat: Full lysstyrke umiddelbart
5. Trykk 5x på logo → Tast 1234
   → Resultat: Exit fra kiosk-mode
```

---

## Roadmap

### For Produksjon

- [ ] **Backend Integration:** API for oppgaver og brukerdata
- [ ] **Authentication:** Bruker-ID via RFID/QR/PIN
- [ ] **Analytics:** Logging og statistikk
- [ ] **Remote Config:** Dynamisk konfigurasjon via API
- [ ] **Error Reporting:** Crashlytics/Sentry integrasjon
- [ ] **CI/CD:** Automated deployment pipeline

### Device Owner Support (Hvis nødvendig)

For full Device Owner funksjonalitet (automatisk låsing uten dialog), må følgende implementeres:

1. **DeviceAdminReceiver klasse**
   ```kotlin
   class KioskDeviceAdminReceiver : DeviceAdminReceiver()
   ```

2. **device_admin.xml policy**
   ```xml
   <device-admin>
       <uses-policies>
           <lock-task />
       </uses-policies>
   </device-admin>
   ```

3. **AndroidManifest receiver-deklarasjon**
4. **Device Policy Manager integrasjon**

**Vurdering:** Ikke nødvendig for de fleste brukstilfeller.

### iOS Support

- [ ] MDM-profil for "Single App Mode"
- [ ] Guided Access alternativ
- [ ] Cross-platform feature parity

---

## Anbefalinger

### For Fellesområder (Anbefalt tilnærming)

**✅ Standard oppsett er tilstrekkelig:**
- Godkjenn kiosk-mode ved installasjon (én gang)
- Monter enhet fysisk (vegg/stativ/bordfeste)
- Wakelock + Smart Dimming håndterer strøm
- Admin PIN beskytter exit-funksjon

**Sikkerhetsnivå:** Høy (fysisk montering + PIN = dobbel beskyttelse)

### For Massedistribusjon (50+ enheter)

**💼 Vurder MDM-løsning:**
- Samsung Knox
- Google Workspace
- Microsoft Intune
- AirWatch / Jamf (iOS)

**Fordeler:**
- Pre-konfigurer enheter remote
- Automatiser oppsett
- Sentral administrasjon
- Device Owner settes automatisk

---

## FAQ

**Q: Må jeg ha Device Owner for at appen skal fungere?**  
A: Nei. Standard Lock Task Mode fungerer utmerket med én gangs godkjenning.

**Q: Hva er forskjellen på Lock Task Mode og Device Owner?**  
A: Lock Task Mode = Appen låser seg til skjermen. Device Owner = Appen har administrative rettigheter over hele enheten og kan låse uten brukerbekreftelse.

**Q: Kan appen kjøre i flere timer uten problemer?**  
A: Ja! Testet med stabil drift i 3+ timer. Wakelock holder den våken, smart dimming sparer strøm.

**Q: Hvordan avinstallerer jeg hvis appen er låst?**  
A: Bruk admin PIN-gate (5x klikk på logo → tast 1234), eller restart enhet i safe mode.

**Q: Fungerer dette på iPad?**  
A: iPad krever MDM-konfigurasjon for "Single App Mode". Samme konsept, men konfigureres via MDM-profil.

**Q: Hva skjer ved strømbrudd / restart?**  
A: Appen starter automatisk ved boot (hvis konfigurert). Kiosk-mode aktiveres automatisk (godkjenning huskes).

**Q: Kan jeg endre idle timeout?**  
A: Ja, i `lib/config/theme.dart` → `idleTimeout`. Anbefalt: 5 minutter for produksjon.

---

## Kontakt

**Utvikler:** Martin  
**GitHub:** [@martingit2](https://github.com/martingit2)

---

*Dokumentasjon oppdatert: Januar 2026*  
*Versjon: 1.0.0*
