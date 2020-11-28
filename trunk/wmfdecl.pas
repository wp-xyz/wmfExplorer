unit wmfDecl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics;

type
  TWMFHeader = packed record
    FileType: Word;        // Type of metafile (0=memory, 1=disk)
    HeaderSize: Word;      // Size of header in WORDS (always 9)
    Version: Word;         // Version of Microsoft Windows used
    FileSize: DWord;       // Total size of the metafile in WORDs
    NumOfObjects: Word;    // Number of objects in the file
    MaxRecordSize: DWord;  // The size of largest record in WORDs
    NumOfParams: Word;     // Not Used (always 0)
  end;
  PWMFHeader = ^TWMFHeader;

  TPlaceableMetaHeader = packed record
    Key: DWord;            // Magic number (always 9AC6CDD7h)
    Handle: Word;          // Metafile HANDLE number (always 0)
    Left: SmallInt;        // Left coordinate in metafile units
    Top: SmallInt;         // Top coordinate in metafile units
    Right: SmallInt;       // Right coordinate in metafile units
    Bottom: SmallInt;      // Bottom coordinate in metafile units
    Inch: Word;            // Number of metafile units per inch
    Reserved: DWord;       // Reserved (always 0)
    Checksum: Word;        // Checksum value for previous 10 WORDs
  end;
  PPlaceableMetaHeader = ^TPlaceableMetaHeader;

  TWMFRecord = packed record
    Size: DWord;           // Total size of the record in WORDs
    Func: Word;            // Function number (defined in WINDOWS.H)
    // Parameters[]: Word; // Parameter values passed to function - will be read separately
  end;


const
  // WMF Record types
  META_EOF = $0000;
  META_REALIZEPALETTE = $0035;
  META_SETPALENTRIES = $0037;
  META_SETBKMODE = $0102;
  META_SETMAPMODE = $0103;
  META_SETROP2 = $0104;
  META_SETRELABS = $0105;
  META_SETPOLYFILLMODE = $0106;
  META_SETSTRETCHBLTMODE = $0107;
  META_SETTEXTCHAREXTRA = $0108;
  META_RESTOREDC = $0127;
  META_RESIZEPALETTE = $0139;
  META_DIBCREATEPATTERNBRUSH = $0142;
  META_SETLAYOUT = $0149;
  META_SETBKCOLOR = $0201;
  META_SETTEXTCOLOR = $0209;
  META_OFFSETVIEWPORTORG = $0211;
  META_LINETO = $0213;
  META_MOVETO = $0214;
  META_OFFSETCLIPRGN = $0220;
  META_FILLREGION = $0228;
  META_SETMAPPERFLAGS = $0231;
  META_SELECTPALETTE = $0234;
  META_POLYGON = $0324;
  META_POLYLINE = $0325;
  META_SETTEXTJUSTIFICATION = $020A;
  META_SETWINDOWORG = $020B;
  META_SETWINDOWEXT = $020C;
  META_SETVIEWPORTORG = $020D;
  META_SETVIEWPORTEXT = $020E;
  META_OFFSETWINDOWORG = $020F;
  META_SCALEWINDOWEXT = $0410;
  META_SCALEVIEWPORTEXT = $0412;
  META_EXCLUDECLIPRECT = $0415;
  META_INTERSECTCLIPRECT = $0416;
  META_ELLIPSE = $0418;
  META_FLOODFILL = $0419;
  META_FRAMEREGION = $0429;
  META_ANIMATEPALETTE = $0436;
  META_TEXTOUT = $0521;
  META_POLYPOLYGON = $0538;
  META_EXTFLOODFILL = $0548;
  META_RECTANGLE = $041B;
  META_SETPIXEL = $041F;
  META_ROUNDRECT = $061C;
  META_PATBLT = $061D;

  META_SAVEDC = $001E;
  META_PIE = $081A;
  META_STRETCHBLT = $0B23;
  META_ESCAPE = $0626;
  META_INVERTREGION = $012A;
  META_PAINTREGION = $012B;
  META_SELECTCLIPREGION = $012C;
  META_SELECTOBJECT = $012D;
  META_SETTEXTALIGN = $012E;
  META_ARC = $0817;
  META_CHORD = $0830;
  META_BITBLT = $0922;
  META_EXTTEXTOUT = $0a32;
  META_SETDIBTODEV = $0d33;
  META_DIBBITBLT = $0940;
  META_DIBSTRETCHBLT = $0b41;
  META_STRETCHDIB = $0f43;
  META_DELETEOBJECT = $01f0;
  META_CREATEPALETTE = $00f7;
  META_CREATEPATTERNBRUSH = $01F9;
  META_CREATEPENINDIRECT = $02FA;
  META_CREATEFONTINDIRECT = $02FB;
  META_CREATEBRUSHINDIRECT = $02FC;
  META_CREATEREGION = $06FF;

  // Pen styles
  PS_COSMETIC = $0000;
  PS_ENDCAP_ROUND = $0000;
  PS_JOIN_ROUND = $0000;
  PS_SOLID = $0000;
  PS_DASH = $0001;
  PS_DOT = $0002;
  PS_DASHDOT = $0003;
  PS_DASHDOTDOT = $0004;
  PS_NULL = $0005;
  PS_INSIDEFRAME = $0006;
  PS_USERSTYLE = $0007;
  PS_ALTERNATE = $0008;
  PS_ENDCAP_SQUARE = $0100;
  PS_ENDCAP_FLAT = $0200;
  PS_JOIN_BEVEL = $1000;
  PS_JOIN_MITER = $2000;

  // Map modes
  MM_TEXT = $0001;         // 1 logical unit = 1 device pixel. x right,  y down
  MM_LOMETRIC = $0002;     // 1 logical unit = 0.1 mm. x right, y up
  MM_HIMETRIC = $0003;     // 1 logical unit = 0.01 mm. x right, y up
  MM_LOENGLISH = $0004;    // 1 logical unit = 0.01 inch. x right, y up
  MM_HIENGLISH = $0005;    // 1 logical unit = 0.001 inch. x right, y up
  MM_TWIPS = $0006;        // 1 logical unit = 1/20 point = 1/1440 inch (twip). x right, y up
  MM_ISOTROPIC = $0007;    // arbitrary units, equally scaled axes. --> META_SETWINDOWEXT, META_SETWINDOWORG
  MM_ANISOTROPIC = $0008;  // arbitrary units, arbitrarily scaled axes.

