unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Crt;


const
       A = 2;       {Fahrzeugquerschnitt [m^2]}
      cw = 0.33;    {cw Wert}
      Pl = 1.1885;  {spezifische Luftmasse bei 1bar und 20°C [kg/m^3]}
     mue = 0.015;   {Reibungskoeffizient}
      mf = 1500;    {Fahrzeugmasse [kg]}
       g = 9.81;    {Erdbeschleunigung [m/s^2]}
  deltat = 0.0001;  {Zeitinkrement}
 maxmess = 3000;    {obere Array Grenze mit Sicherheit; gilt für: deltat>=0.0001
                     v>=40km/h und ktewert>=5000}
 ktewert = 5000;    {nur jeder "ktewert" wird in die Datei geschrieben
                     10000=messwert/sek, 5000=messwert/0.5sek}
     eps = 0.00001; {Epsilon für Real Genauigkeit}


{'oeffentliche' Variablen}
var
  eta, p, v: double;
  modus,vergleichswitch:boolean;
  filename:string;


procedure initialisieren(var eta,p,v:double;var filename:string;
                         var modus:boolean);
procedure warten;
procedure titel;
procedure menu(var vergleichswitch:boolean);
procedure parameter_listen;
procedure parameter_aendern;
procedure modus_waehlen(var abort:boolean);
procedure leistung_waehlen(var p:double; var abort:boolean);
procedure geschwindigkeit_waehlen(var v:double);
procedure daten_ueberschreiben(var x,y:array of double; var j:integer;
                               filename:string);
procedure daten_schreiben(var filename:string);
procedure variablen_berechnen(var Beschleunigung, Verzoegerung,Luftwiderstand,
                                  Rollreibung, Hangabtriebskraft, idle:double);
procedure plotmenu(var multiplot:boolean);
procedure diagramm_plotten;
procedure ergebnis_ausgeben(Gesamtenergie,Gesamtzeit,Gesamtstrecke:double;
                            modus:boolean);
procedure vergleich(var modus:boolean; var eta:double; var filename:string);
procedure Energie_berechnen(var Gesamtenergie,Gesamtzeit,Gesamtstrecke:double;
                            var x,y:Array of double; var j,k:integer;
                            var vergleichswitch:boolean);
procedure beschleunigen_bergauf(var Gesamtenergie,Gesamtzeit,Gesamtstrecke:
                              double; var x,y:Array of double; var j,k:integer);
procedure konstant_bergauf(var Gesamtenergie, Gesamtzeit, Gesamtstrecke: double;
                                    var x,y:Array of double; var j,k:integer);
procedure bremsen_bergauf(var Gesamtenergie, Gesamtzeit, Gesamtstrecke: double;
                                    var x,y:Array of double; var j,k:integer);
procedure beschleunigen_gerade(var Gesamtenergie, Gesamtzeit, Gesamtstrecke:
                              double; var x,y:Array of double; var j,k:integer);
procedure konstant_gerade(var Gesamtenergie, Gesamtzeit, Gesamtstrecke: double;
                                    var x,y:Array of double; var j,k:integer);
procedure beschleunigen_bergab(var Gesamtenergie, Gesamtzeit, Gesamtstrecke:
                              double; var x,y:Array of double; var j,k:integer);
procedure konstant_bergab(var Gesamtenergie, Gesamtzeit, Gesamtstrecke: double;
                                    var x,y:Array of double; var j,k:integer);
procedure bremsen(var Gesamtenergie, Gesamtzeit, Gesamtstrecke: double;
                                    var x,y:Array of double; var j,k:integer);


implementation

{'private' Variablen}
var
  Beschleunigung,Verzoegerung,Luftwiderstand,Rollreibung,Hangabtriebskraft,
  Gesamtenergie, Gesamtzeit, Gesamtstrecke, idle:double;
  abort, multiplot:boolean;
  j,k: integer;                     {modus: false=Diesel/true=Elektro}
  x,y: array [0..maxmess] of double;


