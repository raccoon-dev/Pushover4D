unit uMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.StdCtrls, FMX.TabControl, FMX.ScrollBox, FMX.Memo, FMX.Edit, FMX.ListBox,
  FMX.Layouts, FMX.Controls.Presentation, FMX.Objects, FMX.DateTimeCtrls,
  Rac.Pushover, System.ImageList, FMX.ImgList;

type
  TfrmMain = class(TForm)
    GroupBox1: TGroupBox;
    ListBox1: TListBox;
    ListBoxItem1: TListBoxItem;
    ListBoxItem2: TListBoxItem;
    edtKeyUser: TEdit;
    edtKeyApi: TEdit;
    GroupBox2: TGroupBox;
    memContent: TMemo;
    edtImage: TEdit;
    Label1: TLabel;
    ListBox2: TListBox;
    ListBoxItem3: TListBoxItem;
    ListBoxItem4: TListBoxItem;
    ListBoxItem5: TListBoxItem;
    ListBoxItem6: TListBoxItem;
    ListBoxItem7: TListBoxItem;
    ListBoxItem8: TListBoxItem;
    ListBoxItem9: TListBoxItem;
    ListBoxItem10: TListBoxItem;
    TabControl1: TTabControl;
    TabItem1: TTabItem;
    TabItem2: TTabItem;
    btnSend: TSpeedButton;
    Rectangle1: TRectangle;
    Label2: TLabel;
    cbPriority: TComboBox;
    Label3: TLabel;
    edtLink: TEdit;
    btnClear1: TSpeedButton;
    btnImage: TSpeedButton;
    btnClear2: TSpeedButton;
    edtTitle: TEdit;
    Label4: TLabel;
    Rectangle2: TRectangle;
    Label5: TLabel;
    ListBoxGroupHeader1: TListBoxGroupHeader;
    ListBoxGroupHeader2: TListBoxGroupHeader;
    ListBoxItem11: TListBoxItem;
    ListBoxItem12: TListBoxItem;
    chkSetTimestamp: TCheckBox;
    edtDate: TDateEdit;
    edtTime: TTimeEdit;
    btnShowPass1: TSpeedButton;
    btnShowPass2: TSpeedButton;
    memLogs: TMemo;
    btnSaveLog: TSpeedButton;
    btnClear3: TSpeedButton;
    chkUseHtml: TCheckBox;
    ListBoxItem13: TListBoxItem;
    ListBoxItem14: TListBoxItem;
    ListBoxItem15: TListBoxItem;
    ListBoxItem16: TListBoxItem;
    ListBoxItem17: TListBoxItem;
    ListBoxItem18: TListBoxItem;
    edtLinkTitle: TEdit;
    Label8: TLabel;
    SpeedButton1: TSpeedButton;
    SpeedButton4: TSpeedButton;
    ilImages: TImageList;
    chkUseMonospace: TCheckBox;
    cbSound: TComboBox;
    Label9: TLabel;
    Rectangle3: TRectangle;
    Label6: TLabel;
    edtDevices: TEdit;
    SpeedButton2: TSpeedButton;
    dlgOpenImage: TOpenDialog;
    procedure btnClear1Click(Sender: TObject);
    procedure btnShowPass1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure btnShowPass1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure chkSetTimestampChange(Sender: TObject);
    procedure btnSendClick(Sender: TObject);
    procedure btnImageClick(Sender: TObject);
  private
    Pushover: TPushover;
    function  FormToMessage: TPushoverMessage;
    procedure _OnResponse(Status: Boolean; PushoverMessage: TPushoverMessage; Response: string);
    procedure _OnResponseEmergency(Status: Boolean; PushoverMessage: TPushoverMessage; Receipt: string; Response: string);
    procedure _OnGlance(Status: Boolean; Token: string; Response: string);
    procedure _OnValidateUser(Status: Boolean; UserKey: string; Devices: TStrings; Licenses: TStrings; Response: string);
    procedure _OnGetLimits(AppLimit, AppRemaining: Cardinal; AppReset: TDateTime);
    procedure _OnHTTPError(ErrorCode: Integer; ErrorText: string);
  public
    procedure Log(const Text: string); overload;
    procedure Log(const Text: string; const Args: array of const); overload;
  end;

