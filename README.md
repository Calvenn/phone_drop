<p align="center">
  <img src="assets/app_icon.png" width="250"/>
</p>

# 📱💻 Phone Drop Desktop App

A Flutter desktop and mobile application integrated with a Flask backend server hosted on **Render.com**, enabling **cross-device file transfer** between a **laptop and a phone** using **QR codes** — whether on the **same WiFi network or across the internet**.

---

## ✨ Features

- **🌐 Cloud Hosting via Render.com** – Send and receive files without needing local network setup.
- **📤 Sender Mode**: Upload files from the laptop or phone and share them via a Flask server.
- **📥 Receiver Mode**: Download files from any device via QR code or link, hosted by the Render backend.
- **🌍 Cross-device & Cross-network support**: Works on different WiFi, mobile data, or even globally.
- **📷 QR Code Generation**: Generates a shareable QR code containing the download link.

---

## 🚀 How It Works

### 🌐 Cloud File Transfer (via [Render.com](https://render.com))

1. The app uploads a file to a Flask server hosted on Render (`https://phone-drop.onrender.com/api/upload`).
2. A public download link (`https://phone-drop.onrender.com/download`) is generated.
3. A QR code containing the download URL is displayed in the app.
4. The receiver scans the QR code or opens the link on any device and downloads the file.
5. After one successful download or 10 minutes, the file is removed from memory on the server.

---

### 🖥️ Sender Mode (Desktop/Mobile → Any Device)

1. Select a file to send.
2. The app uploads it to the cloud Flask server on Render.
3. Displays a QR code and shareable link for download.
4. The file is held in memory and available for one download or until 10 minutes pass.

---

### 📲 Receiver Mode (Any Device → Desktop)

1. Scan the QR code shown on your laptop with your phone camera or browser.
2. Upload a file through the Flask upload page (`/`).
3. File is received and listed in the desktop app.
4. App allows direct opening of the uploaded file.
5. After 10 minutes, the server clears the file and stops listening.

---

## ✅ Advantages of Cloud-Hosted Mode

- No need for users to be on the same local network.
- No port forwarding or IP discovery required.
- Secure, temporary in-memory file transfer.
- Accessible from any browser-enabled device.

---

## 🛠 Tech Stack

- **Flutter** (Windows + Android app)
- **Flask** (Python backend)
- **Render.com** (Cloud hosting)
- **QR Flutter** (QR code generation)
- **File Picker** (Cross-platform file selection)
- **HTTP & Path Provider** (for file transfer & storage)

---

## 📎 Links

- [Live Upload API](https://phone-drop.onrender.com/api/upload)
- [Live Download Page](https://phone-drop.onrender.com/download)
