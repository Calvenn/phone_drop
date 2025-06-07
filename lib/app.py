from flask import Flask, request, render_template_string
import os
import sys
import threading

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

def shutdown_server():
    func = request.environ.get('werkzeug.server.shutdown')
    if func is None:
        print('Not running with the Werkzeug Server')
        return
    print('Shutting down server...')
    func()

@app.route('/', methods=['GET', 'POST'])
def upload_file():
    if request.method == 'POST':
        f = request.files['file']
        if f:
            filepath = os.path.join(UPLOAD_FOLDER, f.filename)
            f.save(filepath)
            return f"<h3>✅ Uploaded: {f.filename}</h3><a href='/'>Back</a>"
    return render_template_string(HTML_FORM)

def schedule_shutdown(seconds):
    def shutdown():
        with app.test_request_context('/'):
            shutdown_server()
    timer = threading.Timer(seconds, shutdown)
    timer.daemon = True
    timer.start()

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 5000
    schedule_shutdown(600)  # 600 seconds = 10 minutes
    app.run(host='0.0.0.0', port=port)
