{Unit perteneciente al troyano coolvibes que contiene todas las variables
configurables del troyano}
unit UnitVariables;

interface

uses
  SettingsDef; //Aqu� se define el record de configuracion (TSettings)

var
  Configuracion: TSettings; //Aqu� se guardaran todas las opciones editables del server.
  //Es un record que est� definido en la unidad SettingsDef.
 // MS: TMemoryStream; //MS de la captura de pantalla
  VersionDelServer: array[0..5] of char;
  //Peque�a string donde se guarda la versi�n del servidor,
  //solo le caben 6 caracteres. Si se necesita m�s, hay que agrandarla.
  Sistema_operativo, CPU: string; //Para no tener que mirar el registro cada vez que los necesitemos

  StopSearch: Boolean; //Para parar de buscar

  CapturaWebcam: string; //Variables para el thread
  CapturaPantalla: string;
  CapturaThumb: string;
  CapturaKeylogger: string;
  CapturaAudio: string;
  RecordedAudio: string;
  pararcapturathread: Boolean;

  id1: Longword = 0;
  const
  ENTER = #10#15#80#66#77#1#72#87;//La string que marca el final de cada comando
implementation

end.
