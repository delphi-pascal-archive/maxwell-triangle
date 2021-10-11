//  Maxwell Triangle
//  efg, February 1999

unit ScreenMaxwellTriangle;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, ExtDlgs;

type
  TFormMaxwellTriangle = class(TForm)
    ButtonSaveToFile: TButton;
    ButtonPrint: TButton;
    Image: TImage;
    SavePictureDialog: TSavePictureDialog;
    LabelLab1: TLabel;
    LabelLab2: TLabel;
    LabelDecileLines: TLabel;
    CheckBoxDecileX: TCheckBox;
    CheckBoxDecileY: TCheckBox;
    CheckBoxDecileZ: TCheckBox;
    CheckBoxFill: TCheckBox;
    ComboBoxTriangle: TComboBox;
    LabelRGB: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure CheckBoxClick(Sender: TObject);
    procedure ButtonSaveToFileClick(Sender: TObject);
    procedure ButtonPrintClick(Sender: TObject);
    procedure CheckBoxLabelsClick(Sender: TObject);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure ImageMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
  private
    BlueCorner :  TPoint;
    GreenCorner:  TPoint;
    RedCorner  :  TPoint;
    PROCEDURE UpdateEverything;
  public
    { Public declarations }
  end;

var
  FormMaxwellTriangle: TFormMaxwellTriangle;

