[Setup]
AppId=WinttyCommunityBuild
AppName=Wintty Community Build
AppVersion={#BuildVersion}
AppVerName=Wintty Community Build {#BuildVersion} ({#SourceSha})
AppPublisher=Unofficial community build
DefaultDirName={localappdata}\Programs\Wintty Community Build
DefaultGroupName=Wintty Community Build
UninstallDisplayIcon={app}\Wintty.exe
PrivilegesRequired=lowest
ArchitecturesAllowed=x64os
MinVersion=10.0.22000
WizardStyle=modern
Compression=lzma2
SolidCompression=yes
OutputDir={#OutputDir}
OutputBaseFilename=Wintty-community-{#SourceSha}-x64-setup
SetupIconFile={#StageDir}\Assets\wintty.ico
LicenseFile={#StageDir}\LICENSE
DisableProgramGroupPage=yes
CloseApplications=yes

[Tasks]
Name: desktopicon; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"

[Files]
Source: "{#StageDir}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{autoprograms}\Wintty Community Build"; Filename: "{app}\Wintty.exe"; IconFilename: "{app}\Assets\wintty.ico"
Name: "{autodesktop}\Wintty Community Build"; Filename: "{app}\Wintty.exe"; IconFilename: "{app}\Assets\wintty.ico"; Tasks: desktopicon

[Run]
Filename: "{app}\Wintty.exe"; Description: "Launch Wintty"; Flags: nowait postinstall skipifsilent
