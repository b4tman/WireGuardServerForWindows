#define MyAppName "WireGuard Server for Windows"
#define MyAppVersion "1.6.1"
#define MyAppPublisher "Micah Morrison"
#define MyAppURL "https://github.com/micahmo/WireGuardServerForWindows"
#define MyAppExeName "WireGuardServerForWindows.exe"
#define CliName "ws4w.exe"
#define NetCoreRuntimeVersion "3.1.21"
#define NetCoreRuntime "windowsdesktop-runtime-" + NetCoreRuntimeVersion + "-win-x64.exe"
#define UniversalCrtKb "KB3118401"

; This is relative to SourceDir
#define RepoRoot "..\..\..\.."

[Setup]
;PrivilegesRequired=admin
AppId={{7EE6B381-7799-4674-B83C-5B07C71A5851}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\WS4W
DefaultGroupName=WS4W
AllowNoIcons=yes
; This is relative to the .iss file location
SourceDir=..\WireGuardServerForWindows\bin\Release\netcoreapp3.1\
; These are relative to SourceDir (see RepoRoot)
OutputDir={#RepoRoot}\Installer
SetupIconFile={#RepoRoot}\WireGuardServerForWindows\Images\logo.ico
; This is an install-time path, so it must refer to something on the installed machine, like the main exe
UninstallDisplayIcon={app}\WireGuardServerForWindows.exe
OutputBaseFilename=WS4WSetup-{#MyAppVersion}
Compression=lzma
SolidCompression=yes
WizardStyle=modern
; .NET Core Desktop Runtime install can trigger this, but it doesn't actually require a restart
RestartIfNeededByRun=no

[CustomMessages]
UCrtError={#MyAppName} requires the Universal C Runtime. Please perform all outstanding Windows Updates or search for and install {#UniversalCrtKb} before installing WS4W.

[Code]
function NetCoreRuntimeNotInstalled: Boolean;
begin
  Result := not RegValueExists(HKEY_LOCAL_MACHINE, 'SOFTWARE\WOW6432Node\dotnet\Setup\InstalledVersions\x64\sharedfx\Microsoft.NETCore.App', '{#NetCoreRuntimeVersion}');
end;

// More info: https://docs.microsoft.com/en-us/cpp/windows/universal-crt-deployment?view=msvc-170
function UniversalCrtInstalled: Boolean;
begin
  Result := FileExists(ExpandConstant('{sys}') + '\ucrtbase.dll');
end;

// This is a buit-in function that's called during initialization.
// We'll use it to determine whether we can proceed with the install on this system.
function InitializeSetup(): Boolean;
begin
  if not UniversalCrtInstalled then
    begin
      MsgBox(ExpandConstant('{cm:UCrtError}'), mbCriticalError, MB_OK);
      Result := False;
    end
  else
    Result := True
end;

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "setpath"; Description: "Add '{app}' to the PATH variable for CLI access."; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; These are relative to SourceDir
Source: "*"; DestDir: "{app}"; Excludes: "de,es"; Flags: recursesubdirs;
Source: "..\..\..\..\Installer\{#NetCoreRuntime}"; DestDir: "{tmp}"; Flags: deleteafterinstall; Check: NetCoreRuntimeNotInstalled

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
; .NET Core Desktop Runtime
Filename: "{tmp}\{#NetCoreRuntime}"; Flags: runascurrentuser; StatusMsg: "Installing .NET Core Desktop Runtime..."; Check: NetCoreRuntimeNotInstalled

; CLI in Path
Filename: "{app}\{#CliName}"; Parameters: "setpath"; Flags: runhidden nowait skipifsilent runascurrentuser; Tasks: setpath

; runascurrentuser is needed to launch as admin
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent runascurrentuser

