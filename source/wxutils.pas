unit wxutils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, fpvwmf;

function WMF_GetBkMixModeName(ABkMode: Word): String;
function WMF_GetBinaryRasterOperationName(AValue: Word): String;
function WMF_GetBrushStyleName(AValue: Word): String;
function WMF_GetColorUsageName(AValue: Word): String;
function WMF_GetCompressionName(AValue: Word): String;
function WMF_GetFuncName(AFuncCode: DWord): String;
function WMF_GetMapModeName(AValue: Word): String;
function WMF_GetPenStyleName(AValue: Word): String;
function WMF_GetPolyFillModeName(AValue: Word): String;
function WMF_GetTextAlignName(AValue: Word): String;

procedure WMF_SetBrushStyle(ABrush: TBrush; AValue: Word);
procedure WMF_SetPenStyle(APen: TPen; AValue: Word);

function WordLEtoN(AValue: Word): Word;
function DWordLEtoN(AValue: Cardinal): Cardinal;
function GetFixedFontName: String;

function CalcIniName: String;

implementation

uses
  Forms;

function WMF_GetBinaryRasterOperationName(AValue: Word): String;
begin
  case AValue of
    $0001: Result := 'R2_BLACK';
    $0002: Result := 'R2_NOTMERGEPEN';
    $0003: Result := 'R2_MASKNOTPEN';
    $0004: Result := 'R2_NOTCOPYPEN';
    $0005: Result := 'R2_MASKPENNOT';
    $0006: Result := 'R2_NOT';
    $0007: Result := 'R2_XORPEN';
    $0008: Result := 'R2_NOTMASKPEN';
    $0009: Result := 'R2_MASKPEN';
    $000A: Result := 'R2_NOTXORPEN';
    $000B: Result := 'R2_NOP';
    $000C: Result := 'R2_MERGENOTPEN';
    $000D: Result := 'R2_COPYPEN';
    $000E: Result := 'R2_MERGEPENNOT';
    $000F: Result := 'R2_MERGEPEN';
    $0010: Result := 'R2_WHITE';
    else   Result := '???';
  end;
end;

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

function WMF_GetColorUsageName(AValue: Word): String;
begin
  case AValue of
    0: Result := 'DIB_RGB_COLORS';
    1: Result := 'DIB_PAL_COLORS';
    2: Result := 'DIB_PAL_INDICES';
  end;
end;

function WMF_GetCompressionName(AValue: Word): String;
begin
  case AValue of
    $00: Result := 'BI_RGB';
    $01: Result := 'BI_RLE8';
    $02: Result := 'BI_RLE4';
    $03: Result := 'BI_BITFIELDS';
    $04: Result := 'BI_JPEG';
    $05: Result := 'BI_PNG';
    $0B: Result := 'BI_CMYK';
    $0C: Result := 'BI_CMYKRLE8';
    $0D: Result := 'BI_CMYKRLE4';
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

function WMF_GetPolyFillModeName(AValue: Word): String;
begin
  case AValue of
    $0001: Result := 'ALTERNATE';
    $0002: Result := 'WINDING';
    else   Result := '???';
  end;
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

function WordLEtoN(AValue: Word): Word;
begin
  Result := LEtoN(AValue);
end;

function DWordLEtoN(AValue: Cardinal): Cardinal;
begin
  Result := LEtoN(AValue);
end;

function GetFixedFontName: String;
var
  idx: Integer;
begin
  Result := Screen.SystemFont.Name;
  idx := Screen.Fonts.IndexOf('Courier New');
  if idx = -1 then
    idx := Screen.Fonts.IndexOf('Courier 10 Pitch');
  if idx <> -1 then
    Result := Screen.Fonts[idx]
  else
    for idx := 0 to Screen.Fonts.Count-1 do
      if pos('courier', Lowercase(Screen.Fonts[idx])) = 1 then
      begin
        Result := Screen.Fonts[idx];
        exit;
      end;
end;

function CalcIniName: String;
begin
  Result := GetAppConfigFile(false);
end;

end.

