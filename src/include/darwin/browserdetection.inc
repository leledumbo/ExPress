uses LCLProc, Process, FileUtil, BaseUnix;


const
  TheDefaultBrowser: String = '';
  TheBrowserParams: String = '';

const
  DefBrowsers: Array[0..7] of String =('firefox','iceweasel','opera','mozilla',
                 'netscape','konqueror', 'galeon','safari');
const
  darwin_open = 'open';




function FileIsExecutable(const AFilename: string): boolean;
begin
  Result:= BaseUnix.FpAccess(AFilename,BaseUnix.X_OK)=0;
end;


procedure FindDefaultBrowser(out DefaultBrowser, BrowserParams: String);
var i: Integer;
    OSPath: String;
    darwinopen: String;
begin
  DefaultBrowser := '';
  BrowserParams := '';
  OSPath := GetEnvironmentVariableUTF8('PATH');
  darwinopen := SearchFileInPath(darwin_open,'',OSPath,PathSeparator,[sffDontSearchInBasePath]);
  if (darwinopen <> '') and (DefaultBrowser = '') then
  begin
    DefaultBrowser := darwinopen;
  end;
  //If, at this point, we still haven't found a browser, we'll search for one manually
  if (DefaultBrowser = '') then
  begin
    for i := Low(DefBrowsers) to High(DefBrowsers) do
    begin
      DefaultBrowser := SearchFileInPath(DefBrowsers[i],'',OSPath,PathSeparator,[sffDontSearchInBasePath]);
      if (DefaultBrowser <> '') then Break;
    end;
  end;
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
   if not FileIsExecutable(Trim(Browser)) then
   begin
     Result := OpenUrl_Error_FileNoTExecutable;
     Exit;
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
    BrowserExeName := TheDefaultBrowser;
    if Params = '' then Params := TheBrowserParams;
    if (BrowserExeName = '') then Result := OpenUrl_Error_NoBrowser
    else Result := ExecuteBrowserWithURL(BrowserExeName, URL, Params);
  end;
end;


