unit UnitTransfer;

interface

uses Windows, SysUtils, Dialogs, ComCtrls, IdTCPServer, UnitFunciones;

type
  TCallbackProcedure = procedure(Sender: TObject) of object;

type
  TDescargaHandler = class(TObject)
  public
    ProgressBar: TProgressBar;
    ListView:  TListView;
    AThread:   TIdPeerThread;
    Item:      TListItem; //Item de la descarga
    Descargado: int64;    //Datos descargados
    SizeFile:  int64;
    ultimoBajado: int64;
    Origen, Destino: ansistring;
    Transfering: boolean;
    Finalizado: boolean;
    Status:    string;
    cancelado: boolean;
    callback:  TCallbackProcedure;
    es_descarga: boolean;
    constructor Create(PThread: TIdPeerThread; fname: ansistring;
      TSize: integer; PDownloadPath: ansistring; pListView: TListView;
      p_es_descarga: boolean); overload;
    procedure addToView;
    procedure TransferFile;
    procedure ResumeTransfer;
    procedure CancelarDescarga;
    procedure UploadFile;
    procedure Update;
    procedure UpdateVelocidad;
  private

  end;


implementation

constructor TDescargaHandler.Create(PThread: TIdPeerThread; fname: ansistring;
  TSize: integer; PDownloadPath: ansistring; pListView: TListView; p_es_descarga: boolean);
begin
  Athread     := pThread;
  Origen      := fname;
  Destino     := pDownloadPath;
  SizeFile    := TSize;
  ListView    := pListView;
  transfering := False;
  cancelado   := False;
  finalizado  := False;
  es_descarga := p_es_descarga;
  ProgressBar := TProgressBar.Create(nil);
  ProgressBar.Max := TSize;
  if Athread <> nil then
    AThread.Synchronize(self.addToView)
  else
    self.addToView;

end;

procedure TDescargaHandler.addToView;
var
  RectProg: TRect;
begin
  item := ListView.items.add;
  item.Caption := ExtractFileName(Origen);
  Item.SubItems.Add('En espera');
  Item.SubItems.Add(ObtenerMejorUnidad(self.SizeFile));
  Item.SubItems.Add('0 Kb');
  Item.SubItems.Add('');
  Item.SubItems.Add('En espera');

  if es_descarga then
    Item.ImageIndex := 38
  else
    Item.ImageIndex := 36;

  Item.Data := self; //apunta a un objeto tipo TDescargaHandler

  RectProg      := Item.DisplayRect(drBounds);
  //Posicion izquierda de todo el item mas el ancho de la primera columna
  RectProg.Left := RectProg.Left + ListView.Columns[0].Width;
  //Posicion derecha de la progressbar mas el ancho de la columna donde est�
  RectProg.Right := RectProg.Left + ListView.Columns[1].Width;
  //BoundsRect - Specifies the bounding rectangle of the control, expressed in the coordinate system of the parent control.
  ProgressBar.BoundsRect := RectProg;
  progressBar.Parent := ListView;
end;

procedure TDescargaHandler.TransferFile;
var
  Buffer: array[0..1023] of byte;
  F:      file;
  Read, currRead: integer;
  tickBefore, tickNow: integer;
  seconds: extended;
  buffSize: integer;
begin
  transfering := True;
  status      := 'Descargando';
  AssignFile(F, Destino);
  Rewrite(F, 1);
  Read     := 0;
  currRead := 0;
  tickBefore := getTickCount;
  tickNow  := getTickCount;
  UltimoBajado := 0;
  buffSize := SizeOf(Buffer);
  try
    while ((Read < SizeFile) and Athread.Connection.Connected and not cancelado) do
    begin

      if (SizeFile - Read) >= buffSize then
        currRead := buffSize
      else
        currRead := (SizeFile - Read);

      Athread.Connection.ReadBuffer(buffer, currRead);
      Read := Read + currRead;

      tickNow := getTickCount;
      if (tickNow - TickBefore >= 1000) then
      begin
        Athread.Synchronize(UpdateVelocidad);
        tickBefore   := tickNow;
        UltimoBajado := Descargado;
      end;

      BlockWrite(F, Buffer, currRead);
      currRead   := 0;
      Descargado := Read;
      Athread.Synchronize(Update);

    end;
  finally
    CloseFile(F);
    Athread.Data := nil;
    Athread.Connection.Disconnect;
    seconds     := (gettickcount - tickBefore) / 1000;
    transfering := False;
    if Read <> SizeFile then
    begin
      status      := 'Detenido';
      cancelado   := True;
      Transfering := False;
    end
    else
    begin
      status      := 'Finalizado';
      finalizado  := True;
      transfering := False;
    end;
    Athread.Synchronize(Update);
    if @callback <> nil then
      callback(self);

  end;//end de finally
