from flask import Flask, request, render_template_string, send_file, abort
from io import BytesIO
import sys

app = Flask(__name__)

# Temporary in-memory file store
memory_file = None
memory_filename = None

HTML_FORM = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>PhoneDrop Upload</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      background: #f4f9ff;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
    }
    .container {
      background: white;
      padding: 30px 40px;
      border-radius: 12px;
      box-shadow: 0 0 12px rgba(0, 0, 0, 0.1);
      text-align: center;
    }
    h2 {
      color: #007bff;
      margin-bottom: 20px;
    }
    input[type="file"] {
      padding: 10px;
      border: 1px solid #ddd;
      border-radius: 8px;
      margin-bottom: 20px;
    }
    input[type="submit"] {
      background-color: #007bff;
      color: white;
      border: none;
      padding: 10px 20px;
      font-size: 16px;
      border-radius: 8px;
      cursor: pointer;
      transition: background-color 0.3s ease;
    }
    input[type="submit"]:hover {
      background-color: #0056b3;
    }
    .footer {
      margin-top: 20px;
      font-size: 14px;
      color: #888;
    }
  </style>
</head>
<body>
  <div class="container">
    <h2>📤 Upload File to Your Desktop</h2>
    <form method="post" enctype="multipart/form-data">
      <input type="file" name="file" required><br><br>
      <input type="submit" value="Upload File">
    </form>
    <div class="footer">Powered by PhoneDrop</div>
  </div>
</body>
</html>
'''


@app.route('/', methods=['GET', 'POST'])
def upload_file():
    global memory_file, memory_filename
    if request.method == 'POST':
        f = request.files['file']
        if f:
            memory_file = BytesIO(f.read())  # read into memory
            memory_file.seek(0)
            memory_filename = f.filename
            return f"<h3>Uploaded to memory: {f.filename}</h3><a href='/'>Back</a>"
    return render_template_string(HTML_FORM)

@app.route('/download', methods=['GET'])
def download_file():
    global memory_file, memory_filename
    if memory_file is None:
        return "No file in memory.", 404
    memory_file.seek(0)
    response = send_file(memory_file, download_name=memory_filename, as_attachment=True)
    # Clear memory after sending
    memory_file = None
    memory_filename = None
    return response

@app.route('/api/upload', methods=['POST'])
def api_upload_file():
    global memory_file, memory_filename
    if 'file' not in request.files:
        return "No file part in the request.", 400
    f = request.files['file']
    if f.filename == '':
        return "No selected file.", 400
    if f:
        memory_file = BytesIO(f.read())
        memory_file.seek(0)
        memory_filename = f.filename
        return f"✅ Uploaded to memory via API: {f.filename}", 200
    return "File upload failed.", 500

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 5000
    app.run(host='0.0.0.0', port=port)
