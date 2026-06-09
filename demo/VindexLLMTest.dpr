program VindexLLMTest;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  UMain in 'UMain.pas',
  UAppConfig in 'UAppConfig.pas',
  VindexLLM.Attention in '..\src\VindexLLM.Attention.pas',
  VindexLLM.Chat in '..\src\VindexLLM.Chat.pas',
  VindexLLM.Common in '..\src\VindexLLM.Common.pas',
  VindexLLM.Compute in '..\src\VindexLLM.Compute.pas',
  VindexLLM.Config in '..\src\VindexLLM.Config.pas',
  VindexLLM.ConsoleChat in '..\src\VindexLLM.ConsoleChat.pas',
  VindexLLM.Embeddings in '..\src\VindexLLM.Embeddings.pas',
  VindexLLM.FFN in '..\src\VindexLLM.FFN.pas',
  VindexLLM.GGUFReader in '..\src\VindexLLM.GGUFReader.pas',
  VindexLLM.Inference in '..\src\VindexLLM.Inference.pas',
  VindexLLM.LayerNorm in '..\src\VindexLLM.LayerNorm.pas',
  VindexLLM.Memory in '..\src\VindexLLM.Memory.pas',
  VindexLLM.Model in '..\src\VindexLLM.Model.pas',
  VindexLLM.Model.Gemma3 in '..\src\VindexLLM.Model.Gemma3.pas',
  VindexLLM.Model.Registry in '..\src\VindexLLM.Model.Registry.pas',
  VindexLLM.Resources in '..\src\VindexLLM.Resources.pas',
  VindexLLM.Sampler in '..\src\VindexLLM.Sampler.pas',
  VindexLLM.Session in '..\src\VindexLLM.Session.pas',
  VindexLLM.Shaders in '..\src\VindexLLM.Shaders.pas',
  VindexLLM.Tokenizer in '..\src\VindexLLM.Tokenizer.pas',
  VindexLLM.TokenWriter in '..\src\VindexLLM.TokenWriter.pas',
  VindexLLM.TOML in '..\src\VindexLLM.TOML.pas',
  VindexLLM.TurboQuant in '..\src\VindexLLM.TurboQuant.pas',
  VindexLLM.Utils in '..\src\VindexLLM.Utils.pas',
  VindexLLM.VirtualBuffer in '..\src\VindexLLM.VirtualBuffer.pas',
  VindexLLM.VirtualFile in '..\src\VindexLLM.VirtualFile.pas',
  VindexLLM.Vulkan in '..\src\VindexLLM.Vulkan.pas';

function ParseMode: TAppMode;
var
  LArg: string;
begin
  Result := amInference;
  if ParamCount >= 1 then
  begin
    LArg := LowerCase(ParamStr(1));
    if (LArg = '--chat') or (LArg = '-c') or (LArg = 'chat') then
      Result := amChat;
  end;
end;

begin
  try
    RunApp(ParseMode);
  except
    on E: Exception do
    begin
      Writeln('');
      Writeln('EXCEPTION: ', E.Message);
    end;
  end;

  if TVdxUtils.RunFromIDE() then
    TVdxUtils.Pause();
end.