end;

procedure TDescargaHandler.ResumeTransfer;
var
  Buffer: array[0..1024] of byte;
  F:      file;
  Read, currRead: integer;
  tickBefore, tickNow: integer;
  seconds: extended;
  buffSize: integer;
begin
  transfering := True;
  cancelado   := False;
  status      := 'Descargando';
  tickBefore  := getTickCount;
  if FileExists(destino) then
  begin
    AssignFile(F, Destino);
    reset(F, 1);
  end
  else
  begin
    AssignFile(F, Destino);
    Rewrite(F, 1);
  end;
  seek(f, Descargado);
  Read     := Descargado;
  currRead := 0;

  tickBefore   := getTickCount;
  tickNow      := getTickCount;
  UltimoBajado := 0;
  buffSize     := SizeOf(Buffer);
  try
    while ((Read < SizeFile) and Athread.Connection.Connected and not cancelado) do
    begin
      if (SizeFile - Read) >= buffSize then
        currRead := buffSize
      else
        currRead := (SizeFile - Read);

      Athread.Connection.ReadBuffer(buffer, currRead);
      Read := Read + currRead;

      tickNow := getTickCount;
      if (tickNow - TickBefore >= 1000) then
      begin
        Athread.Synchronize(UpdateVelocidad);
        tickBefore   := tickNow;
        UltimoBajado := Descargado;
      end;

      BlockWrite(F, Buffer, currRead);
      Descargado := Read;
      Athread.Synchronize(Update);
    end;
  finally
    CloseFile(F);
    Athread.Data := nil;
    Athread.Connection.Disconnect;
    seconds     := (gettickcount - tickBefore) / 1000;
    transfering := False;
    if Read <> SizeFile then
    begin
      status      := 'Detenido';
      cancelado   := True;
      Transfering := False;
    end
    else
    begin
      status      := 'Finalizado';
      finalizado  := True;
      transfering := False;
    end;
    Athread.Synchronize(Update);
    if @callback <> nil then
      callback(self);

  end;//end de finally
end;

procedure TDescargaHandler.UploadFile;
var
  myFile:    file;
  byteArray: array[0..1023] of byte;
  Count, sent, filesize: integer;
  tickBefore, tickNow: integer;
begin
  filesize := MyGetFileSize(Origen);
  if not filesize > 0 then
  begin
    MessageDlg('No se pudo acceder al archivo, puede que est� en uso por otra aplicaci�n',
      mtWarning, [mbOK], 0);
    AThread.Connection.Disconnect;
    Exit;
  end;
  transfering := True;
  cancelado   := False;
  status      := 'Subiendo';
  try
    FileMode := $0000;
    AssignFile(myFile, Origen);
    reset(MyFile, 1);
    sent := 0;
    tickBefore := getTickCount;
    UltimoBajado := 0;
    while not EOF(MyFile) and AThread.Connection.Connected and not cancelado do
    begin
      BlockRead(myFile, bytearray, 1024, Count);
      sent    := sent + AThread.Connection.Socket.Send(bytearray, Count);
      tickNow := getTickCount;
      if (tickNow - TickBefore >= 1000) then
      begin
        Athread.Synchronize(UpdateVelocidad);
        tickBefore   := tickNow;
        UltimoBajado := Descargado;
      end;
      //aunque originalmente indicaba cuando se habia descargado tambien
      //nos servira para llevar la cuenta de cuanto hemos subido
      Descargado := sent;
      Athread.Synchronize(Update);
    end;
  finally
    closefile(myfile);
    if sent <> filesize then
    begin
      cancelado   := True;
      transfering := False;
      finalizado  := False;
      Status      := 'Detenido';
    end
    else
    begin
      cancelado   := False;
      transfering := False;
      finalizado  := True;
      Status      := 'Finalizado';
    end;
    Athread.Synchronize(Update);
  end;
end;

procedure TDescargaHandler.CancelarDescarga;
begin
  cancelado   := True;
  transfering := False;
  Finalizado  := False;
end;

procedure TDescargaHandler.Update;
begin
  ProgressBar.Position := self.Descargado;
  if Item.SubItems[4] <> Status then
    Item.SubItems[4] := Status;
  Item.SubItems[2] := ObtenerMejorUnidad(Descargado);
end;

procedure TDescargaHandler.UpdateVelocidad;
begin
  Item.SubItems[3] := ObtenerMejorUnidad(Descargado - UltimoBajado) + '/s';
end;

end.