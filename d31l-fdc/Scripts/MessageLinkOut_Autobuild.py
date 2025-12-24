from pywinauto import Application
from pywinauto.keyboard import send_keys
import os, time

app = Application().start("MessageLinker/MessageLinker.exe")
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
password = os.path.splitext(txt_files[0])[0]

send_keys(password)


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
