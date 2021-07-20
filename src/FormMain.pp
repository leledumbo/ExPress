unit FormMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, ExtCtrls, Buttons, FileUtil, IniPropStorage;

type

  { TMainForm }

  TMainForm = class(TForm)
    BtnAddFile: TButton;
    BtnAddFolder: TButton;
    BtnExecute: TButton;
    BtnAdvanced: TButton;
    BtnSelAll: TButton;
    BtnDeselAll: TButton;
    BtnInvertSel: TButton;
    CheckRecurse: TCheckBox;
    GroupExecute: TGroupBox;
    UserPrefs: TIniPropStorage;
    ListFile: TListView;
    DlgAddFile: TOpenDialog;
    DlgAddDir: TSelectDirectoryDialog;
    GroupInput: TGroupBox;
    GroupOutput: TGroupBox;
    GroupUPXOpts: TGroupBox;
    TrackCompLvl: TTrackBar;
    BtnAbout: TButton;
    BtnHelp: TButton;
    ExPressLogo: TImage;
    CompProgress: TProgressBar;
    PanelLevel: TPanel;
    LabelFaster: TLabel;
    LabelCurLvl: TLabel;
    LabelBetter: TLabel;
    FastestOrBest: TLabel;
    procedure BtnAboutClick(Sender: TObject);
    procedure BtnAddFileClick(Sender: TObject);
    procedure BtnAddFolderClick(Sender: TObject);
    procedure BtnExecuteClick(Sender: TObject);
    procedure BtnAdvancedClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of String);
    procedure ListFileColumnClick(Sender: TObject; Column: TListColumn);
    procedure ListFileKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure TrackCompLvlChange(Sender: TObject);
    procedure UserPrefsRestoreProperties(Sender: TObject);
    procedure UserPrefsSaveProperties(Sender: TObject);
    procedure BtnSelAllClick(Sender: TObject);
    procedure BtnDeselAllClick(Sender: TObject);
    procedure BtnInvertSelClick(Sender: TObject);
    procedure ListFileResize(Sender: TObject);
  private
    function FileAlreadyInList(const FilePath: String): Boolean;
    function AddFile(const FilePath: String): Boolean;
    procedure AddDir(Directory: String; Recursive: Boolean);
    procedure CheckAll(const Checked: Boolean);
    procedure EnableControls(const Enable: Boolean);
    procedure CleanProgressAndResult;
    procedure UpdateListViewAndProgress(AListItem: TListItem;
      const AResultMsg: String; const AFilesDone: Integer);
  public
    { public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$if FPC_FULLVERSION >= 20400}
  {$R *.lfm}
{$endif}

uses
  FormAdv, FormAbout, AppOptions, Helpers, UPXThread;

{ TMainForm functions/procedures }

function TMainForm.FileAlreadyInList(const FilePath: String): Boolean;
var
  i: Integer;
begin
  Result := False;
  if ListFile.Items.Count = 0 then
    Exit;
  i := 0;
  repeat
    if ListFile.Items.Item[i].SubItems.Strings[0] = FilePath then
      Result := True;
    Inc(i);
  until Result or (i = ListFile.Items.Count);
end;

function TMainForm.AddFile(const FilePath: String): Boolean;

  function Supported(const Ext: String): Boolean;
  const
    {$ifdef Windows}
    SupportedFmtCount = 10;
    {$endif}
    {$ifdef Unix}
    SupportedFmtCount = 11;
    {$endif}
  var
    SupportedFmt: array [0..SupportedFmtCount - 1] of
    String = ('.exe', '.dll', '.com', '.sys', '.ocx', '.scr',
      '.dpl', '.bpl', '.acm', '.ax'
{$ifdef Unix}
      , ''
{$endif}
      );
    i: Byte;
  begin
    Result := False;
    i := Low(SupportedFmt);
    repeat
      if LowerCase(Ext) = SupportedFmt[i] then
        Result := True;
      Inc(i);
    until Result or (i > High(SupportedFmt));
  end;

  function IsUPXedAlready: Boolean;
  begin
    with TStringList.Create do
      try
        LoadFromFile(FilePath);
        Result := Pos('UPX!', Text) > 0;
      finally
        Free;
      end;
  end;

