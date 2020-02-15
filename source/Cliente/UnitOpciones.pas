unit UnitOpciones;

interface

uses
  Windows, SysUtils, Classes, Controls, Forms,
  Buttons, StdCtrls, unitMain, unitVariables, ComCtrls, gnugettext,
  ExtCtrls, ImgList, Dialogs, UnitPlugins, Menus;

type
  TFormOpciones = class(TForm)
    BtnGuardar: TSpeedButton;
    PageControlOpciones: TPageControl;
    TabConexion: TTabSheet;
    LabelPuerto: TLabel;
    EditPuerto: TEdit;
    TabNotificaciones: TTabSheet;
    General: TTabSheet;
    GrpBoxAlSalir: TGroupBox;
    CheckBoxPreguntarAlSalir: TCheckBox;
    CheckBoxCloseToTray: TCheckBox;
    GroupBoxConexion: TGroupBox;
    Label1: TLabel;
    CheckBoxEscucharAlIniciar: TCheckBox;
    CheckBoxMandarPingAuto: TCheckBox;
    EditPingTimerInterval: TEdit;
    CheckBoxMinimizeToTray: TCheckBox;
    CheckBoxAutoRefrescar: TCheckBox;
    CheckBoxCerrarControlAlDesc: TCheckBox;
    CheckBoxNotificacionMsn: TCheckBox;
    CheckBoxNotiMsnDesc: TCheckBox;
    CheckBoxGloboalPedirS: TCheckBox;
    CheckBoxAlertaSonora: TCheckBox;
    EditRutaArchivoWav: TEdit;
    TabDirectorios: TTabSheet;
    LabeledEditDirUser: TLabeledEdit;
    LabeledDirScreen: TLabeledEdit;
    LabeledDirWebcam: TLabeledEdit;
    LabeledDirThumbs: TLabeledEdit;
    LabeledDirDownloads: TLabeledEdit;
    CheckBoxCCIndependiente: TCheckBox;
    ImageList: TImageList;
    TabPlugins: TTabSheet;
    ListViewPlugins: TListView;
    SpeedButtonAniadirPlugin: TSpeedButton;
    OpenDialog: TOpenDialog;
    SpeedButton1: TSpeedButton;
    CheckBoxGuardarPluginsEnDisco: TCheckBox;
    EditEstado: TEdit;
    TabAyuda: TTabSheet;
    GroupBoxAyuda: TGroupBox;
    CheckBoxAyuda1: TCheckBox;
    CheckBoxAyuda2: TCheckBox;
    CheckBoxAyuda3: TCheckBox;
    TabApariencia: TTabSheet;
    CheckBoxIncluirTreeView: TCheckBox;
    CheckBoxTreeViewCC: TCheckBox;
    CheckBoxPanelInferior: TCheckBox;
    CheckBoxCapturaInferior: TCheckBox;
    CheckBoxSplash: TCheckBox;
    procedure BtnGuardarClick(Sender: TObject);
    procedure CheckBoxPreguntarAlSalirClick(Sender: TObject);
    procedure CheckBoxCloseToTrayClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SpeedButtonAniadirPluginClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure Pluginadd(Path:string);
    procedure PageControlOpcionesChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    Plugins : string;
  end;

var
  FormOpciones: TFormOpciones;

implementation

{$R *.dfm}

procedure TFormOpciones.BtnGuardarClick(Sender: TObject);
var
  i:integer;
begin
  if CheckBoxPreguntarAlSalir.Checked then
    FormMain.OnCloseQuery := FormMain.FormCloseQuery
  else if CheckBoxCloseToTray.Checked then
    FormMain.OnCloseQuery := FormMain.FormCloseQueryMinimizarAlTray
  else
    FormMain.OnCloseQuery := nil;

  if CheckBoxMinimizeToTray.Checked then
    Application.OnMinimize := FormMain.MinimizeToTrayClick
  else
    Application.OnMinimize := nil;

  FormMain.TimerMandarPing.Interval := StrToIntDef(EditPingTimerInterval.Text, 30) * 1000;
  FormMain.TimerMandarPing.Enabled := CheckBoxMandarPingAuto.Checked;
  FormMain.StatusBar.Panels[1].Text := _('Puerto(s): ') + FormOpciones.EditPuerto.Text;
  Plugins := '';
  for i:=0 to listviewplugins.Items.Count-1 do
    Plugins := Plugins+listviewplugins.Items[i].SubItems[1]+'|';

  FormMain.GuardarArchivoINI();
  Close;
end;

procedure TFormOpciones.CheckBoxPreguntarAlSalirClick(Sender: TObject);
begin
  if CheckBoxCloseToTray.Checked and CheckBoxPreguntarAlSalir.Checked then
    CheckBoxCloseToTray.Checked := False;
