 # PROFIdrive Telegram 1 –  (Bachmann PLC)

---

## 🇦🇹 Deutsch

### Übersicht

Dieser Funktionsbaustein implementiert das PROFIdrive Telegramm 1 zur Ansteuerung eines Servoantriebs über PROFINET.

Der Fokus liegt auf einer einfachen und robusten Drehzahlsteuerung mit klarer Zustandsmaschine.

---

### Hauptfunktionen

- Sicheres Starten und Stoppen des Antriebs  
- Drehzahlvorgabe (Speed Setpoint)  
- Auswertung des Statusworts (ZSW1)  
- Fehlerquittierung (Fault Acknowledge)

---

### Systemintegration

- Kommunikation über PROFINET  
- Kompatibel mit Bachmann SPS-Systemen  
- Einfache Integration in bestehende Projekte  

---

### Vorteile
 
- Klare und einfache Lösung für Drehzahlsteuerung
---

## 🇬🇧 English

### Overview

This function block implements PROFIdrive Telegram 1 for controlling a servo drive via PROFINET.

It focuses on simple and robust speed control using a clear state machine.

---

### Main Functions

- Safe start and stop of the drive  
- Speed setpoint control  
- Status word (ZSW1) evaluation  
- Fault acknowledgment  

---

### System Integration

- Communication via PROFINET  
- Compatible with Bachmann PLC systems  
- Easy integration into existing projects  

---

### Benefits

- Optimized for simple and robust speed control
 
---

##  Project Structure

- FB_PN_DRIVE_TLG_001 → Main function block  
- STRUCT → Telegram bit structures (STW1 / ZSW1)  
- GLOBAL → Global constants and configuration  
- TEST → Example application (CFC)  

---

##  How to Use

1. Import the M-PLC project (.pro file) into SolutionCenter  
2. Open the TEST application (CALL_FB_TLG1)  
3. Connect to the PLC  
4. Enable the axis and set the speed  

---