var
  NewItem: TListItem;
  NewFileSize: String;
  Ext: String;
begin
  Result := True;
  Ext := ExtractFileExt(FilePath);
  if not Supported(Ext) then begin
    Result := False;
    Exit;
  end;
  NewFileSize := FormatFileSize(FilePath);
  if NewFileSize = '' then
    Exit;
  if not FileAlreadyInList(FilePath) then begin
    NewItem := ListFile.Items.Add;
    with NewItem do begin
      Caption := ExtractFileName(FilePath);
      SubItems.Add(FilePath);
      SubItems.Add(NewFileSize);
      SubItems.Add('');
      SubItems.Add('');
      Checked := not IsUPXedAlready;
    end;
  end else
    Error('The file "' + FilePath + '" is already in the list!');
end;

procedure TMainForm.AddDir(Directory: String; Recursive: Boolean);
var
  Info: TSearchRec;
begin
  ListFile.BeginUpdate;
  try
    Directory := IncludeTrailingBackslash(Directory);
    if FindFirst(Directory + AllFilesMask, 0, Info) = 0 then
      try
        repeat
          AddFile(Directory + Info.Name);
        until FindNext(Info) <> 0;
      finally
        FindClose(Info);
      end;
    if Recursive and (FindFirst(Directory + '*', faDirectory, Info) = 0) then
      try
        repeat
          if (Info.Name <> '.') and (Info.Name <> '') and
            (Info.Name <> '..') and ((Info.Attr and faDirectory) <> 0) then
            AddDir(Directory + Info.Name, True);
        until FindNext(Info) <> 0;
      finally
        FindClose(Info);
      end;
  finally
    ListFile.EndUpdate;
  end;
end;

procedure TMainForm.EnableControls(const Enable: Boolean);
begin
  BtnAddFile.Enabled := Enable;
  BtnAddFolder.Enabled := Enable;
  CheckRecurse.Enabled := Enable;

  TrackCompLvl.Enabled := Enable;
  BtnAdvanced.Enabled := Enable;

  BtnHelp.Enabled := Enable;
  BtnAbout.Enabled := Enable;
  BtnExecute.Enabled := Enable;

  BtnSelAll.Enabled := Enable;
  BtnDeselAll.Enabled := Enable;
  BtnInvertSel.Enabled := Enable;

  ListFile.Enabled := Enable;
end;

procedure TMainForm.CleanProgressAndResult;
var
  i: Integer;
begin
  for i := 0 to ListFile.Items.Count - 1 do
    with ListFile.Items[i] do begin
      SubItems[3] := '';
      SubItems[2] := '';
    end;
  CompProgress.Position := 0;
end;

{ TMainForm events }

procedure TMainForm.BtnAddFileClick(Sender: TObject);
var
  NumOfFiles: Byte;
begin
  if DlgAddFile.Execute then
    for NumOfFiles := 0 to DlgAddFile.Files.Count - 1 do
      AddFile(DlgAddFile.Files.Strings[NumOfFiles]);
end;

procedure TMainForm.BtnAboutClick(Sender: TObject);
begin
  with TAboutForm.Create(Self) do
    try
      ShowModal;
    finally
      Free;
    end;
end;

procedure TMainForm.BtnAddFolderClick(Sender: TObject);
begin
  if DlgAddDir.Execute then
    AddDir(DlgAddDir.FileName, CheckRecurse.Checked);
end;

procedure TMainForm.BtnExecuteClick(Sender: TObject);
var
  UPXFile: String;
begin
  if ListFile.Items.Count = 0 then
    Error('No file(s) specified!')
  else begin
    UPXFile := FindDefaultExecutablePath('upx');
    if UPXFile = '' then begin
      Error(
        'UPX executable not found!' + LineEnding +
        'Please put it somewhere in system PATH (must be named upx'
        {$ifdef windows} + '.exe' {$endif}
        + ')'
      );
    end else begin
      CleanProgressAndResult;
      EnableControls(False);
      TUPXThreadRunner.Create(ListFile.Items,TrackCompLvl.Position,UPXFile,
        @UpdateListViewAndProgress);
    end;
  end;
