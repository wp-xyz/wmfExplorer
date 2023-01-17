unit wxMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, mrumanager, Forms, Controls, Graphics, Dialogs,
  ComCtrls, Menus, ActnList, StdActns, ExtCtrls, Grids, StdCtrls, mpHexEditor,
  laz.VirtualTrees;

type

  { TMainForm }

  TMainForm = class(TForm)
    AcExternalViewer: TAction;
    ActionList: TActionList;
    AcFiileExit: TFileExit;
    AcFileOpen: TFileOpen;
    CoolBar: TCoolBar;
    Image: TImage;
    ImageList: TImageList;
    Label1: TLabel;
    WMFObjList: TListBox;
    MenuItem1: TMenuItem;
    MnuRecentlyOpened: TMenuItem;
    MenuItem2: TMenuItem;
    OffsetInfo: TLabel;
    MRUPopupMenu: TPopupMenu;
    Panel2: TPanel;
    HexPanel: TPanel;
    RecordTypeInfo: TLabel;
    ColorDisplay: TShape;
    Separator1: TMenuItem;
    SizeInfo: TLabel;
    LblOffset: TLabel;
    LblRecordType: TLabel;
    LblSize: TLabel;
    MainMenu: TMainMenu;
    MnuFileClose: TMenuItem;
    MnuFileOpen: TMenuItem;
    MnuFile: TMenuItem;
    PageControl1: TPageControl;
    PaintBox1: TPaintBox;
    Panel1: TPanel;
    Splitter1: TSplitter;
    PgData: TTabSheet;
    PgGraphic: TTabSheet;
    Splitter2: TSplitter;
    Splitter3: TSplitter;
    ValueGrid: TStringGrid;
    PgAnalysis: TTabSheet;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    Tree: TLazVirtualStringTree;
    AnalysisTree: TLazVirtualStringTree;
    procedure AcExternalViewerExecute(Sender: TObject);
    procedure AcFileOpenAccept(Sender: TObject);
    procedure AnalysisTreeFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure AnalysisTreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure HexViewClick(Sender: TObject);
    procedure MRUMenuManagerRecentFile(Sender: TObject; const AFileName: String);
    procedure PageControl1Change(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject);
    procedure TreeFocusChanged(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex);
    procedure TreeFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure TreeGetText(Sender: TBaseVirtualTree;
      Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
      var CellText: String);
    procedure ValueGridClick(Sender: TObject);
    procedure ValueGridPrepareCanvas(Sender: TObject; ACol, ARow: Integer;
      AState: TGridDrawState);

  private
    { private declarations }
    FFileName: String;
    FStream: TStream;
    FBuffer: array of byte;
    FCurrOffset: Int64;
    FHexView: TMPHexEditor;
    MRUMenuManager: TMRUMenuManager;
    function AddAnalysisNode(AOffset: Integer; AValue, ADescription: String): PVirtualNode;
    function AddNode(AOffset: Int64; AText: String; ASizeInBytes: Integer): PVirtualNode;
    function GetValueGridDatasize: Integer;
    procedure LoadFile(const AFileName: String);
    procedure PopulateAnalysis(ARecordType: Word; AOffset: Int64);
    procedure PopulateHexView;
    procedure PopulateValueGrid;
    procedure UpdateCaption;
    procedure UpdateWMFObjList(AOffset: Int64);
  public
    { public declarations }
    procedure ReadCmdLine;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

uses
  StrUtils, LCLIntf, LConvEncoding, LazUTF8, Math, bmpcomn,
  fpvwmf, fpvectorial, fpvtocanvas, wxutils;

const
  VALUE_ROW_INDEX      = 1;
  VALUE_ROW_BITS       = 2;
  VALUE_ROW_BYTE       = 3;
  VALUE_ROW_SHORTINT   = 4;
  VALUE_ROW_WORD       = 5;
  VALUE_ROW_SMALLINT   = 6;
  VALUE_ROW_DWORD      = 7;
  VALUE_ROW_LONGINT    = 8;
  VALUE_ROW_QWORD      = 9;
  VALUE_ROW_INT64      = 10;
  VALUE_ROW_SINGLE     = 11;
  VALUE_ROW_DOUBLE     = 12;
  VALUE_ROW_ANSISTRING = 13;
  VALUE_ROW_PANSICHAR  = 14;
  VALUE_ROW_WIDESTRING = 15;
  VALUE_ROW_PWIDECHAR  = 16;

type
  TWMFNodeData = record
    Offset: Int64;
    Text: String;
    Size: Integer;    // in bytes!
  end;
  PWMFNodeData = ^TWMFNodeData;

  TAnalysisNodeData = record
    Offset: Integer;
    Value: String;
    Description: String;
  end;
  PAnalysisNodeData = ^TAnalysisNodeData;


{ TMainForm }

procedure TMainForm.AcFileOpenAccept(Sender: TObject);
begin
  LoadFile(AcFileOpen.Dialog.FileName);
end;

procedure TMainForm.AcExternalViewerExecute(Sender: TObject);
begin
  if FileExists(FFileName) then
    OpenDocument(FFilename);
end;

function TMainForm.AddAnalysisNode(AOffset: Integer; AValue, ADescription: String): PVirtualNode;
var
  data: PAnalysisNodeData;
begin
  Result := AnalysisTree.AddChild(nil);
  data := AnalysisTree.GetNodeData(Result);
  data^.Offset := AOffset;
  data^.Value := AValue;
  data^.Description := ADescription;
end;

function TMainForm.AddNode(AOffset: Int64; AText: String; ASizeInBytes: Integer): PVirtualNode;
var
  data: PWMFNodeData;
begin
  Result := Tree.AddChild(nil);
  data := Tree.GetNodeData(Result);
  data^.Offset := AOffset;
  data^.Text := AText;
  data^.Size := ASizeInBytes;
end;

procedure TMainForm.AnalysisTreeFreeNode(Sender: TBaseVirtualTree;
  Node: PVirtualNode);
var
  data: PAnalysisNodeData;
begin
  data := AnalysisTree.GetNodeData(Node);
  data^.Value := '';
  data^.Description := '';
end;

procedure TMainForm.AnalysisTreeGetText(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: String);
var
  data: PAnalysisNodeData;
begin
  data := AnalysisTree.GetNodedata(Node);
  case Column of
    0: CellText := IntToStr(data^.Offset);
    1: CellText := data^.Value;
    2: CellText := data^.Description;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  MruMenuManager := TMruMenuManager.Create(self);
  with MruMenuManager do
  begin
    MenuItem := MnuRecentlyOpened;
    PopupMenu := MRUPopupMenu;
    IniFileName := CalcIniName;
    IniSection := 'RecentFiles';
    MenuCaptionMask := '%d - %s';
    MaxRecent := 16;
    OnRecentFile := @MRUMenuManagerRecentFile;
  end;

  Tree.NodeDataSize := SizeOf(TWMFNodeData);
  Tree.DefaultNodeHeight := Tree.Canvas.TextHeight('Tg') + 4;
  Tree.Header.DefaultHeight := ValueGrid.DefaultRowHeight;
  Tree.ScrollBarOptions.VerticalIncrement := Tree.DefaultNodeHeight;

  AnalysisTree.NodeDataSize := SizeOf(TAnalysisNodeData);
  AnalysisTree.DefaultNodeHeight := AnalysisTree.Canvas.TextHeight('Tg') + 4;
  AnalysisTree.Header.DefaultHeight := ValueGrid.DefaultRowHeight;
  AnalysisTree.ScrollBarOptions.VerticalIncrement := AnalysisTree.DefaultNodeHeight;

  FHexView := TMPHexEditor.Create(self);
  FHexView.Parent := HexPanel;
  FHexView.Align := alClient;
  FHexView.DrawGutter3D := false;
  FHexView.WantTabs := false;
  FHexView.OnClick := @HexViewClick;
  FHexView.Font.Name := GetFixedFontName;
  FHexView.Font.Style := [];
  FHexView.Font.Size := 9;
  FHexView.BytesPerColumn := 1;
  FHexView.ReadOnlyView := true;
  FHexView.ReadOnlyFile := true;

  with ValueGrid do begin
    ColCount := 3;
    RowCount := VALUE_ROW_PWIDECHAR + 1;
    Cells[0, 0] := 'Data type';
    Cells[1, 0] := 'Value';
    Cells[2, 0] := 'Offset range';
    Cells[0, VALUE_ROW_INDEX] := 'Offset';
    Cells[0, VALUE_ROW_BITS] := 'Bits';
    Cells[0, VALUE_ROW_BYTE] := 'Byte';
    Cells[0, VALUE_ROW_SHORTINT] := 'ShortInt';
    Cells[0, VALUE_ROW_WORD] := 'Word';
    Cells[0, VALUE_ROW_SMALLINT] := 'SmallInt';
    Cells[0, VALUE_ROW_DWORD] := 'DWord';
    Cells[0, VALUE_ROW_LONGINT] := 'LongInt';
    Cells[0, VALUE_ROW_QWORD] := 'QWord';
    Cells[0, VALUE_ROW_INT64] := 'Int64';
    Cells[0, VALUE_ROW_SINGLE] := 'Single';
    Cells[0, VALUE_ROW_DOUBLE] := 'Double';
    Cells[0, VALUE_ROW_ANSISTRING] := 'AnsiString';
    Cells[0, VALUE_ROW_PANSICHAR] := 'PAnsiChar';
    Cells[0, VALUE_ROW_WIDESTRING] := 'WideString';
    Cells[0, VALUE_ROW_PWIDECHAR] := 'PWideChar';
  end;

  UpdateCaption;
  ReadCmdLine;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FStream);
