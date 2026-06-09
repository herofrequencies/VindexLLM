unit UMain;

interface

type
  TAppMode = (amInference, amChat);

procedure RunApp(const AMode: TAppMode);

procedure RunInferenceTest;
procedure RunChatTest;

implementation

uses
  System.IOUtils,
  System.SysUtils,
  VindexLLM.Utils,
  VindexLLM.Inference,
  VindexLLM.Sampler,
  VindexLLM.TokenWriter,
  VindexLLM.ConsoleChat,
  UAppConfig;

procedure RunApp(const AMode: TAppMode);
begin
  case AMode of
    amInference: RunInferenceTest;
    amChat: RunChatTest;
  end;
end;

procedure RunInferenceTest;
const
  CPrompt =
  '''
  Explain how a CPU works in simple terms. Keep the answer under 200 words.
  ''';
var
  LInference: TVdxInference;
  LConfig: TVdxSamplerConfig;
  LLoaded: Boolean;
  LModelPath: string;
begin
  LModelPath := ModelPath;
  WriteRunLog('Starting inference test');
  if not TFile.Exists(LModelPath) then
  begin
    ConsoleWriteLn('Model file not found:');
    ConsoleWriteLn(LModelPath);
    ConsoleWriteLn('');
    ConsoleWriteLn('Download the vetted Gemma 3 4B model into the models folder.');
    ConsoleWriteLn('See models\README.txt for download links.');
    Exit;
  end;

  GTokenWriter := TVdxConsoleTokenWriter.Create();
  try
    GTokenWriter.MaxWidth := 118;

    TVdxUtils.PrintLn(COLOR_CYAN + 'Loading model: %s', [LModelPath]);
    TVdxUtils.PrintLn(COLOR_WHITE + 'Press ESC during generation to cancel.');
    TVdxUtils.PrintLn('');

    LInference := TVdxInference.Create();
    try
      LInference.SetStatusCallback(StatusCallback, nil);
      LInference.SetTokenCallback(PrintToken, nil);
      LInference.SetInferenceEventCallback(InferenceEventCallback, nil);
      LInference.SetCancelCallback(CancelCallback, nil);

      LLoaded := LInference.LoadModel(LModelPath);
      try
        PrintErrors(LInference);
        if not LLoaded then
        begin
          WriteRunLog('Model load failed');
          Exit;
        end;

        WriteRunLog('Model loaded successfully');

        LConfig := TVdxSampler.DefaultConfig();
        LConfig.Temperature := 1.0;
        LConfig.TopK := 64;
        LConfig.TopP := 0.95;
        LConfig.MinP := 0.0;
        LConfig.RepeatPenalty := 1.0;
        LConfig.RepeatWindow := 64;
        LConfig.Seed := 0;
        LInference.SetSamplerConfig(LConfig);

        TVdxUtils.PrintLn(COLOR_CYAN + 'Prompt:');
        TVdxUtils.PrintLn(COLOR_WHITE + CPrompt.Trim);
        TVdxUtils.PrintLn('');
        TVdxUtils.PrintLn(COLOR_CYAN + 'Response:');

        GTokenWriter.Reset();
        LInference.Generate(CPrompt, 512);

        PrintErrors(LInference);
        PrintStats(LInference.GetStats());
        WriteRunLog(Format('Completed: %d generated tokens, stop=%s',
          [LInference.GetStats().GeneratedTokens,
           CVdxStopReasons[LInference.GetStats().StopReason]]));
      finally
        LInference.UnloadModel();
      end;
    finally
      LInference.Free();
    end;
  finally
    GTokenWriter.Free();
    GTokenWriter := nil;
  end;
end;

procedure RunChatTest;
var
  LChat: TVdxConsoleChat;
  LConfig: TVdxSamplerConfig;
  LModelPath: string;
  LEmbedderPath: string;
begin
  LModelPath := ModelPath;
  LEmbedderPath := EmbedderPath;

  if not TFile.Exists(LModelPath) then
  begin
    ConsoleWriteLn('Model file not found:');
    ConsoleWriteLn(LModelPath);
    Exit;
  end;

  if (LEmbedderPath <> '') and not TFile.Exists(LEmbedderPath) then
  begin
    ConsoleWriteLn('Embedder file not found (chat will use keyword search only):');
    ConsoleWriteLn(LEmbedderPath);
    LEmbedderPath := '';
  end;

  LChat := TVdxConsoleChat.Create();
  try
    LChat.ModelPath := LModelPath;
    LChat.EmbedderPath := LEmbedderPath;
    LChat.MemoryDbPath := SessionDbPath;
    LChat.SystemPrompt := 'You are a helpful assistant.';
    LChat.MaxTokens := 512;

    LConfig := TVdxSampler.DefaultConfig();
    LConfig.Temperature := 1.0;
    LConfig.TopK := 64;
    LConfig.TopP := 0.95;
    LConfig.Seed := 0;
    LChat.SamplerConfig := LConfig;

    ConsoleWriteLn('Starting interactive chat. Type quit to exit. Press ESC during generation to cancel.');
    LChat.Run();
  finally
    LChat.Free();
  end;
end;

end.
