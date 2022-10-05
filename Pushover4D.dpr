program Pushover4D;

uses
  System.StartUpCopy,
  FMX.Forms,
  uMain in 'uMain.pas' {frmMain},
  Rac.Pushover in 'Rac.Pushover.pas',
  Rac.Json.Reader in 'Rac.Json.Reader.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
