unit Rac.Pushover;

interface

{x$DEFINE USE_DEBUG_PROXY}

uses
  System.Classes, System.SysUtils, System.DateUtils, System.IOUtils,
  System.Character, System.Threading,
  Rac.Json.Reader,
  IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP;

const
  // Default emergency message repeat settings.
  // Default values (30 and 600) means 12 repeats every half minute.
  // It's enough to piss everyone off.
  DEFAULT_EMERGENCY_RETRY  = 30;  // [min] minimum value = 30
  DEFAULT_EMERGENCY_EXPIRE = 600; // [sec] maximum value = 10800

type TPushoverPriority = (
  ppLowest,
  ppLower,
  ppNormal,
  ppHigh,
  ppEmergency
);

type TPushoverStatus = (
  psUndefined,
  psOk,
  psError,
  psHTTPError
);

type TPushoverSound = (
  sndClientDefault, // Client default
  sndPushover,      // Pushover (default)
  sndBike,          // Bike
  sndBugle,         // Bugle
  sndCashRegister,  // Cash Register
  sndClassical,     // Classical
  sndCosmic,        // Cosmic
  sndFalling,       // Falling
  sndGamelan,       // Gamelan
  sndIncoming,      // Incoming
  sndIntermission,  // Intermission
  sndMagic,         // Magic
  sndMechanical,    // Mechanical
  sndPianoBar,      // Piano Bar
  sndSiren,         // Siren
  sndSpaceAlarm,    // Space Alarm
  sndTugBoat,       // Tug Boat
  sndAlien,         // Alien Alarm (long)
  sndClimb,         // Climb (long)
  sndPersistent,    // Persistent (long)
  sndEcho,          // Pushover Echo (long)
  sndUpDown,        // Up Down (long)
  sndVibrate,       // Vibrate Only
  sndNone           // None (silent)
);

type TPushoverMessage = class
  private
    FApiKey: string;
    FDevices: string;
    FUseMonospace: Boolean;
    FSound: TPushoverSound;
    FLink: string;
    FImagePath: string;
    FUseHTML: Boolean;
    FTitle: string;
    FTimestamp: TDateTime;
    FLinkTitle: string;
    FContent: string;
    FUserKey: string;
    FPriority: TPushoverPriority;
    procedure SetDevices(const Value: string);
  protected
  public
    constructor Create; overload;
    constructor Create(const Content: string); overload;
    constructor Create(const Title,
                             Content: string;
                       const UseHTML: Boolean = False;
                       const UseMonospace: Boolean = False); overload;
    function AsStream(asWwwForm: Boolean = False): TStringStream;
    // Necessary fields:
    property UserKey     : string            read FUserKey      write FUserKey; // Or GroupKey
    property ApiKey      : string            read FApiKey       write FApiKey;
    property Content     : string            read FContent      write FContent;
    // Request:
    property Title       : string            read FTitle        write FTitle;
    property UseHTML     : Boolean           read FUseHTML      write FUseHTML;
    property UseMonospace: Boolean           read FUseMonospace write FUseMonospace;
    property Priority    : TPushoverPriority read FPriority     write FPriority;
    property ImagePath   : string            read FImagePath    write FImagePath;
    property Link        : string            read FLink         write FLink;
    property LinkTitle   : string            read FLinkTitle    write FLinkTitle;
    property Sound       : TPushoverSound    read FSound        write FSound;
    property Timestamp   : TDateTime         read FTimestamp    write FTimestamp;
    property Devices     : string            read FDevices      write SetDevices;
end;

type TOnResponse          = procedure(Status: Boolean;
                                      PushoverMessage: TPushoverMessage;
                                      Response: string) of Object;
type TOnResponseEmergency = procedure(Status: Boolean;
                                      PushoverMessage: TPushoverMessage;
                                      Receipt: string;
                                      Response: string) of Object;
type TOnGlance            = procedure(Status: Boolean;
                                      RequestId: string;
                                      Response: string) of Object;
type TOnValidateUser      = procedure(Status: Boolean;
                                      UserKey: string;
                                      Devices: TStrings;
                                      Licenses: TStrings;
                                      Response: string) of Object;
type TOnGetLimits         = procedure(AppLimit,
                                      AppRemaining: Cardinal;
                                      AppReset: TDateTime) of Object;
type TOnHTTPError         = procedure(ErrorCode: Integer;
                                      ErrorText: string) of Object;