function WMF_GetBkMixModeName(ABkMode: Word): String;
function WMF_GetBrushStyleName(AValue: Word): String;
function WMF_GetFuncName(AFuncCode: DWord): String;
function WMF_GetMapModeName(AValue: Word): String;
function WMF_GetPenStyleName(AValue: Word): String;
function WMF_GetTextAlignName(AValue: Word): String;

procedure WMF_SetBrushStyle(ABrush: TBrush; AValue: Word);
procedure WMF_SetPenStyle(APen: TPen; AValue: Word);

implementation

function WMF_GetBkMixModeName(ABkMode: Word): String;
begin
  case ABkMode of
    1: Result := 'Transparent';
    2: Result := 'Opaque';
  end;
end;

function WMF_GetBrushStyleName(AValue: Word): String;
begin
  case AValue of
    0: Result := 'BS_SOLID';
    1: Result := 'BS_NULL';
    2: Result := 'BS_HATCHED';
    3: Result := 'BS_PATTERN';
    4: Result := 'BS_INDEXED';
    5: Result := 'BS_DIBPATTERN';
    6: Result := 'BS_DIBPATTERNPT';
    7: Result := 'BS_PATTERN8X8';
    8: Result := 'BS_DIBPATTERN8X8';
    9: Result := 'BS_MONOPATTERN';
    else Result := '???';
  end;
end;