end;

function TMainForm.GetValueGridDataSize: Integer;

  function ExtractLength(s: String): Integer;
  var
    i: Integer;
    n1, n2: Integer;
    isFirst: Boolean;
  begin
    isFirst := true;
    n1 := 0;
    n2 := 0;
    for i:=1 to Length(s) do
      case s[i] of
        '0'..'9':
          if isFirst then
            n1 := n1*10 + ord(s[i]) - ord('0') else
            n2 := n2*10 + ord(s[i]) - ord('0');
        ' ': if isFirst then isFirst := false;
      end;
    Result := n2 - n1 + 1;
  end;

begin
  Result := -1;
  case ValueGrid.Row of
    VALUE_ROW_BITS       : Result := SizeOf(Byte);
    VALUE_ROW_BYTE       : Result := SizeOf(Byte);
    VALUE_ROW_SHORTINT   : Result := SizeOf(ShortInt);
    VALUE_ROW_WORD       : Result := SizeOf(Word);
    VALUE_ROW_SMALLINT   : Result := SizeOf(SmallInt);
    VALUE_ROW_DWORD      : Result := SizeOf(DWord);
    VALUE_ROW_LONGINT    : Result := SizeOf(LongInt);
    VALUE_ROW_QWORD      : Result := SizeOf(QWord);
    VALUE_ROW_INT64      : Result := SizeOf(Int64);
    VALUE_ROW_SINGLE     : Result := SizeOf(Single);
    VALUE_ROW_DOUBLE     : Result := SizeOf(Double);
    VALUE_ROW_ANSISTRING,
    VALUE_ROW_WIDESTRING,
    VALUE_ROW_PANSICHAR,
    VALUE_ROW_PWIDECHAR  : Result := ExtractLength(ValueGrid.Cells[2, ValueGrid.Row]);
  end;
end;

procedure TMainForm.HexViewClick(Sender: TObject);
begin
//  FCurrOffset := HexView.SelStart.Index;
  PopulateValueGrid;
  ValueGridClick(nil);
  //UpdateStatusbar;
end;

procedure TMainForm.PopulateValueGrid;
var
  buf: array[0..1023] of Byte;
  w: word absolute buf;
  dw: DWord absolute buf;
  qw: QWord absolute buf;
  dbl: double absolute buf;
  sng: single absolute buf;
  idx: Integer;
  i, j: Integer;
  s: String;
  sw: WideString;
  ls: SizeInt;
  pw: PWideChar;
  pa: PAnsiChar;
