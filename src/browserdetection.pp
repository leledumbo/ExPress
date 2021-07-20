unit BrowserDetection;


{
 /***************************************************************************
                               BrowserDetection.pp
                               -------------------
 ***************************************************************************/

 *****************************************************************************
 *                                                                           *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,    *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}


{
 The purpose of this unit is to provide a cross-plaftorm mechanism to
 open a given URL in an external browser.
 It also gives the user the opportunity to use a specific browser.

 At startup the unit tries to detect the default browser (or url-handler) on
 the system. On Windows this detecting is not done, since the OS provides an
 own mechanisme to open URL's using the ShellExecute method.
 Users can override the default browser and the default parameters it expects.


}


{$mode objfpc}{$H+}

{$IFNDEF LINUX}
  {$IFNDEF WINDOWS}
    {$IFNDEF DARWIN}
    {$fatal This unit only works under Windows, Linux or Mac OSX (Darwin)}
    {$ENDIF DARWIN}
  {$ENDIF WINDOWS}
{$ENDIF LINUX}

interface

uses
  Classes, SysUtils; 

const
  OpenURL_Error_NoBrowser = 2;  //No browser specified or found
  OpenUrl_Error_FileNotExecutable = -1234;
  OpenURL_Success = 0;

function OpenUrlInBrowser(URL, Params, BrowserExeName: String): LongInt; overload;
function OpenUrlInBrowser(URL: String): LongInt; overload;
procedure GetDefaultBrowser(out ABrowser, AParams: String);
procedure SetDefaultBrowser(const ABrowser, AParams: String);
//Force a new browserdetection, without having to restart the app
Procedure DoBrowserDetection;


implementation

{$I browserdetection.inc}



function OpenUrlInBrowser(URL: String ): LongInt; overload;
begin
  Result := OpenUrlInBrowser(URL, '', '');
end;

procedure GetDefaultBrowser(out ABrowser, AParams: String);
begin
  ABrowser := TheDefaultBrowser;
  AParams := TheBrowserparams;
end;

procedure SetDefaultBrowser(const ABrowser, AParams: String);
begin
  TheDefaultBrowser := ABrowser;
  TheBrowserParams := AParams;
end;

procedure DoBrowserDetection;
begin
  FindDefaultBrowser(TheDefaultBrowser, TheBrowserParams);
end;


Initialization
  DoBrowserDetection;

end.


(*
function FilenameIsWinAbsolute(const TheFilename: string): boolean;
begin
  Result:=((length(TheFilename)>=2) and (TheFilename[1] in ['A'..'Z','a'..'z'])
           and (TheFilename[2]=':'))
     or ((length(TheFilename)>=2)
         and (TheFilename[1]='\') and (TheFilename[2]='\'));
end;

function FilenameIsUnixAbsolute(const TheFilename: string): boolean;
begin
  Result:=(TheFilename<>'') and (TheFilename[1]='/');
end;


function FilenameIsAbsolute(const TheFilename: string):boolean;
begin
  {$IFDEF win32}
  // windows
  Result:=FilenameIsWinAbsolute(TheFilename);
  {$ELSE}
  // unix
  Result:=FilenameIsUnixAbsolute(TheFilename);
  {$ENDIF}
end;


function SearchFileInPath(const Filename, BasePath, SearchPath: String; const Delimiter: string = PathSeparator): string; overload;
var
  p, StartPos, l: integer;
  CurPath, Base: string;
begin
  //debugln('[SearchFileInPath] Filename="',Filename,'" BasePath="',BasePath,'" SearchPath="',SearchPath,'" Delimiter="',Delimiter,'"');
  if (Filename='') then begin
    Result:=Filename;
    exit;
  end;
  // check if filename absolute
  if FilenameIsAbsolute(Filename) then begin
    if FileExists(Filename) then begin
      Result:=ExpandFilename(Filename);
      exit;
    end else begin
      Result:='';
      exit;
    end;
  end;
  if BasePath <> '' then
  begin
    Base:=ExpandFilename(IncludeTrailingPathDelimiter(BasePath));
    // search in current directory
    if FileExists(Base+Filename) then begin
      Result:=Base+Filename;
      exit;
    end;
  end;
  // search in search path
  StartPos:=1;
  l:=length(SearchPath);
  while StartPos<=l do begin
    p:=StartPos;
    while (p<=l) and (pos(SearchPath[p],Delimiter)<1) do inc(p);
    CurPath:=Trim(copy(SearchPath,StartPos,p-StartPos));
    if CurPath<>'' then begin
      if not FilenameIsAbsolute(CurPath) then
        CurPath:=Base+CurPath;
      Result:=ExpandFilename(IncludeTrailingPathDelimiter(CurPath)+Filename);
      if FileExists(Result) then exit;
    end;
    StartPos:=p+1;
  end;
  Result:='';
end;

function SearchFileInPath(const Filename, BasePath: String; const Delimiter: string = PathSeparator): string; overload;
begin
  Result := SearchFileInPath(FileName, BasePath, GetEnvironmentVariable('PATH'), Delimiter);
end;
*)