var
  frmMain: TfrmMain;

implementation

{$I keys.inc}

{$R *.fmx}

procedure TfrmMain.btnClear1Click(Sender: TObject);
begin
  if Assigned(Sender) and (Sender is TFmxObject) then
    if Assigned((Sender as TFmxObject).Parent) and ((Sender as TFmxObject).Parent is TEdit) then
      ((Sender as TFmxObject).Parent as TEdit).Text := ''
    else
    if Assigned((Sender as TFmxObject).Parent) and ((Sender as TFmxObject).Parent is TMemo) then
      ((Sender as TFmxObject).Parent as TMemo).Lines.Clear;
end;

procedure TfrmMain.btnImageClick(Sender: TObject);
begin
  if dlgOpenImage.Execute then
    edtImage.Text := dlgOpenImage.FileName;
end;

procedure TfrmMain.btnSendClick(Sender: TObject);
begin
  Pushover.Send(FormToMessage);
end;

procedure TfrmMain.btnShowPass1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if Assigned(Sender) and (Sender is TFmxObject) then
    if Assigned((Sender as TFmxObject).Parent) and ((Sender as TFmxObject).Parent is TEdit) then
      ((Sender as TFmxObject).Parent as TEdit).Password := False;
end;

procedure TfrmMain.btnShowPass1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if Assigned(Sender) and (Sender is TFmxObject) then
    if Assigned((Sender as TFmxObject).Parent) and ((Sender as TFmxObject).Parent is TEdit) then
      ((Sender as TFmxObject).Parent as TEdit).Password := True;
end;

procedure TfrmMain.chkSetTimestampChange(Sender: TObject);
begin
  edtDate.Enabled := chkSetTimestamp.IsChecked;
  edtTime.Enabled := chkSetTimestamp.IsChecked;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  Pushover                     := TPushover.Create;
  Pushover.OnResponse          := _OnResponse;
  Pushover.OnResponseEmergency := _OnResponseEmergency;
  Pushover.OnGlance            := _OnGlance;
  Pushover.OnValidateUser      := _OnValidateUser;
  Pushover.OnGetLimits         := _OnGetLimits;
  Pushover.OnHTTPError         := _OnHTTPError;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  Pushover.DisposeOf;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  edtKeyUser.Text := USER_KEY;
  edtKeyApi.Text  := API_KEY;
end;

function TfrmMain.FormToMessage: TPushoverMessage;
var
  prior: TPushoverPriority;
  snd: TPushoverSound;
  ts: TDateTime;
begin
  if memContent.Lines.Text.Trim = '' then
  begin
    memContent.SetFocus;
    raise Exception.Create('Content can''t be empty, it is only necessary field except User Key and API Key.');
  end;

  // Do not forget! That two fields are mandatory.
  Pushover.UserKey := edtKeyUser.Text; // UserKey might be replaced with GroupKey
  Pushover.ApiKey  := edtKeyApi.Text;

  case cbPriority.ItemIndex of
    0: prior := TPushoverPriority.ppEmergency;
    1: prior := TPushoverPriority.ppHigh;
    2: prior := TPushoverPriority.ppNormal;
    3: prior := TPushoverPriority.ppLower;
    4: prior := TPushoverPriority.ppLowest;
  else
    raise Exception.Create('Wrong priority value');
  end;

  // In real app you should assign snd variable more properly:
  //  if cbSound.ItemIndex < 0 then
  //    snd := TPushoverSound.sndClentDefault
  //  else
  //    snd := TPushoverSound(cbSound.ItemIndex);
  case cbSound.ItemIndex of
     1: snd := TPushoverSound.sndPushover;
     2: snd := TPushoverSound.sndBike;
     3: snd := TPushoverSound.sndBugle;
     4: snd := TPushoverSound.sndCashRegister;
     5: snd := TPushoverSound.sndClassical;
     6: snd := TPushoverSound.sndCosmic;
     7: snd := TPushoverSound.sndFalling;
     8: snd := TPushoverSound.sndGamelan;
     9: snd := TPushoverSound.sndIncoming;
    10: snd := TPushoverSound.sndIntermission;
    11: snd := TPushoverSound.sndMagic;
    12: snd := TPushoverSound.sndMechanical;
    13: snd := TPushoverSound.sndPianoBar;
    14: snd := TPushoverSound.sndSiren;
    15: snd := TPushoverSound.sndSpaceAlarm;
    16: snd := TPushoverSound.sndTugBoat;
    17: snd := TPushoverSound.sndAlien;
    18: snd := TPushoverSound.sndClimb;
    19: snd := TPushoverSound.sndPersistent;
    20: snd := TPushoverSound.sndEcho;
    21: snd := TPushoverSound.sndUpDown;
    22: snd := TPushoverSound.sndVibrate;
    23: snd := TPushoverSound.sndNone;
  else
    snd := TPushoverSound.sndClientDefault;
  end;

  if chkSetTimestamp.IsChecked then
    ts := Int(edtDate.Date) +
          (Trunc(edtTime.Time * MinsPerDay) / MinsPerDay)
  else
    ts := 0.0;

  Result := TPushoverMessage.Create(
    edtTitle.Text,
    memContent.Lines.Text,
    chkUseHtml.IsChecked,
    chkUseMonospace.IsChecked
  );
  Result.Priority  := prior;
  Result.ImagePath := edtImage.Text;
  Result.Link      := edtLink.Text;
  Result.LinkTitle := edtLinkTitle.Text;
  Result.Sound     := snd;
  Result.Timestamp := ts;
  Result.Devices   := edtDevices.Text;
