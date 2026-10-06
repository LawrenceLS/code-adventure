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
