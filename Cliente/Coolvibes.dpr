program Coolvibes;

uses
  Forms,
  UnitMain in 'UnitMain.pas' {FormMain},
  UnitFormControl in 'UnitFormControl.pas' {FormControl},
  UnitFormReg in 'UnitFormReg.pas' {FormReg},
  ScreenMaxCap in 'ScreenMaxCap.pas' {ScreenMax},
  UnitOpciones in 'UnitOpciones.pas' {FormOpciones},
  UnitAbout in 'UnitAbout.pas' {FormAbout},
  UnitFormSendKeys in 'UnitFormSendKeys.pas' {FormSendKeys},
  UnitID in 'UnitID.pas' {FormID},
  UnitFormConfigServer in 'UnitFormConfigServer.pas' {FormConfigServer},
  SettingsDef in '..\Server\SettingsDef.pas',
  UnitFormNotifica in 'UnitFormNotifica.pas' {FormNotifica},
  UnitVariables in 'UnitVariables.pas',
  UnitFunciones in 'UnitFunciones.pas',
  UnitTransfer in 'UnitTransfer.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Coolvibes';
  Application.CreateForm(TFormMain, FormMain);
  Application.CreateForm(TFormOpciones, FormOpciones);
  Application.CreateForm(TFormAbout, FormAbout);
  Application.CreateForm(TFormSendKeys, FormSendKeys);
  Application.CreateForm(TFormID, FormID);
  Application.CreateForm(TFormConfigServer, FormConfigServer);
  Application.Run;
end.
