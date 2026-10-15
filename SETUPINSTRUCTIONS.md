Hello and welcome to the repository for this project

First things first open terminal from a folder you want to use for this repository, then git clone "https://github.com/LawrenceLS/code-adventure"

Setup Godot & VS Code:

Setup Godot:
download the official godot launcher version 4.7 or above here: "https://godotengine.org/download/windows/"
import the project by opening the cloned repository folder in the Godot Editor
Click on Editor in the top menu bar and select Editor Settings
Find Text Editor and click on External.
Use External Editor by checking its box.
In the Exec Path field, browse and select your VS Code executable file: Windows: Typically located at C:/Users//AppData/Local/Programs/Microsoft VS Code/Code.exe
In the Exec Flags field, copy and paste the following exact string "{project} --goto {file}:{line}:{col}"
it should look like this: 
<img width="1120" height="491" alt="image" src="https://github.com/user-attachments/assets/2798c56b-246f-4119-8d68-1fecb49ba08c" />

Setup VS Code:
- Install VS Code editor here: "https://code.visualstudio.com/"
- find extensions on the side bar or go to view tab and open extensions.
- then install godot-tools by Geequlim in vs code extensions
- now when you edit or make files that execute code it will open up the godot projects file/folder for you to manage in vs code

Setup Git for Github:
find command prompt terminal in windows right click and run it as administrator and type:
"winget install --id Git.Git -e --source winget", then refresh the terminal by closing and then opening a new terminal. 
type: "git --version" to confirm and make sure git is installed.
enter in your credentials/login like so:
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
Next to connect your newly installed Git to GitHub from CMD, the most secure and modern method is using SSH keys. 
This authenticates your computer with GitHub so you can push and pull code without typing your password every time.

Here is how to set it up step-by-step: 

Generate a New SSH Key
1. Open Command Prompt (CMD).
2. Run the following command (replace the email with your GitHub email address): "ssh-keygen -t ed25519 -C "your.email@example.com""
3. Press Enter to accept the default file location.
4. When prompted to enter a passphrase, you can either type a secure password or just press Enter twice to leave it empty (easier for personal PCs).

Add Your SSH Key to GitHub
Next, you need to copy your public key and save it to your GitHub profile.
1. Print your public key in CMD by running this command: "type %userprofile%\.ssh\id_ed25519.pub"
2. Highlight and copy the entire output string that appears (it starts with ssh-ed25519 and ends with your email).
3. Go to GitHub.com and log in.
4. In the top-right corner, click your profile photo → Settings.
5. In the left sidebar, click SSH and GPG keys.
6. Click the green New SSH key button.
7. Give it a Title (e.g., "Windows Laptop") and paste your copied key into the "Key" box.
8. Click Add SSH key.

Test the Connection
Go back to your Command Prompt and run this command to make sure everything works:
"ssh -T git@github.com"


