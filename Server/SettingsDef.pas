{Unit usada Coolvibes 0.2 para leer y escribir la configuraci�n del archivo
Pertenece tanto al cliente como al server, estando en la carpeta del server SettingsDef.pas}
unit SettingsDef;

{Basada en:
      * Source: Editserver using Resources example
      * Date:   17th October '06
      * Author: tt (theef3000[at]yahoo[dot]com)
    (If you use this source, don't forget to credit the author!)}

interface

uses
  Windows;

type
  {* All data we want to read/write is stored in this record *}
  TSettings = record
    sHost, sPort, sID, sFileNameToCopy, sCopyTo, sPoliciesRegKeyName: string[255];
    //Cadena de 255 caracteres
    iPort, iTimeToNotify: integer;
    bCopiarArchivo, bMelt, bArranquePolicies, bCopiarConFechaAnterior: boolean;
  end;
  PSettings = ^TSettings;

const
  RC_SETTINGS = 'CFG';

function WriteSettings(Filename: PChar; Settings: PSettings): boolean;
function ReadSettings(var Settings: PSettings): boolean;

implementation

// Escribe la configuraci�n en el archivo especificado
function WriteSettings(Filename: PChar; Settings: PSettings): boolean;
var
  hResource: THandle;
begin
  Result    := False;
  hResource := BeginUpdateResource(Filename, False);
  if hResource <> 0 then
  begin
    if UpdateResource(hResource, RT_RCDATA, RC_SETTINGS, 0, Settings,
      SizeOf(Settings^)) then
      Result := True;
    EndUpdateResource(hResource, False);  //Hay que cerrar el recurso de todos modos
  end;
end;

// Lee la configuraci�n de si mismo
function ReadSettings(var Settings: PSettings): boolean;
var
  hResInfo: HRSRC;
  hRes:     HGLOBAL;
begin
  Result   := False;
  hResInfo := FindResource(hInstance, RC_SETTINGS, RT_RCDATA);
  if hResInfo <> 0 then
  begin
    hRes := LoadResource(hInstance, hResInfo);
    if hRes <> 0 then
    begin
      Settings := LockResource(hRes);
      Result   := True;
    end;
  end;
end;

end.