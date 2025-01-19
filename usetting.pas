unit USetting;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  fgl, UConsts, fpjson, IniFiles;

const
  DefaultChatGPTURL = 'https://api.openai.com/v1/chat/completions';
  DefaultModel = 'gpt-4';
  DefaultMaxToken = 2048;
  DefaultTemperature = '0,1';

type
  { TSingletonSettingObj }

  TSingletonSettingObj = class(TObject)
  private
    FApiKey: string;
    FURL: string;
    FModel: string;
    FMaxToken: Integer;
    FTemperature: string;
    FIdentifier: string;
    FCodeFormatter: Boolean;

    FHistoryEnabled: Boolean;
    FHistoryPath: string;
    FShouldReloadHistory: Boolean;
    FHighlightColor: TColor;

    FAnimatedLetters: Boolean;
    FTimeOut: Integer;
    FLastQuestion: string;

    FTaskList: specialize TFPGList<string>;

    class var FInstance: TSingletonSettingObj;
    class function GetInstance: TSingletonSettingObj; static;

    procedure LoadDefaults;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ReadConfig;
    procedure WriteConfig;
    function GetSetting: string;
    function GetHistoryFullPath: string;
    class function IsValidJson(const AJsonString: string): Boolean;
    class property Instance: TSingletonSettingObj read GetInstance;

    property ApiKey: string read FApiKey write FApiKey;
    property URL: string read FURL write FURL;
    property Model: string read FModel write FModel;
    property MaxToken: Integer read FMaxToken write FMaxToken;
    property Temperature: string read FTemperature write FTemperature;
    property CodeFormatter: Boolean read FCodeFormatter write FCodeFormatter;
    property Identifier: string read FIdentifier write FIdentifier;
    property HistoryEnabled: Boolean read FHistoryEnabled write FHistoryEnabled;
    property HistoryPath: string read FHistoryPath write FHistoryPath;
    property ShouldReloadHistory: Boolean read FShouldReloadHistory write FShouldReloadHistory;
    property HighlightColor: TColor read FHighlightColor write FHighlightColor;
    property AnimatedLetters: Boolean read FAnimatedLetters write FAnimatedLetters;
    property TimeOut: Integer read FTimeOut write FTimeOut;
    property LastQuestion: string read FLastQuestion write FLastQuestion;

    property TaskList: specialize TFPGList<string> read FTaskList write FTaskList;
  end;



  { TFrm_Setting }

  TFrm_Setting = class(TForm)
    Btn_Default: TButton;
    Btn_Save: TButton;
    cbbModel: TComboBox;
    chk_AnimatedLetters: TCheckBox;
    edt_ApiKey: TEdit;
    edt_MaxToken: TEdit;
    edt_Temperature: TEdit;
    edt_Url: TEdit;
    grp_OpenAI: TGroupBox;
    edtTimeout: TLabeledEdit;
    lbl_1: TLabel;
    lbl_2: TLabel;
    lbl_3: TLabel;
    lbl_4: TLabel;
    lbl_5: TLabel;
    pnlMain: TPanel;
    pnlBottom: TPanel;
    pnlOpenAI: TPanel;
    procedure Btn_DefaultClick(Sender: TObject);
    procedure Btn_SaveClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
  private
    procedure LoadDefaults;
  public
    ChangeFocus: Boolean;
  end;

var
  Frm_Setting: TFrm_Setting;

implementation

{$R *.lfm}

{ TFrm_Setting }

procedure TFrm_Setting.Btn_DefaultClick(Sender: TObject);
begin
  LoadDefaults;
end;

procedure TFrm_Setting.Btn_SaveClick(Sender: TObject);
begin
  with TSingletonSettingObj.Instance do
  begin
    ApiKey := edt_ApiKey.Text;
    URL := edt_Url.Text;
    Model := cbbModel.Text;
    MaxToken := StrToInt(edt_MaxToken.Text);
    Temperature := edt_Temperature.Text;
    AnimatedLetters := chk_AnimatedLetters.Checked;
    TimeOut := StrToInt(edtTimeout.Text);
    LastQuestion := 'Create a class to make a Zip file in Delphi.';
    WriteConfig;
  end;
  Close;
end;

procedure TFrm_Setting.FormCreate(Sender: TObject);
begin
  ChangeFocus := False;
end;

procedure TFrm_Setting.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Ord(Key) = 27 then
    Close;
end;

procedure TFrm_Setting.FormShow(Sender: TObject);
begin
  if ChangeFocus then
  begin
    edt_ApiKey.Color := clYellow;
    edt_ApiKey.SetFocus;
  end;