function WMF_GetFuncName(AFuncCode: DWord): String;
begin
  case AFuncCode of
    META_EOF                   : Result := 'META_EOF';
    META_REALIZEPALETTE        : Result := 'META_REALIZEPALETTE';
    META_SETPALENTRIES         : Result := 'META_SETPALENTRIES';
    META_SETBKMODE             : Result := 'META_SETBKMODE';
    META_SETMAPMODE            : Result := 'META_SETMAPMODE';
    META_SETROP2               : Result := 'META_SETROP2';
    META_SETRELABS             : Result := 'META_SETRELABS';
    META_SETPOLYFILLMODE       : Result := 'META_SETPOLYFILLMODE';
    META_SETSTRETCHBLTMODE     : Result := 'META_SETSTRETCHBLTMODE';
    META_SETTEXTCHAREXTRA      : Result := 'META_SETTEXTCHAREXTRA';
    META_RESTOREDC             : Result := 'META_RESTOREDC';
    META_RESIZEPALETTE         : Result := 'META_RESIZEPALETTE';
    META_DIBCREATEPATTERNBRUSH : Result := 'META_DIBCREATEPATTERNBRUSH';
    META_SETLAYOUT             : Result := 'META_SETLAYOUT';
    META_SETBKCOLOR            : Result := 'META_SETBKCOLOR';
    META_SETTEXTCOLOR          : Result := 'META_SETTEXTCOLOR';
    META_OFFSETVIEWPORTORG     : Result := 'META_OFFSETVIEWPORTORG';
    META_LINETO                : Result := 'META_LINETO';
    META_MOVETO                : Result := 'META_MOVETO';
    META_OFFSETCLIPRGN         : Result := 'META_OFFSETCLIPRGN';
    META_FILLREGION            : Result := 'META_FILLREGION';
    META_SETMAPPERFLAGS        : Result := 'META_SETMAPPERFLAGS';
    META_SELECTPALETTE         : Result := 'META_SELECTPALETTE';
    META_POLYGON               : Result := 'META_POLYGON';
    META_POLYLINE              : Result := 'META_POLYLINE';
    META_SETTEXTJUSTIFICATION  : Result := 'META_SETTEXTJUSTIFICATION';
    META_SETWINDOWORG          : Result := 'META_SETWINDOWORG';
    META_SETWINDOWEXT          : Result := 'META_SETWINDOWEXT';
    META_SETVIEWPORTORG        : Result := 'META_SETVIEWPORTORG';
    META_SETVIEWPORTEXT        : Result := 'META_SETVIEWPORTEXT';
    META_OFFSETWINDOWORG       : Result := 'META_OFFSETWINDOWORG';
    META_SCALEWINDOWEXT        : Result := 'META_SCALEWINDOWEXT';
    META_SCALEVIEWPORTEXT      : Result := 'META_SCALEVIEWPORTEXT';
    META_EXCLUDECLIPRECT       : Result := 'META_EXCLUDECLIPRECT';
    META_INTERSECTCLIPRECT     : Result := 'META_INTERSECTCLIPRECT';
    META_ELLIPSE               : Result := 'META_ELLIPSE';
    META_FLOODFILL             : Result := 'META_FLOODFILL';
    META_FRAMEREGION           : Result := 'META_FRAMEREGION';
    META_ANIMATEPALETTE        : Result := 'META_ANIMATEPALETTE';
    META_TEXTOUT               : Result := 'META_TEXTOUT';
    META_POLYPOLYGON           : Result := 'META_POLYPOLYGON';
    META_EXTFLOODFILL          : Result := 'META_EXTFLOODFILL';
    META_RECTANGLE             : Result := 'META_RECTANGLE';
    META_SETPIXEL              : Result := 'META_SETPIXEL';
    META_ROUNDRECT             : Result := 'META_ROUNDRECT';
    META_PATBLT                : Result := 'META_PATBLT';

    META_SAVEDC                : Result := 'META_SAVEDC';
    META_PIE                   : Result := 'META_PIE';
    META_STRETCHBLT            : Result := 'META_STRETCHBLT';
    META_ESCAPE                : Result := 'META_ESCAPE';
    META_INVERTREGION          : Result := 'META_INVERTREGION';
    META_PAINTREGION           : Result := 'META_PAINTREGION';
    META_SELECTCLIPREGION      : Result := 'META_SELECTCLIPREGION';
    META_SELECTOBJECT          : Result := 'META_SELECTOBJECT';
    META_SETTEXTALIGN          : Result := 'META_SETTEXTALIGN';
    META_ARC                   : Result := 'META_ARC';
    META_CHORD                 : Result := 'META_CHORD';
    META_BITBLT                : Result := 'META_BITBLT';
    META_EXTTEXTOUT            : Result := 'META_EXTTEXTOUT';
    META_SETDIBTODEV           : Result := 'META_SETDIBTODEV';
    META_DIBBITBLT             : Result := 'META_DIBBITBLT';
    META_DIBSTRETCHBLT         : Result := 'META_DIBSTRETCHBLT';
    META_STRETCHDIB            : Result := 'META_STRETCHDIB';
    META_DELETEOBJECT          : Result := 'META_DELETEOBJECT';
    META_CREATEPALETTE         : Result := 'META_CREATEPALETTE';
    META_CREATEPATTERNBRUSH    : Result := 'META_CREATEPATTERNBRUSH';
    META_CREATEPENINDIRECT     : Result := 'META_CREATEPENINDIRECT';
    META_CREATEFONTINDIRECT    : Result := 'META_CREATEFONTINDIRECT';
    META_CREATEBRUSHINDIRECT   : Result := 'META_CREATEBRUSHINDIRECT';
    META_CREATEREGION          : Result := 'META_CREATEREGION';
    else                         Result := Format('$%.04x', [AFuncCode]);
  end;
