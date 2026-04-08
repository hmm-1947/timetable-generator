; ------------------------------------------------------------
; Inno Setup script for Funzi Windows Installer
; ------------------------------------------------------------
[Setup]
AppName=TimeTables
AppVersion=1.3.0
AppPublisher=JoshuaFiverr
DefaultDirName={autopf}\TimeTables
DefaultGroupName=TimeTables
UninstallDisplayIcon={app}\TimeTables.exe
OutputDir=.
OutputBaseFilename=TimeTablesInstaller
Compression=lzma
SolidCompression=yes
WizardStyle=modern
SetupIconFile=windows\runner\resources\app_icon.ico
PrivilegesRequired=lowest

[Files]
; Copy all built Flutter files to the installation directory
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

[Icons]
; Create desktop and Start Menu shortcuts
Name: "{group}\timtables"; Filename: "{app}\timetables.exe"
Name: "{userdesktop}\timetables"; Filename: "{app}\timetables.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional icons:"

[Run]
; Run the app after installation
Filename: "{app}\timetables.exe"; Description: "Launch TimeTables"; Flags: nowait postinstall skipifsilent