implementation
{$R *.DFM}

  USES
    Math,       // MaxValue
    Printers;   // Printer

  CONST
    PixelCountMax = 32768;

  TYPE
    TRGBTripleArray = ARRAY[0..PixelCountMax-1] OF TRGBTriple;
    pRGBTripleArray = ^TRGBTripleArray;

  //==  PrintBitmap  =======================================================

  // Based on posting to borland.public.delphi.winapi by Rodney E Geraghty,
  // 8/8/97.  Used to print bitmap on any Windows printer.
  PROCEDURE PrintBitmap(Canvas:  TCanvas; DestRect:  TRect;  Bitmap:  TBitmap);
    VAR
      BitmapHeader:  pBitmapInfo;
      BitmapImage :  POINTER;
      HeaderSize  :  DWORD;    // Use DWORD for compatibility with D3 and D4
      ImageSize   :  DWORD;
  BEGIN
    GetDIBSizes(Bitmap.Handle, HeaderSize, ImageSize);
    GetMem(BitmapHeader, HeaderSize);
    GetMem(BitmapImage,  ImageSize);
    TRY
      GetDIB(Bitmap.Handle, Bitmap.Palette, BitmapHeader^, BitmapImage^);
      StretchDIBits(Canvas.Handle,
                    DestRect.Left, DestRect.Top,     // Destination Origin
                    DestRect.Right  - DestRect.Left, // Destination Width
                    DestRect.Bottom - DestRect.Top,  // Destination Height
                    0, 0,                            // Source Origin
                    Bitmap.Width, Bitmap.Height,     // Source Width & Height
                    BitmapImage,
                    TBitmapInfo(BitmapHeader^),
                    DIB_RGB_COLORS,
                    SRCCOPY)
    FINALLY
      FreeMem(BitmapHeader);
      FreeMem(BitmapImage)
    END
  END {PrintBitmap};


  //========================================================================


  FUNCTION CreateMaxwellTriangle(CONST size:  INTEGER;
                                 CONST TriangleIndex:  INTEGER;
                                 CONST xFlag, yFlag, zFlag:  BOOLEAN;
                                 CONST FillFlag:  BOOLEAN;
                                 VAR BlueCorner,
                                     GreenCorner,
                                     RedCorner:  TPoint):  TBitmap;
    TYPE
      TPosition = (posCenter, posXaxis, posYaxis);

    VAR
      i          :  INTEGER;
      iLeft      :  INTEGER;
      iRight     :  INTEGER;
      iR,iG,iB   :  INTEGER;
      j          :  INTEGER;
      jR,jG,jB   :  INTEGER;
      MaxFraction:  DOUBLE;
      Offset     :  INTEGER;
      row        :  pRGBTripleArray;
      s          :  STRING;
      x          :  DOUBLE;
      xMax       :  DOUBLE;
      y          :  DOUBLE;
      z          :  DOUBLE;

    PROCEDURE DecileLines (CONST Canvas:  TCanvas;
      CONST iMiddle, jMiddle, i1,j1, i2,j2:  INTEGER;
      CONST red, green, blue:  INTEGER;
      CONST Position:  TPosition);

      VAR
        k    :  INTEGER;
        iA,iB:  INTEGER;
        jA,jB:  INTEGER;
        s    :  STRING;
    BEGIN
      FOR k := 10 DOWNTO 0 DO
      BEGIN
        IF   FillFlag
        THEN Canvas.Pen.Color := clSilver
        ELSE Canvas.Pen.Color :=
               RGB( MulDiv(red,  10-k,10),
                    MulDiv(green,10-k,10),
                    MulDiv(blue, 10-k,10) );

        iA := iMiddle + MulDiv(i1-iMiddle, k, 10);
        iB := iMiddle + MulDiv(i2-iMiddle, k, 10);

        jA := jMiddle + MulDiv(j1-jMiddle, k, 10);
        jB := jMiddle + MulDiv(j2-jMiddle, k, 10);

        Canvas.MoveTo(iA,jA);
        Canvas.LineTo(iB,jB);

        IF   FillFlag
        THEN Canvas.Font.Color := clDkGray
        ELSE Canvas.Font.Color := RGB(red, green, blue);
        s := Format('%.1f', [ (10-k) / 10 ]);

        CASE Position OF
          posCenter:
            Canvas.TextOut((iA+iB) DIV 2 - Canvas.TextWidth(s)  DIV 2,
                         (jA+jB) DIV 2 - Canvas.TextHeight(s) DIV 2, s);

          posXaxis:
            Canvas.TextOut((iA+iB) DIV 2 - Canvas.TextWidth(s)  DIV 2,
                            jB + Canvas.TextHeight(s) DIV 4, s);

          posYaxis:
            Canvas.TextOut( iA - 3*Canvas.TextWidth(s) DIV 2,
                           (jA+jB) DIV 2 - Canvas.TextHeight(s) DIV 2, s);
        END;

      END
    END {DecileLines};


  BEGIN

    IF   TriangleIndex = 0          // Equilateral Triangle
    THEN BEGIN
      iB := MulDiv(Size,  2, 100);
      iR := MulDiv(Size, 98, 100);
      iG := MulDiv(Size, 50, 100);
      // Center top-to-bottom based on equilateral triangle
      Offset := Round(Size - (iR - iB)*SQRT(3)/2) DIV 2;
      jB := size - Offset;
      jR := size - Offset;
      jG := Offset;
    END
    ELSE BEGIN                      // Right Triangle
      iB := MulDiv(Size, 10, 100);
      iR := MulDiv(Size, 90, 100);
      iG := iB;

      jB := MulDiv(Size, 90, 100);
      jR := jB;
      jG := MulDiv(Size, 10, 100)
    END;

    RESULT := TBitmap.Create;
    RESULT.Width  := size;
    RESULT.Height := size;
    RESULT.PixelFormat := pf24bit;

    RESULT.Canvas.Brush.Color := clBtnFace;
    RESULT.Canvas.FillRect(RESULT.Canvas.ClipRect);

    RESULT.Canvas.Pen.Color := clWhite;
    RESULT.Canvas.MoveTo (iR,jR);
    RESULT.Canvas.LineTo (iG,jG);
    RESULT.Canvas.LineTo (iB,jB);
    RESULT.Canvas.LineTo (iR,jR);

    RESULT.Canvas.Brush.Style := bsClear;

    IF  FillFlag
    THEN BEGIN

      FOR j := jG TO jB DO
      BEGIN
        row := RESULT.Scanline[j];

        xMax := (j - jG) / (jB - jG);
        y := 1.0 - xMax;      //  y = 1.0 for j = jG; 0.0 for j = jB

        iLeft  := ROUND(iG + xMax*(iB - iG));
        iRight := ROUND(iG + xMax*(iR - iG));

        IF  iRight > iLeft
        THEN BEGIN

          FOR i := iLeft TO iRight DO
          BEGIN
            x := xMax * (i - iLeft) / (iRight - iLeft);
            z := 1.0 - x - y;

            // Given fractions x,y,z such that x + y + z = 1.0,
            // assign RGB components = 255 * fraction / max [x,y,z].
            // So, equal-energy white is (x,y,z) = (1/3, 1/3, 1/3),
            // which is converted to RGB color (255, 255, 255)

            maxFraction := MaxValue([x, y, z]);

            WITH row[i] DO
            BEGIN
               rgbtRed   := ROUND( 255 * x/maxFraction );
               rgbtGreen := ROUND( 255 * y/maxFraction );
               rgbtBlue  := ROUND( 255 * z/maxFraction );
            END
          END

        END

      END

    END;

    IF   xFlag
    THEN BEGIN
      RESULT.Canvas.Font.Height := MulDiv(size, 4, 100);
      IF   TriangleIndex = 0
      THEN BEGIN
        DecileLines (RESULT.Canvas, iR,jR, iG,jG, iB,jB, 255,   0,   0, posCenter);
        RESULT.Canvas.Font.Height := MulDiv(size, 6, 100);
        RESULT.Canvas.TextOut( (iB+iG) DIV 2 - 2*RESULT.Canvas.TextWidth('x'),
                               (jB+jG) DIV 2 - RESULT.Canvas.TextHeight('x'), 'x')
      END
      ELSE BEGIN
        DecileLines (RESULT.Canvas, iR,jR, iG,jG, iB,jB, 255,   0,   0, posXAxis);
        RESULT.Canvas.Font.Height := MulDiv(size, 6, 100);
        RESULT.Canvas.TextOut( (iB+iR) DIV 2,
                               MulDiv(Size,99,100) - RESULT.Canvas.TextHeight('x'),
                               'x')
      END
    END;

    IF   yFlag
    THEN BEGIN
      RESULT.Canvas.Font.Height := MulDiv(size, 4, 100);
      IF   TriangleIndex = 0
      THEN BEGIN
        DecileLines (RESULT.Canvas, iG,jG, iB,jB, iR,jR,   0, 255,   0, posCenter);
        RESULT.Canvas.Font.Height := MulDiv(size, 6, 100);
        RESULT.Canvas.TextOut( (iB+iR) DIV 2 - RESULT.Canvas.TextWidth('y') DIV 2,
                               (jB+jR) DIV 2, 'y')
      END
      ELSE BEGIN
        DecileLines (RESULT.Canvas, iG,jG, iB,jB, iR,jR,   0, 255,   0, posYaxis);
        RESULT.Canvas.Font.Height := MulDiv(size, 6, 100);
        RESULT.Canvas.TextOut( MulDiv(Size, 1,100),
                               (jG + jR) DIV 2 - RESULT.Canvas.TextHeight('y') DIV 2,
                               'y')
      END

    END;

    IF   zFlag
    THEN BEGIN
      RESULT.Canvas.Font.Height := MulDiv(size, 4, 100);
      DecileLines (RESULT.Canvas, iB,jB, iG,jG, iR,jR,   0,   0, 255, posCenter);
      RESULT.Canvas.Font.Height := MulDiv(size, 6, 100);
      RESULT.Canvas.TextOut( (iG+iR) DIV 2 + RESULT.Canvas.TextWidth('z'),
                             (jG+jR) DIV 2 - RESULT.Canvas.TextHeight('z'),  'z');
    END;

    RESULT.Canvas.Font.Height := MulDiv(size, 6, 100);

    RESULT.Canvas.Font.Color := clRed;
    s := 'Red';
    IF   TriangleIndex = 0
    THEN i := iR - RESULT.Canvas.TextWidth(s)
    ELSE i := iR - RESULT.Canvas.TextWidth(s) DIV 2;
    RESULT.Canvas.TextOut(i, jR + RESULT.Canvas.TextHeight(s) DIV 2,  s);

    RESULT.Canvas.Font.Color := clLime;
    s := 'Green';
    IF   TriangleIndex = 0
    THEN i := iG - RESULT.Canvas.TextWidth(s) DIV 2
    ELSE i := MulDiv(Size,1,100);
    RESULT.Canvas.TextOut(i, jG - 3*RESULT.Canvas.TextHeight(s) DIV 2,  s);

    RESULT.Canvas.Font.Color := clBlue;
    s := 'Blue';
    IF   TriangleIndex = 0
    THEN i := iB
    ELSE i := MulDiv(Size,1,100);
    RESULT.Canvas.TextOut(i, jB + RESULT.Canvas.TextHeight(s) DIV 2,  s);

    BlueCorner  := Point(iB, jB);
    GreenCorner := Point(iG, jG);
    RedCorner   := Point(iR, jR)
  END {CreateMaxwellTriangle};


  //========================================================================

