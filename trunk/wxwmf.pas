{ Declarations for Windows meta files

  Infos taken from
  - http://msdn.microsoft.com/en-us/library/cc250370.aspx
  - http://wvware.sourceforge.net/caolan/ora-wmf.html
  - http://www.symantec.com/avcenter/reference/inside.the.windows.meta.file.format.pdf
}

unit wxwmf;

interface

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
    Key: DWord;               // Magic number (always 9AC6CDD7h)
    Handle: Word;             // Metafile HANDLE number (always 0)
    Left: SmallInt;           // Left coordinate in metafile units
    Top: SmallInt;            // Top coordinate in metafile units
    Right: SmallInt;          // Right coordinate in metafile units
    Bottom: SmallInt;         // Bottom coordinate in metafile units
    Inch: Word;               // Number of metafile units per inch
    Reserved: DWord;          // Reserved (always 0)
    Checksum: Word;           // Checksum value for previous 10 WORDs
  end;
  PPlaceableMetaHeader = ^TPlaceableMetaHeader;

  TEnhancedMetaHeader = packed record      // 80 bytes
    RecordType: DWord;        // Record type, must be 00000001h for EMF
    RecordSize: DWord;        // Size of the record in bytes
    BoundsLeft: LongInt;      // Left inclusive bounds
    BoundsRight: LongInt;     // Right inclusive bounds
    BoundsTop: LongInt;       // Top inclusive bounds
    BoundsBottom: LongInt;    // Bottom inclusive bounds
    FrameLeft: LongInt;       // Left side of inclusive picture frame
    FrameRight: LongInt;      // Right side of inclusive picture frame
    FrameTop: LongInt;        // Top side of inclusive picture frame
    FrameBottom: LongInt;     // Bottom side of inclusive picture frame
    Signature: DWord;         // Signature ID (always $464D4520)
    Version: DWord;           // Version of the metafile, always $00000100
    Size: DWord;              // Size of the metafile in bytes
    NumOfRecords: DWord;      // Number of records in the metafile
    NumOfHandles: Word;       // Number of handles in the handle table
    Reserved: Word;           // Not used (always 0)
    SizeOfDescrip: DWord;     // Length of description string (16-bit chars) in WORDs, incl zero
    OffsOfDescrip: DWord;     // Offset of description string in metafile (from beginning)
    NumPalEntries: DWord;     // Number of color palette entries
    WidthDevPixels: LongInt;  // Width of display device in pixels
    HeightDevPixels: LongInt; // Height of display device in pixels
    WidthDevMM: LongInt;      // Width of display device in millimeters
    HeightDevMM: LongInt;     // Height of display device in millimeters
  end;

  TWMFRecord = packed record
    Size: DWord;              // Total size of the record in WORDs
    Func: Word;               // Function number (defined in WINDOWS.H)
    // Parameters[]: Word;    // Parameter values passed to function - will be read separately
  end;

  TWMFBrushRecord = packed record
    Style: Word;
    ColorRED: byte;
    ColorGREEN: Byte;
    ColorBLUE: byte;
    // Brush hatch/pattern data of variable length follow
    case integer of
      0: (Hatch: Word);
      // pattern not yet implemented here...
  end;
  PWMFBrushRecord = ^TWMFBrushRecord;

  TWMFColorRecord = packed record
    ColorRED: Byte;
    ColorGREEN: Byte;
    ColorBLUE: Byte;
    Reserved: Byte;
  end;
  PWMFColorRecord = ^TWMFColorRecord;

  TWMFFontRecord = packed record
    Height: Word;
    Width: Word;
    Escapement: Word;
    Orientation: Word;
    Weight: Word;
    Italic: Byte;
    UnderLine: Byte;
    Strikeout: Byte;
    CharSet: Byte;
    OutPrecision: Byte;
    ClipPrecision: Byte;
    Quality: Byte;
    PitchAndFamily: byte;
    Facename: PChar;
  end;
  PWMFFontRecord = ^TWMFFontRecord;

  TWMFPenRecord = packed record
    Style: Word;
    Width: Word;
    Ignored1: Word;
    ColorRED: Byte;
    ColorGREEN: Byte;
    ColorBLUE: Byte;
    Ignored2: Byte;
  end;
  PWMFPenRecord = ^TWMFPenRecord;

  TWMFPointRecord = packed record
    Y: Word;
    X: Word;
  end;

  TWMFRectRecord = packed record
    Bottom: Word;
    Right: Word;
    Top: Word;
    Left: Word;
  end;
  PWMFRectRecord = ^TWMFRectRecord;


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

  // Brush styles
  BS_SOLID = $0000;
  BS_NULL = $0001;
  BS_HATCHED = $0002;
  BS_PATTERN = $0003;
  BS_INDEXED = $0004;
  BS_DIBPATTERN = $0005;
  BS_DIBPATTERNPT = $0006;
  BS_PATTERN8X8 = $0007;
  BS_DIBPATTERN8X8 = $0008;
  BS_MONOPATTERN = $0009;

  // Character sets
  ANSI_CHARSET = $00000000;
  DEFAULT_CHARSET = $00000001;
  SYMBOL_CHARSET = $00000002;
  MAC_CHARSET = $0000004D;
  SHIFTJIS_CHARSET = $00000080;
  HANGUL_CHARSET = $00000081;
  JOHAB_CHARSET = $00000082;
  GB2312_CHARSET = $00000086;
  CHINESEBIG5_CHARSET = $00000088;
  GREEK_CHARSET = $000000A1;
  TURKISH_CHARSET = $000000A2;
  VIETNAMESE_CHARSET = $000000A3;
  HEBREW_CHARSET = $000000B1;
  ARABIC_CHARSET = $000000B2;
  BALTIC_CHARSET = $000000BA;
  RUSSIAN_CHARSET = $000000CC;
  THAI_CHARSET = $000000DE;
  EASTEUROPE_CHARSET = $000000EE;
  OEM_CHARSET = $000000FF;

  // Family font
  FF_DONTCARE = $00;
  FF_ROMAN = $01;
  FF_SWISS = $02;
  FF_MODERN = $03;
  FF_SCRIPT = $04;
  FF_DECORATIVE = $05;

  // Flood fill
  FLOODFILLBORDER = $0000;
  FLOODFILLSURFACE = $0001;

  // Font quality
  DEFAULT_QUALITY = $00;
  DRAFT_QUALITY = $01;
  PROOF_QUALITY = $02;
  NONANTIALIASED_QUALITY = $03;
  ANTIALIASED_QUALITY = $04;
  CLEARTYPE_QUALITY = $05;

  // Hatch style
  HS_HORIZONTAL = $0000;
  HS_VERTICAL = $0001;
  HS_FDIAGONAL = $0002; // \\\
  HS_BDIAGONAL = $0003; // ///
  HS_CROSS = $0004;     // +++
  HS_DIAGCROSS = $0005; // xxxx

  // Map mode
  MM_TEXT = $0001;         // 1 logical unit = 1 device pixel. +x right, +y down
  MM_LOMETRIC = $0002;     // 1 logical unit = 0.1 mm. +x right, +y up
  MM_HIMETRIC = $0003;     // 1 logical unit = 0.01 mm. +x right, +y up
  MM_LOENGLISH = $0004;    // 1 logical unit = 0.01 inch. +x right, +y up
  MM_HIENGLISH = $0005;    // 1 logical unit = 0.001 inch. +x right, +y up
  MM_TWIPS = $0006;        // 1 logical unit = 1/20 point = 1/1440 inch (twip). +x right, +y up
  MM_ISOTROPIC = $0007;    // arbitrary units, equally scaled axes. --> META_SETWINDOWEXT, META_SETWINDOWORG
  MM_ANISOTROPIC = $0008;  // arbitrary units, arbitrarily scaled axes.

  // Metafile enumeration
  MEMORYMETAFILE = $0001;  // Metafile is stored in memory
  DISKMETAFILE = $0002;    // ... on disk.

  // MixMode
  TRANSPARENT = $0001;
  OPAQUE = $0002;

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

  // PitchFont
  DEFAULT_PITCH = 0;
  FIXED_PITCH = 1;
  VARIABLE_PITCH = 2;

  // PolyFillMode
  ALTERNATE = $0001;
  WINDING = $0002;

  // TextAlignment flags
  TA_NOUPDATECP = $0000;
  TA_LEFT = $0000;
  TA_TOP = $0000;
  TA_UPDATECP = $0001;
  TA_RIGHT = $0002;
  TA_CENTER = $0006; // Why not $0004?
  TA_BOTTOM = $0008;
  TA_BASELINE = $0018;
  TA_RTLREADING = $0100;

  // Vertical text alignment flags
  // Used if font has vertical baseline, such as Kanji.
  VTA_TOP = $0000;
  VTA_RIGHT = $0000;
  VTA_BOTTOM = $0002;
  VTA_CENTER = $0006;  // why not $0004?
  VTA_BASELINE = $0018;



implementation

end.
