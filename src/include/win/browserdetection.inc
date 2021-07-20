uses LCLProc, Process, FileUtil, ShellApi, LCLType;

const
  TheDefaultBrowser: String = '';
  TheBrowserParams: String = '';

function ExecuteFile(const FileName: string): LongInt;
var
  zFileName, zParams, zDir: array[0..255] of Char;
  AHandle: THandle;
begin
  AHandle := ShellExecute(LongInt(nil), nil,
    StrPCopy(zFileName, FileName), StrPCopy(zParams, ''),
    StrPCopy(zDir, ''), SW_SHOWNORMAL);

  if AHandle <= 32 then
  begin
    Result := LongInt(AHandle);
    //DebugLn('ExecuteFule: Result = ',DbgS(Result));
  end
  else
  begin
    Result := OpenUrl_Success;
    //DebugLn('ExecuteFule: Result = ',DbgS(Result));
  end;
end;


procedure FindDefaultBrowser(out DefaultBrowser, BrowserParams: String);
begin
  DefaultBrowser := '';
  BrowserParams := '';
end;





function ExecuteBrowserWithURL(const Browser, URL, Params: String): LongInt;
var
  BrowserProc: TProcess;
begin
  if not FileExistsUTF8(Browser) then
  begin
    Result := OpenUrl_Error_NoBrowser;
    exit;
   end;
   BrowserProc := TProcess.Create(nil);
   try
     try
       BrowserProc.CommandLine := Browser + #32 + Params + #32 + Url;
       BrowserProc.Execute;
       //Debugln('BrowserProc.ExitStatus = ',DbgS(BrowserProc.ExitStatus));
       //Debugln('BrowserProc.ProcessID = ',DbgS(BrowserProc.ProcessID));
       //Debugln('BrowserProc.Handle = ',DbgS(BrowserProc.Handle));
       //Debugln('BrowserProc.Active = ',DbgS(BrowserProc.Active));
       Result := OpenUrl_Success;
     except
       Result := GetLastOSError;
     end;
   finally
     BrowserProc.Free;
   end;
end;


function OpenUrlInBrowser(URL, Params, BrowserExeName: String ): LongInt; overload;
begin
  URL := Trim(URL);
  URL := StringReplace(URL, #32, '%20', [rfReplaceAll]);
  if (BrowserExeName <> '') then
  begin
    Result := ExecuteBrowserWithURL(BrowserExeName, Params, URL);
  end
  else
  begin//BrowserExeName = ''
    Result := ExecuteFile(URL);
  end;
end;


