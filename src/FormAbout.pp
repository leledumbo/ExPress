unit FormAbout;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  FileUtil;

type

  { TAboutForm }

  TAboutForm = class(TForm)
    BtnOK: TButton;
    GroupAbout: TGroupBox;
    ExplExpress: TLabel;
    ExplGPL1: TLabel;
    ExplGPL2: TLabel;
    LinkEmail: TLabel;
    LinkUPX: TLabel;
    LinkColorProgress: TLabel;
    Thanks: TLabel;
    Wile64: TLabel;
    LblComponent: TLabel;
    LinkBrowserDetection: TLabel;
    procedure LinkUPXClick(Sender: TObject);
    procedure LinkEmailClick(Sender: TObject);
    procedure WhenMouseLeave(Sender: TObject);
    procedure WhenMouseEnter(Sender: TObject);
    procedure LinkColorProgressClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

implementation

uses
  LCLIntf;

{ TAboutForm }

procedure TAboutForm.WhenMouseEnter(Sender: TObject);
begin
  with TLabel(Sender).Font do begin
    Color := clHighlight;
    Style := [fsUnderline];
  end;
end;

procedure TAboutForm.WhenMouseLeave(Sender: TObject);
begin
  with TLabel(Sender).Font do begin
    Color := clWindowText;
    Style := [];
  end;
end;

procedure TAboutForm.LinkUPXClick(Sender: TObject);
begin
  OpenURL('http://upx.sourceforge.net');
end;

procedure TAboutForm.LinkEmailClick(Sender: TObject);
begin
  OpenURL('mailto:leledumbo_cool@yahoo.co.id');
end;

procedure TAboutForm.LinkColorProgressClick(Sender: TObject);
begin
  OpenURL('http://wile64.free.fr');
end;

{$if (FPC_VERSION >= 2) and (FPC_RELEASE >= 4)}
  {$R *.lfm}
{$else}
initialization
  {$I FormAbout.lrs}
{$endif}

end.

