program Antriebsvergleich;

{$mode objfpc}{$H+}

uses {$IFDEF UNIX} {$IFDEF UseCThreads}
  cthreads, {$ENDIF} {$ENDIF}
  Classes,
  Crt,
  Sysutils,
  uMain { you can add units after this };

{$R *.res}

begin
  initialisieren(eta,p,v,filename,modus);
  menu(vergleichswitch);
end. {Antriebsvergleich}

