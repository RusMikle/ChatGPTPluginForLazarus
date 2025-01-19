unit UThread;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StdCtrls, USetting, fphttpclient, fpjson, Dialogs, LazUtf8;

type

  TShowAnswerEvent = procedure(AAnswer: String; AAnimated: Boolean; ADone: Boolean) of Object;

  { TExecutorTrd }
  TExecutorTrd = class(TThread)
  private
    FAnswer: string;
    FDone: Boolean;
    FOnShowAnswer: TShowAnswerEvent;
    FPrompt: string;
    FTemperature: string;
    FModel: string;
    FApiKey: string;
    FUrl: string;
    FAnimated: Boolean;
    FTimeOut: Integer;

    function CorrectPrompt(APrompt: string): string;
    procedure DoSync;
  protected
    procedure Execute; override;
  public
    constructor Create(AApiKey, AModel, APrompt, AUrl: string; ATemperature: string; AAnimated: Boolean; ATimeOut: Integer);
    destructor Destroy; override;
    property OnShowAnswer: TShowAnswerEvent read FOnShowAnswer write FOnShowAnswer;
  end;

  { TOpenAIAPI }

  TOpenAIAPI = class
  private
    FAccessToken: string;
    FUrl: string;
    FTimeOut: Integer;
  public
    constructor Create(const AAccessToken, AUrl: string; ATimeOut: Integer);
    function Query(const AModel: string; const APrompt: string; ATemperature: string): string;
  end;

implementation

{ TOpenAIAPI }

constructor TOpenAIAPI.Create(const AAccessToken, AUrl: string; ATimeOut: Integer);
begin
  inherited Create;
  FAccessToken := AAccessToken;
  FUrl := AUrl;
  FTimeOut := ATimeOut;
end;

function TOpenAIAPI.Query(const AModel: string; const APrompt: string; ATemperature: string): string;
var
  LvHttpClient: TFPHTTPClient;
  LvResponseStream: TMemoryStream;
  LvResponseContent: TStringStream;
  LvResponseJSON: TJSONObject;
begin
  Result := '';
  LvHttpClient := TFPHTTPClient.Create(nil);
  LvHttpClient.ConnectTimeout := FTimeOut * 1000;
  LvHttpClient.IOTimeout := (FTimeOut * 1000) * 2;

  try
    LvHttpClient.RequestHeaders.Add('Authorization: Bearer ' + FAccessToken);
    LvHttpClient.AddHeader('Content-Type', 'application/json; charset=UTF-8');
    LvHttpClient.AddHeader('AcceptEncoding', 'deflate, gzip;q=1.0, *;q=0.5');

    LvResponseStream := TMemoryStream.Create;
    try
     LvHttpClient.RequestBody := TStringStream.Create('{"model": "' + AModel + '", "messages": [{"role": "user", "content": "' + APrompt + '"}]}');

        try
          try
            LvHttpClient.Post(FUrl, LvResponseStream);
            LvResponseStream.Position := 0;
            LvResponseContent := TStringStream.Create('');
            LvResponseContent.CopyFrom(LvResponseStream, LvResponseStream.Size);
            LvResponseJSON := GetJSON(LvResponseContent.DataString) as TJSONObject;
            if Assigned(LvResponseJSON) then
            begin
              if LvResponseJSON.Find('choices') <> nil then
                 //Result := UTF8encode((LvResponseJSON.Find('choices') as TJSONArray).Items[0].FindPath('message').FindPath('content').AsString)
                 Result := (LvResponseJSON.Find('choices') as TJSONArray).Items[0].FindPath('message').FindPath('content').AsString
              else if LvResponseJSON.Find('error') <> nil then
                //Result := UTF8encode(LvResponseJSON.Find('error').FindPath('message').AsString)
                Result := LvResponseJSON.Find('error').FindPath('message').AsString
              else
                Result := 'No valid Answer, try again please.';
            end
            else
              Result := 'No valid Answer, try again please.';
          except on E: Exception do
            Result := 'ERROR: ' + E.Message;
          end;
        finally
          if Assigned(LvResponseJSON) then
             LvResponseJSON.Free;
          LvResponseContent.Free;
        end;
    finally
      LvResponseStream.Free;
    end;
  finally
    LvHttpClient.Free;
  end;
end;

{ TExecutorTrd }

procedure TExecutorTrd.DoSync;
begin
  if Assigned(FOnShowAnswer) then
    FOnShowAnswer(FAnswer, TSingletonSettingObj.Instance.AnimatedLetters, FDone);
end;

function TExecutorTrd.CorrectPrompt(APrompt: string): string;
begin
  if not APrompt.IsEmpty then
  begin
    while APrompt[APrompt.Length] = '?' do
    begin
      if APrompt.Length > 1 then
        APrompt := LeftStr(APrompt, APrompt.Length - 1)
      else
        Break;
    end;
  end;
  Result := APrompt
end;

procedure TExecutorTrd.Execute;
var
  LvAPI: TOpenAIAPI;
  LvResult: String;
  //I: Integer;

  procedure _AnimateUtf8(const AText: String);
  var
    i, Len: integer;
    CharLen: integer;
    Symbol: String;
    Temp: String;
  begin
    Temp := '';
    i := 1;
    Len := UTF8Length(AText);  // Количество Unicode-символов

    while i <= Length(AText) do
    begin
      Sleep(1);
      // UTF8Copy(AText, StartCharIndex, SymbolCount)
      // Также есть UTF8CodepointSize(), UTF8CharacterToWideChar(), и т.д.
      CharLen := UTF8CharacterLength(@AText[i]);
      Symbol := Copy(AText, i, CharLen);
      i += CharLen;

      //Temp += Symbol;

      FAnswer := Symbol;
      FDone := i > Length(AText);
      Synchronize(@DoSync);
    end;
  end;

begin
  try
    LvAPI := TOpenAIAPI.Create(FApiKey, FUrl, FTimeOut);
    try
      if not Terminated then
        LvResult := LvAPI.Query(FModel, FPrompt, FTemperature).Trim;

      if (FAnimated) and (LvResult.Length > 1) then
      begin
        _AnimateUtf8 (LvResult);
        {for I := 0 to Pred(LvResult.Length) do
        begin
          Sleep(1);
          FAnswer := LvResult[I];
          FDone := (I = Pred(LvResult.Length));
          Synchronize(@DoSync);
        end;}
      end
      else
      begin
        FAnswer := LvResult;
        FDone := True;
        Synchronize(@DoSync);
      end;

    finally
      LvAPI.Free;
    end;
  except on E:Exception do
    begin
      FAnswer := E.Message;
      FDone := True;
      Synchronize(@DoSync);
    end;
  end;
end;

constructor TExecutorTrd.Create(AApiKey, AModel, APrompt, AUrl: string; ATemperature: string; AAnimated: Boolean; ATimeOut: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := True;

  FApiKey := AApiKey;
  FModel := AModel;
  FPrompt := CorrectPrompt(APrompt);
  FTemperature := ATemperature;
  FUrl := AUrl;
  FAnimated := AAnimated;
  FTimeOut := ATimeOut;

  FDone := False;
  FAnswer := '';
end;

destructor TExecutorTrd.Destroy;
begin
  inherited Destroy;
end;

end.