end;

procedure TFrm_Setting.LoadDefaults;
begin
  edt_ApiKey.Text := '';
  edt_Url.Text := DefaultChatGPTURL;
  cbbModel.Text := DefaultModel;
  edt_MaxToken.Text := IntToStr(DefaultMaxToken);
  edt_Temperature.Text := DefaultTemperature;
  chk_AnimatedLetters.Checked := True;
  edtTimeout.Text := '40';
end;

{ TSingletonSettingObj }

class function TSingletonSettingObj.GetInstance: TSingletonSettingObj;
begin
  if not Assigned(FInstance) then
    FInstance := TSingletonSettingObj.Create;
  Result := FInstance;
end;

constructor TSingletonSettingObj.Create;
begin
  inherited;
  FTaskList := specialize TFPGList<string>.Create;
  LoadDefaults;
end;

destructor TSingletonSettingObj.Destroy;
begin
  FTaskList.Free;
  inherited Destroy;
end;

procedure TSingletonSettingObj.LoadDefaults;
begin
  FApiKey := '';
  FURL := DefaultChatGPTURL;
  FModel := DefaultModel;
  FMaxToken := DefaultMaxToken;
  FTemperature := DefaultTemperature;
  FHistoryEnabled := False;
  FShouldReloadHistory := False;
  FHistoryPath := '';
  FHighlightColor := clRed;
  FAnimatedLetters := True;
  FTimeOut := 20;
  FLastQuestion := 'Create a class to make a Zip file in Delphi.';
end;

procedure TSingletonSettingObj.ReadConfig;
var
  LvIniFile: TIniFile;
begin
  LvIniFile := TIniFile.Create(GetAppConfigDir(False) + 'ChatGPTConfigFile');
  try
    FURL := LvIniFile.ReadString('ChatGPT', 'URL', DefaultChatGPTURL);
    FApiKey := LvIniFile.ReadString('ChatGPT', 'APIKey', '');
    FModel := LvIniFile.ReadString('ChatGPT', 'Model', DefaultModel);
    FMaxToken := LvIniFile.ReadInteger('ChatGPT', 'MaxToken', DefaultMaxToken);
    FTemperature := LvIniFile.ReadString('ChatGPT', 'Temperature', DefaultTemperature);
    FAnimatedLetters := LvIniFile.ReadBool('ChatGPT', 'AnimatedLetters', True);
    FTimeOut := LvIniFile.ReadInteger('ChatGPT', 'TimeOut', 20);
    FLastQuestion := LvIniFile.ReadString('ChatGPT', 'LastQuestion', 'Create a class in Lazarus to manage reading and writing XML files');
  finally
    LvIniFile.Free;
  end;
end;

procedure TSingletonSettingObj.WriteConfig;
var
  LvIniFile: TIniFile;
begin
  LvIniFile := TIniFile.Create(GetAppConfigDir(False) + 'ChatGPTConfigFile');
  try
    LvIniFile.WriteString('ChatGPT', 'URL', FURL);
    LvIniFile.WriteString('ChatGPT', 'APIKey', FApiKey);
    LvIniFile.WriteString('ChatGPT', 'Model', FModel);
    LvIniFile.WriteInteger('ChatGPT', 'MaxToken', FMaxToken);
    LvIniFile.WriteString('ChatGPT', 'Temperature', FTemperature);
    LvIniFile.WriteBool('ChatGPT', 'AnimatedLetters', FAnimatedLetters);
    LvIniFile.WriteInteger('ChatGPT', 'TimeOut', FTimeOut);
  finally
    LvIniFile.Free;
  end;
end;

function TSingletonSettingObj.GetSetting: string;
begin
  Result := EmptyStr;
  ShowMessage('You need an API key, please fill the setting parameters in setting form.');
  Frm_Setting := TFrm_Setting.Create(nil);
  try
    Frm_Setting.ShowModal;
  finally
    FreeAndNil(Frm_Setting);
  end;
  Result := TSingletonSettingObj.Instance.ApiKey;
end;

function TSingletonSettingObj.GetHistoryFullPath: string;
begin
  Result := FHistoryPath + '\History.sdb';
end;

class function TSingletonSettingObj.IsValidJson(const AJsonString: string): Boolean;
var
  LvJsonObj: TJSONObject;
begin
  Result := False;
  try
    LvJsonObj := TJSONObject(GetJSON(AJsonString));
    Result := Assigned(LvJsonObj); // If parsing succeeds, JSON is valid
    LvJsonObj.Free;
  except
    Result := False;
  end;
end;

end.

