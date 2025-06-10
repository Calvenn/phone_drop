# Phone Drop Desktop App

A Flutter desktop application paired with a Flask backend server that enables seamless file transfer between a laptop and a phone over the same WiFi network using QR codes.

---

## Features

- **Sender Mode**: Upload files from the laptop and share them via a Flask server.
- **Receiver Mode**: Download files sent from the phone or laptop through the Flask server.
- Automatically detects the local IP address and finds a free port.
- Generates a QR code for easy connection via phone browser.
- Starts a 10-minute countdown timer after which the Flask server automatically shuts down.
- Monitors file upload/download folders and lists files in the desktop app UI.
- Allows opening downloaded/uploaded files directly from the app.
- Gracefully kills the Flask server process when the app closes or timer ends.

---

## How It Works

### Sender Mode (Laptop → Phone)

1. Select a file on the laptop using the app.
2. The app launches a Flask server locally, hosting the selected file.
3. A QR code with the server URL (`http://<local_ip>:<port>/download`) is generated and displayed.
4. The phone scans the QR code to open the file download page in its browser.
5. The phone downloads the file directly from the laptop.
6. The app runs a 10-minute timer and shuts down the Flask server when time expires or app closes.

### Receiver Mode (Phone → Laptop)

1. The phone opens the Flask server URL scanned from the QR code on the laptop.
2. The phone uploads a file through the Flask upload page served by the desktop Flask server.
3. The Flask server saves the uploaded file to a local `uploads` folder on the laptop.
4. The desktop app monitors this folder and displays the uploaded files in its UI.
5. Files can be opened directly from the desktop app.
6. A 10-minute countdown timer runs and automatically stops the server and clears resources.

---
