---
name: printer-troubleshooting-guide
enabled: true
description: |
  Use when performing printer troubleshooting guide — common printer issues
  resolution guide covering connectivity problems, print quality issues, paper
  jams, driver configuration, and network printer setup. Provides systematic
  troubleshooting steps for helpdesk agents to resolve the most frequent
  printer-related support tickets.
required_connections:
  - prefix: itsm
    label: "ITSM Tool (ServiceNow, Freshservice, etc.)"
config_fields:
  - key: user_name
    label: "Affected User Name"
    required: true
    placeholder: "e.g., Jane Smith"
  - key: printer_name
    label: "Printer Name / Model"
    required: true
    placeholder: "e.g., HP LaserJet Pro M404, 3rd Floor Printer"
  - key: issue_description
    label: "Issue Description"
    required: true
    placeholder: "e.g., prints blank pages, offline, paper jam"
  - key: connection_type
    label: "Connection Type"
    required: false
    placeholder: "e.g., network, USB, wireless"
features:
  - HELPDESK
---

# Printer Troubleshooting Guide

Troubleshooting printer issue for **{{ user_name }}**
Printer: **{{ printer_name }}** | Connection: {{ connection_type }}
Issue: **{{ issue_description }}**

## Decision Tree

```
START: What is the printer issue?
│
├─ Printer Offline / Not Found
│  ├─ Network printer?
│  │  ├─ Ping printer IP → If fail, check network cable/WiFi
│  │  ├─ Print server running? → Restart print spooler service
│  │  └─ Correct port/IP configured? → Update printer port
│  ├─ USB printer?
│  │  ├─ Cable connected? → Try different USB port/cable
│  │  └─ Driver installed? → Install/update driver
│  └─ Wireless printer?
│     ├─ On same network? → Verify SSID match
│     └─ WiFi direct enabled? → Check printer wireless settings
│
├─ Print Jobs Stuck in Queue
│  ├─ Clear print queue
│  ├─ Restart print spooler service
│  └─ Remove and re-add printer
│
├─ Poor Print Quality
│  ├─ Streaks/lines → Clean print heads, check toner
│  ├─ Faded output → Replace toner/ink cartridge
│  ├─ Smudges → Check fuser unit, paper type
│  └─ Wrong colors → Run alignment/calibration
│
├─ Paper Jam
│  ├─ Remove jammed paper (follow arrows)
│  ├─ Check for torn paper fragments
│  ├─ Inspect rollers for wear
│  └─ Verify correct paper size/type loaded
│
└─ Cannot Print Specific Content
   ├─ PDF won't print → Try "Print as Image"
   ├─ Large file fails → Check printer memory
   └─ Wrong output → Check default printer, duplex settings
```

## Troubleshooting Steps

### Printer Offline / Cannot Find Printer

1. **Verify printer power and status**
   - [ ] Printer is powered on and display shows "Ready"
   - [ ] No error lights or messages on printer panel
   - [ ] Paper is loaded and trays are closed

2. **Check connectivity**
   - [ ] Network cable is connected (for wired network printers)
   - [ ] Ping printer IP address: `ping [printer-ip]`
   - [ ] Verify printer IP has not changed (check DHCP lease or printer config page)

3. **Fix on user's computer**
   - [ ] Open Settings > Printers & Scanners
   - [ ] Check if {{ printer_name }} shows as "Offline"
   - [ ] Right-click printer > "Use Printer Online" if available
   - [ ] If printer is missing, re-add via IP address or print server path

4. **Print spooler fix (Windows)**
   ```
   1. Open Services (services.msc)
   2. Find "Print Spooler" service
   3. Stop the service
   4. Delete files in C:\Windows\System32\spool\PRINTERS\
   5. Start the service
   6. Try printing again
   ```

### Print Quality Issues
1. **Print a test page** from printer's control panel (not from computer)
2. If test page is poor quality:
   - [ ] Check toner/ink levels
   - [ ] Run printer's built-in cleaning cycle
   - [ ] Replace cartridge if low
3. If test page is fine but computer prints are poor:
   - [ ] Check print driver settings (draft vs normal vs high quality)
   - [ ] Verify correct paper type selected in driver
   - [ ] Update or reinstall printer driver

### Paper Jam Resolution
1. [ ] Turn off printer
2. [ ] Open all access panels (front, rear, trays)
3. [ ] Remove jammed paper — pull gently in the direction of paper path
4. [ ] Check for small torn pieces that may remain
5. [ ] Inspect paper trays — fan paper before loading, do not overfill
6. [ ] Close all panels and power on
7. [ ] If recurring jams: check roller condition, request maintenance

## Escalation Criteria

Escalate to printer/hardware team if:
- Printer hardware failure (fuser, roller, formatter board)
- Network printer needs IP reconfiguration on network side
- Print server issues affecting multiple users
- Firmware update required
- Recurring paper jams indicating mechanical issue

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format

Generate a resolution report with:
1. **Issue summary** (user, printer, symptom)
2. **Troubleshooting steps performed** with results
3. **Resolution** applied
4. **Preventive recommendations** if applicable