type TPushover = class
  private
    FHttp: TIdHTTP;
    FOnResponse: TOnResponse;
    FOnHTTPError: TOnHTTPError;
    FAppReset: TDateTime;
    FAppRemaining: Cardinal;
    FAppLimit: Cardinal;
    FOnGetLimits: TOnGetLimits;
    FApiKey: string;
    FOnResponseEmergency: TOnResponseEmergency;
    FOnGlance: TOnGlance;
    FUserKey: string;
    FOnValidateUser: TOnValidateUser;
  protected
    procedure DoOnResponse(Status: Boolean; PushoverMessage: TPushoverMessage; Response: string);
    procedure DoOnResponseEmergency(Status: Boolean; PushoverMessage: TPushoverMessage; Receipt: string; Response: string);
    procedure DoOnHTTPError(ErrorCode: Integer; ErrorText: string);
    procedure DoOnGetLimits;
    procedure DoOnGlance(Status: Boolean; RequestId: string; Response: string);
    procedure DoOnValidateUser(Status: Boolean; UserKey: string; Devices: TStrings; Licenses: TStrings; Response: string);
    procedure PrepareMessage(PushoverMessage: TPushoverMessage);
    procedure SetupHttp;
    procedure PrepareHTTP(asWwwForm: Boolean);
    function  GetContentType(PushoverMessage: TPushoverMessage): Boolean;
    procedure CheckResponse(PushoverMessage: TPushoverMessage; Response: String);
    procedure FillLimits;
    function Write(PushoverMessage: TPushoverMessage; Url: string; Content: TStream): Boolean;
    procedure ExtractJsonArray(Json: TJsonReader; Name: String; List: TStrings);
    function ExtractJsonStatus(Json: TJsonReader): Boolean;
    function ExtractJsonReceipt(Json: TJsonReader): string;
    function ExtractJsonRequestId(Json: TJsonReader): string;
    procedure ExtractJsonDevices(Json: TJsonReader; List: TStrings);
    procedure ExtractJsonLicenses(Json: TJsonReader; List: TStrings);
  public
    // Basic functions:
    constructor Create;
    destructor  Destroy; override;
    // Main functions:
    procedure Send(PushoverMessage: TPushoverMessage);
    procedure Glance(Title,
                     Text,
                     Subtext: string;
                     Count: Integer;
                     Percent: Byte;
                     UseCount,
                     UsePercent: Boolean;
                     Devices: string = ''); overload;
    procedure GlanceUpdate(Title,
                           Text,
                           Subtext: string;
                           Count: Integer;
                           Percent: Byte;
                           UpdateTitle,
                           UpdateText,
                           UpdateSubtext,
                           UpdateCount,
                           UpdatePercent: Boolean;
                           Devices: string = '');
    // Emergency messages functions:
    procedure SendEmergency(PushoverMessage: TPushoverMessage; Retry, Expire: Cardinal);
    procedure CheckReceipt(ReceiptId: string); // Used to pull emergency priority notification status
                                               // DO NOT call CheckReceipt more than once per 5 seconds (!)
    procedure CancelReceipt(ReceiptId: string); // Cancel emergency priority notification status
    // Additional commands:
    //procedure GetUserLimits(UserKey: string);
    procedure ValidateUser(UserKey: string; Devices: string = ''); // Or ValidateGroup
    // Helper functions:
    function ExtractError(Response: string; Errors: TStrings): Boolean;
    function ResponseStreamToString(ContentStream: TStream): string;
    // Necessary fields:
    property UserKey: string read FUserKey write FUserKey;
    property ApiKey : string read FApiKey  write FApiKey;
    // Limits:
    property AppLimit    : Cardinal  read FAppLimit;
    property AppRemaining: Cardinal  read FAppRemaining;
    property AppReset    : TDateTime read FAppReset;
    // Notifications:
    property OnResponse         : TOnResponse          read FOnResponse           write FOnResponse;
    property OnResponseEmergency: TOnResponseEmergency read FOnResponseEmergency  write FOnResponseEmergency;
    property OnGlance           : TOnGlance            read FOnGlance             write FOnGlance;
    property OnValidateUser     : TOnValidateUser      read FOnValidateUser       write FOnValidateUser;
    property OnGetLimits        : TOnGetLimits         read FOnGetLimits          write FOnGetLimits;
    property OnHTTPError        : TOnHTTPError         read FOnHTTPError          write FOnHTTPError;
end;

implementation

