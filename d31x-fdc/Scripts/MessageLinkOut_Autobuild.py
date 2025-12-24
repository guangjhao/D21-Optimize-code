from pywinauto import Application
from pywinauto.keyboard import send_keys
import os, time, sys

input_car_model = sys.argv[1]

app = Application().start("MessageLinker/MessageLinker4.exe")
app_window = app['MessageLinker']

# Fill in password
checkbox = app_window['自定義密碼']
checkbox.click()

send_keys("{TAB}")

current_dir = os.path.abspath(__file__)
upper_two_levels_dir = os.path.abspath(os.path.join(current_dir, "../.."))
CMM_folder_path = os.path.join(upper_two_levels_dir, 'documents', 'MessageMap')
all_files = os.listdir(CMM_folder_path)
txt_files = [file for file in all_files if file.endswith('.txt')]

if 'password.txt' in txt_files:
    with open(os.path.join(CMM_folder_path, 'password.txt'), 'r', encoding='utf-8') as f:
        password = f.read().strip()
else:
    password = os.path.splitext(txt_files[0])[0]
    
password_edit = app_window.child_window(auto_id="PW", control_type="System.Windows.Forms.TextBox")
password_edit.set_text(password)

# Select File Folder
button = app_window['Select File Folder']
button.click()

file_dialog = app_window.child_window(title="瀏覽資料夾", control_type="Window")

send_keys("{TAB}")
send_keys("{TAB}")

for _ in range(50):
    checkbox = app_window['VMC']
    send_keys("{VK_DOWN}")

send_keys("{ENTER}")

app_window.close()