end;

procedure TFormOpciones.CheckBoxCloseToTrayClick(Sender: TObject);
begin
  if CheckBoxCloseToTray.Checked and CheckBoxPreguntarAlSalir.Checked then
    CheckBoxPreguntarAlSalir.Checked := False;
end;

procedure TFormOpciones.FormCreate(Sender: TObject);
var
  s: string;
const
  ENTER = #13 + #10;
begin
  PageControlOpciones.ActivePage := General;
  s := '%CoolDir% => ' + _('Directorio de coolvibes');
  s := s + ENTER + '%Identificator% => ' + _('Nombre del servidor');
  s := s + ENTER + '%UserName% => ' + _('Nombre de usuario del servidor');
  s := s + ENTER + '%PCName% => ' + _('Nombre de PC del servidor');

  LabeledEditDirUser.Hint := s;
  LabeledDirScreen.Hint := s;
  LabeledDirWebcam.Hint := s;
  LabeledDirThumbs.Hint := s;
  LabeledDirDownloads.Hint := s;

end;

procedure TFormOpciones.SpeedButtonAniadirPluginClick(Sender: TObject);
begin
  Opendialog.FilterIndex := 0;
  OpenDialog.InitialDir := extractfilepath(paramstr(0));

  OpenDialog.Execute;

  Pluginadd(Opendialog.filename);
end;

procedure TFormOpciones.Pluginadd(Path:string);
var
  h : THandle;
  Plugin : TPlugin;
  Item : TListItem;
  NuevaPath : string;
  mitem : Tmenuitem;
  i : integer;
  procedure Creadir(dir: string);
  var
    tmp: string;
  begin
    while Pos('\', dir) > 0 do
      begin
        tmp := tmp + Copy(dir, 1, Pos('\', dir));
        Delete(dir, 1, Pos('\', dir));
        if not directoryexists(tmp) then
          CreateDirectory(PChar(tmp), nil);
      end;
  end;
begin
  if not fileexists(copy(Path,1,length(Path)-5)+'S.dll') then  //So existe el plugin por parte del servidor
  begin
    EditEstado.Text := _('No existe el plugin por parte del servidor, asegurate de que est�n en la misma carpeta');
    exit;
  end;
  if path = '' then exit;
  
  try
    H := Loadlibrary(PChar(Path));
  except
    EditEstado.Text := _('Imposible cargar el plugin');
    exit;
  end;

  if H = 0 then
  begin
    EditEstado.Text := _('Imposible cargar el plugin');
    exit;    //Error al cargar la dll
  end;
  
  Plugin := TPlugin.Create(H);

  for i:= 0 to ListViewPlugins.Items.Count-1 do
    if ListViewPlugins.Items[i].caption = Plugin.PluginName then
      begin
        EditEstado.Text := _('Ya est� cargado un plugin con ese nombre');
        exit;  //Ya est� cargado el plugin con ese nombre
      end;
  if (Plugin.Autor = '') and (Plugin.PluginName = '') then exit; //No es un plugin
  Nuevapath := extractfilepath(paramstr(0))+'Recursos\Plugins\'+Plugin.PluginName+'\';

  //"Instalamos" el plugin
  Creadir(NuevaPath);
  Nuevapath := Nuevapath+extractfilename(Path);
  copyfile(pchar(Path),pchar(NuevaPath), false); //La dll del cliente

  copyfile(pchar(copy(Path,1,length(Path)-5)+'S.dll'),pchar(extractfilepath(NuevaPath)+extractfilename(copy(Path,1,length(Path)-5)+'S.dll')), false); //el server

  Item := ListViewPlugins.Items.Add;
  item.ImageIndex := 4;
  item.Caption := Plugin.PluginName;
  item.SubItems.Add(Plugin.Autor);
  item.SubItems.Add(Nuevapath);
  mitem := TMenuItem.Create(Formmain.PopupMenuConexiones);
  mitem.Caption := item.caption;
  mitem.OnClick := Formmain.PluginClick;
  mitem.Hint := item.Caption;
  mitem.ImageIndex := 260;
  item.Data := mitem;
  Formmain.Plugins.Add(mitem);
end;

procedure TFormOpciones.SpeedButton1Click(Sender: TObject);
var
  index : integer;
begin
  if ListViewPlugins.Selected = nil then exit;
  index := TMenuItem(ListViewPlugins.Selected.data).MenuIndex;
  Formmain.Plugins.Delete(index);
  ListViewPlugins.Selected.Delete;
end;

procedure TFormOpciones.PageControlOpcionesChange(Sender: TObject);
begin
    EditEstado.Text := '';
end;

procedure TFormOpciones.FormShow(Sender: TObject);
begin
  FormOpciones.ShowHint := CheckboxAyuda1.Checked;
end;

end.