PROCEDURE TFormMaxwellTriangle.UpdateEverything;
  VAR
    Bitmap:  TBitmap;
BEGIN
  Bitmap := CreateMaxwellTriangle(Image.Width,
                ComboBoxTriangle.ItemIndex,
                CheckBoxDecileX.Checked,
                CheckBoxDecileY.Checked,
                CheckBoxDecileZ.Checked,
                CheckBOxFill.Checked,
                BlueCorner, GreenCorner, RedCorner);
  TRY
    Image.Picture.Graphic := Bitmap;
  FINALLY
    Bitmap.Free
  END;
END;


procedure TFormMaxwellTriangle.FormCreate(Sender: TObject);
begin
  ComboBoxTriangle.ItemIndex := 0;
  UpdateEverything
end;


procedure TFormMaxwellTriangle.CheckBoxClick(Sender: TObject);
begin
  UpdateEverything
end;


procedure TFormMaxwellTriangle.ButtonSaveToFileClick(Sender: TObject);
  CONST
    ImageSizeForFile = 512;

  VAR
    Bitmap     :  TBitmap;
    BlueCorner :  TPoint;    // don't use points that MouseMove knows about
    GreenCorner:  TPoint;
    RedCorner  :  TPoint;
BEGIN
  IF   SavePictureDialog.Execute
  THEN BEGIN
    Bitmap := CreateMaxwellTriangle(ImageSizeForFile,
                                    ComboBoxTriangle.ItemIndex,
                                    CheckBoxDecileX.Checked,
                                    CheckBoxDecileY.Checked,
                                    CheckBoxDecileZ.Checked,
                                    CheckBoxFill.Checked,
                                    BlueCorner, GreenCorner, RedCorner);

    TRY
      Bitmap.SavetoFile(SavePictureDialog.Filename);
      ShowMessage('File ' + SavePictureDialog.Filename + ' written.')
    FINALLY
      Bitmap.Free
    END

  END