end;

procedure TfrmMain.Log(const Text: string; const Args: array of const);
begin
  Log(Format(Text, Args));
end;

procedure TfrmMain.Log(const Text: string);
begin
  memLogs.Lines.Append(Text);
end;

procedure TfrmMain._OnGetLimits(AppLimit, AppRemaining: Cardinal;
  AppReset: TDateTime);
begin
  Log('GetLimits: AppLimit: %d; AppRemaining: %d; AppReset: %s', [
    AppLimit,
    AppRemaining,
    DateTimeToStr(AppReset)
  ]);
end;

procedure TfrmMain._OnGlance(Status: Boolean; Token, Response: string);
begin
  Log('Glance: %s: Token=%s; %s', [
    BoolToStr(Status, True),
    Token,
    Response
  ]);
end;

procedure TfrmMain._OnHTTPError(ErrorCode: Integer; ErrorText: string);
begin
  Log('HTTP Error: Code: %d; Text=%s', [
    ErrorCode,
    ErrorText
  ]);
end;

procedure TfrmMain._OnResponse(Status: Boolean;
  PushoverMessage: TPushoverMessage; Response: string);
var
  sl: TStringList;
begin
  // PushoverMessage might be nil in CheckReceipt response
  if Status then
  begin
    Log('Response: %s: %s', [
      BoolToStr(Status, True),
      Response
    ]);
  end else
  begin
    sl := TStringList.Create;
    try
      Pushover.ExtractError(Response, sl);
      Log('Response: %s: %s: %s', [
        BoolToStr(Status, True),
        sl.Text.Trim.Replace(#13#10, ';', [rfReplaceAll]),
        Response
      ]);
    finally
      sl.DisposeOf;
    end;
  end;
end;

procedure TfrmMain._OnResponseEmergency(Status: Boolean;
  PushoverMessage: TPushoverMessage; Receipt, Response: string);
var
  sl: TStringList;
begin
  if Status then
  begin
    Log('Response Emergency: %s: Receipt=%s; %s', [
      BoolToStr(Status, True),
      Receipt,
      Response
    ]);
  end else
  begin
    sl := TStringList.Create;
    try
      Pushover.ExtractError(Response, sl);
      Log('Response Emergency: %s: Receipt=%s: %s: %s', [
        BoolToStr(Status, True),
        Receipt,
        sl.Text.Trim.Replace(#13#10, ';', [rfReplaceAll]),
        Response
      ]);
    finally
      sl.DisposeOf;
    end;
  end;
end;

procedure TfrmMain._OnValidateUser(Status: Boolean; UserKey: string; Devices,
  Licenses: TStrings; Response: string);
begin
  Log('Validate User: %s: %s', [
    BoolToStr(Status, True),
    Response
  ]);
end;

end.
