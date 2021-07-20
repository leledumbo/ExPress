unit AppOptions; 

{$mode objfpc}{$H+}

interface

uses
  Process;

var
  CompTune: record
    LZMA, Force, Brute, UltraBrute: Boolean;
  end;
  Overlay: (olCopy, olStrip, olSkip);
  Additional: record
    AllMethods, AllFilters: Boolean;
  end;
  Other: record
    KeepBackup, SaveAsDef: Boolean;
  end;
  UPXThreadCount: Byte;

implementation

end.