end;

function WMF_GetMapModeName(AValue: Word): String;
begin
  case AValue of
    MM_TEXT        : Result := 'MM_TEXT';
    MM_LOMETRIC    : Result := 'MM_LOMETRIC';
    MM_HIMETRIC    : Result := 'MM_HIMETRIC';
    MM_LOENGLISH   : Result := 'MM_LOENGLISH';
    MM_HIENGLISH   : Result := 'MM_HIENGLISH';
    MM_TWIPS       : Result := 'MM_TWIPS';
    MM_ISOTROPIC   : Result := 'MM_ISOTROIPIC';
    MM_ANISOTROPIC : Result := 'MM_ANISOTROPIC';
  end;
end;

function WMF_GetPenStyleName(AValue: Word): String;
begin
  Result := '';
  case AValue and $000F of
    $0000: Result := Result + ' + PS_SOLID';
    $0001: Result := Result + ' + PS_DASH';
    $0002: Result := Result + ' + PS_DOT';
    $0003: Result := Result + ' + PS_DASHDOT';
    $0004: Result := Result + ' + PS_DASHDOTDOT';
    $0005: Result := Result + ' + PS_NULL';
    $0006: Result := Result + ' + PS_INSIDEFRAME';
    $0007: Result := Result + ' + PS_USERSTYLE';
    $0008: Result := Result + ' + PS_ALTERNATE';
  end;
  case AValue and $0100 of
    $0000: Result := Result + ' + PS_ENDCAP_ROUND';
    $0100: Result := Result + ' + PS_ENDCAP_SQUARE';
    $0200: Result := Result + ' + PS_ENDCAP_FLAT';
  end;
  case AValue and $1000 of
    $0000: Result := Result + ' + PS_JOIN_ROUND';
    $1000: Result := Result + ' + PS_JOIN_BEVEL';
    $2000: Result := Result + ' + PS_JOIN_MITER';
  end;
  if Result <> '' then Delete(Result, 1, 3);
  if Result = '' then Result := '???';
end;

function WMF_GetTextAlignName(AValue: Word): String;
begin
  if AValue = 0 then
    Result := 'TA_NOUPDATECP + TA_LEFT + TA_TOP'
  else begin
    Result := '';
    if AValue and $0001 <> 0 then
      Result := Result + ' + TA_UPDATECP';
    if AValue and $0002 <> 0 then
      Result := Result + ' + TA_RIGHT';
    if AValue and $0004 <> 0 then
      Result := Result + ' + TA_CENTER';
    if AVAlue and $0008 <> 0 then
      Result := Result + ' + TA_BOTTOM';
    if AValue and $0010 <> 0 then
      Result := Result + ' + TA_BASELINE';
    if AValue and $0100 <> 0 then
      Result := Result + ' + TA_RTLREADING';
    if Result <> '' then
      Delete(Result, 1, 3);
    if Result = '' then
      Result := '???';
  end;
end;

procedure WMF_SetPenStyle(APen: TPen; AValue: Word);
begin
  APen.Style := psSolid;
  APen.EndCap := pecRound;
  APen.JoinStyle := pjsRound;
  case AValue and $000F of
    $0001: APen.Style := psDash;
    $0002: APen.Style := psDot;
    $0003: APen.Style := psDashDot;
    $0004: APen.Style := psDashDotDot;
    $0005: APen.Style := psClear;
    $0006: APen.Style := psInsideFrame;
//    $0007: Result := Result + ' + PS_USERSTYLE';
//    $0008: Result := Result + ' + PS_ALTERNATE';
  end;
  case AValue and $0100 of
    $0100: APen.EndCap := pecSquare;
    $0200: APen.EndCap := pecFlat;
  end;
  case AValue and $1000 of
    $1000: APen.JoinStyle := pjsBevel;
    $2000: APen.JoinStyle := pjsMiter;
  end;
end;

procedure WMF_SetBrushStyle(ABrush: TBrush; AValue: Word);
begin
  ABrush.Style := bsSolid;
  case AValue of
    1: ABrush.Style := bsClear;
    2: ABrush.Style := bsFDiagonal;
    // there are more...
  end
end;

end.

