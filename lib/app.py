from flask import Flask, request, render_template_string
import os
import sys

app = Flask(__name__)
UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

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
    if request.method == 'POST':
        f = request.files['file']
        if f:
            filepath = os.path.join(UPLOAD_FOLDER, f.filename)
            f.save(filepath)
            return f"<h3>✅ Uploaded: {f.filename}</h3><a href='/'>Back</a>"
    return render_template_string(HTML_FORM)

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 5000
    app.run(host='0.0.0.0', port=port)