end;

procedure TMainForm.BtnAdvancedClick(Sender: TObject);
begin
  with TAdvForm.Create(Self) do
    try
      ShowModal;
    finally
      Free;
    end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  Files: array of String;
  i: Integer;
  {$ifdef unix}
  IniFilePath: String;
  {$endif}
begin
  {$ifdef unix}
  IniFilePath := AppendPathDelim(ExtractFilePath(Application.ExeName));
  UserPrefs.IniFileName := IniFilePath + '.' +
    ExtractFileName(Application.ExeName);
  {$endif}
  with ListFile do begin
    GridLines := True;
    ShowHint := True;
  end;
  SetLength(Files, ParamCount);
  for i := 0 to ParamCount - 1 do
    Files[i] := ParamStr(i + 1);
  FormDropFiles(Self, Files);
end;

procedure TMainForm.FormDropFiles(Sender: TObject;
  const FileNames: array of String);
var
  i: Integer;
begin
  for i := Low(FileNames) to High(FileNames) do
    if DirPathExists(FileNames[i]) then
      AddDir(FileNames[i], CheckRecurse.Checked)
    else if not AddFile(FileNames[i]) then
      Error('The File "' + FileNames[i] + '" is not supported!');
end;

procedure TMainForm.ListFileColumnClick(Sender: TObject; Column: TListColumn);
const
  Descending: Boolean = False;

  procedure QuickSort(var Items: TListItems; l, r, Comparator: Integer);
  var
    i, j: Integer;
    MidSz: Int64;
    Mid: String;
    Tmp: TListItem;
  begin
    i := l;
    j := r;
    if Comparator > 0 then
      if Comparator in [2, 3] then
        MidSz := FileSize(Items.Item[(l + r) div 2].SubItems.Strings[0])
      else
        Mid := Items.Item[(l + r) div 2].SubItems.Strings[0]
    else
      Mid := Items.Item[(l + r) div 2].Caption;
    repeat
      if Comparator > 0 then
        if Comparator in [2, 3] then
          try
            while FileSize(Items.Item[i].SubItems.Strings[0]) < MidSz do
              Inc(i);
            while MidSz < FileSize(Items.Item[j].SubItems.Strings[0]) do
              Dec(j);
          except
            on e: Exception do
              ShowMessage(e.Message);
          end else begin
          while CompareText(Items.Item[i].SubItems.Strings[0], Mid) < 0 do
            Inc(i);
          while CompareText(Mid, Items.Item[j].SubItems.Strings[0]) < 0 do
            Dec(j);
        end else begin
        while CompareText(Items.Item[i].Caption, Mid) < 0 do
          Inc(i);
        while CompareText(Mid, Items.Item[j].Caption) < 0 do
          Dec(j);
      end;
      if i <= j then begin
        Tmp := Items.Item[i];
        Items.Item[i] := Items.Item[j];
        Items.Item[j] := Tmp;
        Inc(i);
        Dec(j);
      end;
    until i > j;
    if i < r then
      QuickSort(Items, i, r, Comparator);
    if l < j then
      QuickSort(Items, l, j, Comparator);
  end;

  procedure ReverseItems;
  var
    i, j: Integer;
    Tmp: TListItem;
  begin
    i := 0;
    j := ListFile.Items.Count - 1;
    while i < j do begin
      Tmp := ListFile.Items.Item[i];
      ListFile.Items.Item[i] := ListFile.Items.Item[j];
      ListFile.Items.Item[j] := Tmp;
      Inc(i);
      Dec(j);
    end;
  end;

var
  TempItems: TListItems;
begin
  if (Column.Index <> 4) and (ListFile.Items.Count > 0) then begin
    TempItems := ListFile.Items;
    QuickSort(TempItems, 0, ListFile.Items.Count - 1, Column.Index);
    if Descending then
      ReverseItems;
    Descending := not Descending;
    ListFile.Items := TempItems;
  end;
end;

