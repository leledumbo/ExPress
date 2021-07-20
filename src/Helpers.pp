unit Helpers;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Dialogs;

procedure Error(AMsg: String);
function FormatFileSize(FilePath: String): String;

implementation

procedure Error(AMsg: String);
begin
  MessageDlg('ERROR!', AMsg, mtError, [mbOK], 0);
end;

function FormatFileSize(FilePath: String): String;
var
  TheFileSize: Int64;
  StrFileSize: String;
begin
  TheFileSize := FileSize(FilePath);
  if TheFileSize = -1 then begin
    Result := '';
    Exit;
  end;
  StrFileSize := IntToStr(TheFileSize);
  case Length(StrFileSize) of
    1..3: Result := StrFileSize + ' B';
    4..6: Result := IntToStr(TheFileSize shr 10) + ' KB';
    7..9: Result := IntToStr(TheFileSize shr 20) + ' MB';
    else Result := IntToStr(TheFileSize shr 30) + ' GB';
  end;
end;

end.

