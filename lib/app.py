from flask import Flask, request, render_template_string, send_file, abort
from io import BytesIO
import sys

app = Flask(__name__)

# Temporary in-memory file store
memory_file = None
memory_filename = None

HTML_FORM = '''
<!DOCTYPE html>
<html>
<head><title>Upload</title></head>
<body>
  <h2>Upload File to Desktop</h2>
  <form method="post" enctype="multipart/form-data">
    <input type="file" name="file"><br><br>
    <input type="submit" value="Upload">
  </form>
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
            return f"<h3>✅ Uploaded to memory: {f.filename}</h3><a href='/'>Back</a>"
    return render_template_string(HTML_FORM)

@app.route('/download', methods=['GET'])
def download_file():
    global memory_file, memory_filename
    if memory_file is None:
        return "❌ No file in memory.", 404
    memory_file.seek(0)
    response = send_file(memory_file, download_name=memory_filename, as_attachment=True)
    # Clear memory after sending
    memory_file = None
    memory_filename = None
    return response

# <--- Add this new API route here --->
@app.route('/api/upload', methods=['POST'])
def api_upload_file():
    global memory_file, memory_filename
    if 'file' not in request.files:
        return "❌ No file part in the request.", 400
    f = request.files['file']
    if f.filename == '':
        return "❌ No selected file.", 400
    if f:
        memory_file = BytesIO(f.read())
        memory_file.seek(0)
        memory_filename = f.filename
        return f"✅ Uploaded to memory via API: {f.filename}", 200
    return "❌ File upload failed.", 500

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 5000
    app.run(host='0.0.0.0', port=port)
