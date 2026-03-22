# Privacy Compliance Research — AquaFaste (Hydration Tracker)

**Date:** 2026-03-22  
**Scope:** App Store privacy nutrition labels, GDPR, Apple Health data rules, privacy policy, ATT  
**App Profile:** Hydration tracker with HealthKit integration, push notifications, no ads, no third-party tracking, no user accounts (or optional accounts)

---

## 1. App Store Privacy Nutrition Labels

### What They Are
Since December 2020, all App Store apps must disclose data collection practices through "Privacy Nutrition Labels" in App Store Connect. These appear on the app's product page and are self-reported by the developer.

**Sources:** [Apple Developer — App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/), [Apple — User Privacy and Data Use](https://developer.apple.com/app-store/user-privacy-and-data-use/)

### What AquaFaste Must Declare

The privacy label questionnaire covers 14 categories of data. For a hydration tracker with HealthKit and notifications (no ads, no tracking), the likely declarations are:

#### Health & Fitness Data
- **Data type:** Health (water intake written to HealthKit)
- **Usage purpose:** App Functionality
- **Linked to identity:** Only if data is associated with a user account or device identifier that you transmit off-device. If all health data stays on-device (HealthKit only), it does **not** need to be declared — Apple states: *"Data that is processed only on device is not 'collected' and does not need to be disclosed."*
- **Key rule:** "Collect" means transmitting data off the device in a way that allows you or third-party partners to access it for longer than necessary to service the request in real time.

#### If Using Analytics (e.g., TelemetryDeck, basic crash reporting)
- **Data type:** Diagnostics (crash data, performance data)
- **Usage purpose:** Analytics, App Functionality
- **Linked to identity:** Typically "Not linked to identity" if anonymized
- Declare even if the data seems innocuous — Apple now actively verifies labels against actual app behavior using automated scanning.

#### Notifications (Push Notifications via APNs)
- Push notification tokens themselves are **not** a data type you need to separately declare, as they are part of the Apple framework. However, if you collect an email or identifier to send notifications, that must be declared.
- If using only local notifications (no server), nothing additional to declare.

#### What Likely Does NOT Need Declaring
- Data stored purely on-device (HealthKit local store, UserDefaults preferences)
- Data collected by Apple itself (Apple handles its own disclosure)

### Best-Case Label: "Data Not Collected"
If AquaFaste:
- Stores all data on-device only (HealthKit + local storage)
- Uses only local notifications (no push server)
- Has no analytics SDK
- Has no user accounts

Then the label can be: **"The developer does not collect any data from this app."** This is the gold standard for privacy-focused apps.

### Privacy Manifests (Required since Spring 2024)
Apps must include a `PrivacyInfo.xcprivacy` file if using "Required Reason APIs" (UserDefaults, file timestamps, system boot time, disk space). Must declare approved reasons for accessing these APIs. Apple validates that SDKs have proper privacy manifests.

**Source:** [App Store Privacy Policy Requirements Guide](https://iossubmissionguide.com/app-store-privacy-policy-requirements)

---

## 2. GDPR Compliance for EU Users

### Applicability
GDPR applies if the app is available to users in the EU/EEA, regardless of where the developer is based. Health data is classified as **"special category data"** under GDPR Article 9, requiring explicit consent for processing.

**Key penalties:** Up to €20 million or 4% of global annual turnover, whichever is higher.

### Core Requirements for AquaFaste

#### Lawful Basis for Processing
- **Consent** is the primary lawful basis for health data processing. Must be freely given, specific, informed, and unambiguous.
- Pre-ticked boxes are NOT compliant.
- Users must actively opt in.
- Users must be able to withdraw consent as easily as they grant it.

**Source:** [GDPR Compliance for Apps — GDPR Local](https://gdprlocal.com/gdpr-compliance-for-apps/)

#### Data Minimization
- Collect only data necessary for the app's function (water intake, reminders).
- Don't request HealthKit permissions you don't need.

#### Data Subject Rights (must be supported)
1. **Right to Access** — users can request a copy of their data
2. **Right to Rectification** — users can correct their data
3. **Right to Erasure** ("Right to be Forgotten") — users can request deletion
4. **Right to Data Portability** — users can export their data
5. **Right to Restrict Processing** — users can limit how data is used
6. **Right to Withdraw Consent** — at any time, easily accessible

#### Privacy by Design and Default
- Data protection must be integrated into the app from the outset, not bolted on after.
- Only necessary personal data should be processed by default.
- On-device processing preferred over cloud transmission.

**Source:** [Secure Privacy — GDPR Compliance for Mobile Apps 2026](https://secureprivacy.ai/blog/gdpr-compliance-mobile-apps)

#### Data Breach Notification
- Must notify supervisory authority within 72 hours of becoming aware of a breach.
- Must notify affected users if breach poses high risk to their rights.

#### Data Processing Agreements
- If using ANY third-party service that processes personal data (analytics, crash reporting, cloud storage), you need a DPA with that provider.
- The app publisher remains the primary controller responsible for all data processing, including what happens inside third-party SDKs.

### AquaFaste's GDPR Advantage
Since AquaFaste has:
- No ad SDKs
- No user tracking
- On-device data storage (HealthKit)
- No user accounts (or minimal optional accounts)

GDPR compliance is significantly simplified. The main obligations are:
1. A compliant privacy policy
2. Respecting HealthKit consent as GDPR consent (with proper disclosure)
3. Providing a way to delete data (can point to iOS Settings > Health > Data Access)
4. If adding any analytics, ensure it's privacy-preserving (e.g., TelemetryDeck, no PII)

---

## 3. Apple HealthKit Data Requirements

### Core Rules (App Store Review Guidelines §5.1.3)

#### Encryption Requirements
- HealthKit data is encrypted at rest on the device with passcode/Touch ID/Face ID protection.
- HealthKit data is encrypted during iCloud sync (end-to-end with iOS 12+ and 2FA).
- Apple encrypts the data; once your app reads it and sends it off-device, **responsibility shifts to you**. You must use encryption in transit (TLS) and at rest on any server.

**Source:** [Apple Support — Protecting access to user's health data](https://support.apple.com/guide/security/protecting-access-to-users-health-data-sec88be9900f/web)

#### No Sharing / Advertising Restrictions
- **Apps are NOT allowed to use health data for advertising.** This is enforced at the API entitlement level.
- Apps must not sell health data to data brokers, advertising networks, or information resellers.
- Apps must not use health data for purposes unrelated to improving the user's health or health research (with user consent).
- Health data cannot be shared with third parties without explicit user consent and disclosure.

**Source:** [Apple Developer — Health and fitness apps](https://developer.apple.com/health-fitness/)

#### Consent Model
- HealthKit requires **granular, per-data-type consent**. Each data type (e.g., water intake, steps) needs separate read/write permission.
- Users can revoke permissions at any time via Settings > Health > Data Access & Devices.
- If the user revokes permission, the app immediately loses access.
- Apps must provide clear **purpose strings** explaining why access is needed and how data will be used.

#### Required for HealthKit Apps
1. **Privacy policy** that clearly discloses how health/fitness information will be used — mandatory, non-negotiable
2. **HealthKit entitlement** in the app's capabilities
3. **Purpose strings** in Info.plist (`NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`)
4. Must indicate HealthKit integration in marketing text
5. Must clearly identify HealthKit functionality in the app's UI
6. Process on device when possible; use end-to-end encryption when transmitting
7. Only request access to data that's **core to the app's functionality**

**Source:** [Apple Developer Documentation — Protecting user privacy](https://developer.apple.com/documentation/healthkit/protecting-user-privacy), [McCann FitzGerald — HealthKit Data Protection](https://www.mccannfitzgerald.com/knowledge/data-privacy-and-cyber-risk/apple-healthkit-the-rise-of-the-mobile-health-app-and-its-data-protection)

#### What AquaFaste Should Request
- **Write:** `HKQuantityType.dietaryWater` (to log water intake)
- **Read:** `HKQuantityType.dietaryWater` (to display history, including entries from other apps)
- Do NOT request access to unrelated types (heart rate, steps, etc.) — Apple explicitly warns against this and may reject the app.

#### New in 2025: Third-party AI Disclosure
Apple's revised App Review Guidelines (November 2025) require: *"You must clearly disclose where personal data will be shared with third parties, including with third-party AI, and obtain explicit permission before doing so."* If AquaFaste ever adds AI features using third-party services, this will require explicit disclosure and consent.

**Source:** [TechCrunch — Apple's new guidelines on third-party AI](https://techcrunch.com/2025/11/13/apples-new-app-review-guidelines-clamp-down-on-apps-sharing-personal-data-with-third-party-ai/)

---

## 4. Privacy Policy Requirements

### Apple's Requirements (App Store Review Guidelines §5.1.1)

Every app must have a privacy policy. This is required even if the app collects NO data.

**Where it must appear:**
1. **App Store Connect** — privacy policy URL in metadata (required for submission)
2. **Within the app** — accessible from settings or an easily reachable location
3. **Before data collection** — shown before requesting sensitive permissions

**Source:** [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

### What the Privacy Policy Must Include

Per Apple's guidelines, the policy must clearly and explicitly:

1. **Identify what data the app collects**, how it collects that data, and all uses of that data
2. **Confirm third-party data protection** — any third party with whom data is shared must provide equal protection as stated in the privacy policy
3. **Explain data retention/deletion policies** and describe how a user can revoke consent and/or request deletion
4. **Be specific to the app** — a generic company privacy policy will be rejected; it must specifically cover this app's data practices

**Source:** [TermsFeed — Privacy Policy for iOS Apps](https://www.termsfeed.com/blog/ios-apps-privacy-policy/)

### Additional Requirements for HealthKit Apps
The privacy policy must specifically disclose:
- What health/fitness data types are accessed
- How health data will be used
- Whether health data is transmitted off-device
- Who has access to the data
- How long data is retained

### Recommended Privacy Policy Sections for AquaFaste

1. **Identity** — Developer/company name, contact information
2. **Data Collected** — Water intake data (via HealthKit), notification preferences, app usage preferences
3. **How Data Is Used** — Track daily hydration, provide reminders, sync with Apple Health
4. **Data Storage** — All data stored locally on device via HealthKit and app local storage; no cloud transmission
5. **Third-Party Sharing** — "We do not share your data with any third parties" (if true)
6. **Data Retention & Deletion** — Data persists in HealthKit (managed by user); app-specific data deleted when app is uninstalled; users can delete HealthKit data via Settings
7. **User Rights** — Right to access, correct, delete data; how to exercise these rights
8. **Children's Privacy** — Statement about age requirements
9. **Changes to Policy** — How users will be notified of changes
10. **Contact Information** — How to reach the developer for privacy inquiries

### Hosting
- Must be a publicly accessible URL (not behind a login)
- Must not return a 404
- Must be available in the app's primary language
- Can be hosted on a simple webpage (GitHub Pages, personal site, etc.)

---

## 5. App Tracking Transparency (ATT) Rules

### What ATT Is
Since iOS 14.5 (April 2021), apps must request user permission through the `AppTrackingTransparency` framework before tracking users across other companies' apps and websites, or accessing the device's advertising identifier (IDFA).

**Source:** [Apple Developer — User Privacy and Data Use](https://developer.apple.com/app-store/user-privacy-and-data-use/)

### Definition of "Tracking"
Tracking means linking user or device data collected from your app with user or device data collected from other companies' apps, websites, or offline properties for:
- Targeted advertising
- Advertising measurement
- Sharing with data brokers

### Does AquaFaste Need ATT? **NO.**

ATT is required when apps:
- Access the IDFA (advertising identifier)
- Implement cross-app tracking
- Share user data with data brokers for advertising
- Display targeted ads based on data from other companies' apps/websites

Since AquaFaste:
- Has **no ad SDKs**
- Does **not access IDFA**
- Does **not share data with third parties**
- Does **not track users across apps/websites**
- Has **no advertising network integration**

**AquaFaste does NOT need to implement the ATT prompt.** No `AppTrackingTransparency` framework import is needed.

### Important Caveat
If any third-party SDK is later added that accesses unique identifiers or creates shared identity across apps, ATT would become required. Developers are responsible for all code in their apps, including third-party SDKs.

**Source:** [Apple Developer — User Privacy and Data Use](https://developer.apple.com/app-store/user-privacy-and-data-use/)

### ATT and GDPR Interaction
ATT and GDPR are complementary, not substitutes. ATT covers cross-app tracking (Apple enforcement), while GDPR covers all personal data processing (legal enforcement). An app needs both ATT compliance (if tracking) AND GDPR compliance (if processing EU users' data). Since AquaFaste does neither tracking nor significant data processing, both are simplified.

**Source:** [Secure Privacy — Mobile App Consent for iOS 2025](https://secureprivacy.ai/blog/mobile-app-consent-ios-2025)

---

## Summary: AquaFaste Privacy Compliance Checklist

### Must Do (Before Submission)

| # | Requirement | Status |
|---|-------------|--------|
| 1 | Write and host a privacy policy URL | TODO |
| 2 | Add privacy policy link in App Store Connect metadata | TODO |
| 3 | Add privacy policy link accessible within the app (Settings screen) | TODO |
| 4 | Complete Privacy Nutrition Label questionnaire in App Store Connect | TODO |
| 5 | Add `PrivacyInfo.xcprivacy` manifest if using Required Reason APIs | TODO |
| 6 | Add HealthKit purpose strings in Info.plist | TODO |
| 7 | Request only `dietaryWater` read/write permissions (minimum necessary) | TODO |
| 8 | Indicate HealthKit integration in marketing text and app UI | TODO |

### Should Do (Best Practices)

| # | Recommendation | Priority |
|---|---------------|----------|
| 1 | Keep all data on-device only (enables "Data Not Collected" label) | HIGH |
| 2 | Use only local notifications (avoid push notification server) | HIGH |
| 3 | If analytics needed, use privacy-preserving solution (TelemetryDeck) | MEDIUM |
| 4 | Provide data export functionality (supports GDPR portability) | MEDIUM |
| 5 | Show privacy info before requesting HealthKit permissions | MEDIUM |
| 6 | Include GDPR-specific language in privacy policy for EU users | MEDIUM |

### Do NOT Do

| # | Prohibition | Source |
|---|------------|--------|
| 1 | Never use health data for advertising | Apple §5.1.3 |
| 2 | Never sell or share health data with data brokers | Apple §5.1.3 |
| 3 | Never transmit health data without encryption | Apple + GDPR |
| 4 | Never request HealthKit data types unrelated to hydration tracking | Apple HIG |
| 5 | Never implement ATT prompt unnecessarily (no tracking = no prompt) | Apple ATT |
| 6 | Never store health data in iCloud or third-party cloud without E2E encryption | Apple §5.1.3 |
| 7 | Never share personal data with third-party AI without explicit disclosure | Apple §5.1.2 (Nov 2025) |

---

## Sources

1. [Apple Developer — App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)
2. [Apple Developer — User Privacy and Data Use](https://developer.apple.com/app-store/user-privacy-and-data-use/)
3. [Apple Developer — Health and fitness apps](https://developer.apple.com/health-fitness/)
4. [Apple Developer — Protecting user privacy (HealthKit)](https://developer.apple.com/documentation/healthkit/protecting-user-privacy)
5. [Apple Support — Protecting access to user's health data](https://support.apple.com/guide/security/protecting-access-to-users-health-data-sec88be9900f/web)
6. [Apple — Health App & Privacy](https://www.apple.com/legal/privacy/data/en/health-app/)
7. [Apple — Consumer Health Personal Data Privacy Policy](https://www.apple.com/legal/privacy/consumer-health-personal-data/en-ww/)
8. [Apple — App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
9. [App Store Privacy Policy Requirements 2025 Guide](https://iossubmissionguide.com/app-store-privacy-policy-requirements)
10. [GDPR Compliance for Apps — GDPR Local](https://gdprlocal.com/gdpr-compliance-for-apps/)
11. [Secure Privacy — GDPR Compliance for Mobile Apps 2026](https://secureprivacy.ai/blog/gdpr-compliance-mobile-apps)
12. [Secure Privacy — Mobile App Consent for iOS 2025](https://secureprivacy.ai/blog/mobile-app-consent-ios-2025)
13. [TechCrunch — Apple's new guidelines on third-party AI (Nov 2025)](https://techcrunch.com/2025/11/13/apples-new-app-review-guidelines-clamp-down-on-apps-sharing-personal-data-with-third-party-ai/)
14. [TermsFeed — Privacy Policy for iOS Apps](https://www.termsfeed.com/blog/ios-apps-privacy-policy/)
15. [McCann FitzGerald — HealthKit Data Protection Implications](https://www.mccannfitzgerald.com/knowledge/data-privacy-and-cyber-risk/apple-healthkit-the-rise-of-the-mobile-health-app-and-its-data-protection)
16. [The Momentum — What You Can and Can't Do With HealthKit Data](https://www.themomentum.ai/blog/what-you-can-and-cant-do-with-apple-healthkit-data)
