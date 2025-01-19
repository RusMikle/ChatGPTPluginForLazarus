unit UConsts;

{$mode objfpc}{$H+}

interface

const
  DefaultChatGPTURL = 'https://api.openai.com/v1/chat/completions';
  DefaultChatGPT4 = 'https://api.openai.com/v1/chat/completions';
  DefaultModel = 'gpt-4';
  DefaultMaxToken = 2048;
  DefaultTemperature = '0,1';
  DefaultIdentifier = 'cpt';
  DefaultCodeFormatter = False;
  DefaultRTL = False;


  DefaultWriteSonicURL = 'https://api.writesonic.com/v2/business/content/chatsonic?engine=premium';
  DefaultYouChatURL = 'https://betterapi.net/youdotcom/chat';
  CRLF = #13#10;

  ContextMenuAddTest = 'Create unit test for the following Delphi code';
  ContextMenuFindBugs = 'Find possible bugs in the following Delphi code';
  ContextMenuOptimize = 'Optimize the following Delphi code';
  ContextMenuAddComments = 'Add descriptive comments for the following Delphi code';
  ContextMenuCompleteCode = 'Try to complete the following Delphi code and return the completed code';

implementation

end.

