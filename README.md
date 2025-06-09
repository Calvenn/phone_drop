# Phone Drop Desktop App

A Flutter desktop application paired with a Flask backend server that allows uploading files from a phone by scanning a QR code. The app shows uploaded files and features a 10-minute countdown timer for the Flask server session.

---

## Features

- Starts a Flask server subprocess to handle file uploads.
- Generates a QR code displaying the local IP and port for phone connection.
- Displays a 10-minute countdown timer showing time remaining before server shutdown.
- Watches the `uploads` folder and lists uploaded files in the app UI.
- Allows opening uploaded files directly from the desktop app.
- Automatically kills the Flask server process when the app closes.

---

## How It Works

1. On startup, the Flutter desktop app:
   - Detects the local IPv4 address.
   - Finds a free port starting from 5000.
   - Launches the Flask server (`app.py`) on the found port.
   - Displays a QR code with the server URL (`http://<local_ip>:<port>`).
   - Starts a 10-minute countdown timer.
   - Monitors the `uploads` folder for new files.

2. Users scan the QR code with their phone browser to access the file upload page.

3. Uploaded files are saved to the `uploads` folder on the desktop and listed in the app.

4. The countdown timer counts down from 10 minutes.

5. The Flask server process is killed automatically when the app is closed.