const
  USER_AGENT           = 'Pushover4D/1.0';
  BOUNDARY             = '--abcdefg';
  URL_MESSAGES         = 'https://api.pushover.net/1/messages.json';
  URL_UG_VALIDATE      = 'https://api.pushover.net/1/users/validate.json';
  URL_GLANCES          = 'https://api.pushover.net/1/glances.json';
  URL_LIMITS           = 'https://api.pushover.net/1/apps/limits.json?token=%s';
  URL_RECEIPT          = 'https://api.pushover.net/1/receipts/%s.json?token=%s';
  URL_RECEIPT_CANCEL   = 'https://api.pushover.net/1/receipts/%s/cancel.json';
  MAX_LENGTH_TEXT      = 1024;
  MAX_LENGTH_TITLE     = 250;
  MAX_LENGTH_LINK      = 512;
  MAX_LENGTH_LINKTITLE = 100;
  MAX_IMAGE_SIZE       = 2621440; // 2.5 [MB]
  MAX_GLANCE_TITLE     = 100;
  MAX_GLANCE_TEXT      = 100;
  MAX_GLANCE_SUBTEXT   = 100;

  function PushoverSound2String(PushoverSound: TPushoverSound): string;
  begin
    case PushoverSound of
      sndPushover:     Result := 'pushover';
      sndBike:         Result := 'bike';
      sndBugle:        Result := 'bugle';
      sndCashRegister: Result := 'cashregister';
      sndClassical:    Result := 'classical';
      sndCosmic:       Result := 'cosmic';
      sndFalling:      Result := 'falling';
      sndGamelan:      Result := 'gamelan';
      sndIncoming:     Result := 'incoming';
      sndIntermission: Result := 'intermission';
      sndMagic:        Result := 'magic';
      sndMechanical:   Result := 'mechanical';
      sndPianoBar:     Result := 'pianobar';
      sndSiren:        Result := 'siren';
      sndSpaceAlarm:   Result := 'spacealarm';
      sndTugBoat:      Result := 'tugboat';
      sndAlien:        Result := 'alien';
      sndClimb:        Result := 'climb';
      sndPersistent:   Result := 'persistent';
      sndEcho:         Result := 'echo';
      sndUpDown:       Result := 'updown';
      sndVibrate:      Result := 'vibrate';
      sndNone:         Result := 'none';
    else
      Result := '';
    end;
  end;

function Encode(Text: string): string;
var
  i, j: Integer;
  c: Char;
  rbs: RawByteString;