end;


procedure TFormMaxwellTriangle.ButtonPrintClick(Sender: TObject);
CONST
    ImageSizeForFile = 1024;
    iMargin =  8;  //  8% margin left and right
    jMargin = 10;  // 10% margin top and bottom

  VAR
    Bitmap             :  TBitmap;
    BlueCorner         :  TPoint;   // don't use points that MouseMove knows about
    GreenCorner        :  TPoint;
    iFromLeftMargin    :  INTEGER;
    iPrintedImageWidth :  INTEGER;
    jFromPageMargin    :  INTEGER;
    jPrintedImageHeight:  INTEGER;
    RedCorner          :  TPoint;
    s                  :  STRING;
    TargetRectangle    :  TRect;
begin
  Printer.Orientation := poPortrait;

  Bitmap := CreateMaxwellTriangle(ImageSizeForFile,
                                  ComboBoxTriangle.ItemIndex,
                                  CheckBoxDecileX.Checked,
                                  CheckBoxDecileY.Checked,
                                  CheckBoxDecileZ.Checked,
                                  CheckBoxFill.Checked,
                                  BlueCorner, GreenCorner, RedCorner);
  TRY
    Printer.BeginDoc;
    TRY
      iFromLeftMargin := MulDiv(Printer.PageWidth,  iMargin, 100);
      jFromPageMargin := MulDiv(Printer.PageHeight, jMargin, 100);

      iPrintedImageWidth  := MulDiv(Printer.PageWidth, 100-2*iMargin, 100);
      jPrintedImageHeight := iPrintedImageWidth;  // Aspect ratio is 1 for these images

      TargetRectangle := Rect(iFromLeftMargin, jFromPageMargin,
                              iFromLeftMargin + iPrintedImageWidth,
                              jFromPageMargin + jPrintedImageHeight);

      // Header
      Printer.Canvas.Font.Size := 14;
      Printer.Canvas.Font.Name := 'Arial';
      Printer.Canvas.Font.Color := clBlack;
      Printer.Canvas.Font.Style := [fsBold];
      s := 'Maxwell Triangle';
      Printer.Canvas.TextOut(
        (Printer.PageWidth - Printer.Canvas.TextWidth(s)) DIV 2,  // center
        jFromPageMargin - 3*Printer.Canvas.TextHeight(s) DIV 2,
        s);

      // Bitmap
      PrintBitmap(Printer.Canvas, TargetRectangle, Bitmap);

      // Footer
      Printer.Canvas.Font.Size := 12;
      Printer.Canvas.Font.Name := 'Arial';
      Printer.Canvas.Font.Color := clBlue;
      Printer.Canvas.Font.Style := [fsBold, fsItalic];
      s := 'efg''s Computer Lab';
      Printer.Canvas.TextOut(iFromLeftMargin,
                             Printer.PageHeight -
                             Printer.Canvas.TextHeight(s),
                             s);

      Printer.Canvas.Font.Style := [fsBold];
      s := 'www.efg2.com/lab';
      Printer.Canvas.TextOut(Printer.PageWidth -
                             iFromLeftMargin   -
                             Printer.Canvas.TextWidth(s),
                             Printer.PageHeight -
                             Printer.Canvas.TextHeight(s),
                             s)
    FINALLY
      Printer.EndDoc
    END;

  FINALLY
    Bitmap.Free
  END;

  ShowMessage ('Image Printed')
