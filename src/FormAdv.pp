unit FormAdv;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Spin;

type

  { TAdvForm }

  TAdvForm = class(TForm)
    BtnOK: TButton;
    CGAdditional: TCheckGroup;
    CGTuning: TCheckGroup;
    CGOther: TCheckGroup;
    RGOverlay: TRadioGroup;
    ThreadPanel: TPanel;
    LblThreadCount: TLabel;
    SpinEditThreadCount: TSpinEdit;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

implementation

uses
  AppOptions;

{ TAdvForm }

procedure TAdvForm.FormCreate(Sender: TObject);
begin
  with CompTune do
    with CGTuning do begin
      Checked[0] := LZMA;
      Checked[1] := Force;
      Checked[2] := Brute;
      Checked[3] := UltraBrute;
    end;
  RGOverlay.ItemIndex := Ord(Overlay);
  with Additional do
    with CGAdditional do begin
      Checked[0] := AllMethods;
      Checked[1] := AllFilters;
    end;
  with Other do
    with CGOther do begin
      Checked[0] := KeepBackup;
      Checked[1] := SaveAsDef;
    end;
  SpinEditThreadCount.Value := UPXThreadCount;
end;

procedure TAdvForm.FormDestroy(Sender: TObject);
begin
  if ModalResult = mrOK then begin
    with CompTune do
      with CGTuning do begin
        LZMA := Checked[0];
        Force := Checked[1];
        Brute := Checked[2];
        UltraBrute := Checked[3];
      end;
    Ord(Overlay) := RGOverlay.ItemIndex;
    with Additional do
      with CGAdditional do begin
        AllMethods := Checked[0];
        AllFilters := Checked[1];
      end;
    with Other do
      with CGOther do begin
        KeepBackup := Checked[0];
        SaveAsDef := Checked[1];
      end;
    UPXThreadCount := SpinEditThreadCount.Value;
  end;
end;

{$if (FPC_VERSION >= 2) and (FPC_RELEASE >= 4)}
  {$R *.lfm}
{$else}
initialization
  {$I FormAdv.lrs}
{$endif}

end.

