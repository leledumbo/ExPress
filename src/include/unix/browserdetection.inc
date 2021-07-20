uses LCLProc, Process, FileUtil, BaseUnix;


const
  TheDefaultBrowser: String = '';
  TheBrowserParams: String = '';


type
 TXDesktopType = (dtUnknown, dtKDE, dtGnome, dtXfce);

const
  DefBrowsers: Array[0..7] of String =('firefox','iceweasel','opera','mozilla',
                 'netscape','konqueror', 'galeon','safari');
const
  xdg_open = 'xdg-open';
  KDE_DESKTOP_LAUNCH = 'DESKTOP_LAUNCH';
  kde_open = 'kde-open';
  kfm_client = 'kfmclient';
  gnome_open = 'gnome-open';
  exo_open = 'exo-open';
  gnome_session = 'gnome-session';
  xfce_mcs_manage = 'xfce-mcs-manage';
  //sfce_mcs_manage = 'sfce-mcs-manage';
  ksmserver = 'ksmserver';


//const XDesktopToStr: array[TXDesktopType] of string = ('Unknown', 'KDE', 'Gnome', 'Xfce' );
function GetXDesktopType: TXDesktopType;
var
  Proc: tprocess;
  SL: TStringList;
  z: integer;
begin
  Result := dtUnknown;
  if UpperCase(GetEnvironmentVariable('KDE_FULL_SESSION')) = 'TRUE' then Result := dtKDE
  else if GetEnVironmentVariable('GNOME_DESTOP') <> '' then Result := dtGnome
  else
  begin
    //code by Graame Geldenhuys
    Proc := tprocess.Create(nil);
    SL := TStringList.Create;
    try
    Proc.CommandLine := 'ps -ux';
    Proc.Options := [poUsePipes, poWaitonexit];
    try
      Proc.Execute;
      SL.LoadFromStream(Proc.OutPut);
      for z := 0 to (SL.Count - 1) do
      begin
        if ansipos(gnome_session, SL[z]) > 0 then
          Result := dtGnome else
        if (ansipos(xfce_mcs_manage, SL[z]) > 0) {or (ansipos(sfce_mcs_manage, SL[z]) > 0)} then
          Result := dtXfce;
        if ansipos(ksmserver, SL[z]) > 0 then
          Result := dtKDE;
      end;//for
      except
        on E: Exception do
        begin
          DebugLn('Exception occurred after TProcess.Execute in function GetXDesktopType');
          DebugLn(E.Message);
          DumpStack;
        end;
      end;//try..except
    finally
      Proc.Free;
      SL.Free;
    end;//try..finally
  end;
  //DebugLn('XDeskTopType = ',XDesktopToStr[Result]);
end;


function FileIsExecutable(const AFilename: string): boolean;
begin
  Result:= BaseUnix.FpAccess(AFilename,BaseUnix.X_OK)=0;
end;


procedure FindDefaultBrowser(out DefaultBrowser, BrowserParams: String);
var i: Integer;
    OSPath: String;
    DT: TXDesktopType;
    xdgopen: string;
    kdedesktoplaunch: string;
    kdeopen: string;
    kfmclient: string;
    gnomeopen: string;
    exoopen: string;
begin
  DefaultBrowser := '';
  BrowserParams := '';
  OSPath := GetEnvironmentVariableUTF8('PATH');
  DT :=  GetXDesktopType;
  xdgopen := SearchFileInPath(xdg_open,'',OSPath,PathSeparator,[sffDontSearchInBasePath]);
  kdeopen := SearchFileInPath(kde_open,'',OSPath,PathSeparator,[sffDontSearchInBasePath]);
  kfmclient := SearchFileInPath(kfm_client,'',OSPath,PathSeparator,[sffDontSearchInBasePath]);
  gnomeopen := SearchFileInPath(gnome_open,'',OSPath,PathSeparator,[sffDontSearchInBasePath]);
  exoopen := SearchFileInPath(exo_open,'',OSPath,PathSeparator,[sffDontSearchInBasePath]);
  case DT of
    dtKDE:
    begin
      kdedesktoplaunch := GetEnvironmentVariable(KDE_DESKTOP_LAUNCH);
      if (kdedesktoplaunch <> '') then
        kdedesktoplaunch := SearchFileInPath(kdedesktoplaunch,'',OSPath,PathSeparator,[sffDontSearchInBasePath]);
      if (xdgopen <> '') and (DefaultBrowser = '') then
      begin
        //xdg-open corrects a wrong returncode in KDE <= 3.4, so we prefer this
        DefaultBrowser := xdgopen;
      end else
      if (kdedesktoplaunch <> '') and (DefaultBrowser = '') then
      begin
        DefaultBrowser := kdedesktoplaunch;
      end else
      if (kdeopen <> '') and (DefaultBrowser = '') then
      begin
        DefaultBrowser := kdeopen;
      end else
      if (kfmclient <> '') and (DefaultBrowser = '') then
      begin
        DefaultBrowser := kfmclient;
        TheBrowserParams := 'openURL ';
      end else
      if (gnomeopen <> '') and (DefaultBrowser = '') then
      begin
        DefaultBrowser := gnomeopen;
      end;
    end;//dtKDE
    dtGnome:
    begin
      if (xdgopen <> '') and (DefaultBrowser = '') then
      begin
        DefaultBrowser := xdgopen;
      end else
      if (gnomeopen <> '') and (DefaultBrowser = '') then
      begin
        DefaultBrowser := gnomeopen;
      end;
    end;//dtGnome
    dtXfce:
    begin
      if (xdgopen <> '') and (DefaultBrowser = '') then
      begin
        DefaultBrowser := xdgopen;
      end else
      if (exoopen <> '') and (DefaultBrowser = '') then
      begin
        DefaultBrowser := exoopen;
      end;//dtXfce
    end;//dtXfce
  end;//case
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
    Result := OpenUrl_Error_FileNotExecutable;
    Exit;
  end;
  BrowserProc := TProcess.Create(nil);
  try
    try
      BrowserProc.CommandLine := Browser + #32 + Params + #32 + Url;
      //DebugLn('BrowserProc.CommandLine = ',BrowserProc.CommandLine);
      BrowserProc.Execute;
      //Debugln('BrowserProc.ExitStatus = ',DbgS(BrowserProc.ExitStatus));
      //Debugln('BrowserProc.ProcessID = ',DbgS(BrowserProc.ProcessID));
      //Debugln('BrowserProc.Handle = ',DbgS(BrowserProc.Handle));
      //Debugln('BrowserProc.Active = ',DbgS(BrowserProc.Active));
      Result := OpenUrl_Success;
    except
      on E: Exception do
      begin
        Result := GetLastOSError;
        DebugLn('An exception occurred in ExecuteBrowserWithURL:');
        DebugLn(E.ClassName,': ',E.Message);
      end;
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