{##############################################################################}
{                               Initialisierung                                }
{##############################################################################}

procedure initialisieren(var eta,p,v:double;var filename:string;
                         var modus:boolean);

begin
  eta:=0.32; p:=50000; v:=13.89;
  filename:='Dieseldaten.dat'; modus:=false;
end; {initialisieren}


{##############################################################################}
{                                   warten                                     }
{##############################################################################}

procedure warten;

begin
 writeln;
 write('<Enter> zum fortfahren...');
 readkey; // da readlns nicht beachtet wurden
end; {warten}


{##############################################################################}
{                                    Titel                                     }
{##############################################################################}

procedure titel;

begin
 writeln('*******************************************************************',
          '************');
 writeln('*                Antriebsvergleich: Diesel- gegen Elektroantrieb',
          '              *');
 writeln('*******************************************************************',
          '************');
end; {titel}


{##############################################################################}
{                                    Menue                                     }
{##############################################################################}

procedure menu(var vergleichswitch:boolean);

var
  auswahl:byte;

begin
  try
  clrscr;
  titel;
  parameter_listen;
  writeln('Was moechten Sie tun?');
  writeln('1: Simulation starten     2: automatischer Vergleich');
  writeln('3: Parameter aendern      4: Diagramm plotten');
  writeln('5: Programm beenden');
  writeln();
  write('Eingabe: ');
  read(auswahl);
  case auswahl of
    1: begin
        vergleichswitch:=false; {-> Rueckkehr ins Menue nach Energie_berechnen}
        Energie_berechnen(Gesamtenergie,Gesamtzeit,Gesamtstrecke,x,y,j,k,
                          vergleichswitch);
       end; {1}
    2: begin
        vergleichswitch:=true; {-> Energie_berechnen laeuft vollstaendig durch}
        vergleich(modus,eta,filename);
        menu(vergleichswitch);
       end; {2}
    3: parameter_aendern;
    4: plotmenu(multiplot);
    5: exit;
    else
     begin
      writeln('Ungueltige Wahl! Bitte Zahl zwischen 1 und 5 eingeben.');
      warten;
      menu(vergleichswitch);
     end; {else}
  end; {case}
  except
    on e: exception do
     begin
      writeln('Ungueltige Wahl! Bitte Zahl zwischen 1 und 5 eingeben.');
      writeln('Error (menu): ' + e.message);
      warten;
      initialisieren(eta,p,v,filename,modus);
      menu(vergleichswitch);
     end; {e: exception}
  end; {try except}
end; {menu}


{##############################################################################}
{                                 Parameter listen                             }
{##############################################################################}

procedure parameter_listen;

begin
 writeln('Die aktuell eingestellten Parameter lauten: ');
 write('Modus: ');
  if modus = true then
   write('Elektromodus')
  else write('Dieselmodus');
 writeln('   Leistungsklasse: ',(p/1000):0:0,'kW',
         '   Sollgeschwindigkeit: ',(v*3.6):0:0,'km/h');
 writeln;
end; {parameter_listen}


{##############################################################################}
{                                 Parameter aendern                            }
{##############################################################################}

procedure parameter_aendern;

begin
 modus_waehlen(abort);
 if abort then menu(vergleichswitch)
 else
  begin
   leistung_waehlen(p,abort);
   if abort then menu(vergleichswitch)
   else
    begin
     geschwindigkeit_waehlen(v);
     menu(vergleichswitch);
    end; {inneres abort}
  end; {aeusseres abort}
end; {parameter_aendern}


{##############################################################################}
{                                 Modus waehlen                                }
{##############################################################################}

procedure modus_waehlen(var abort:boolean);

var
 auswahl:byte;

begin
 try
  abort:=false;
  clrscr;
  writeln('1: Dieselmodus   2: Elektromodus');
  writeln('3: zurueck zum Menue');
  writeln();
  write('Bitte Modus waehlen: ');
  read(auswahl);
  case auswahl of
    1: begin modus:=false; eta:=0.32; filename:='Dieseldaten.dat' end;
    2: begin modus:=true; eta:=0.68; filename:='Elektrodaten.dat' end;
    3: abort:=true
    else
     begin
      writeln;
      writeln('Ungueltige Wahl! Bitte 1, 2 oder 3 eingeben.');
      warten;
      modus_waehlen(abort);
     end; {else}
  end; {case}
 except
  on e: exception do
   begin
    writeln;
    writeln('Ungueltige Wahl! Bitte 1, 2 oder 3 eingeben.');
    writeln('Error (modus_waehlen): ' + e.message);
    warten;
    modus_waehlen(abort);
   end; {e: exception}
 end; {try except}
end; {modus_waehlen}


{##############################################################################}
{                                Leistung waehlen                              }
{##############################################################################}

procedure leistung_waehlen(var p:double; var abort:boolean);

var
  auswahl:byte;

begin
  try
  clrscr;
  writeln('1: 30kW   2: 50kW   3: 60kW');
  writeln('4: zurueck zum Menue');
  writeln();
  Write('Bitte Leistungsklasse waehlen: ');
  read(auswahl);
  case auswahl of
    1: p:=30000;
    2: p:=50000;
    3: p:=60000;
    4: abort:=true
    else
     begin
      writeln;
      writeln('Ungueltige Wahl! Bitte Zahl zwischen 1 und 4 eingeben.');
      warten;
      leistung_waehlen(p,abort);
     end; {else}
  end; {case}
  except
    on e: exception do
     begin
      writeln;
      writeln('Ungueltige Wahl! Bitte Zahl zwischen 1 und 4 eingeben.');
      Writeln('Error (leistung_waehlen): ' + e.message);
      warten;
      leistung_waehlen(p,abort);
    end; {e: exception}
  end; {try except}
end; {leistung_waehlen}


{##############################################################################}
{                            Geschwindigkeit waehlen                           }
{##############################################################################}

procedure geschwindigkeit_waehlen(var v:double);

var
 auswahl:byte;

begin
 try
  clrscr;
  writeln('1: 40km/h   2: 50km/h   3: 60km/h');
  writeln('4: zurueck zum Menue');
  writeln();
  write('Bitte Sollgeschwindigkeit waehlen: ');
  read(auswahl);
  case auswahl of
    1:
     v:=11.11;
    2:
     v:=13.89;
    3:
     if p=30000 then
      begin
       clrscr;
       writeln('Die gewaehlte Motorleistung (',(p/1000):0:0,'kW) ist fuer',
               ' diese Geschwindigkeit zu gering.');
       writeln('Bitte waehlen sie 40km/h oder 50km/h');
       warten;
       geschwindigkeit_waehlen(v);
      end
     else
      v:=16.67;
    4:
     writeln();
    else
     begin
      writeln;
      writeln('Ungueltige Wahl! Bitte Zahl zwischen 1 und 4 eingeben.');
      warten;
      geschwindigkeit_waehlen(v);
     end; {else}
  end; {case}
 except
    on e: exception do
     begin
      writeln;
      writeln('Ungueltige Wahl! Bitte Zahl zwischen 1 und 4 eingeben.');
      writeln('Error (geschwindigkeit_waehlen): ' + e.message);
      warten;
      geschwindigkeit_waehlen(v);
     end; {e: exception}
 end; {try except}
end; {geschwindigkeit_waehlen}


{##############################################################################}
{                             Daten ueberschreiben                             }
{##############################################################################}

procedure daten_ueberschreiben(var x,y:array of double; var j:integer;
                               filename:string);

var
 i:integer;
 F:Textfile;

begin
 try
  i:=1; k:=ktewert;
  AssignFile(F, filename);
  Rewrite(F);
  while i<j do
   begin
    write(F, x[i],' ');
    writeln(F, (y[i]/1000));  //Umrechnung von J in kJ
    i:=i+1;
   end;
  CloseFile(F);
  writeln();
  writeln('Datei wurde als "',filename,'" im Programmverzeichnis',
          ' gespeichert.');
  warten;
 except
  on e: exception do
     begin
      writeln('Error (daten_ueberschreiben): ' + e.message);
      warten;
      daten_ueberschreiben(x,y,j,filename);
     end; {e: exception}
 end; {try except}
end; {daten_ueberschreiben}


{##############################################################################}
{                                Daten schreiben                               }
{##############################################################################}

procedure daten_schreiben(var filename:string);

var
 F:Textfile;
 auswahl:integer;

begin
 try
  AssignFile(F, filename);
   if FileExists(filename) then
    begin
     writeln();
     writeln('Datei existiert bereits. Ueberschreiben?  1: Ja   2: Nein');
     write('Eingabe: ');
     readln(auswahl);
     case auswahl of
      1:
       daten_ueberschreiben(x,y,j,filename);
      2:
       begin
        writeln();
        writeln('Schreibvorgang abgebrochen');
        warten;
       end; {2}
      else
       begin
        writeln();
        writeln('Ungueltige Wahl! Bitte 1 fuer Ja oder 2 fuer Nein eingeben.');
        warten;
        writeln();
        daten_schreiben(filename);
       end; {else}
     end; {case}
    end {if FileExists(filename)}
   else
     daten_ueberschreiben(x,y,j,filename);
 except
  on e: exception do
     begin
      writeln('Ungueltige Wahl! Bitte 1 fuer Ja oder 2 fuer Nein eingeben.');
      writeln('Error (daten_schreiben): ' + e.message);
      warten;
      daten_schreiben(filename);
     end; {e: exception}
 end; {try except}
end; {daten_schreiben}


{##############################################################################}
{                              variablen berechnen                             }
{##############################################################################}

procedure variablen_berechnen(var Beschleunigung, Verzoegerung,Luftwiderstand,
                                  Rollreibung, Hangabtriebskraft, idle:double);

begin
    Beschleunigung := (v*v)/600;
      Verzoegerung := (v*v)/400;
    Luftwiderstand := 0.5*A*Cw*Pl;  //nur der konstante Faktor, ohne v^2 !
       Rollreibung := mue*mf*g;     //cos(a)=0.9992≈1, deshalb vernachlaessigt
 Hangabtriebskraft := mf*g*(0.04);
              idle := p*0.2*deltat; //Leerlaufenergie
end; {variablen_berechnen}


{##############################################################################}
{                                   Plotmenü                                   }
{##############################################################################}

procedure plotmenu(var multiplot:boolean);

var
 auswahl:byte;
 mode:string;

begin
 try
  clrscr;
  if modus then mode:='(Elektromodus)'
  else mode:='(Dieselmodus)';
  writeln('1: Einzeldiagramm plotten  2: Vergleichsdiagramm plotten  ',
          '3: zurueck zum Menue');
  writeln('   ',mode);
  writeln();
  write('Bitte Plotmodus waehlen: ');
  readln(auswahl);
  case auswahl of
   1:
    begin
     multiplot:=false;
     diagramm_plotten;
    end; {1}
   2:
    begin
     multiplot:=true;
     diagramm_plotten;
    end; {2}
   3: menu(vergleichswitch)
   else
    begin
     writeln('Ungueltige Wahl! Bitte 1, 2 oder 3 eingeben.');
     warten;
     plotmenu(multiplot);
    end; {else}
  end; {case}
 except
   on e: exception do
     begin
      writeln('Ungueltige Wahl! Bitte 1, 2 oder 3 eingeben.');
      writeln('Error (plotmenu): ' + e.message);
      warten;
      plotmenu(multiplot);
    end; {e: exception}
 end; {try except}
end; {plotmenu}


{##############################################################################}
{                               Diagramm plotten                               }
{##############################################################################}

procedure diagramm_plotten;

var
 diagramm:string;

begin
 try
  if multiplot=false then
   begin
    if modus = true then
     if fileexists(filename) then
      begin
       diagramm := 'skripte/oeffneE.bat';
       SysUtils.ExecuteProcess('gnuplot/bin/wgnuplot.exe',
                               ['skripte/Elektroplot.plt']);
      end {fileexists(filename)}
     else
      begin
      writeln('Die benoetigte Datendatei "',filename,'" konnte nicht gefunden',
              ' werden!');
      writeln('Kehre ins Hauptmenue zurueck...');
      warten;
      menu(vergleichswitch);
      end {else}
    else {modus = false}
     if fileexists(filename) then
      begin
       diagramm := 'skripte/oeffneD.bat';
       SysUtils.ExecuteProcess('gnuplot/bin/wgnuplot.exe',
                               ['skripte/Dieselplot.plt']);
      end {fileexists(filename)}
     else
      begin
      writeln('Die benoetigte Datendatei "',filename,'" konnte nicht gefunden',
              ' werden!');
      writeln('Kehre ins Hauptmenue zurueck...');
      warten;
      menu(vergleichswitch);
      end; {else}
   end {multiplot=false}
  else {multiplot=true}
   if fileexists('Dieseldaten.dat') or fileexists('Elektrodaten.dat') then
    begin
     diagramm := 'skripte/oeffneM.bat';
     SysUtils.ExecuteProcess('gnuplot/bin/wgnuplot.exe',
                             ['skripte/Multiplot.plt']);
    end {fileexists('Dieseldaten.dat') or fileexists('Elektrodaten.dat')}
   else
    begin
     writeln('Es wurde keine Datendatei gefunden!');
     writeln('Kehre ins Hauptmenue zurueck...');
     warten;
     menu(vergleichswitch);
    end; {else}
  SysUtils.ExecuteProcess(diagramm,[]);
  menu(vergleichswitch);
 except
   on e: exception do
    begin
     writeln('Error (diagramm_plotten): ' + e.message);
     warten;
     plotmenu(multiplot);
    end; {e: exception}
 end; {try except}
end; {diagramm_plotten}


{##############################################################################}
{                               Ergebnis ausgeben                              }
{##############################################################################}

procedure ergebnis_ausgeben(Gesamtenergie,Gesamtzeit,Gesamtstrecke:double;
                            modus:boolean);

begin
 writeln();
 writeln('---------------------------------------------------------');
 write('Modus: ':15);
 if modus = true then writeln('Elektromodus':12) else writeln('Dieselmodus':12);
 writeln('Gesamtenergie: ', (Gesamtenergie / 1000):9:3, ' kJ':3);
 writeln('Gesamtstrecke: ', Gesamtstrecke:9:0, ' m':3);
 writeln('Gesamtzeit: ':15, Gesamtzeit:9:0, ' s':3);
 writeln('---------------------------------------------------------');
end; {ergebnis_ausgeben}


{##############################################################################}
{                                   Vergleich                                  }
{##############################################################################}

procedure vergleich(var modus:boolean; var eta:double; var filename:string);

var
 GesamtenergieAlt,GesamtenergieDiff:double;
 MAlt,MNeu:string;

begin
 GesamtenergieAlt:=0; GesamtenergieDiff:=0;
 Energie_berechnen(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k,
                   vergleichswitch);
 GesamtenergieAlt:=Gesamtenergie;                          //letzte Werte merken
 if modus = true then
  begin modus:=false; eta:=0.32; filename:='Dieseldaten.dat';
  MAlt:='Energieverbrauch Elektro: '; MNeu:='Energieverbrauch Diesel: '; end
 else {modus = false}                                           //Modus wechseln
  begin modus:=true; eta:=0.68; filename:='Elektrodaten.dat';
  MAlt:='Energieverbrauch Diesel: '; MNeu:='Energieverbrauch Elektro: '; end;
 Energie_berechnen(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k,
                   vergleichswitch);
 GesamtenergieDiff:= abs(GesamtenergieAlt-Gesamtenergie);

 writeln();
 writeln('---------------------------------------------------------');
 writeln(MAlt:26, (GesamtenergieAlt/1000):9:3, ' kJ':3);
 writeln(MNeu:26, (Gesamtenergie/1000):9:3, ' kJ':3);
 writeln('------------':38);
 writeln('Gesamtenergiedifferenz: ':26,(GesamtenergieDiff/1000):9:3,' kJ':3);
 writeln;
 writeln('Gesamtstrecke: ':26, Gesamtstrecke:9:0, ' m':3);
 writeln('Gesamtzeit: ':26, Gesamtzeit:9:0, ' s':3);
 writeln('---------------------------------------------------------');
 warten;
end; {vergleich}


{##############################################################################}
{                               Energie berechnen                              }
{##############################################################################}

procedure Energie_berechnen(var Gesamtenergie,Gesamtzeit,Gesamtstrecke:double;
                            var x,y:Array of double; var j,k:integer;
                            var vergleichswitch:boolean);

begin
 Gesamtenergie:=0; Gesamtzeit:=0; Gesamtstrecke:=0; k:=ktewert;
 j:=0; x[j]:=0; y[j]:=0; j:=j+1;
 variablen_berechnen(Beschleunigung, Verzoegerung, Luftwiderstand, Rollreibung,
                     Hangabtriebskraft, idle);
 beschleunigen_gerade(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k);
 konstant_gerade(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k);
 bremsen(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k);              //  1km
 beschleunigen_gerade(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k);
 konstant_gerade(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k);
 bremsen(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k);              //  2km
 beschleunigen_gerade(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k);
 konstant_gerade(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k);
 bremsen(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k);              //  3km
 beschleunigen_bergauf(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k);
 konstant_bergauf(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k);
 if abs(v-16.67)<eps then {real Genauigkeit macht sonst Probleme (eig. v=16.67)}
  bremsen(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k)
 else
  bremsen_bergauf(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k);     //  4km
 beschleunigen_bergauf(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k);
 konstant_bergauf(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k);
 if abs(v-16.67)<eps then
  bremsen(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k)
 else
  bremsen_bergauf(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k);     //  5km
 beschleunigen_bergab(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k);
 konstant_bergab(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k);
 bremsen(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k);              //  6km
 beschleunigen_bergab(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k);
 konstant_bergab(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k);
 bremsen(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k);              //  7km
 beschleunigen_gerade(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k);
 konstant_gerade(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k);
 bremsen(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k);              //  8km
 beschleunigen_gerade(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k);
 konstant_gerade(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k);
 bremsen(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k);              //  9km
 beschleunigen_gerade(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k);
 konstant_gerade(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k);
 bremsen(Gesamtenergie, Gesamtzeit, Gesamtstrecke,x,y,j,k);              // 10km
 ergebnis_ausgeben(Gesamtenergie, Gesamtzeit, Gesamtstrecke, Modus);
 daten_schreiben(filename);
 if vergleichswitch=false then menu(vergleichswitch);
end; {Energie_berechnen}


{##############################################################################}
{                             beschleunigen bergauf                            }
{##############################################################################}

procedure beschleunigen_bergauf(var Gesamtenergie,Gesamtzeit,Gesamtstrecke:
                              double; var x,y:Array of double; var j,k:integer);

var
  Strecke, t, E_Bereich, Energie: double;

begin
  E_Bereich := 0;
  Strecke := 0;
  Energie := 0;
  t := 0;
  if modus=false then
    while Strecke <= 300 do
     begin
      Strecke := 0.5 * Beschleunigung * t * t;
      {  Energiegleichungen bestehen aus
        [Kräfte*Weg]/Wirkungsgrad + Leerlaufenergie (nur beim Diesel) }
      Energie := (((mf*Beschleunigung+Luftwiderstand*(Beschleunigung*t)*
                   (Beschleunigung*t)+Rollreibung+Hangabtriebskraft)*
                  ((Beschleunigung*t)*deltat))/eta)+idle;
      t := t + deltat;
      E_Bereich := E_Bereich + Energie;
      if k=ktewert then
       begin
        x[j]:=Gesamtstrecke+Strecke;
        y[j]:=Gesamtenergie+E_Bereich;
        j:=j+1;
        k:=0;
       end; {k=ktewert}
      k:=k+1;
     end  {end if modus=false}
  else  {modes=true}
    while Strecke <= 300 do
     begin
      Strecke := 0.5 * beschleunigung * t * t;
      Energie := (((mf*beschleunigung+Luftwiderstand*(beschleunigung*t)*
                   (beschleunigung*t)+Rollreibung+Hangabtriebskraft)*
                  ((beschleunigung*t)*deltat))/eta);
      t := t + deltat;
      E_Bereich := E_Bereich + Energie;
      if k=ktewert then
       begin
        x[j]:=Gesamtstrecke+Strecke;
        y[j]:=Gesamtenergie+E_Bereich;
        j:=j+1;
        k:=0;
       end; {k=ktewert}
      k:=k+1;
     end;  {end if modus=true}
  Gesamtstrecke := Gesamtstrecke + Strecke;
  Gesamtzeit := Gesamtzeit + t;
  Gesamtenergie := Gesamtenergie + E_Bereich;
end; {beschleunigen_bergauf}


{##############################################################################}
{                           konstante Fahrt bergauf                            }
{##############################################################################}

procedure konstant_bergauf(var Gesamtenergie, Gesamtzeit, Gesamtstrecke: double;
                           var x,y:Array of double; var j,k:integer);

var
  Strecke, t, E_Bereich, Energie: double;

begin
  E_Bereich := 0;
  Strecke := 0;
  Energie := 0;
  t := 0;
  if modus=false then
    while Strecke <= 500 do
     begin
      Strecke := v * t;
      Energie := (((Luftwiderstand*v*v+Rollreibung+Hangabtriebskraft)*
                   (v*deltat))/eta)+idle;
      t := t + deltat;
      E_Bereich := E_Bereich + Energie;
      if k=ktewert then
       begin
        x[j]:=Gesamtstrecke+Strecke;
        y[j]:=Gesamtenergie+E_Bereich;
        j:=j+1;
        k:=0;
       end; {k=ktewert}
      k:=k+1;
     end  {end if modus=false}
  else  {modes=true}
    while Strecke <= 500 do
     begin
      Strecke := v * t;
      Energie := (((Luftwiderstand*v*v+Rollreibung+Hangabtriebskraft)*
                   (v*deltat))/eta);
      t := t + deltat;
      E_Bereich := E_Bereich + Energie;
      if k=ktewert then
       begin
        x[j]:=Gesamtstrecke+Strecke;
        y[j]:=Gesamtenergie+E_Bereich;
        j:=j+1;
        k:=0;
       end; {k=ktewert}
      k:=k+1;
     end;  {end if modus=true}
  Gesamtstrecke := Gesamtstrecke + Strecke;
  Gesamtzeit := Gesamtzeit + t;
  Gesamtenergie := Gesamtenergie + E_Bereich;
end; {konstant_bergauf}


{##############################################################################}
{                                bremsen bergauf                               }
{##############################################################################}

procedure bremsen_bergauf(var Gesamtenergie, Gesamtzeit, Gesamtstrecke: double;
                                    var x,y:Array of double; var j,k:integer);
var
  Strecke, t, E_Bereich, Energie: double;
begin
  E_Bereich := 0;
  Strecke := 0;
  Energie := 0;
  t := 0;
  if modus=false then
    while abs(Strecke-200)>=eps do {hier wird eig. Strecke <= 199.99999 geprüft}
     begin
      Strecke := -0.5*Verzoegerung*t*t + v*t;
      Energie := (((Luftwiderstand*(v-Verzoegerung*t)*(v-Verzoegerung*t)
                    +Rollreibung+Hangabtriebskraft)*((v-Verzoegerung*t)*deltat))
                    /eta)+idle;
      t := t + deltat;
      E_Bereich := E_Bereich + Energie;
      if k=ktewert then
       begin
        x[j] := Gesamtstrecke+Strecke;
        y[j] := Gesamtenergie+E_Bereich;
        j:=j+1;
        k:=0;
       end; {k=ktewert}
      k:=k+1;
     end  {end if modus=false}
  else {modus=true}
    while abs(Strecke-200)>=eps do {hier wird eig. Strecke <= 199.99999 geprüft}
     begin
      Strecke := -0.5*Verzoegerung*t*t + v*t;
      Energie := (((Luftwiderstand*(v-Verzoegerung*t)*(v-Verzoegerung*t)
                   +Rollreibung+Hangabtriebskraft)*((v-Verzoegerung*t)*deltat))
                    /eta);
      t := t + deltat;
      E_Bereich := E_Bereich + Energie;
      if k=ktewert then
       begin
        x[j] := Gesamtstrecke+Strecke;
        y[j] := Gesamtenergie+E_Bereich;
        j:=j+1;
        k:=0;
       end; {k=ktewert}
      k:=k+1;
     end;  {end if modus=true}
  Gesamtstrecke := Gesamtstrecke + Strecke;
  Gesamtzeit := Gesamtzeit + t;
  Gesamtenergie := Gesamtenergie + E_Bereich;
end; {bremsen_bergauf}


{##############################################################################}
{                         beschleunigen gerade Strecke                         }
{##############################################################################}

procedure beschleunigen_gerade(var Gesamtenergie,Gesamtzeit,Gesamtstrecke:
                               double;var x,y:Array of double; var j,k:integer);

var
  Strecke, t, E_Bereich, Energie: double;

begin
  E_Bereich := 0;
  Strecke := 0;
  Energie := 0;
  t := 0;
  if modus=false then
    while Strecke <= 300 do
     begin
      Strecke := 0.5 * Beschleunigung * t * t;
      Energie := (((mf*Beschleunigung+Luftwiderstand*(Beschleunigung*t)*
                   (Beschleunigung*t)+Rollreibung)*((Beschleunigung*t)*deltat))
                   /eta)+idle;
      t := t + deltat;
      E_Bereich := E_Bereich + Energie;
      if k=ktewert then
       begin
        x[j]:=Gesamtstrecke+Strecke;
        y[j]:=Gesamtenergie+E_Bereich;
        j:=j+1;
        k:=0;
       end; {k=ktewert}
      k:=k+1;
     end  {end if modus=false}
  else {modus=true}
    while Strecke <= 300 do
     begin
      Strecke := 0.5 * Beschleunigung * t * t;
      Energie := (((mf*Beschleunigung+Luftwiderstand*(Beschleunigung*t)*
                   (Beschleunigung*t)+Rollreibung)*((Beschleunigung*t)*deltat))
                   /eta);
      t := t + deltat;
      E_Bereich := E_Bereich + Energie;
      if k=ktewert then
       begin
        x[j]:=Gesamtstrecke+Strecke;
        y[j]:=Gesamtenergie+E_Bereich;
        j:=j+1;
        k:=0;
       end; {k=ktewert}
      k:=k+1;
     end;  {end if modus=true}
  Gesamtstrecke := Gesamtstrecke + Strecke;
  Gesamtzeit := Gesamtzeit + t;
  Gesamtenergie := Gesamtenergie + E_Bereich;
end; {beschleunigen_gerade}


{##############################################################################}
{                         konstante Fahrt gerade Strecke                       }
{##############################################################################}

procedure konstant_gerade(var Gesamtenergie, Gesamtzeit, Gesamtstrecke: double;
                          var x,y:Array of double; var j,k:integer);

var
  Strecke, t, E_Bereich, Energie: double;

begin
  E_Bereich := 0;
  Strecke := 0;
  Energie := 0;
  t := 0;
  if modus=false then
    while Strecke <= 500 do
     begin
      Strecke := v * t;
      Energie := (((Luftwiderstand*v*v+Rollreibung)*(v*deltat))/eta)+idle;
      t := t + deltat;
      E_Bereich := E_Bereich + Energie;
      if k=ktewert then
       begin
        x[j]:=Gesamtstrecke+Strecke;
        y[j]:=Gesamtenergie+E_Bereich;
        j:=j+1;
        k:=0;
       end; {k=ktewert}
      k:=k+1;
     end  {end if modus=false}
  else {modus=true}
    while Strecke <= 500 do
     begin
      Strecke := v * t;
      Energie := (((Luftwiderstand*v*v+Rollreibung)*(v*deltat))/eta);
      t := t + deltat;
      E_Bereich := E_Bereich + Energie;
      if k=ktewert then
       begin
        x[j]:=Gesamtstrecke+Strecke;
        y[j]:=Gesamtenergie+E_Bereich;
        j:=j+1;
        k:=0;
       end; {k=ktewert}
      k:=k+1;
     end;  {end if modus=true}
  Gesamtstrecke := Gesamtstrecke + Strecke;
  Gesamtzeit := Gesamtzeit + t;
  Gesamtenergie := Gesamtenergie + E_Bereich;
end; {konstant_gerade}


{##############################################################################}
{                             beschleunigen bergab                             }
{##############################################################################}

procedure beschleunigen_bergab(var Gesamtenergie, Gesamtzeit, Gesamtstrecke:
                              double; var x,y:array of double; var j,k:integer);

var
  Strecke, t, E_Bereich, E_Bereich2, Energie: double;

begin {Ebene 0 auf}
 E_Bereich := 0;
 E_Bereich2 := 0;
 Strecke := 0;
 Energie := 0;
 t := 0;
 if modus=false then {Ebene 1 auf}
  begin
   while Strecke <= 300 do {Ebene 2 auf}
    begin
     if v=11.11 then {Ebene 3 auf}
      begin
       Strecke := 0.5 * Beschleunigung * t * t;
       t := t + deltat;
       E_Bereich := E_Bereich + idle;
       if k=ktewert then {Ebene 4 auf}
        begin
         x[j]:=Gesamtstrecke+Strecke;
         y[j]:=Gesamtenergie+E_Bereich;
         j:=j+1;
         k:=0;
        end; {if k=ktewert, Ebene 4 zu}
       k:=k+1;
      end {if v=11.11, Ebene 3 zu}
     else {else if v=11.11, Ebene 3 auf}
      begin
       Strecke := 0.5 * Beschleunigung * t * t;
       Energie := (((mf*Beschleunigung+Luftwiderstand*(Beschleunigung*t)*
                    (Beschleunigung*t)+Rollreibung-Hangabtriebskraft)*
                   ((Beschleunigung*t)*deltat))/eta)+idle;
       t := t + deltat;
       E_Bereich := E_Bereich + Energie;
       E_Bereich2 := E_Bereich2 + idle;
       if k=ktewert then {Ebene 4 auf}
        begin
         x[j] := Gesamtstrecke+Strecke;
         if E_Bereich>0 then {Ebene 5 auf}
          y[j] := Gesamtenergie+E_Bereich
         else
          y[j] := Gesamtenergie+E_Bereich2; {Ebene 5 zu}
         j:=j+1;
         k:=0;
        end; {Ebene 4 zu}
       k:=k+1;
      end; {else if v=11.11, Ebene 3 zu}
    end; {Strecke <= 300}
  end {modus=false}
 else { modus=true, Ebene 1 auf}
  begin
   while Strecke <= 300 do {Ebene 2 auf}
    begin
     if v=11.11 then   //Energie bleibt konstant {Ebene 3 auf}
      begin
       Strecke := 0.5 * Beschleunigung * t * t;
       t := t + deltat;
       if k=ktewert then {Ebene 4 auf}
        begin
         x[j]:=Gesamtstrecke+Strecke;
         y[j]:=Gesamtenergie;
         j:=j+1;
         k:=0;
        end; {Ebene 4 zu}
       k:=k+1;
      end {if v=11.11, Ebene 3 zu}
     else {else if v=11.11, Ebene 3 auf}
      begin
       Strecke := 0.5 * Beschleunigung * t * t;
       Energie := (((mf*Beschleunigung+Luftwiderstand*(Beschleunigung*t)*
                    (Beschleunigung*t)+Rollreibung-Hangabtriebskraft)*
                   ((Beschleunigung*t)*deltat))/eta);
       t := t + deltat;
       E_Bereich := E_Bereich + Energie;
       //E_Bereich2 steht auf 0 und aendert sich hier nicht
       if k=ktewert then {Ebene 4 auf}
        begin
         x[j] := Gesamtstrecke+Strecke;
         if E_Bereich>0 then {Ebene 5 auf}
          y[j] := Gesamtenergie+E_Bereich
         else
          y[j] := Gesamtenergie; {Ebene 5 zu}
         j:=j+1;
         k:=0;
        end; {if k=ktewert, Ebene 4 zu}
       k:=k+1;
      end; {else if v=11.11, Ebene 3 zu}
    end; {while Strecke<=300, Ebene 2 zu}
  end; {end if modus=true, Ebene 1 auf}
 Gesamtstrecke := Gesamtstrecke + Strecke;
 Gesamtzeit := Gesamtzeit + t;
 if E_Bereich>0 then
  Gesamtenergie := Gesamtenergie + E_Bereich
 else
  Gesamtenergie := Gesamtenergie + E_Bereich2;
end; {beschleunigen_bergab, Ebene 0 zu}


{##############################################################################}
{                           konstante Fahrt bergab                             }
{##############################################################################}

procedure konstant_bergab(var Gesamtenergie, Gesamtzeit, Gesamtstrecke: double;
                          var x,y:array of double; var j,k:integer);

var
  Strecke, t, E_Bereich: double;

begin
  E_Bereich := 0;
  Strecke := 0;
  t := 0;
  if modus=false then
    while Strecke <= 500 do
     begin
      Strecke := v * t;
      t := t + deltat;
      E_Bereich := E_Bereich + idle;
      if k=ktewert then
       begin
        x[j]:=Gesamtstrecke+Strecke;
        y[j]:=Gesamtenergie+E_Bereich;
        j:=j+1;
        k:=0;
       end; {k=ktewert}
      k:=k+1;
     end  {end if modus=false}
  else  {modus=true}
    while Strecke <= 500 do
     begin
      Strecke := v * t;
      t := t + deltat;
      if k=ktewert then
       begin
        x[j]:=Gesamtstrecke+Strecke;
        y[j]:=Gesamtenergie;
        j:=j+1;
        k:=0;
       end; {k=ktewert}
      k:=k+1;
     end;  {end if modus=true}
  Gesamtstrecke := Gesamtstrecke + Strecke;
  Gesamtzeit := Gesamtzeit + t;
  Gesamtenergie := Gesamtenergie + E_Bereich
end; {konstant_bergab}


{##############################################################################}
{                                    bremsen                                   }
{##############################################################################}

procedure bremsen(var Gesamtenergie, Gesamtzeit, Gesamtstrecke: double;
                  var x,y:Array of double; var j,k:integer);

var
  Strecke, t, E_Bereich: double;

begin
  E_Bereich := 0;
  Strecke := 0;
  t := 0;
  if modus=false then
   while abs(Strecke-200)>=eps do  {hier wird eig. Strecke <= 199.99999 geprüft}
    begin
     Strecke := v*t - 0.5*Verzoegerung*t*t;
     t := t + deltat;
     E_Bereich := E_Bereich + idle;
     if k=ktewert then
      begin
       x[j]:=Gesamtstrecke+Strecke;
       y[j]:=Gesamtenergie+E_Bereich;
       j:=j+1;
       k:=0;
      end; {k=ktewert}
     k:=k+1;
    end  {modus=false}
  else  {modus=true}
   while abs(Strecke-200)>=eps do
    begin
     Strecke := v*t - 0.5*Verzoegerung*t*t;
     t := t + deltat;
     if k=ktewert then
      begin
       x[j]:=Gesamtstrecke+Strecke;
       y[j]:=Gesamtenergie;
       j:=j+1;
       k:=0;
      end; {k=ktewert}
     k:=k+1;
    end;  {modus=true}
  Gesamtstrecke := Gesamtstrecke + Strecke;
  Gesamtzeit := Gesamtzeit + t;
  Gesamtenergie := Gesamtenergie + E_Bereich
end; {bremsen}


end.{uMain}