end;


procedure TFormMaxwellTriangle.CheckBoxLabelsClick(Sender: TObject);
begin
  UpdateEverything
end;


procedure TFormMaxwellTriangle.FormMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  LabelRGB.Caption := ''
end;

procedure TFormMaxwellTriangle.ImageMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
  VAR
    a,b,c,d      :  Double;
    xChromaticity:  Double;
    yChromaticity:  Double;
    zChromaticity:  Double;
    RHS1,RHS2    :  Double;
    determinant  :  Double;
begin
  // Not worth optimizing this

  // 2-by-2 determinant coefficients
  a := RedCorner.X    - BlueCorner.X;
  b := GreenCorner.X  - BlueCorner.X;
  c := RedCorner.Y    - BlueCorner.Y;
  d := GreenCorner.Y  - BlueCorner.Y;
  determinant := a*d - b*c;

  IF   ABS(determinant) < 0.00001
  THEN BEGIN
    LabelRGB.Caption := 'Invalid Triangle Specified'
  END
  ELSE BEGIN
    RHS1 := X - BlueCorner.X;
    RHS2 := Y - BlueCorner.Y;

    xChromaticity := (RHS1 * d - RHS2 * b   ) / determinant;
    yChromaticity := (a * RHS2 - c    * RHS1) / determinant;
    zChromaticity := 1.0 - xChromaticity - yChromaticity;

    IF   (xChromaticity < 0.0) OR
         (yChromaticity < 0.0) OR
         (zChromaticity < 0.0)
    THEN LabelRGB.Caption := 'Outside of Gamut'
    ELSE  LabelRGB.Caption := Format('(x,y,z) = (%.3f,%.3f,%.3f)',
            [xChromaticity, yChromaticity, zChromaticity])
  END
end;

end.