procedure TMainForm.ListFileKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  i: Integer;
begin
  if Key = 46 then // Delete key pressed
    with ListFile.Items do
      if Count > 0 then
        try
          ListFile.BeginUpdate;
          i := 0;
          while Item[i] <> nil do
            if Item[i].Selected then begin
              Item[i].Free;
              if i > 0 then
                Dec(i);
            end else
              Inc(i);
        finally
          ListFile.EndUpdate;
        end;
end;

procedure TMainForm.TrackCompLvlChange(Sender: TObject);
begin
  if TrackCompLvl.Position < 9 then
    LabelCurLvl.Caption := ' ' + IntToStr(TrackCompLvl.Position + 1)
  else
    LabelCurLvl.Caption := IntToStr(TrackCompLvl.Position + 1);
  with FastestOrBest do
    case TrackCompLvl.Position of
      0: Caption := 'Fastest';
      9: Caption := 'Best';
      else Caption := ' ';
    end;
end;

procedure TMainForm.UserPrefsRestoreProperties(Sender: TObject);
begin
  with UserPrefs do begin
    IniSection := 'AdvancedOpts';
    with CompTune do begin
      LZMA := ReadBoolean('LZMA', False);
      Force := ReadBoolean('Force', False);
      Brute := ReadBoolean('Brute', False);
      UltraBrute := ReadBoolean('UltraBrute', False);
    end;
    Ord(Overlay) := ReadInteger('Overlay', 0);
    with Additional do begin
      AllMethods := ReadBoolean('AllMethods', False);
      AllFilters := ReadBoolean('AllFilters', False);
    end;
    with Other do begin
      KeepBackup := ReadBoolean('KeepBackup', False);
      SaveAsDef := ReadBoolean('SaveAsDefault', False);
    end;
    UPXThreadCount := ReadInteger('ThreadCount', 1);
    IniSection := 'Preferences';
  end;
  TrackCompLvlChange(nil);
end;

procedure TMainForm.UserPrefsSaveProperties(Sender: TObject);
begin
  UserPrefs.IniSection := 'AdvancedOpts';
  if Other.SaveAsDef then
    with UserPrefs do begin
      with CompTune do begin
        WriteBoolean('LZMA', LZMA);
        WriteBoolean('Force', Force);
        WriteBoolean('Brute', Brute);
        WriteBoolean('UltraBrute', UltraBrute);
      end;
      WriteInteger('Overlay', Ord(Overlay));
      with Additional do begin
        WriteBoolean('AllMethods', AllMethods);
        WriteBoolean('AllFilters', AllFilters);
      end;
      WriteBoolean('KeepBackup', Other.KeepBackup);
      WriteInteger('ThreadCount', UPXThreadCount);
    end;
  with UserPrefs do begin
    WriteBoolean('SaveAsDefault', Other.SaveAsDef);
    IniSection := 'Preferences';
  end;
end;

procedure TMainForm.CheckAll(const Checked: Boolean);
var
  i: Integer;
begin
  with ListFile.Items do
    for i := 0 to Count - 1 do
      Item[i].Checked := Checked;
end;

procedure TMainForm.BtnSelAllClick(Sender: TObject);
begin
  CheckAll(True);
end;

procedure TMainForm.BtnDeselAllClick(Sender: TObject);
begin
  CheckAll(False);
end;

procedure TMainForm.BtnInvertSelClick(Sender: TObject);
var
  i: Integer;
begin
  with ListFile.Items do
    for i := 0 to Count - 1 do
      Item[i].Checked := not Item[i].Checked;
end;

procedure TMainForm.ListFileResize(Sender: TObject);
begin
  ListFile.Column[4].Width := ListFile.Width - 362;
end;

procedure TMainForm.UpdateListViewAndProgress(AListItem: TListItem;
  const AResultMsg: String; const AFilesDone: Integer);
begin
  with AListItem do begin
    SubItems[3] := AResultMsg;
    SubItems[2] := FormatFileSize(SubItems[0]);
  end;
  CompProgress.Position := AFilesDone * 100 div ListFile.Items.Count;
  if CompProgress.Position >= 100 then
    EnableControls(True);
end;

initialization
{$if FPC_FULLVERSION < 20400}
  {$I FormMain.lrs}
{$endif}

end.

