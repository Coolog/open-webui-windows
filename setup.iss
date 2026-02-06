; ============================================================
; Open WebUI Windows 安装包配置
; 使用 Inno Setup 编译
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

; 如果没有 icon.ico，使用默认图标
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
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Messages]
chinesesimplified.BeveledLabel=Open WebUI 安装程序
chinesesimplified.WelcomeLabel1=欢迎使用 Open WebUI 安装向导
chinesesimplified.WelcomeLabel2=本向导将引导您完成 Open WebUI 的安装。%n%n安装内容包括：%n• Open WebUI 主程序%n• Embedding 代理服务%n• Ollama (如未安装)%n• AI 模型 (qwen2.5:7b, qwen3-embedding)%n%n建议关闭其他应用程序后继续。
chinesesimplified.SelectDirLabel3=请选择安装位置。程序和数据将存放在此目录下。
chinesesimplified.SelectDirBrowseLabel=点击"下一步"继续。如需选择其他文件夹，请点击"浏览"。
chinesesimplified.InfoAfterClickLabel=请阅读以下使用说明，然后点击"下一步"继续。

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce

[Files]
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
Name: "{group}\启动 Open WebUI"; Filename: "{app}\start.bat"; WorkingDir: "{app}"
Name: "{group}\停止 Open WebUI"; Filename: "{app}\stop.bat"; WorkingDir: "{app}"
Name: "{group}\使用说明"; Filename: "{app}\README.md"
Name: "{group}\打开安装目录"; Filename: "{app}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Open WebUI"; Filename: "{app}\start.bat"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{cmd}"; Parameters: "/c set ""INSTALL_DIR={app}"" && ""{app}\install.bat"""; WorkingDir: "{app}"; Flags: runhidden waituntilterminated; StatusMsg: "正在配置环境和下载模型（可能需要几分钟）..."
Filename: "{app}\start.bat"; Description: "立即启动 Open WebUI"; WorkingDir: "{app}"; Flags: nowait postinstall skipifsilent shellexec

[UninstallRun]
Filename: "{app}\stop.bat"; Parameters: "--no-pause"; WorkingDir: "{app}"; Flags: runhidden waituntilterminated

[UninstallDelete]
Type: filesandordirs; Name: "{app}\app\.venv"
Type: filesandordirs; Name: "{app}\app\logs"
Type: filesandordirs; Name: "{app}\app\__pycache__"

[Code]
function InitializeUninstall(): Boolean;
begin
  Result := True;
  if MsgBox('是否同时删除用户数据（对话记录、上传文件、向量数据库等）？' + #13#10 + #13#10 + 
            '选择"是"将删除 data 目录下的所有数据' + #13#10 + 
            '选择"否"将保留用户数据', mbConfirmation, MB_YESNO) = IDYES then
  begin
    DelTree(ExpandConstant('{app}\data'), True, True, True);
  end;
end;
