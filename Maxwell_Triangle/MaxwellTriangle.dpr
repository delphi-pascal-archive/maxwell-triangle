//  ColorMix:  Additive and Subtractive Colors
//  efg, January 1999

program MaxwellTriangle;

uses
  Forms,
  ScreenMaxwellTriangle in 'ScreenMaxwellTriangle.pas' {FormMaxwellTriangle};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFormMaxwellTriangle, FormMaxwellTriangle);
  Application.Run;
end.
