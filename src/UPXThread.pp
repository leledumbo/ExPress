unit UPXThread;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SyncObjs, ComCtrls;

type

  TUPXThreadFinishCallback = procedure(AListItem: TListItem; const AResultMsg: String) of object;

  { TUPXThread }

  TUPXThread = class(TThread)
  private
    { Private declarations }
    FListItem: TListItem;
    FThreadCount: PInteger;
    FUPXPath: String;
    FUPXArgs: TStrings;
    FResultMsg: String;
    FFinishCallback: TUPXThreadFinishCallback;
    procedure UpdateStatus;
  public
    property ResultMsg: String read FResultMsg;
    constructor Create(const AListItem: TListItem; AThreadCount: PInteger;
      const AUPXPath: String; const AUPXArgs: TStrings;
      AFinishCallback: TUPXThreadFinishCallback);
    destructor Destroy; override;
    procedure Execute; override;
  end;

  TUPXThreadRunnerCallerCallback = procedure (AListItem: TListItem;
    const AResultMsg: String; const AFilesDone: Integer) of object;

  { TUPXThreadRunner }

  TUPXThreadRunner = class(TThread)
  private
    FFiles: TListItems;
    FCompressionLevel: Integer;
    FUPXPath: String;
    FCallerCallback: TUPXThreadRunnerCallerCallback;
    FDoneCount: Integer;
    FListItemCS: TCriticalSection;
    procedure UpdateStateAndTellCaller(AListItem: TListItem;
      const AResultMsg: String);
  public
    constructor Create(AFiles: TListItems; const ACompressionLevel: Integer;
      AUPXPath: String; ACallerCallback: TUPXThreadRunnerCallerCallback);
    procedure Execute; override;
  end;

implementation

uses
  StrUtils, Process, AppOptions;

{ TUPXThreadRunner }

constructor TUPXThreadRunner.Create(AFiles: TListItems;
  const ACompressionLevel: Integer; AUPXPath: String;
  ACallerCallback: TUPXThreadRunnerCallerCallback);
begin
  FFiles := AFiles;
  FCompressionLevel := ACompressionLevel;
  FUPXPath := AUPXPath;
  FCallerCallback := ACallerCallback;
  inherited Create(false);
end;

procedure TUPXThreadRunner.Execute;

  function GenerateUPXArg(const Compress: Boolean): TStrings; inline;
  begin
    Result := TStringList.Create;
    if Compress then begin
      if FCompressionLevel < 9 then
        Result.Add('-' + IntToStr(FCompressionLevel + 1))
      else
        Result.Add('--best');
      with CompTune do begin
        if LZMA then
          Result.Add('--lzma');
        if Force then
          Result.Add('-f');
        if Brute then
          Result.Add('--brute');
        if UltraBrute then
          Result.Add('--ultra-brute');
      end;
      case Overlay of
        olCopy : Result.Add('--overlay=copy');
        olStrip: Result.Add('--overlay=strip');
        olSkip : Result.Add('--overlay=skip');
      end;
      with Additional do begin
        if AllMethods then
          Result.Add('--all-methods');
        if AllFilters then
          Result.Add('--all-filters');
      end;
      if Other.KeepBackup then
        Result.Add('-k');
    end else
      Result.Add('-d');
  end;

var
  CurrentFile: TListItem;
  FileCount, ThreadCount, NextFileIndex: Integer;
begin
  FileCount := FFiles.Count;
  FDoneCount := 0;
  NextFileIndex := 0;
  ThreadCount := 0;
  FListItemCS := TCriticalSection.Create;
  while FDoneCount < FileCount do begin
    { create new thread only if not all files have been handled (not
      necessarily processed) and number of running threads hasn't exceed the
      given limit }
    if (NextFileIndex < FileCount) and (ThreadCount < UPXThreadCount) then begin
      CurrentFile := FFiles[NextFileIndex];
      TUPXThread.Create(CurrentFile, @ThreadCount, FUPXPath,
        GenerateUPXArg(CurrentFile.Checked), @UpdateStateAndTellCaller);
      Inc(NextFileIndex);
    end else begin
      Sleep(1);
    end;
  end;
  { possible problem: when all files have been processed but the last thread
    hasn't been destroyed yet, above loop would terminate and possibly this
    method as well, destroying the stack frame of ThreadCount variable and
    would cause Access Violation because in thread's destructor, this variable
    would be decremented }
  while ThreadCount > 0 do Sleep(1);
  FListItemCS.Free;
end;

procedure TUPXThreadRunner.UpdateStateAndTellCaller(AListItem: TListItem;
  const AResultMsg: String);
begin
  FListItemCS.Acquire;
  try
    Inc(FDoneCount);
    FCallerCallback(AListItem,AResultMsg,FDoneCount);
  finally
    FListItemCS.Release;
  end;
end;

{ TUPXThread }

procedure TUPXThread.Execute;
var
  TempPos: LongWord;
begin
  with TProcess.Create(nil) do
    try
      try
        Options := [poWaitOnExit, poNoConsole, poUsePipes];
          {$if FPC_FULLVERSION < 20600}
        FUPXArgs.Delimiter := ' ';
        CommandLine := FUPXPath + FUPXArgs.DelimitedText +
          ' "' + AListItem.SubItems[0] + '"';
          {$else}
        Executable := FUPXPath;
        Parameters.AddStrings(FUPXArgs);
        Parameters.Add(FListItem.SubItems[0]);
          {$endif}
        FUPXArgs.Free;
        Execute;
        if ExitStatus <> 0 then
        begin
          with TStringList.Create do
            try
              LoadFromStream(StdErr);
              FResultMsg := Text;
            finally
              Free;
            end;
          TempPos := RPosEx(':', FResultMsg, RPos(':', FResultMsg) - 1);
          if FResultMsg[TempPos + 1] <> DirectorySeparator then
            FResultMsg :=
              Copy(FResultMsg, TempPos + 1, Length(FResultMsg) - TempPos)
          else
            FResultMsg :=
              Copy(FResultMsg, TempPos - 1, Length(FResultMsg) - TempPos);
        end else
          FResultMsg := 'OK';
      except
        on e: Exception do
          FResultMsg := e.Message;
      end;
      Synchronize(@UpdateStatus);
    finally
      Free;
    end;
end;

procedure TUPXThread.UpdateStatus;
begin
  FFinishCallback(FListItem, FResultMsg);
end;

constructor TUPXThread.Create(const AListItem: TListItem; AThreadCount: PInteger;
  const AUPXPath: String; const AUPXArgs: TStrings;
  AFinishCallback: TUPXThreadFinishCallback);
begin
  FreeOnTerminate := True;
  FListItem := AListItem;
  FThreadCount := AThreadCount;
  FFinishCallback := AFinishCallback;
  FUPXPath := AUPXPath;
  FUPXArgs := AUPXArgs;
  Inc(FThreadCount^);
  inherited Create(False);
end;

destructor TUPXThread.Destroy;
begin
  Dec(FThreadCount^);
end;

end.
