; ============================================================
; Open WebUI Windows 安装包配置
; 包含嵌入式 Python，无需用户预装
; ============================================================

#define MyAppName "Open WebUI"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Open WebUI"
#define MyAppURL "https://github.com/open-webui/open-webui"
#define MyAppExeName "start.bat"

[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}

DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}

DisableDirPage=no
UsePreviousAppDir=yes

OutputDir=output
OutputBaseFilename=OpenWebUI-Setup-{#MyAppVersion}

#ifexist "icon.ico"
SetupIconFile=icon.ico
UninstallDisplayIcon={app}\icon.ico
#endif

Compression=lzma2/ultra64
SolidCompression=yes
LZMAUseSeparateProcess=yes

PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog

WizardStyle=modern
WizardSizePercent=100

InfoAfterFile=README.md

AllowNoIcons=yes
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[CustomMessages]
english.AppName=Open WebUI
english.LaunchApp=Launch Open WebUI

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce

[Files]
; 嵌入式 Python（包含 pip）
Source: "python\*"; DestDir: "{app}\python"; Flags: ignoreversion recursesubdirs createallsubdirs

; 应用程序文件
Source: "embed_proxy.py"; DestDir: "{app}\app"; Flags: ignoreversion
Source: "requirements.txt"; DestDir: "{app}\app"; Flags: ignoreversion
Source: "install.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "start.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "stop.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "README.md"; DestDir: "{app}"; Flags: ignoreversion

#ifexist "icon.ico"
Source: "icon.ico"; DestDir: "{app}"; Flags: ignoreversion
#endif

[Dirs]
Name: "{app}\app"
Name: "{app}\app\logs"
Name: "{app}\data"
Name: "{app}\data\cache"
Name: "{app}\data\uploads"
Name: "{app}\data\vector_db"

[Icons]
Name: "{group}\Start Open WebUI"; Filename: "{app}\start.bat"; WorkingDir: "{app}"
Name: "{group}\Stop Open WebUI"; Filename: "{app}\stop.bat"; WorkingDir: "{app}"
Name: "{group}\README"; Filename: "{app}\README.md"
Name: "{group}\Open Install Directory"; Filename: "{app}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Open WebUI"; Filename: "{app}\start.bat"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{cmd}"; Parameters: "/c set ""INSTALL_DIR={app}"" && ""{app}\install.bat"""; WorkingDir: "{app}"; Flags: runhidden waituntilterminated; StatusMsg: "Configuring environment and downloading models (this may take a few minutes)..."
Filename: "{app}\start.bat"; Description: "{cm:LaunchApp}"; WorkingDir: "{app}"; Flags: nowait postinstall skipifsilent shellexec

[UninstallRun]
Filename: "{app}\stop.bat"; Parameters: "--no-pause"; WorkingDir: "{app}"; Flags: runhidden waituntilterminated

[UninstallDelete]
Type: filesandordirs; Name: "{app}\app\.venv"
Type: filesandordirs; Name: "{app}\app\logs"
Type: filesandordirs; Name: "{app}\app\__pycache__"
Type: filesandordirs; Name: "{app}\python"

[Code]
function InitializeUninstall(): Boolean;
begin
  Result := True;
  if MsgBox('Do you also want to delete user data (chat history, uploaded files, vector database)?'#13#10#13#10 + 
            'Click "Yes" to delete all data in the data directory'#13#10 + 
            'Click "No" to keep user data', mbConfirmation, MB_YESNO) = IDYES then
  begin
    DelTree(ExpandConstant('{app}\data'), True, True, True);
  end;
end;
