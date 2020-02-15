{Unit perteneciente al troyano coolvibes que contiene todas las variables
configurables del troyano}
unit UnitVariables;

interface

uses
  SettingsDef, classes; //Aqu� se define el record de configuracion (TSettings)

var
  Configuracion: TSettings; //Aqu� se guardaran todas las opciones editables del server.
  //Es un record que est� definido en la unidad SettingsDef.
  MS: TMemoryStream; //MS de la captura de pantalla
  VersionDelServer: array[0..5] of char;
 //Peque�a string donde se guarda la versi�n del servidor,
 //solo le caben 6 caracteres. Si se necesita m�s, hay que agrandarla.

implementation

end.