begin
//  idx := HexView.SelStart.Index;
  idx := FHexView.SelStart;

  i := ValueGrid.RowCount;
  j := ValueGrid.ColCount;

  ValueGrid.Cells[1, VALUE_ROW_INDEX] := IntToStr(FCurrOffset + idx);

  // Byte, ShortInt
  if idx <= Length(FBuffer)-SizeOf(byte) then begin
    ValueGrid.Cells[1, VALUE_ROW_BITS] := IntToBin(FBuffer[idx], 8);
    ValueGrid.Cells[2, VALUE_ROW_BITS] := Format('%d ... %d', [idx, idx]);
    ValueGrid.Cells[1, VALUE_ROW_BYTE] := IntToStr(FBuffer[idx]);
    ValueGrid.Cells[2, VALUE_ROW_BYTE] := ValueGrid.Cells[2, VALUE_ROW_BITS];
    ValueGrid.Cells[1, VALUE_ROW_SHORTINT] := IntToStr(ShortInt(FBuffer[idx]));
    ValueGrid.Cells[2, VALUE_ROW_SHORTINT] := ValueGrid.Cells[2, VALUE_ROW_BITS];
  end
  else begin
    ValueGrid.Cells[1, VALUE_ROW_BYTE] := '';
    ValueGrid.Cells[2, VALUE_ROW_BYTE] := '';
    ValueGrid.Cells[1, VALUE_ROW_SHORTINT] := '';
    ValueGrid.Cells[2, VALUE_ROW_SHORTINT] := '';
  end;

  // Word, SmallInt
  if idx <= Length(FBuffer)-SizeOf(word) then begin
    buf[0] := FBuffer[idx];
    buf[1] := FBuffer[idx+1];
    ValueGrid.Cells[1, VALUE_ROW_WORD] := IntToStr(WordLEToN(w));
    ValueGrid.Cells[2, VALUE_ROW_WORD] := Format('%d ... %d', [idx, idx+SizeOf(Word)-1]);
    ValueGrid.Cells[1, VALUE_ROW_SMALLINT] := IntToStr(SmallInt(WordLEToN(w)));
    ValueGrid.Cells[2, VALUE_ROW_SMALLINT] := ValueGrid.Cells[2, VALUE_ROW_WORD];
  end else begin
    ValueGrid.Cells[1, VALUE_ROW_WORD] := '';
    ValueGrid.Cells[2, VALUE_ROW_WORD] := '';
    ValueGrid.Cells[1, VALUE_ROW_SMALLINT] := '';
    ValueGrid.Cells[2, VALUE_ROW_SMALLINT] := '';
  end;

  // DWord, LongInt
  if idx <= Length(FBuffer) - SizeOf(DWord) then begin
    for i:=0 to SizeOf(DWord)-1 do buf[i] := FBuffer[idx+i];
    ValueGrid.Cells[1, VALUE_ROW_DWORD] := IntToStr(DWordLEToN(dw));
    ValueGrid.Cells[2, VALUE_ROW_DWORD] := Format('%d ... %d', [idx, idx+SizeOf(DWord)-1]);
    ValueGrid.Cells[1, VALUE_ROW_LONGINT] := IntToStr(LongInt(DWordLEToN(dw)));
    ValueGrid.Cells[2, VALUE_ROW_LONGINT] := ValueGrid.Cells[2, VALUE_ROW_DWORD];
  end else begin
    ValueGrid.Cells[1, VALUE_ROW_DWORD] := '';
    ValueGrid.Cells[2, VALUE_ROW_DWORD] := '';
    ValueGrid.Cells[1, VALUE_ROW_LONGINT] := '';
    ValueGrid.Cells[2, VALUE_ROW_LONGINT] := '';
  end;

  // QWord, Int64
  if idx <= Length(FBuffer) - SizeOf(QWord) then begin
    for i:=0 to SizeOf(QWord)-1 do buf[i] := FBuffer[idx+i];
    ValueGrid.Cells[1, VALUE_ROW_QWORD] := Format('%d', [qw]);
    ValueGrid.Cells[2, VALUE_ROW_QWORD] := Format('%d ... %d', [idx, idx+SizeOf(QWord)-1]);
    ValueGrid.Cells[1, VALUE_ROW_INT64] := Format('%d', [Int64(qw)]);
    ValueGrid.Cells[2, VALUE_ROW_INT64] := ValueGrid.Cells[2, VALUE_ROW_QWORD];
  end else begin
    ValueGrid.Cells[1, VALUE_ROW_QWORD] := '';
    ValueGrid.Cells[2, VALUE_ROW_QWORD] := '';
    ValueGrid.Cells[1, VALUE_ROW_INT64] := '';
    ValueGrid.Cells[2, VALUE_ROW_INT64] := '';
  end;

  // Single
  if idx <= Length(FBuffer) - SizeOf(single) then begin
    for i:=0 to SizeOf(single)-1 do buf[i] := FBuffer[idx+i];
    ValueGrid.Cells[1, VALUE_ROW_SINGLE] := Format('%f', [sng]);
    ValueGrid.Cells[2, VALUE_ROW_SINGLE] := Format('%d ... %d', [idx, idx+SizeOf(Single)-1]);
  end else begin
    ValueGrid.Cells[1, VALUE_ROW_SINGLE] := '';
    ValueGrid.Cells[2, VALUE_ROW_SINGLE] := '';
  end;

  // Double
  if idx <= Length(FBuffer) - SizeOf(double) then begin
    for i:=0 to SizeOf(double)-1 do buf[i] := FBuffer[idx+i];
    ValueGrid.Cells[1, VALUE_ROW_DOUBLE] := Format('%f', [dbl]);
    ValueGrid.Cells[2, VALUE_ROW_DOUBLE] := Format('%d ... %d', [idx, idx+SizeOf(Double)-1]);
  end else begin
    ValueGrid.Cells[1, VALUE_ROW_DOUBLE] := '';
    ValueGrid.Cells[2, VALUE_ROW_DOUBLE] := '';
  end;

  // AnsiString
  if idx < Length(FBuffer) then begin
    ls := Min(FBuffer[idx], Length(FBuffer) - idx - 1);
    SetLength(s, ls);
    i := idx + 1;
    j := 0;
    while (i < Length(FBuffer)) and (j < Length(s)) do begin
      inc(j);
      s[j] := char(FBuffer[i]);
      inc(i);
    end;
    SetLength(s, j);
    ValueGrid.Cells[1, VALUE_ROW_ANSISTRING] := s;
    ValueGrid.Cells[2, VALUE_ROW_ANSISTRING] := Format('%d ... %d', [idx, ls * SizeOf(char) + 1]);
  end else begin
    ValueGrid.Cells[1, VALUE_ROW_ANSISTRING] := '';
    ValueGrid.Cells[2, VALUE_ROW_ANSISTRING] := '';
  end;

  // PAnsiChar
  // Avoid buffer overrun
  if idx < Length(FBuffer) then begin
    pa := PAnsiChar(@FBuffer[idx]);
    ls := 0;
    while (pa^ <> #0) and (pa - @FBuffer[0] < Length(FBuffer)) do
    begin
      inc(pa);
      inc(ls);
    end;
    SetLength(s, ls);
    Move(FBuffer[idx], s[1], ls);
    ValueGrid.Cells[1, VALUE_ROW_PANSICHAR] := s;
    ValueGrid.Cells[2, VALUE_ROW_PANSICHAR] := Format('%d ... %d', [idx, idx + ls]);
  end else
  begin
    ValueGrid.Cells[1, VALUE_ROW_PANSICHAR] := '';
    ValueGrid.Cells[2, VALUE_ROW_PANSICHAR] := '';
  end;

  // WideString
  if idx < Length(FBuffer) then begin
    ls := Min(FBuffer[idx], (Length(FBuffer) - idx - 1) div SizeOf(WideChar));
    SetLength(sw, ls);
    j := 0;
    i := idx + 2;
    while (i < Length(FBuffer)-1) and (j < Length(sw)) do begin
      buf[0] := FBuffer[i];
      buf[1] := FBuffer[i+1];
      inc(i, SizeOf(WideChar));
      inc(j);
      sw[j] := WideChar(w);
    end;
    SetLength(sw, j);
    ValueGrid.Cells[1, VALUE_ROW_WIDESTRING] := UTF8Encode(sw);
    ValueGrid.Cells[2, VALUE_ROW_WIDESTRING] := Format('%d ... %d', [idx, idx + (ls+1)*SizeOf(wideChar)]);
  end else begin
    ValueGrid.Cells[1, VALUE_ROW_WIDESTRING] := '';
    ValueGrid.Cells[2, VALUE_ROW_WIDESTRING] := '';
  end;

  // PWideChar
  // Avoid buffer overrun
  if idx < Length(FBuffer) then begin
    pw := PWideChar(@FBuffer[idx]);
    ls := 0;
    while (pw^ <> #0) and (pw - @FBuffer[0] < Length(FBuffer)-1) do
    begin
      inc(pw);
      inc(ls);
    end;
    s := {%H-}WideCharLenToString(PWideChar(@FBuffer[idx]), ls);
    ValueGrid.Cells[1, VALUE_ROW_PWIDECHAR] := s;
    ValueGrid.Cells[2, VALUE_ROW_PWIDECHAR] := Format('%d ... %d', [idx, idx + ls * SizeOf(widechar)]);
  end else
  begin
    ValueGrid.Cells[1, VALUE_ROW_PWIDECHAR] := '';
    ValueGrid.Cells[2, VALUE_ROW_PWIDECHAR] := '';
  end;
end;

procedure TMainForm.LoadFile(const AFileName: String);
var
  fs: TFileStream;
  b: Byte;
  phdr: TPlaceableMetaHeader;
  mhdr: TWMFHeader;
  savedPos: Int64;
  rec: TWMFRecord;
begin
  if not FileExists(AFileName) then begin
    MessageDlg(Format('File "%s" does not exist.', [AFileName]), mtError, [mbOK], 0);
    exit;
  end;

  FreeAndNil(FStream);
  FStream := TMemoryStream.Create;
  fs := TFileStream.Create(AFileName, fmOpenRead + fmShareDenyWrite);
  try
    FStream.CopyFrom(fs, fs.Size);
    FStream.Position := 0;
    SetLength(FBuffer, FStream.Size);
    FStream.ReadBuffer(FBuffer[0], FStream.Size);
  finally
    fs.Free;
  end;

  FStream.Position := 0;
  FHexView.LoadFromStream(FStream);
  Tree.Clear;
  AnalysisTree.Clear;

  FStream.Position := 0;
  b := FStream.ReadByte;

  FStream.Position := 0;
  if b = $D7 then begin  // Assume that file begins with a placeable meta file header
    FStream.ReadBuffer(phdr, SizeOf(phdr));
    if phdr.Key <> $9AC6CDD7 then begin
      MessageDlg(Format('Unknown structure of file "%s"', [AFileName]), mtError, [mbOK], 0);
      exit;
    end;
    AddNode(0, 'Placeable Meta Header', SizeOf(phdr));
  end else
  if not ((b = 0) or (b = 1)) then begin
    MessageDlg(Format('Unknown structure of file "%s"', [AFileName]), mtError, [mbOK], 0);
    exit;
  end;

  // Read "normal" metafile header
  AddNode(FStream.Position, 'WMF header', SizeOf(mhdr));
  mhdr := Default(TWMFHeader);
  FStream.ReadBuffer(mhdr, SizeOf(mhdr));

  // Read metafile records
  while FStream.Position < FStream.Size do begin
    savedPos := FStream.Position;
    FStream.ReadBuffer(rec, SizeOf(rec));
    AddNode(savedPos, WMF_GetFuncName(rec.Func), rec.Size * SizeOf(word));
    if rec.Size = 0 then begin
      MessageDlg('Invalid record size 0 encountered at offset '+ IntToStr(savedPos) + '. Closing...',
        mtError, [mbOK], 0);
      break;
    end;
    FStream.Position := savedPos + rec.Size*SizeOf(word);
    if rec.Func = META_EOF then
      break;
  end;

  // Done.
  MruMenuManager.AddToRecent(AFileName);
  FFilename := AFileName;
  UpdateCaption;

  // Update display
  if PageControl1.ActivePage = PgGraphic then
    Paintbox1.Invalidate;
end;

procedure TMainForm.MRUMenuManagerRecentFile(Sender: TObject;
  const AFileName: String);
begin
  LoadFile(AFileName);
end;

procedure TMainForm.PageControl1Change(Sender: TObject);
begin
  if PageControl1.ActivePage = PgGraphic then
    Paintbox1.Invalidate;
end;

procedure TMainForm.PaintBox1Paint(Sender: TObject);
var
  vec: TvVectorialDocument;
  page: TvVectorialPage;
  f: Double;
begin
  if (FStream = nil) or (FStream.Size = 0) then
    exit;

  vec := TvVectorialDocument.Create;
  try
    FStream.Position := 0;
    vec.ReadFromStream(FStream, vfWindowsMetafileWMF);
    page := vec.GetPageAsVectorial(0);
    if (page.Width = 0) or (page.Height = 0) then
      exit;
    if (page.Width / page.Height < Paintbox1.ClientWidth / Paintbox1.ClientHeight) then
      f := Paintbox1.ClientHeight / page.Height
    else
      f := Paintbox1.ClientWidth / page.Width;
    if page.UseTopLeftCoordinates then
      DrawFPVectorialToCanvas(page, Paintbox1.Canvas, 0, 0, f, f)
    else
      DrawFPVectorialToCanvas(page, Paintbox1.Canvas, 0, round(page.Height*f), f, -f);
  finally
    vec.Free;
  end;
end;
(*
var
  b: Byte;
  savedPos: Int64;
  phdr: TPlaceableMetaHeader;
  mhdr: TWMFHeader;
  params: array of Word;
  rec: TWMFRecord;
  minx, miny, maxx, maxy: Integer;
  list: TFPList;
  lPen: TPen;
  lBrush: TBrush;
  lFont: TFont;
  obj: TObject;
  i: Integer;
  pts: Array of TPoint;

  function ScaleX(x: Integer): Integer;
  begin
    Result := round((x - minx) / (maxx - minx) * Paintbox1.Width);
  end;

  function ScaleY(y: Integer): Integer;
  begin
    Result := round((y - miny) / (maxy - miny) * Paintbox1.Height);
  end;

  function GetDWord(FromIndex: Integer): DWord;
  begin
    Move(params[FromIndex], Result, SizeOf(DWord));
  end;

begin
  if FStream = nil then
    exit;

  // Rewind stream from other sheets
  FStream.Position := 0;

  // Check header(s)
  b := FStream.ReadByte;
  FStream.Position := 0;

  // Assume that file begins with a placeable meta file header
  if b = $D7 then begin
    FStream.ReadBuffer(phdr, SizeOf(phdr));
    minx := phdr.Left;
    miny := phdr.Top;
    maxx := phdr.Right;
    maxy := phdr.Bottom;
  end else begin
    MessageDlg('Placeable meta header required', mtError, [mbOK], 0);
    exit;
  end;

  list := TFPList.Create;
  try
    // Read "normal" metafile header
    FStream.ReadBuffer(mhdr, SizeOf(mhdr));

    // Read metafile records
    while FStream.Position < FStream.Size do begin
      savedPos := FStream.Position;
      FStream.ReadBuffer(rec, SizeOf(rec));
      if rec.Func = META_EOF then
        break;
      if rec.Size = 3 then
        Continue;
      SetLength(params, rec.Size - 3);
      FStream.ReadBuffer(params[0], Length(params) * SizeOf(word));

      case rec.Func of
        META_MOVETO:
          Paintbox1.Canvas.MoveTo(ScaleX(params[1]), ScaleY(params[0]));
        META_LINETO:
          Paintbox1.Canvas.LineTo(ScaleX(params[1]), ScaleY(params[0]));
        META_RECTANGLE:
          Paintbox1.Canvas.Rectangle(ScaleX(params[3]), ScaleY(params[2]), ScaleX(params[1]), ScaleY(params[0]));
        META_POLYGON:
          begin
            SetLength(pts, params[0]);
            for i:=0 to High(pts) do
              pts[i] := Point(ScaleX(params[i*2+1]), ScaleY(params[i*2+2]));
            Paintbox1.Canvas.Polygon(pts);
          end;
        META_POLYLINE:
          begin
            SetLength(pts, params[0]);
            for i:=0 to High(pts) do
              pts[i] := Point(ScaleX(params[i*2+1]), ScaleY(params[i*2+2]));
            Paintbox1.Canvas.PolyLine(pts);
          end;

        META_CREATEPENINDIRECT:
          begin
            lPen := TPen.Create;
            WMF_SetPenStyle(lPen, params[0]);
            lPen.Width := Max(1, params[1]);
            lPen.Color := TColor(GetDWord(2));
            list.Add(lPen);
          end;
        META_CREATEBRUSHINDIRECT:
          begin
            lBrush := TBrush.Create;
            WMF_SetBrushStyle(lBrush, params[0]);
            list.Add(lBrush);
          end;
        META_CREATEFONTINDIRECT:
          begin
            lFont := TFont.Create;
            list.Add(lFont);
          end;
        META_CREATEPALETTE:
          list.Add(nil);  // not supported
        META_CREATEPATTERNBRUSH:
          list.Add(nil);  // not supported
        META_CREATEREGION:
          list.Add(nil);  // not supported
        META_SELECTOBJECT:
          if params[0] < list.Count then begin
            obj := TObject(list[params[0]]);
            if obj is TPen then
              Paintbox1.Canvas.Pen.Assign(TPen(obj))
            else
            if obj is TBrush then
              Paintbox1.Canvas.Brush.Assign(TBrush(obj))
            else
            if obj is TFont then
              Paintbox1.Canvas.Font.Assign(TFont(obj));
          end;
        META_DELETEOBJECT:
          if params[0] < list.Count then begin
            obj := TObject(list[params[0]]);
            if obj <> nil then obj.Free;
            list[params[0]] := nil;
          end;
      end;
      FStream.Position := savedPos + rec.Size*SizeOf(word);
    end;

  finally
    for i:=0 to list.Count-1 do
      TObject(list[i]).Free;
    list.Free;
  end;
end;
  *)
procedure TMainForm.PopulateAnalysis(ARecordType: Word; AOffset: Int64);
var
  phdr: PPlaceableMetaHeader = nil;
  mhdr: PWMFHeader = nil;
  i, j, k, n: Integer;
  npts: Array of Integer;
  s: String;
  bmp: TBitmap;

  function GetByte(ABufIndex: Integer): Byte;
  begin
    Result := FBuffer[ABufIndex];
  end;

  function GetWord(ABufIndex: Integer): Word;
  begin
    Move(FBuffer[ABufIndex], Result, SizeOf(Word));
  end;

  function GetSmallInt(ABufIndex: Integer): SmallInt;
  begin
    Move(FBuffer[ABufIndex], Result, SizeOf(SmallInt));
  end;

  function GetDWord(ABufIndex: Integer): DWord;
  begin
    Move(FBuffer[ABufIndex], Result, SizeOf(DWord));
  end;

  function GetString(ABufIndex: Integer; Len: Word): String;
  var
    ansistr: AnsiString;
  begin
    SetLength(ansistr, Len);
    Move(FBuffer[ABufIndex], ansistr[1], Len);
    Result := WinCPToUTF8(ansistr);
  end;

  function GetCString(ABufIndex: Integer; AMaxLen: Integer): String;
  var
    ansistr: AnsiString;
    P: PChar;
    n: Integer;
  begin
    ansistr := PChar(@FBuffer[ABufIndex]);
    if Length(ansistr) > AMaxLen then
      exit('');
    Result := ISO_8859_1ToUTF8(ansistr);
  end;

  function GetBitmap(ABufIndex: Integer): TBitmap;
  var
    memstream: TMemoryStream;
    bmpFileHdr: TBitmapFileHeader;
    bmpCoreHdr: PWMFBitmapCoreHeader;
    bmpInfoHdr: PWMFBitmapInfoHeader;
    hasCoreHdr: Boolean;
    imgSize: Int64;
    datasize: Int64;
    w, h: Integer;
  begin
    bmpCoreHdr := PWMFBitmapCoreHeader(@FBuffer[ABufIndex]);
    bmpInfoHdr := PWMFBitmapInfoHeader(@FBuffer[ABufIndex]);
    hasCoreHdr := bmpInfoHdr^.HeaderSize = SizeOf(TWMFBitmapCoreHeader);
    if hasCoreHdr then
      exit(nil);

    w := bmpInfoHdr^.Width;
    h := bmpInfoHdr^.Height;
    if (w = 0) or (h = 0) then
      exit(nil);

    memstream := TMemoryStream.Create;
    try
      datasize := Length(FBuffer) - ABufIndex;
      // Put a bitmap file header before the bitmap info header and the data
      bmpFileHdr.bfType := BMmagic;
      bmpFileHdr.bfSize:= SizeOf(bmpFileHdr) + datasize;
      if bmpInfoHdr^.Compression in [BI_RGB, BI_BITFIELDS, BI_CMYK] then
        imgSize := (w + bmpInfoHdr^.Planes * bmpInfoHdr^.BitCount + 31) div 32 * abs(h)
      else
        imgSize := bmpInfoHdr^.ImageSize;
      bmpFileHdr.bfOffset := bmpFileHdr.bfSize - imgSize;
      bmpFileHdr.bfReserved := 0;
      memstream.WriteBuffer(bmpFileHdr, SizeOf(bmpFileHdr));
      memstream.WriteBuffer(FBuffer[ABufIndex], Length(FBuffer) - ABufIndex);
      memstream.Position := 0;
      Result := TBitmap.Create;
      Result.SetSize(w, h);
      Result.Canvas.Brush.Color := clWhite;
      Result.Canvas.FillRect(0, 0, w, h);
      Result.LoadFromStream(memStream);
    finally
      memstream.Free;
    end;
  end;

  procedure UpdateColorDisplay(AColor: TColor);
  begin
    Image.Parent := Panel1;
    Image.Align := alNone;
    ColorDisplay.Parent := Panel2;
    ColorDisplay.Align := alClient;
    ColorDisplay.Brush.Color := AColor;
    ColorDisplay.Brush.Style := bsSolid;
    ColorDisplay.Pen.Style := psSolid;
    ColorDisplay.Paint;
  end;

begin
  AnalysisTree.BeginUpdate;
  try
    AnalysisTree.Clear;
    OffsetInfo.Caption := IntToStr(AOffset);
    SizeInfo.Caption := IntToStr(Length(FBuffer)) + ' bytes';
    ColorDisplay.Brush.Style := bsClear;
    ColorDisplay.Pen.Style := psClear;
    Image.Picture.Clear;
    Image.Parent := Panel1;
    ColorDisplay.Parent := Panel1;
    Image.Align := alNone;
    ColorDisplay.Align := alNone;
    if ARecordType = $FFFF then begin  // Placeable meta header
      phdr := PPlaceableMetaHeader(@FBuffer[0]);
      RecordTypeInfo.Caption := 'Placeable meta header';
      AddAnalysisNode(0, Format('$%.8x', [phdr^.Key]), 'Key (Magic number, always $9AC6CDD7)');
      AddAnalysisNode(4, Format('%d ($%.4x)', [phdr^.Handle, phdr^.Handle]), 'Metafile HANDLE number (always 0)');
      AddAnalysisNode(6, IntToStr(phdr^.Left), 'Left coordinate in metafile units');
      AddAnalysisNode(8, IntToStr(phdr^.Top), 'Top coordinate in metafile units');
      AddAnalysisNode(10, IntToStr(phdr^.Right), 'Right coordinate in metafile units');
      AddAnalysisNode(12, IntToStr(phdr^.Bottom), 'Bottom coordinate in metafile units');
      AddAnalysisNode(14, IntToStr(phdr^.Inch), 'Number of metafile units per inch');
      AddAnalysisNode(16, IntToStr(phdr^.Reserved), 'Reserved (always 0)');
      AddAnalysisNode(20, IntToStr(phdr^.Checksum), 'Checksum value for previous 10 WORDs');
    end else
    if ARecordType = $FFFE then begin // WMF Header
      mhdr := PWMFHeader(@FBuffer[0]);
      RecordTypeInfo.Caption := 'WMF header';
      AddAnalysisNode(0, IntToStr(mhdr^.FileType), 'Type of metafile (0=memory, 1=disk)');
      AddAnalysisNode(2, IntToStr(mhdr^.HeaderSize), 'Size of header in WORDS (always 9)');
      AddAnalysisNode(4, Format('$%.4x', [mhdr^.Version]), 'Version of Microsoft Windows used');
      AddAnalysisNode(6, IntToStr(mhdr^.FileSize), Format(
        'Total size of the metafile in WORDs (%d bytes)', [mhdr^.FileSize*2]));
      AddAnalysisNode(10, IntToStr(mhdr^.NumOfObjects), 'Number of objects in the file');
      AddAnalysisNode(12, IntToStr(mhdr^.MaxRecordSize), Format(
        'Size of largest record in WORDs (%d bytes)', [mhdr^.MaxRecordSize*2]));
      AddAnalysisNode(16, IntToStr(mhdr^.NumOfParams), 'Not used (always 0)');
    end else begin
      RecordTypeInfo.Caption := Format('%0:s (%1:d = $%1:.4x)', [WMF_GetFuncName(ARecordType), ARecordType]);
      AddAnalysisNode(0, IntToStr(GetDWord(0)),
        'Record size (in WORDs)');
      AddAnalysisNode(4, Format('$%.4x', [GetWord(4)]),
        Format('Function code (%s)', [WMF_GetFuncName(GetWord(4))]));

      case ARecordType of
        META_ARC:
          begin
            AddAnalysisNode(6, IntToStr(GetSmallInt(6)),
              'YENDARC (y coordinate of the ending point of radial line defining the end point)');
            AddAnalysisNode(8, IntToStr(GetSmallInt(8)),
              'XENDARC (x coordinate of the ending point of radial line defining the end point)');
            AddAnalysisNode(10, IntToStr(GetSmallInt(10)),
              'YSTARTARC (y coordinate of the ending point of radial line defining the start point)');
            AddAnalysisNode(12, IntToStr(GetSmallInt(12)),
              'XSTARTARC (x coordinate of the ending point of radial line defining the start point)');
            AddAnalysisNode(14, IntToStr(GetSmallInt(14)),
              'BOTTOMRECT (Bottom value of bounding rectangle, in logical units)');
            AddAnalysisNode(16, IntToStr(GetSmallInt(16)),
              'RIGHTRECT (Right value of the bouding rectangle, in logical units)');
            AddAnalysisNode(18, IntToStr(GetSmallInt(18)),
              'TOPRECT (Top value of the bounding rectangle, in logical units)');
            AddAnalysisNode(20, IntToStr(GetSmallInt(20)),
              'LEFTRECT (Left value of the bounding rect, in logical units)');
          end;

        META_CREATEBRUSHINDIRECT:
          begin
            n := GetWord(6);
            AddAnalysisNode(6, IntToStr(n),
              Format('Brush style (%s)', [WMF_GetBrushStyleName(n)]));
            if n in [0, 2] then begin // BS_SOLID, BS_HATCHED
              AddAnalysisNode(8, Format('%0:d ($%0:.2x)', [GetByte(8)]),
                'Intensity of red');
              AddAnalysisNode(9, Format('%0:d ($%0:.2x)', [GetByte(9)]),
                'Intensity of green');
              AddAnalysisNode(10, Format('%0:d ($%0:.2x)', [GetByte(10)]),
                'Intensity of blue');
              AddAnalysisNode(11, Format('%0:d ($%0:.2x)', [GetByte(11)]),
                'Reserved');
              UpdateColorDisplay(GetDWord(8));
            end else
              AddAnalysisNode(8, Format('%0:d ($%0:.8x)', [GetDWord(8)]),
                'Color (to be ignored for this pattern)');
            if n in [3, 6, 2] then   // BS_PATTERN, BS_DIBPATTERNPT, BS_HATCHED
              AddAnalysisNode(12, '(not decoded)', 'Brush hatch / pattern');
          end;

        META_CREATEFONTINDIRECT:
          begin
            AddAnalysisNode(6, IntToStr(GetSmallInt(6)),
              'Font height (in logical units)');
            AddAnalysisNode(8, IntToStr(GetSmallInt(8)),
              'Font width (in logical units)');
            AddAnalysisNode(10, IntToStr(GetSmallInt(10)),
              'Escapement (in tenths of degrees)');
            AddAnalysisNode(12, IntToStr(GetSmallInt(12)),
              'Orientation (in tenths of degrees)');
            AddAnalysisNode(14, IntToStr(GetSmallInt(14)),
              'Weight (0=Default, 400=Normal, 700=Bold), max 1000');
            AddAnalysisNode(16, IntToStr(GetByte(16)),
              'Italic (0=FALSE, 1=TRUE)');
            AddAnalysisNode(17, IntToStr(GetByte(17)),
              'Underline (0=FALSE, 1=TRUE)');
            AddAnalysisNode(18, IntToStr(GetByte(18)),
              'Strikeout (0=FALSE, 1=TRUE)');
            AddAnalysisNode(19, IntToStr(GetByte(19)),
              'CharSet');
            AddAnalysisNode(20, IntToStr(GetByte(20)),
              'OutPrecision');
            AddAnalysisNode(21, IntToStr(GetByte(21)),
              'ClipPrecision');
            AddAnalysisNode(22, IntToStr(GetByte(22)),
              'Quality');
            AddAnalysisNode(23, IntToStr(GetByte(23)),
              'Pitch and family');
            AddAnalysisNode(24, GetCString(24, 32),
              'Face name');
          end;

        META_CREATEPENINDIRECT:
          begin
            AddAnalysisNode(6, IntToStr(GetWord(6)),
              Format('Pen style (%s)', [WMF_GetPenStyleName(GetWord(6))]));
            AddAnalysisNode(8, IntToStr(GetWord(8)),
              'Pen width');
            AddAnalysisNode(10, IntToStr(GetWord(10)),
              'Ignored');
            AddAnalysisNode(12, Format('%0:d ($%0:.2x)', [GetByte(12)]),
              'Intensity of red');
            AddAnalysisNode(13, Format('%0:d ($%0:.2x)', [GetByte(13)]),
              'Intensity of green');
            AddAnalysisNode(14, Format('%0:d ($%0:.2x)', [GetByte(14)]),
              'Intensity of blue');
            AddAnalysisNode(15, Format('%0:d ($%0:.2x)', [GetByte(15)]),
              'Reserved');
            UpdateColorDisplay(GetDWord(12));
          end;

        META_DELETEOBJECT:
          begin
            AddAnalysisNode(6, IntToStr(GetWord(6)),
              'Index into WMF Object Table to get object to be deleted');
          end;

        META_DIBCREATEPATTERNBRUSH:
          begin
            n := GetWord(6);
            AddAnalysisNode(6, IntToStr(n),
              Format('Brush style (%s)', [WMF_GetBrushStyleName(n)]));
            n := GetWord(8);
            AddAnalysisNode(8, IntToStr(n),
              Format('Color usage (%s)', [WMF_GetColorUsageName(n)]));
            n := GetDWord(10);
            AddAnalysisNode(10, IntToStr(n),
              'DIBHeaderInfo: HeaderSize');
            if n = $0000000C then begin
              AddAnalysisNode(14, IntToStr(GetWord(14)),
                'BitmapCoreHeader.Width');
              AddAnalysisNode(16, IntToStr(GetWord(16)),
                'BitmapCoreHeader.Height');
              AddAnalysisNode(18, IntToStr(GetWord(18)),
                'BitmapCoreHeader.Planes');
              AddAnalysisNode(20, IntToStr(GetWord(20)),
                'BitmapCoreHeader.BitCount');
              AddAnalysisNode(22, '...',
                'Colors and bitmap buffer');
            end else begin
              AddAnalysisNode(14, IntToStr(GetDWord(14)),
                'BitmapInfoHeader.Width');
              AddAnalysisNode(18, IntToStr(GetDWord(18)),
                'BitmapInfoHeader.Height');
              AddAnalysisNode(22, IntToStr(GetWord(22)),
                'BitmapInfoHeaer.Planes');
              AddAnalysisNode(24, IntToStr(GetWord(24)),
                'BitmapInfoHeader.BitCount');
              n := GetDWord(26);
              AddAnalysisNode(26, IntToStr(n), Format(
                'BitmapInfoHeader.Compression (%s)', [WMF_GetCompressionName(n)]));
              AddAnalysisNode(30, IntToStr(GetDWord(30)),
                'BitmapInfoHeader.ImageSize, bytes');
              AddAnalysisNode(34, IntToStr(GetDWord(34)),
                'BitmapInfoHeader.XPelsPerMeter');
              AddAnalysisNode(38, IntToStr(GetDWord(38)),
                'BitmapInfoHeader.YPelsPerMeter');
              AddAnalysisNode(42, IntToStr(GetDWord(42)),
                'BitmapInfoHeader.ColorUsed');
              AddAnalysisNode(46, IntToStr(GetDWord(46)),
                'BitmapInfoHeader.ColorImportant');
              AddAnalysisNode(50, '...',
                'Colors and bitmap buffer');
              bmp := GetBitmap(10);  // Offset to DIBHeaderInfo.Size
              if bmp <> nil then begin
                Image.Picture.Assign(bmp);
                Image.Proportional := (bmp.Width > Image.Width) or (bmp.Height > Image.Height);
                Image.Parent := Panel2;
                Image.Align := alClient;
                bmp.Free;
              end;
            end;
          end;

        META_ELLIPSE, META_RECTANGLE:
          begin
            AddAnalysisNode(6, IntToStr(GetSmallInt(6)),
              'Bottom value (in logical units)');
            AddAnalysisNode(8, IntToStr(GetSmallInt(8)),
              'Right value (in logical units)');
            AddAnalysisNode(10, IntToStr(GetSmallInt(10)),
              'Top value (in logical units)');
            AddAnalysisNode(12, IntToStr(GetSmallInt(12)),
              'Left value (in logical units)');
          end;

        META_EOF:
          begin
            // no more data
          end;

        META_EXTTEXTOUT:
          begin
            AddAnalysisNode(6, IntToStr(GetSmallInt(6)),
              'Y coordinate (in logical units) where text is located');
            AddAnalysisNode(8, IntToStr(GetSmallInt(8)),
              'X coordinate (in logical units) where text is located');
            j := GetSmallInt(10);
            AddAnalysisNode(10, IntToStr(j),
              'String length (character count)');
            n := GetWord(12);
            AddAnalysisNode(12, Format('%0:d ($%0:.4x)', [n]),
              'Option flags (OPAQUE = 2, CLIPPED = 4)');
            if n <> 0 then begin
              AddAnalysisNode(14, IntToStr(GetSmallInt(14)),
                'Background/clipping rectangle: Bottom');
              AddAnalysisNode(16, IntToStr(GetSmallInt(16)),
                'Background/clipping rectangle: Right');
              AddAnalysisNode(18, IntToStr(GetSmallInt(18)),
                'Background/clipping rectangle: Top');
              AddAnalysisNode(20, IntToStr(GetSmallInt(20)),
                'Background/clipping rectangle: Left');
              k := 22;
            end else
              k := 14;
            AddAnalysisNode(k, GetString(k, j),
              'String');
            if odd(j) then inc(k, j+1) else inc(k,j);
            for i:=0 to j-1 do
              if k + i*2 < Length(FBuffer) then
                AddAnalysisNode(k+i*2, IntToStr(GetSmallInt(k+i*2)),
                  'Distance to next character');
          end;

        META_FLOODFILL:
          begin
            AddAnalysisNode(6, Format('%0:d ($%0:.2x)', [GetByte(6)]),
              'Intensity of red');
            AddAnalysisNode(7, Format('%0:d ($%0:.2x)', [GetByte(7)]),
              'Intensity of green');
            AddAnalysisNode(8, Format('%0:d ($%0:.2x)', [GetByte(8)]),
              'Intensity of blue');
            AddAnalysisNode(9, Format('%0:d ($%0:.2x)', [GetByte(19)]),
              'Reserved');
            AddAnalysisNode(10, IntToStr(GetSmallInt(10)),
              'Y value of point where filling starts (in logical units)');
            AddAnalysisNode(12, IntToStr(GetSmallInt(12)),
              'X value of point where fillint starts (in logical units)');
            UpdateColorDisplay(GetDWord(6));
          end;


        META_LINETO, META_MOVETO:
          begin
            AddAnalysisNode(6, IntToStr(GetSmallInt(6)),
              'Y value (in logical units)');
            AddAnalysisNode(8, IntToStr(GetSmallInt(8)),
              'X value (in logical units)');
          end;

        META_OFFSETVIEWPORTORG:
          begin
            AddAnalysisNode(6, IntToStr(GetSmallInt(6)),
              'y coordinate of the viewport origin offset (in device units)');
            AddAnalysisNode(8, IntToStr(GetSmallInt(8)),
              'x coordinate of the viewport origin offset (in device units)');
          end;

        META_OFFSETWINDOWORG:
          begin
            AddAnalysisNode(6, IntToStr(GetSmallInt(6)),
              'y coordinate of the output window origin offset (in device units)');
            AddAnalysisNode(8, IntToStr(GetSmallInt(8)),
              'x coordinate of the output window origin offset (in device units)');
          end;

        META_POLYLINE, META_POLYGON:
          begin
            AddAnalysisNode(6, IntToStr(GetWord(6)), 'Number of points');
            for i:=0 to GetWord(6)-1 do begin
              AddAnalysisNode(8 + i*4, IntToStr(GetSmallInt(8 + i*4)),
                Format('X coordinate of point #%d (in logical units)', [i+1]));
              AddAnalysisNode(8 + i*4 + 2, IntToStr(GetSmallInt(8 + i*4 + 2)),
                Format('Y coordinate of point #%d (in logical units)', [i+1]));
            end;
          end;

        META_POLYPOLYGON:
          begin
            n := GetWord(6);
            AddAnalysisNode(6, IntToStr(n), 'Number of polygons');
            SetLength(nPts, n);
            for i:=0 to n-1 do begin
              nPts[i] := GetWord(8+2*i);
              AddAnalysisNode(8+2*i, IntToStr(nPts[i]),
                Format('Number of points in polygon #%d', [i+1]));
            end;
            k := 8 + 2*n;
            for i:=0 to n-1 do
              for j:=0 to npts[i]-1 do begin
                AddAnalysisNode(k, IntToStr(GetSmallInt(k)), Format(
                  'Polygon #%d: X coordinate of point #%d (in logical units)',
                  [i+1, j+1])
                );
                inc(k,2);
                AddAnalysisNode(k, IntToStr(GetSmallInt(k)), Format(
                  'Polygon #%d: Y coordinate of point #%d (in logical units)',
                  [i+1, j+1])
                );
                inc(k,2);
              end;
          end;

        META_ROUNDRECT:
          begin
            AddAnalysisNode(6, IntToStr(GetSmallInt(6)),
              'Height of ellipse for rounded corner (in logical units)');
            AddAnalysisNode(8, IntToStr(GetSmallInt(8)),
              'Width of ellipse for rounded corner (in logical units)');
            AddAnalysisNode(10, IntToStr(GetSmallInt(10)),
              'Bottom value (in logical units)');
            AddAnalysisNode(12, IntToStr(GetSmallInt(12)),
              'Right value (in logical units)');
            AddAnalysisNode(14, IntToStr(GetSmallInt(14)),
              'Top value (in logical units)');
            AddAnalysisNode(16, IntToStr(GetSmallInt(16)),
              'Left value (in logical units)');
          end;

        META_SELECTCLIPREGION:
          begin
            AddAnalysisNode(6, IntToStr(GetWord(6)),
              'Index into WMF Object Table to get the region to be selected for clipping.');
          end;

        META_SELECTOBJECT:
          begin
            AddAnalysisNode(6, IntToStr(GetWord(6)),
              'Index into WMF Object Table to get object to be selected');
          end;

        META_SELECTPALETTE:
          begin
            AddAnalysisNode(6, IntToStr(GetWord(6)),
              'Index into WMF Object Table to get the palette to be selected.');
          end;

        META_SETBKCOLOR, META_SETTEXTCOLOR:
          begin
            AddAnalysisNode(6, Format('%0:d ($%0:.2x)', [GetByte(6)]),
              'Intensity of red');
            AddAnalysisNode(7, Format('%0:d ($%0:.2x)', [GetByte(7)]),
              'Intensity of green');
            AddAnalysisNode(8, Format('%0:d ($%0:.2x)', [GetByte(8)]),
              'Intensity of blue');
            AddAnalysisNode(9, Format('%0:d ($%0:.2x)', [GetByte(9)]),
              'Reserved');
            UpdateColorDisplay(GetDWord(6));
          end;

        META_SETBKMODE:
          begin
            AddAnalysisNode(6, Format('%0:d ($%0:.2x)', [GetWord(6)]),
              Format('Background mix mode (%s)', [WMF_GetBkMixModeName(GetWord(6))]));
          end;

        META_SETMAPMODE:
          begin
            AddAnalysisNode(6, IntToStr(GetWord(6)),
              Format('Map mode (%s)', [WMF_GetMapModeName(GetWord(6))]));
          end;

        META_SETPIXEL:
          begin
            AddAnalysisNode(6, Format('%0:d ($%0:.2x)', [GetByte(6)]),
              'Intensity of red');
            AddAnalysisNode(7, Format('%0:d ($%0:.2x)', [GetByte(7)]),
              'Intensity of green');
            AddAnalysisNode(8, Format('%0:d ($%0:.2x)', [GetByte(8)]),
              'Intensity of blue');
            AddAnalysisNode(9, Format('%0:d ($%0:.2x)', [GetByte(9)]),
              'Reserved');
            AddAnalysisNode(10, IntToStr(GetSmallInt(10)),
              'Y coordinate of pixel (in logical units)');
            AddAnalysisNode(12, IntToStr(GetSmallInt(12)),
              'X coordinate of pixel (in logical units)');
            UpdateColorDisplay(GetDWord(6));
          end;

        META_SETPOLYFILLMODE:
          begin
            AddAnalysisNode(6, Format('%0:d ($%0:.2x)', [GetWord(6)]),
              Format('Polygon fill mode (%s)', [WMF_GetPolyFillModeName(GetWord(6))]));
          end;

        META_SETROP2:
          begin
            AddAnalysisNode(6, Format('%0:d ($%0:.2x)', [GetWord(6)]),
              Format('Foreground raster operation mix mode (%s)',
                [WMF_GetBinaryRasterOperationName(GetWord(6))])
            );
          end;

        META_SETTEXTALIGN:
          begin
            AddAnalysisNode(6, Format('%0:d ($%0:.2x)', [GetWord(6)]),
              Format('Text alignment (%s)', [WMF_GetTextAlignName(GetWord(6))]));
          end;

        META_SETTEXTCHAREXTRA:
          begin
            AddAnalysisNode(6, IntToStr(GetWord(6)),
              'Amount of space (in logical units) to be added to each character.');
          end;

        META_SETTEXTJUSTIFICATION:
          begin
            AddAnalysisNode(6, IntToStr(GetWord(6)),
              'Break count, i.e. number of space characters in line');
            AddAnalysisNode(8, IntToStr(GetWord(8)),
              'Break extra, i.e. extra space (in logical units) to be added to line of text');
          end;

        META_SETVIEWPORTEXT:
          begin
            AddAnalysisNode(6, IntToStr(GetSmallInt(6)),
              'Vertical extent of the viewport (in device units)');
            AddAnalysisNode(8, IntToStr(GetSmallInt(8)),
              'Horizontal extent of the viewport (in device units)');
          end;

        META_SETVIEWPORTORG:
          begin
            AddAnalysisNode(6, IntToStr(GetSmallInt(6)),
              'y coordinate of the viewport origin (in logical units)');
            AddAnalysisNode(8, IntToStr(GetSmallInt(8)),
              'x coordinate of the viewport origin (in logical units)');
          end;

        META_SETWINDOWEXT:
          begin
            AddAnalysisNode(6, IntToStr(GetSmallInt(6)),
              'Vertical extent of the output window (in logical units)');
            AddAnalysisNode(8, IntToStr(GetSmallInt(8)),
              'Horizontal extent of the output window (in logical units)');
          end;

        META_SETWINDOWORG:
          begin
            AddAnalysisNode(6, IntToStr(GetSmallInt(6)),
              'y coordinate of the output window origin (in logical units)');
            AddAnalysisNode(8, IntToStr(GetSmallInt(8)),
              'x coordinate of the output window origin (in logical units)');
          end;

        META_STRETCHDIB:
          begin
            AddAnalysisNode(6, Format('%0:d ($%0:.8x)', [GetDWord(6)]),
              'Ternary raster operation (must be SRC_COPY for jpeg and png)');
            AddAnalysisNode(10, Format('%0:d ($%0:.4x)', [GetWord(10)]),
              'Color usage (must be DIB_RGB_COLORS for jpeg or png)');
            AddAnalysisNode(12, IntToStr(GetSmallInt(12)),
              'Height of source rectangle (in logical units)');
            AddAnalysisNode(14, IntToStr(GetSmallInt(14)),
              'Width of source rectangle (in logical units)');
            AddAnalysisNode(16, IntToStr(GetSmallInt(16)),
              'Y coordinate of source rectangle (in logical units)');
            AddAnalysisNode(18, IntToStr(GetSmallInt(18)),
              'X coordinate of source rectangle (in logical units)');

            AddAnalysisNode(20, IntToStr(GetSmallInt(20)),
              'Height of destination rectangle (in logical units)');
            AddAnalysisNode(22, IntToStr(GetSmallInt(22)),
              'Width of destination rectangle (in logical units)');
            AddAnalysisNode(24, IntToStr(GetSmallInt(24)),
              'Y coordinate of destination rectangle (in logical units)');
            AddAnalysisNode(26, IntToStr(GetSmallInt(26)),
              'X coordinate of destination rectangle (in logical units)');

            n := GetDWord(28);
            if n = 0 then begin
              AddAnalysisNode(28, IntToStr(GetDWord(28)),
                'BitmapCoreHeader.HeaderSize');
              AddAnalysisNode(32, IntToStr(GetWord(32)),
                'BitmapCoreHeader.Width');
              AddAnalysisNode(34, IntToStr(GetWord(34)),
                'BitmapCoreHeader.Height');
              AddAnalysisNode(36, IntToStr(GetWord(36)),
                'BitmapCoreHeader.Planes');
              n := GetWord(38);
              case n of
                0 : s := 'undefined';
                1 : s := '1 bpp: two colors';
                4 : s := '4 bpp: 16 colors';
                8 : s := '8 bpp: 256 colors';
                16: s := '16 bpp: 2^16 colors';
                24: s := '2^24 colors';
                32: s := '2^24 colors';
              end;
              AddAnalysisNode(38, IntToStr(GetWord(38)),
                Format('BitmapCoreHeader.BitCount per pixel (%d = %s)', [n, s]));
              n := 40;
            end else begin
              AddAnalysisNode(28, IntToStr(GetDWord(28)),
                'BitmapInfoHeader.HeaderSize');
              AddAnalysisNode(32, IntToStr(GetDWord(32)),
                'BitmapInfoHeader.Width');
              AddAnalysisNode(36, IntToStr(GetDWord(36)),
                'BitmapInfoHeader.Height');
              AddAnalysisNode(40, IntToStr(GetWord(40)),
                'BitmapInfoHeader.Planes');
              n := GetWord(42);
              case n of
                0 : s := 'undefined';
                1 : s := '1 bpp: two colors';
                4 : s := '4 bpp: 16 colors';
                8 : s := '8 bpp: 256 colors';
                16: s := '16 bpp: 2^16 colors';
                24: s := '2^24 colors';
                32: s := '2^24 colors';
              end;
              AddAnalysisNode(42, IntToStr(n),
                'BitmapInfoHeader.BitCount per pixel (' + s + ')');
              n := GetDWord(44);
              case n of
                0: s := 'BI_RGB';
                1: s := 'BI_RLE8';
                2: s := 'BI_RLE4';
                3: s := 'BI_BITFIELDS';
                4: s := 'BI_JPEG';
                5: s := 'BI_PNG';
               $B: s := 'BI_CMYK';
               $C: s := 'BI_CMYKRLE8';
               $D: s := 'BI_CMYKREL4';
              end;
              AddAnalysisNode(44, IntToStr(n),
                Format('BitmapInfoHeader.Compression (%d = %s)', [n, s]));
              if n = 0 then  // BI_RGB
                s := 'ImageSize (ignored)'
              else if n in [4, 5] then  // BI_JPEG or BI_PNG
                s := 'ImageSize (specifies the size of the jpeg/png image buffer)'
              else
                s := 'ImageSize';
              n := GetDWord(48);
              AddAnalysisNode(48, IntToStr(GetDWord(48)),
                s);
              AddAnalysisNode(52, IntToStr(GetDWord(52)),
                'XPelsPerMeter');
              AddAnalysisNode(56, IntToStr(GetDWord(56)),
                'YPelsPerMeter');
              AddAnalysisNode(60, IntToStr(GetDWord(60)),
                'Colors used');
              AddAnalysisNode(64, IntToStr(GetDWord(64)),
                'Colors important');
              n := 68;
            end;
            AddAnalysisNode(n, '...', 'Colors and Image');
          end;

        META_TEXTOUT:
          begin
            n := GetWord(6);
            AddAnalysisNode(6, IntToStr(n),
              'Text length (in Bytes)');
            AddAnalysisNode(8, GetString(8, n),
              'String');
            if odd(n) then inc(n);
            AddAnalysisNode(8 + n, IntToStr(GetSmallInt(8 + n)),
              'Y coordinate of point at which drawing starts (in logical units)');
            AddAnalysisNode(10 + n, IntToStr(GetSmallInt(10 + n)),
              'X coordinate of point at which drawing starts (in logical units)');
          end;
        else
          AddAnalysisNode(6, '...', '(Undecoded data)');
      end;
    end;

  finally
    AnalysisTree.EndUpdate;
  end;
end;

procedure TMainForm.PopulateHexView;
var
  stream: TMemoryStream;
begin
  stream := TMemoryStream.Create;
  try
    stream.Write(FBuffer[0], Length(FBuffer));
    stream.Position := 0;
    FHexView.Clear;
    FHexView.LoadFromStream(stream);
  finally
    stream.Free;
  end;
end;

procedure TMainForm.ReadCmdLine;
begin
  if ParamCount > 0 then
    LoadFile(ParamStr(1));
end;

procedure TMainForm.TreeFocusChanged(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex);
var
  data: PWMFNodeData;
  funcCode: word = 0;
begin
  if FStream = nil then
    exit;

  if Node = nil then begin
    FStream.Position := 0;
    FHexView.LoadFromStream(FStream);
    exit;
  end;

  data := Tree.GetNodeData(Node);
  if (data = nil) then
    exit;

  // Read the stream at offset data^.Offset and put the data into FBuffer
  FStream.Position := data^.Offset;
  FCurrOffset := FStream.Position;
  if data^.Text = 'Placeable Meta Header' then begin
    SetLength(FBuffer, SizeOf(TPlaceableMetaHeader));
    FStream.ReadBuffer(FBuffer[0], SizeOf(TPlaceableMetaHeader));
    PopulateHexView;
    PopulateAnalysis($FFFF, data^.Offset);
  end else
  if data^.Text = 'WMF header' then begin
    SetLength(FBuffer, SizeOf(TWMFHeader));
    FStream.ReadBuffer(FBuffer[0], SizeOf(TWMFHeader));
    PopulateHexView;
    PopulateAnalysis($FFFE, data^.Offset);
  end else begin
    SetLength(FBuffer, data^.Size);   // data^.Size is in bytes
    FStream.ReadBuffer(FBuffer[0], data^.Size);
    Move(FBuffer[4], funcCode, SizeOf(funcCode));
    PopulateHexView;
    PopulateAnalysis(funccode, data^.Offset);
  end;
  PopulateValueGrid;
  ValueGridClick(nil);
  UpdateWMFObjList(data^.Offset);
end;

procedure TMainForm.TreeFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
var
  data: PWMFNodeData;
begin
  data := Tree.GetNodeData(Node);
  data^.Text := '';
end;

procedure TMainForm.TreeGetText(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: String);
var
  data: PWMFNodeData;
begin
  data := Tree.GetNodeData(Node);
  case Column of
    0: CellText := IntToStr(data^.Offset);
    1: CelLText := data^.Text;
  end;
end;

procedure TMainForm.UpdateCaption;
begin
  if FFileName <> '' then
    Caption := Format('wmfExplorer - "%s"', [FFileName])
  else
    Caption := 'wmfExplorer';
end;

procedure TMainForm.UpdateWMFObjList(AOffset: Int64);
type
  TParamArray = array of word;
const
  SIZE_OF_WORD = 2;

  procedure AddToList(AInfo: String);
  var
    i: Integer;
    s: String;
  begin
    for i := 0 to WMFObjList.Items.Count-1 do
    begin
      s := WMFObjList.Items[i];
      while (s <> '') and (s[1] in [' ', '-', '0'..'9']) do
        Delete(s, 1, 1);
      if s = '' then begin
        WMFObjList.Items[i] := Format('%d - %s', [i, AInfo]);
        exit;
      end;
    end;
    i := WMFObjList.Items.Count;
    WMFObjList.Items.Add(Format('%d - %s', [i, AInfo]));
  end;

  procedure BrushInfo(const AParams: TParamArray);
  var
    brushRec: PWMFBrushRecord;
    info: String;
  begin
    info := 'BRUSH: style';
    brushRec := PWMFBrushRecord(@AParams[0]);

    // brush style
    case brushRec^.Style of
      BS_SOLID:
        info := info + ' solid';
      BS_NULL:
        info := info + ' clear';
      BS_HATCHED:
        case brushRec^.Hatch of
          HS_HORIZONTAL : info := info + ' horizontal';
          HS_VERTICAL   : info := info + ' vertical';
          HS_FDIAGONAL  : info := info + ' diagonal';
          HS_BDIAGONAL  : info := info + ' back-diagonal';
          HS_CROSS      : info := info + ' cross';
          HS_DIAGCROSS  : info := info + ' diag-cross';
        end;
      else
        info := info + ' (unknown)';
    end;

    // brush color
    info := info + ', color ' + Format('#$%.2x%.2x%.2x', [brushRec^.ColorRED, brushRec^.ColorGREEN, brushRec^.ColorBlue]);

    AddToList(info);
  end;

  procedure FontInfo(const AParams: TParamArray);
  var
    fontRec: PWMFFontRecord;
    fntName: String = '';
    idx: Integer;
    info: String;
  begin
    info := 'FONT:';

    idx := Length(AParams);
    fontRec := PWMFFontRecord(@AParams[0]);

    // Get font name
    SetLength(fntName, 32);
    idx := SizeOf(TWMFFontRecord) div SIZE_OF_WORD;
    fntname := StrPas(PChar(@AParams[idx]));

    info := info + ' "' + fntName + '", size ' + IntToStr(fontRec^.Height);
    if fontRec^.Weight >= 700 then
      info := info + ', bold';
    if fontRec^.Italic <> 0 then
      info := info + ', italic';
    if fontRec^.Underline <> 0 then
      info := info + ', underline';
    if fontRec^.Strikeout <> 0 then
      info := info + ', strikeout';
    if fontRec^.Escapement <> 0 then
      info := info + FormatFloat(', 0.0°', 1.0*fontRec^.Escapement);

    AddToList(info);
  end;

  procedure PenInfo(const AParams: TParamArray);
  var
    penRec: PWMFPenRecord;
    info: String;
  begin
    info := 'PEN: stye ';

    penRec := PWMFPenRecord(@AParams[0]);
    // pen style
    case penRec^.Style and $000F of
      PS_DASH       : info := info + ' dash';
      PS_DOT        : info := info + ' dot';
      PS_DASHDOT    : info := info + ' dash-dot';
      PS_DASHDOTDOT : info := info + ' dash-dot-dot';
      PS_NULL       : info := info + ' clear';
      PS_INSIDEFRAME: info := info + ' insideFrame';
      else            info := info + ' (unknown)';
    end;

    // pen width
    info := info + ', width ' + IntToStr(penRec^.Width);

    // pen color
    info := info + ', color ' + Format('#$%.2x%.2x%.2x', [penRec^.ColorRED, penRec^.ColorGREEN, penRec^.ColorBlue]);

    AddToList(info);
  end;

  procedure RegionInfo(const AParams: TParamArray);
  var
    info: String;
  begin
    info := 'REGION: (not handled)';
    AddToList(info);
  end;

  procedure PaletteInfo(const AParams: TParamArray);
  var
    info: String;
  begin
    info := 'PALETTE: (not handled)';
    AddToList(info);
  end;

  procedure PatternBrushInfo(const AParams: TParamArray);
  var
    info: String;
  begin
    info := 'PATTERN BRUSH: (not handled)';
    AddToList(info);
  end;

  procedure DIBPatternBrushInfo(const AParams: TParamArray);
  var
    info: String;
  begin
    info := 'DIB PATTERN BRUSH: (not handled)';
    AddToList(info);
  end;

  procedure DeleteObj(const AParams: TParamArray);
  var
    idx: Integer;
  begin
    idx := AParams[0];
    WMFObjList.Items[idx] := Format('%d -', [idx]);
  end;

  procedure SelectObj(const AParams: TParamArray);
  var
    idx: Integer;
  begin
    idx := AParams[0];
    WMFObjList.ItemIndex := idx;
  end;

var
  phdr: TPlaceableMetaHeader;
  mhdr: TWMFHeader;
  rec: TWMFRecord;
  params: TParamArray = nil;
  savedPos: Int64;
  startPos: Int64;
  b: Byte;
begin
  startPos := FStream.Position;
  WMFObjList.Items.Clear;

  FStream.Position := 0;
  b := FStream.ReadByte;
  FStream.Position := 0;
  if b = $D7 then begin  // Assume that file begins with a placeable meta file header
    phdr := Default(TPlaceableMetaHeader);
    FStream.ReadBuffer(phdr, SizeOf(phdr));
    if phdr.Key <> $9AC6CDD7 then begin
      MessageDlg(Format('Unknown structure of file "%s"', [FFileName]), mtError, [mbOK], 0);
      exit;
    end;
  end else
  if not ((b = 0) or (b = 1)) then begin
    MessageDlg(Format('Unknown structure of file "%s"', [FFileName]), mtError, [mbOK], 0);
    exit;
  end;

  // Read "normal" metafile header
  mhdr := Default(TWMFHeader);
  FStream.ReadBuffer(mhdr, SizeOf(mhdr));

  // Read metafile records
  while FStream.Position < FStream.Size do begin
    savedPos := FStream.Position;
    FStream.ReadBuffer(rec, SizeOf(rec));

    if rec.Func = META_EOF then
      break;

    if rec.Size < 3 then begin
      MessageDlg(Format('Record size error at position %d', [savedPos]), mtError, [mbOk], 0);
      exit;
    end;

    // Read parameters
    SetLength(params, rec.Size - 3);
    FStream.ReadBuffer(params[0], (rec.Size - 3)*SIZE_OF_WORD);

    case rec.Func of
      META_CREATEBRUSHINDIRECT:
        BrushInfo(params);
      META_CREATEFONTINDIRECT:
        FontInfo(params);
      META_CREATEPALETTE:
        PaletteInfo(params);
      META_CREATEPATTERNBRUSH:
        PatternBrushInfo(params);
      META_CREATEPENINDIRECT:
        PenInfo(params);
      META_CREATEREGION:
        RegionInfo(params);
      META_DIBCREATEPATTERNBRUSH:
        DIBPatternBrushInfo(params);
      META_DELETEOBJECT:
        DeleteObj(params);
      META_SELECTOBJECT:
        SelectObj(params);
    end;
    if rec.Size = 0 then begin
      MessageDlg('Invalid record size 0 encountered at offset '+ IntToStr(savedPos) + '. Closing...',
        mtError, [mbOK], 0);
      break;
    end;
    FStream.Position := savedPos + rec.Size*SizeOf(word);
    if FStream.Position > AOffset then
      break;
  end;

  FStream.Position := startPos;
end;

procedure TMainForm.ValueGridClick(Sender: TObject);
var
  n: Integer;
begin
  if FHexView.SelStart = -1 then
    exit;

  n := GetValueGridDataSize;
  if n = -1 then
    exit;

  if FHexView.SelStart + n >= FHexView.DataSize then
    exit;

  if n > 0 then
    FHexView.SelEnd := FHexView.SelStart + n - 1
  else
    FHexView.SelEnd := FHexView.SelStart;
end;

procedure TMainForm.ValueGridPrepareCanvas(sender: TObject; aCol,
  aRow: Integer; aState: TGridDrawState);
begin
  if ARow = 0 then ValueGrid.Canvas.Font.Style := [fsBold];
end;

end.

