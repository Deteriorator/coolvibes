unit UnitTransfer;

interface

uses Windows, SysUtils, SocketUnit;

type
  TThreadInfo = class(TObject)
  public
    host:   string;
    port:   integer;
    SH:     string;
    Action: string;
    FileName: ansistring;
    Alias:  ansistring;
    RemoteFileName: ansistring;
    ThreadId: longword;
    Beginning: integer;
    UploadSize: int64;
    deleteAfterTransfer: boolean;
    constructor Create(pHost: string; pPort: integer; pSH, pFilename, pAction: ansistring;
      pBeginning: integer); overload;

  end;


procedure ThreadedTransfer(Parameter: Pointer);
procedure sendFile(MySock: TClientSocket; Path: ansistring; Beginning: int64);
procedure getFile(MySock: TClientSocket; localPath: ansistring; filesize: integer);
function leerLinea(MySock: TClientSocket): string;
function MyGetFileSize(path: string): int64;


const
  ENTER = #10;

implementation

constructor TThreadInfo.Create(pHost: string; pPort: integer;
  pSH, pFilename, pAction: ansistring; pBeginning: integer);
begin
  Host   := pHost;
  Port   := pPort;
  SH     := pSH;
  FileName := pFileName;
  Alias  := '';
  Action := pAction;
  Beginning := pBeginning;
end;

function leerLinea(MySock: TClientSocket): string;
var
  buf: char;
begin
  buf := ' ';
  while buf <> #10 do
  begin
    MySock.ReceiveBuffer(buf, 1);
    Result := Result + buf;
  end;
  Result := Trim(Result);
end;

procedure ThreadedTransfer(Parameter: Pointer);
var
  ThreadInfo: TThreadInfo;
  SocketTransf: TClientSocket;
  FileSize: integer;
  aux: string;
begin
  ThreadInfo := TThreadInfo(Parameter);

  try

    SocketTransf := TClientSocket.Create;
    SocketTransf.Connect(ThreadInfo.host, ThreadInfo.port);

    if SocketTransf.Connected then
    begin
      //informamos a cual conexion principal pertenecemos
      SocketTransf.SendString('SH|' + ThreadInfo.SH + ENTER);
      FileSize := MyGetFileSize(ThreadInfo.FileName);
      if ThreadInfo.Action <> 'SENDFILE' then
      begin
        if trim(ThreadInfo.Alias) <> '' then
          SocketTransf.SendString(ThreadInfo.Action + '|' + ThreadInfo.Alias +
            '|' + IntToStr(FileSize) + ENTER)
        else
          SocketTransf.SendString(ThreadInfo.Action + '|' + ThreadInfo.FileName +
            '|' + IntToStr(FileSize) + ENTER);

         if fileexists(ThreadInfo.FileName) then //poco probable pero podr�a pasar
        SendFile(SocketTransf, ThreadInfo.FileName, ThreadInfo.Beginning);
      end
      else
      begin
        SocketTransf.SendString(ThreadInfo.Action + '|' + ThreadInfo.RemoteFileName + ENTER);
        leerLinea(SocketTransf);//la linea de maininfo que me m andan al conectarme
        getFile(SocketTransf, ThreadInfo.FileName, ThreadInfo.UploadSize);
      end;
      if ThreadInfo.deleteAfterTransfer then
        DeleteFile(PChar(ThreadInfo.filename));
      //closeHandle(threadInfo.ThreadId);
    end;

  except


  end;//try-Except
end;

procedure sendFile(MySock: TClientSocket; Path: ansistring; Beginning: int64);
var
  myFile:    file;
  byteArray: array[0..1023] of byte;
  Count, filesize: integer;
begin
  try
    filesize := MyGetFileSize(path);
    if not filesize > 0 then
    begin
      //     MySock.SendString('takeMessage;Could not access file, size: '+IntToStr(filesize));
    end
    else
      FileMode := $0000;
    AssignFile(myFile, path);
    reset(MyFile, 1);
    seek(myFile, beginning);
    while not EOF(MyFile) and Mysock.Connected do
    begin
      BlockRead(myFile, byteArray, 1024, Count);
      Mysock.SendBuffer(bytearray, Count);
    end;
    closefile(myfile);
  except
    closefile(myfile);
  end;
end;


procedure getFile(MySock: TClientSocket; localPath: ansistring; filesize: integer);
var
  myFile:      file;
  byteArray:   array[0..1023] of byte;
  TotalRead, currRead: integer;
  CurrWritten: integer;
  Excepcion:   boolean;
begin
  try
    Excepcion := False;
    AssignFile(MyFile, localPath);
    Rewrite(MyFile, 1);
    Totalread := 0;
    currRead  := 0;
    while ((TotalRead < filesize)) do
    begin
      currRead  := MySock.ReceiveBuffer(byteArray, sizeof(bytearray));
      TotalRead := TotalRead + currRead;
      BlockWrite(MyFile, bytearray, currRead, currwritten);
      currwritten := currread;
    end;
  except
    Excepcion := True;
    CloseFile(MyFile);
    if MySock.Connected then
      MySock.Disconnect;
    MySock.Free;
  end;
  if not Excepcion then
  begin
    CloseFile(MyFile);
    if MySock.Connected then
      MySock.Disconnect;
    MySock.Free;
  end;
end;

function MyGetFileSize(path: string): int64;
var
  SearchRec: TSearchRec;
begin
  if FindFirst(path, faAnyFile, SearchRec) = 0 then                  // if found

    Result := int64(SearchRec.FindData.nFileSizeHigh) shl int64(32) +
      // calculate the size
      int64(SearchREc.FindData.nFileSizeLow)
  else
    Result := -1;
  findclose(SearchRec);
end;

end.