begin
  // If anyone have an idea how to improve it, don't hesitate to do so.
  Result := '';
  for i := Low(Text) to High(Text) do
  begin
    c := Text[i];
    if CharInSet(c, ['a'..'z', 'A'..'Z', '0'..'9'])  then
      Result := Result + c else
    case c of
      // Source: https://developer.mozilla.org/en-US/docs/Glossary/percent-encoding
      '%' : Result := Result + '%25';
      ' ' : Result := Result + '+';
      ':' : Result := Result + '%3A';
      '/' : Result := Result + '%2F';
      '?' : Result := Result + '%3F';
      '#' : Result := Result + '%23';
      '[' : Result := Result + '%5B';
      ']' : Result := Result + '%5D';
      '@' : Result := Result + '%40';
      '!' : Result := Result + '%21';
      '$' : Result := Result + '%24';
      '&' : Result := Result + '%26';
      '''': Result := Result + '%27';
      '(' : Result := Result + '%28';
      ')' : Result := Result + '%29';
      '*' : Result := Result + '%2A';
      '+' : Result := Result + '%2B';
      ',' : Result := Result + '%2C';
      ';' : Result := Result + '%3B';
      '=' : Result := Result + '%3D';
    else
      begin
        rbs := UTF8Encode(c);
        if Length(rbs) > 1 then
        begin
          for j := Low(rbs) to High(rbs) do
            Result := Result + '%' + IntToHex(Ord(rbs[j]), 2);
        end else
          Result := Result + String(rbs);
      end;
    end;
  end;
end;

function wwwFormItem(const Name, Value: string): string;
const
  EOL = #13#10;
begin
  Result := '--' + BOUNDARY + EOL +
            'Content-Disposition: form-data; name="' + Name + '"' + EOL +
            EOL +
            Value + EOL;
end;

{ TPushover }

procedure TPushover.CancelReceipt(ReceiptId: string);
var
  s: TStringStream;
begin
  // There is OnHTTPError notification only
  if ReceiptId <> '' then
  begin
    TTask.Run(procedure
    begin
      s := TStringStream.Create('token=' + Encode(ApiKey));
      try
        Write(nil, Format(URL_RECEIPT_CANCEL, [ReceiptId]), s);
      finally
        s.DisposeOf;
      end;
    end);
  end else
    raise Exception.Create('Pushover: Empty Receipt ID');
end;

procedure TPushover.CheckReceipt(ReceiptId: string);
var
  s: TStringStream;
  j: TJsonReader;
  r: string;
begin
  //
  // (!) Do not execute it faster than once every 5 seconds (!)
  //
  if ReceiptId <> '' then
  begin
    TTask.Run(procedure
    begin
      s := TStringStream.Create('token=' + Encode(ApiKey));
      try
        r := FHttp.Get(Format(URL_RECEIPT, [Encode(ReceiptId), Encode(ApiKey)]));
        if (FHttp.ResponseCode = 200) or ((FHttp.ResponseCode >= 400) and (FHttp.ResponseCode <= 499)) then
        begin
          if FHttp.ResponseCode = 200 then
            FillLimits;
          j := TJsonReader.Create(r);
          try
            DoOnResponse(ExtractJsonStatus(j), nil, r);
          finally
            j.DisposeOf;
          end;
        end else
          DoOnHTTPError(FHttp.ResponseCode, FHttp.ResponseText);
      finally
        s.DisposeOf;
      end;
    end);
  end else
    raise Exception.Create('Pushover: Empty Receipt ID');
end;

procedure TPushover.CheckResponse(PushoverMessage: TPushoverMessage; Response: String);
var
  j: TJsonReader;
begin
  if (FHttp.ResponseCode = 200) or ((FHttp.ResponseCode >= 400) and (FHttp.ResponseCode <= 499)) then
  begin
    if FHttp.ResponseCode = 200 then
      FillLimits;
    if not Assigned(PushoverMessage) then
      Exit;
    j := TJsonReader.Create(Response);
    try
      if PushoverMessage.Priority = TPushoverPriority.ppEmergency then
        DoOnResponseEmergency(ExtractJsonStatus(j), PushoverMessage, ExtractJsonReceipt(j), Response)
      else
        DoOnResponse(ExtractJsonStatus(j), PushoverMessage, Response);
    finally
      j.DisposeOf;
    end;
  end else
    DoOnHTTPError(FHttp.ResponseCode, FHttp.ResponseText);
end;

constructor TPushover.Create;
begin
  FHttp := TIdHTTP.Create;
  SetupHttp;
end;

destructor TPushover.Destroy;
begin
  FHttp.DisposeOf;
  inherited;
end;

procedure TPushover.DoOnGetLimits;
begin
  if Assigned(FOnGetLimits) then
    TThread.Synchronize(TThread.Current, procedure
    begin
      FOnGetLimits(AppLimit, AppRemaining, AppReset);
    end);
end;

procedure TPushover.DoOnGlance(Status: Boolean; RequestId, Response: string);
begin
  if Assigned(FOnGlance) then
    TThread.Synchronize(TThread.Current, procedure
    begin
      FOnGlance(Status, RequestId, Response);
    end);
end;

procedure TPushover.DoOnHTTPError(ErrorCode: Integer; ErrorText: string);
begin
  if Assigned(FOnHTTPError) then
    TThread.Synchronize(TThread.Current, procedure
    begin
      FOnHTTPError(ErrorCode, ErrorText);
    end);
end;

procedure TPushover.DoOnResponse(Status: Boolean;
  PushoverMessage: TPushoverMessage; Response: string);
begin
  if Assigned(FOnResponse) then
    TThread.Synchronize(TThread.Current, procedure
    begin
      FOnResponse(Status, PushoverMessage, Response);
    end);
end;

procedure TPushover.DoOnResponseEmergency(Status: Boolean;
  PushoverMessage: TPushoverMessage; Receipt, Response: string);
begin
  if Assigned(FOnResponseEmergency) then
    TThread.Synchronize(TThread.Current, procedure
    begin
      FOnResponseEmergency(Status, PushoverMessage, Receipt, Response);
    end);
end;

procedure TPushover.DoOnValidateUser(Status: Boolean; UserKey: string; Devices,
  Licenses: TStrings; Response: string);
begin
  if Assigned(FOnValidateUser) then
    TThread.Synchronize(TThread.Current, procedure
    begin
      FOnValidateUser(Status, UserKey, Devices, Licenses, Response);
    end);
end;

function TPushover.ExtractError(Response: string; Errors: TStrings): Boolean;
var
  j: TJsonReader;
begin
  j := TJsonReader.Create(Response);
  try
    ExtractJsonArray(j, 'errors', Errors);
    Result := Errors.Count > 0;
  finally
    j.DisposeOf;
  end;
end;

procedure TPushover.ExtractJsonArray(Json: TJsonReader; Name: String;
  List: TStrings);
var
  bIsName: Boolean;
begin
  List.Clear;
  bIsName := False;
  while Json.Read do
    if bIsName then
    begin
      if Json.TokenType = TJsonToken.EndArray then
        Break;
      if (Json.TokenType = TJsonToken.String) then
        List.Append(Json.ValueAsString);
    end else
      if Json.IsPropertyName(Name) then
        bIsName := True;
end;

procedure TPushover.ExtractJsonDevices(Json: TJsonReader; List: TStrings);
begin
  ExtractJsonArray(Json, 'devices', List);
end;

procedure TPushover.ExtractJsonLicenses(Json: TJsonReader; List: TStrings);
begin
  ExtractJsonArray(Json, 'licenses', List);
end;

function TPushover.ExtractJsonReceipt(Json: TJsonReader): string;
begin
  Result := '';
  Json.Rewind;
  while Json.Read do
    if Json.IsPropertyName('receipt') then
    begin
      Result := Json.ReadAsString;
      Break;
    end;
end;

function TPushover.ExtractJsonStatus(Json: TJsonReader): Boolean;
begin
  Result := False;
  Json.Rewind;;
  while Json.Read do
    if Json.IsPropertyName('status') then
    begin
      Result := Json.ReadAsInteger = 1;
      Break;
    end;
end;

procedure TPushover.FillLimits;
var
  s: string;
  i: Int64;
begin
  s := FHttp.Response.RawHeaders.Values['X-Limit-App-Limit'];
  if s <> '' then
    FAppLimit := StrToIntDef(s, 0);
  s := FHttp.Response.RawHeaders.Values['X-Limit-App-Remaining'];
  if s <> '' then
    FAppRemaining := StrToIntDef(s, 0);
  s := FHttp.Response.RawHeaders.Values['X-Limit-App-Reset'];
  if s <> '' then
  begin
    i := StrToIntDef(s, 0);
    if i > 0 then
      FAppReset := UnixToDateTime(i);
  end;
  DoOnGetLimits;
end;

function TPushover.ExtractJsonRequestId(Json: TJsonReader): string;
begin
  Result := '';
  Json.Rewind;
  while Json.Read do
    if Json.IsPropertyName('request') then
    begin
      Result := Json.ReadAsString;
      Break;
    end;
end;

function TPushover.GetContentType(PushoverMessage: TPushoverMessage): Boolean;
begin
  Assert(Assigned(PushoverMessage));
  Result := (PushoverMessage.ImagePath <> '') and
            (TFile.Exists(PushoverMessage.ImagePath));
end;

//procedure TPushover.GetUserLimits(UserKey: string);
//begin
//  Assert(False);
//  if UserKey <> '' then
//  begin
//    // ToDo: Maybe in the future.
//    //
//    // Limits are gathered on almost every (except CancelReceipt) succesful
//    // (HTTP Return code = 200) command,
//    // so for now i think this function isn't necessary.
//  end else
//    raise Exception.Create('Pushover: Empty User Key');
//end;

procedure TPushover.Glance(Title, Text, Subtext: string; Count: Integer;
  Percent: Byte; UseCount, UsePercent: Boolean; Devices: string);
begin
  GlanceUpdate(Title, Text, Subtext, Count, Percent, Title <> '', Text <> '', Subtext <> '', UseCount, UsePercent, Devices);
end;

procedure TPushover.GlanceUpdate(Title, Text, Subtext: string;
  Count: Integer; Percent: Byte; UpdateTitle, UpdateText, UpdateSubtext,
  UpdateCount, UpdatePercent: Boolean; Devices: string);
var
  s: TStringStream;
  j: TJsonReader;
begin
  if not (UpdateTitle or UpdateText or UpdateSubtext or UpdateCount or UpdatePercent) then
    raise Exception.Create('At least one data parameter (text or numeric) must be provided for glance command');
  if Title.Length > MAX_GLANCE_TITLE then
    raise Exception.Create('Maximum glance title length is ' + IntToStr(MAX_GLANCE_TITLE) + ' characters.');
  if Text.Length > MAX_GLANCE_TEXT then
    raise Exception.Create('Maximum glance text length is ' + IntToStr(MAX_GLANCE_TEXT) + ' characters.');
  if Subtext.Length > MAX_GLANCE_SUBTEXT then
    raise Exception.Create('Maximum glance subtext length is ' + IntToStr(MAX_GLANCE_SUBTEXT) + ' characters.');

  TTask.Run(procedure
  begin
    s := TStringStream.Create;
    try
      s.WriteString('token=' + Encode(ApiKey));
      s.WriteString('&user=' + Encode(UserKey));
      if Devices <> '' then
        s.WriteString('&device=' + Encode(Devices));
      if UpdateTitle then
        s.WriteString('&title=' + Encode(Title));
      if UpdateText then
        s.WriteString('&text=' + Encode(Text));
      if UpdateSubtext then
        s.WriteString('&subtext=' + Encode(Subtext));
      if UpdateCount then
        s.WriteString('&count=' + IntToStr(Count));
      if UpdatePercent then
        if (Percent <= 100) then
          s.WriteString('&percent=' + IntToStr(Percent))
        else
          raise Exception.Create('Wrong percent value. Current percent value = ' + IntToStr(Percent) + ' and should be between 0 and 100 (inclusive)');
      PrepareHTTP(False);
      if Write(nil, URL_GLANCES, s) then
      begin
        j := TJsonReader.Create(ResponseStreamToString(FHttp.Response.ContentStream));
        try
          DoOnGlance(ExtractJsonStatus(j), ExtractJsonRequestId(j), FHttp.ResponseText);
        finally
          j.DisposeOf;
        end;
      end;
    finally
      s.DisposeOf;
    end;
  end);
end;

procedure TPushover.SetupHttp;
begin
{$IF defined(USE_DEBUG_PROXY)}
  FHttp.ProxyParams.ProxyServer := '127.0.0.1';
  FHttp.ProxyParams.ProxyPort   := 8080;
  FHttp.ProxyParams.BasicAuthentication := False;
{$ENDIF}
  FHttp.HTTPOptions := [
    //hoInProcessAuth,
    hoKeepOrigProtocol,
    hoForceEncodeParams,
    //hoNonSSLProxyUseConnectVerb,
    //hoNoParseMetaHTTPEquiv,
    hoWaitForUnexpectedData,
    hoTreat302Like303,
    hoNoProtocolErrorException, // Necessary (!)
    //hoNoReadMultipartMIME,
    //hoNoParseXmlCharset,
    hoWantProtocolErrorContent // Necessary (!)
    //hoNoReadChunked
  ];
  FHttp.Request.UserAgent     := USER_AGENT;
  FHttp.Request.CacheControl  := 'no-cache';
  FHttp.ProtocolVersion       := TIdHTTPProtocolVersion.pv1_1;
  FHttp.Request.RawHeaders.AddValue('Connection', 'keep-alive');
  FHttp.Request.CharSet       := 'utf-8';
  FHttp.Request.AcceptCharSet := 'utf-8';
  FHttp.Request.Accept        := 'text/html,application/json;q=0.9,*/*;q=0.8';
end;

function TPushover.ResponseStreamToString(ContentStream: TStream): string;
var
  s: TStringStream;
  p: Int64;
begin
  Assert(Assigned(ContentStream));
  Assert(ContentStream.Size > 0);
  p := ContentStream.Position;
  ContentStream.Position := 0;
  s := TStringStream.Create;
  try
    s.CopyFrom(ContentStream, ContentStream.Size);
    ContentStream.Position := p;
  finally
    s.DisposeOf;
  end;
end;

procedure TPushover.PrepareHTTP(asWwwForm: Boolean);
begin
  if asWwwForm then
    FHttp.Request.ContentType := 'multipart/form-data; boundary=' + BOUNDARY
  else
    FHttp.Request.ContentType := 'application/x-www-form-urlencoded';
end;

procedure TPushover.PrepareMessage(PushoverMessage: TPushoverMessage);
begin
  Assert(Assigned(PushoverMessage));
  if PushoverMessage.UserKey = '' then
    PushoverMessage.UserKey := Self.UserKey;
  if PushoverMessage.ApiKey = '' then
    PushoverMessage.ApiKey  := Self.ApiKey;
  if PushoverMessage.Content.Length > MAX_LENGTH_TEXT then
    raise Exception.Create('Pushover: Maximum message text length is ' + IntToStr(MAX_LENGTH_TEXT) + ' characters');
  if PushoverMessage.Title.Length > MAX_LENGTH_TITLE then
    raise Exception.Create('Pushover: Maximum message title length is ' + IntToStr(MAX_LENGTH_TITLE) + ' characters');
  if PushoverMessage.Link.Length > MAX_LENGTH_LINK then
    raise Exception.Create('Pushover: Maximum message link length is ' + IntToStr(MAX_LENGTH_LINK) + ' characters');
  if PushoverMessage.LinkTitle.Length > MAX_LENGTH_LINKTITLE then
    raise Exception.Create('Pushover: Maximum message link title length is ' + IntToStr(MAX_LENGTH_LINKTITLE) + ' characters');
end;

procedure TPushover.Send(PushoverMessage: TPushoverMessage);
var
  wwwForm: Boolean;
  s: TStringStream;
begin
  if PushoverMessage.Priority <> TPushoverPriority.ppEmergency then
  begin
    Assert(Assigned(PushoverMessage));
    TTask.Run(procedure
    begin
      PrepareMessage(PushoverMessage);
      wwwForm := GetContentType(PushoverMessage);
      PrepareHTTP(wwwForm);
      s := PushoverMessage.AsStream(wwwForm);
      try
        Write(PushoverMessage, URL_MESSAGES, s);
      finally
        s.DisposeOf;
      end;
    end);
  end else
    SendEmergency(
      PushoverMessage,
      DEFAULT_EMERGENCY_RETRY,
      DEFAULT_EMERGENCY_EXPIRE
    );
end;

procedure TPushover.SendEmergency(PushoverMessage: TPushoverMessage; Retry,
  Expire: Cardinal);
var
  wwwForm: Boolean;
  s: TStringStream;
begin
  if (PushoverMessage.Priority = TPushoverPriority.ppEmergency) then
  begin
    Assert(Assigned(PushoverMessage));
    TTask.Run(procedure
    begin
      // Prepare and send image
      PrepareMessage(PushoverMessage);
      wwwForm := GetContentType(PushoverMessage);
      PrepareHTTP(wwwForm);
      s := PushoverMessage.AsStream(wwwForm);
      try
        s.Position := s.Size;
        // Add two additional parameters
        if wwwForm then
        begin
          s.WriteString(wwwFormItem('retry', IntToStr(Retry)));
          s.WriteString(wwwFormItem('expire', IntToStr(Expire)));
        end else
        begin
          s.WriteString('&retry=' + IntToStr(Retry));
          s.WriteString('&expire=' + IntToStr(Expire));
        end;
        // Send
        Write(PushoverMessage, URL_MESSAGES, s);
      finally
        s.DisposeOf;
      end;
    end);
  end else
    Send(PushoverMessage);
end;

procedure TPushover.ValidateUser(UserKey: string; Devices: string);
var
  s: TStringStream;
  j: TJsonReader;
  d, l: TStringList;
begin
  if UserKey <> '' then
  begin
    TTask.Run(procedure
    begin
      PrepareHTTP(False);
      s := TStringStream.Create(Format('token=%s&user=%s', [ApiKey, UserKey]));
      try
        if Devices <> '' then
          s.WriteString('&device=' + Encode(Devices));
        if Write(nil, URL_UG_VALIDATE, s) then
        begin
          j := TJsonReader.Create(ResponseStreamToString(FHttp.Response.ContentStream));
          d := TStringList.Create;
          l := TStringList.Create;
          try
            ExtractJsonDevices(j, d);
            ExtractJsonLicenses(j, l);
            DoOnValidateUser(ExtractJsonStatus(j), UserKey, d, l, FHttp.ResponseText);
          finally
            l.DisposeOf;
            d.DisposeOf;
            j.DisposeOf;
          end;
        end;
      finally
        s.DisposeOf;
      end;
    end);
  end else
    raise Exception.Create('Pushover: Empty User Key');
end;

function TPushover.Write(PushoverMessage: TPushoverMessage; Url: string; Content: TStream): Boolean;
var
  r: string;
begin
  try
    Content.Position := 0;
    r := FHttp.Post(Url, Content);
    CheckResponse(PushoverMessage, r);
    Result := True;
  except
    on e: Exception do
    begin
      DoOnHTTPError(FHttp.ResponseCode, FHttp.ResponseText);
      Result := False;
    end;
  end;
end;

{ TPushoverMessage }

function TPushoverMessage.AsStream(asWwwForm: Boolean): TStringStream;
const
  EOL = #13#10;
var
  mime: string;
  buf: TBytes;
//{$IFDEF DEBUG}
//  f: TFileStream;
//{$ENDIF}
begin
  Result := TStringStream.Create;

  if FContent = '' then
    raise Exception.Create('Pushover: Missing content in the Pushover message');
  if FApiKey = '' then
    raise Exception.Create('Pushover: Empty API Key in the message');
  if FUserKey = '' then
    raise Exception.Create('Pushover: Empty User Key (token) in the message');

  if asWwwForm then
  begin
    // Image is necessary here
    if FImagePath = '' then
      raise Exception.Create('Pushover: Empty image path in the pushover message');
    if not TFile.Exists(FImagePath) then
      raise Exception.Create('Pushover: Can''t find image from the pushover message');

    Result.WriteString(wwwFormItem('user', FUserKey));
    Result.WriteString(wwwFormItem('token', FApiKey));
    Result.WriteString(wwwFormItem('message', FContent));

    if FTitle <> '' then
      Result.WriteString(wwwFormItem('title', FTitle));

    case FPriority of
      ppLowest   : Result.WriteString(wwwFormItem('priority', '-2'));
      ppLower    : Result.WriteString(wwwFormItem('priority', '-1'));
      ppHigh     : Result.WriteString(wwwFormItem('priority', '1'));
      ppEmergency: Result.WriteString(wwwFormItem('priority', '2'));
    else
      //s.WriteString(wwwFormItem('priority',  '0'));
    end;

    if FUseHTML then
      Result.WriteString(wwwFormItem('html', '1'));

    if FUseMonospace then
      Result.WriteString(wwwFormItem('monospace', '1'));

    if FTimestamp > 0 then
      Result.WriteString(wwwFormItem('timestamp', IntToStr(DateTimeToUnix(FTimestamp))));

    if FLink <> '' then
      Result.WriteString(wwwFormItem('url', FLink));

    if FLinkTitle <> '' then
      Result.WriteString(wwwFormItem('url_title', FLinkTitle));

    if FSound <> TPushoverSound.sndClientDefault then
      Result.WriteString(wwwFormItem('sound', PushoverSound2String(FSound)));

    if FDevices <> '' then
      Result.WriteString(wwwFormItem('devices', FDevices));

    if (FImagePath = '') or (not TFile.Exists(FImagePath)) then
      raise Exception.Create('Pushover: Can''t locate image: ' + EOL + FImagePath);

    if TFile.GetSize(FImagePath) > MAX_IMAGE_SIZE then
      raise Exception.Create('Pushover: Image too large');

    if SameText(TPath.GetExtension(FImagePath), '.jpg') or SameText(TPath.GetExtension(FImagePath), '.jpeg') then
      mime := 'jpeg' else
    if SameText(TPath.GetExtension(FImagePath), '.png') then
      mime := 'png'
    else
      raise Exception.Create('Pushover: Attachment image different than jpeg and png');

    Result.WriteString(
      '--' + BOUNDARY + EOL +
      'Content-Disposition: form-data; name="attachment"; filename="' + TPath.GetFileName(FImagePath) + '"' + EOL +
      'Content-Type: image/' + mime + EOL +
      EOL
    );
    buf := TFile.ReadAllBytes(FImagePath);
    try
      Result.WriteBuffer(buf, Length(buf));
    finally
      SetLength(buf, 0);
    end;
    Result.WriteString(EOL + '--' + BOUNDARY + '--' + EOL);

//{$IFDEF DEBUG}
//    f := TFileStream.Create('raw_message.bin', fmCreate);
//    try
//      Result.Position := 0;
//      f.CopyFrom(Result, Result.Size);
//    finally
//      f.DisposeOf;
//    end;
//{$ENDIF}
  end else
  begin
    Result.WriteString('user='     + Encode(FUserKey));
    Result.WriteString('&token='   + Encode(FApiKey));
    Result.WriteString('&message=' + Encode(FContent));

    if FTitle <> '' then
      Result.WriteString('&title=' + Encode(FTitle));

    case FPriority of
      ppLowest   : Result.WriteString('&priority=-2');
      ppLower    : Result.WriteString('&priority=-1');
      ppHigh     : Result.WriteString('&priority=1');
      ppEmergency: Result.WriteString('&priority=2');
    else
      //Result.WriteString('&priority=0');
    end;

    if FUseHTML then
      Result.WriteString('&html=1');

    if FUseMonospace then
      Result.WriteString('&monospace=1');

    if FTimestamp > 0 then
      Result.WriteString('&timestamp=' + IntToStr(DateTimeToUnix(FTimestamp)));

    if FLink <> '' then
      Result.WriteString('&url=' + Encode(FLink));

    if FLinkTitle <> '' then
      Result.WriteString('&url_title=' + Encode(FLinkTitle));

    if FSound <> TPushoverSound.sndClientDefault then
      Result.WriteString('&sound=' + PushoverSound2String(FSound));

    if FDevices <> '' then
      Result.WriteString('&devices=' + Encode(FDevices));
  end;
end;

constructor TPushoverMessage.Create;
begin
  inherited;
  FApiKey       := '';
  FDevices      := '';
  FUseMonospace := False;
  FSound        := TPushoverSound.sndClientDefault;
  FLink         := '';
  FImagePath    := '';
  FUseHTML      := False;
  FTitle        := '';
  FTimestamp    := 0.0;
  FLinkTitle    := '';
  FContent      := '';
  FUserKey      := '';
  FPriority     := TPushoverPriority.ppNormal;
end;

constructor TPushoverMessage.Create(const Content: string);
begin
  Create;
  FContent := Content;
end;

constructor TPushoverMessage.Create(const Title, Content: string; const UseHTML,
  UseMonospace: Boolean);
begin
  Create;
  FTitle        := Title;
  FContent      := Content;
  FUseHTML      := UseHTML;
  FUseMonospace := UseMonospace;
end;

procedure TPushoverMessage.SetDevices(const Value: string);
begin
  FDevices := Value.Trim.Replace(' ', '', [rfReplaceAll]);
end;

end.
