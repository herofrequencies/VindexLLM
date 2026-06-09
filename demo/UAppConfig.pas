unit UAppConfig;

interface

uses
  VindexLLM.Utils,
  VindexLLM.Inference,
  VindexLLM.TokenWriter;

function ModelPath: string;
function EmbedderPath: string;
function ProjectRoot: string;
function SessionDbPath: string;

procedure ConsoleWriteLn(const AText: string);
procedure WriteRunLog(const AText: string);

var
  GTokenWriter: TVdxConsoleTokenWriter;

procedure StatusCallback(const AText: string; const AUserData: Pointer);
procedure PrintErrors(const AInference: TVdxInference);
procedure InferenceEventCallback(const AEvent: TVdxInferenceEvent;
  const AUserData: Pointer);
function CancelCallback(const AUserData: Pointer): Boolean;
procedure PrintToken(const AToken: string; const AUserData: Pointer);
procedure PrintStats(const AStats: PVdxInferenceStats);

implementation

uses
  WinAPI.Windows,
  System.IOUtils,
  System.SysUtils,
  System.Generics.Collections;

function ProjectRoot: string;
var
  LExeDir: string;
  LDirName: string;
begin
  LExeDir := ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  LDirName := ExtractFileName(LExeDir);
  if SameText(LDirName, 'bin') then
    Result := TPath.GetFullPath(TPath.Combine(LExeDir, '..'))
  else
    Result := LExeDir;
end;

function SessionDbPath: string;
begin
  Result := TPath.Combine(ProjectRoot, 'demo\session.db');
end;

function ModelPath: string;
begin
  Result := TPath.Combine(ProjectRoot, 'models\gemma-3-4b-it-q4_0.gguf');
end;

function EmbedderPath: string;
begin
  Result := TPath.Combine(ProjectRoot, 'models\embeddinggemma-300m-qat-Q8_0.gguf');
end;

procedure WriteRunLog(const AText: string);
var
  LLogPath: string;
begin
  LLogPath := TPath.Combine(ProjectRoot, 'demo\last-run.log');
  ForceDirectories(TPath.GetDirectoryName(LLogPath));
  TFile.AppendAllText(LLogPath, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + '  ' + AText + sLineBreak);
end;

procedure ConsoleWriteLn(const AText: string);
begin
  if TVdxUtils.HasConsole() then
    TVdxUtils.PrintLn(AText)
  else
    Writeln(AText);
end;

procedure StatusCallback(const AText: string; const AUserData: Pointer);
begin
  ConsoleWriteLn(AText);
end;

procedure PrintErrors(const AInference: TVdxInference);
var
  LErrors: TVdxErrors;
  LItems: TList<TVdxError>;
  LI: Integer;
  LErr: TVdxError;
  LColor: string;
  LLabel: string;
begin
  LErrors := AInference.GetErrors();
  if LErrors = nil then
    Exit;
  LItems := LErrors.GetItems();
  if LItems.Count = 0 then
    Exit;

  TVdxUtils.PrintLn('');
  for LI := 0 to LItems.Count - 1 do
  begin
    LErr := LItems[LI];
    case LErr.Severity of
      esHint:
      begin
        LColor := COLOR_CYAN;
        LLabel := 'HINT';
      end;
      esWarning:
      begin
        LColor := COLOR_YELLOW;
        LLabel := 'WARN';
      end;
      esError:
      begin
        LColor := COLOR_RED;
        LLabel := 'ERROR';
      end;
      esFatal:
      begin
        LColor := COLOR_MAGENTA;
        LLabel := 'FATAL';
      end;
    else
      LColor := COLOR_WHITE;
      LLabel := '?';
    end;

    if LErr.Code <> '' then
      TVdxUtils.PrintLn(LColor + '[%s] %s: %s', [LLabel, LErr.Code, LErr.Message])
    else
      TVdxUtils.PrintLn(LColor + '[%s] %s', [LLabel, LErr.Message]);
  end;
end;

procedure InferenceEventCallback(const AEvent: TVdxInferenceEvent;
  const AUserData: Pointer);
begin
  if AEvent = ieGenerateEnd then
    TVdxUtils.PrintLn();

  TVdxUtils.PrintLn(COLOR_GREEN + '[event] %s', [CVdxEventNames[AEvent]]);
end;

function CancelCallback(const AUserData: Pointer): Boolean;
begin
  Result := (GetAsyncKeyState(VK_ESCAPE) and $8000) <> 0;
end;

procedure PrintToken(const AToken: string; const AUserData: Pointer);
begin
  GTokenWriter.Write(AToken);
end;

procedure PrintStats(const AStats: PVdxInferenceStats);
var
  LStopColor: string;
begin
  TVdxUtils.PrintLn();

  TVdxUtils.Print(COLOR_WHITE + 'Prefill:    ');
  TVdxUtils.Print(COLOR_CYAN + '%d tokens in %.0fms ', [
    AStats.PrefillTokens, AStats.PrefillTimeMs]);
  TVdxUtils.PrintLn(COLOR_GREEN + '(%.1f tok/s)', [AStats.PrefillTokPerSec]);

  TVdxUtils.Print(COLOR_WHITE + 'Generation: ');
  TVdxUtils.Print(COLOR_CYAN + '%d tokens in %.0fms ', [
    AStats.GeneratedTokens, AStats.GenerationTimeMs]);
  TVdxUtils.PrintLn(COLOR_GREEN + '(%.1f tok/s)', [AStats.GenerationTokPerSec]);

  case AStats.StopReason of
    srEOS,
    srStopToken:   LStopColor := COLOR_GREEN;
    srMaxTokens,
    srContextFull: LStopColor := COLOR_YELLOW;
    srCancelled:   LStopColor := COLOR_RED;
  else
    LStopColor := COLOR_WHITE;
  end;
  TVdxUtils.Print(COLOR_WHITE + 'TTFT: ');
  TVdxUtils.Print(COLOR_CYAN + '%.0fms', [AStats.TimeToFirstTokenMs]);
  TVdxUtils.Print(COLOR_WHITE + ' | Total: ');
  TVdxUtils.Print(COLOR_CYAN + '%.0fms', [AStats.TotalTimeMs]);
  TVdxUtils.Print(COLOR_WHITE + ' | Stop: ');
  TVdxUtils.PrintLn(LStopColor + '%s', [CVdxStopReasons[AStats.StopReason]]);

  TVdxUtils.Print(COLOR_WHITE + 'VRAM: ');
  if AStats.VRAMUsage.TotalBytes > UInt64(10) * 1024 * 1024 * 1024 then
    TVdxUtils.Print(COLOR_YELLOW + '%d MB ', [AStats.VRAMUsage.TotalBytes div (1024 * 1024)])
  else
    TVdxUtils.Print(COLOR_GREEN + '%d MB ', [AStats.VRAMUsage.TotalBytes div (1024 * 1024)]);
  TVdxUtils.PrintLn(COLOR_CYAN + '(weights: %d, cache: %d, buffers: %d)', [
    AStats.VRAMUsage.WeightsBytes div (1024 * 1024),
    AStats.VRAMUsage.CacheBytes div (1024 * 1024),
    AStats.VRAMUsage.BuffersBytes div (1024 * 1024)]);
end;

end.
