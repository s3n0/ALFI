{$M 16384,0,0}
{$F+,N+,E-}

uses
   Alfi, Dos ;

var
    TLAC : boolean;
     BUF : string;



procedure SedemNast( flags,CS,IP,AX,BX,CX,DX,DI,SI,DS,ES,BP:word);  interrupt;
begin

  { testujem vlastne pozadovanu sluzbu v reg.AH }
  case ($FF00 and AX) of
        $0000 : if TLAC=false then
                   begin
                      TLAC:=True;
                      if 27 = ord(BUF[1]) then
                                       begin
                                         Veta( BUF + chr(AX and $00FF)  );
                                         AX  := AX and $FF00 ;
                                         BUF := ''   ;
                                       end;
                      if 27 = (AX and $00FF) then
                                       begin
                                         BUF := chr(27)  ;
                                         AX  := AX and $FF00;
                                       end;
                      Veta(  chr(AX and $00FF)  );
                      TLAC:=False;
                   end;
        $0100 : begin  ResetAlfi;  TLAC:=false;   BUF:='';   end;
      end;

   { inac stale je pozadovany status v reg.AH, takze ho teraz nastavym }
   AX:=($00FF and AX) or $9000;     { normalny status = tlaciaren pripravena }

   if (X > 1140)
      then  Veta( chr(10)+chr(13)  );    { urobim enter pri fest dlhom riadku }
   if (Y > 1720)
      then  AX:=AX or $B000;         { Paper Out = ziadat vymenu papiera ! }
   if TLAC=true
      then  AX:=AX and $7FFF;        { Busy = tlaciaren zaneprazdnena (tlacou)}

   if port[$60]=01 then begin  PeroHore;  AX:=AX or $0800;  end;    { I/O error, alebo koniec tlace po stlaceni ESC }

end;







BEGIN
   writeln;
   writeln('(c)1999, Michal Dlugos, Poprad');
   writeln('Ovladac pre vystup textu na suradnicovy zapisovac ALFI na prerusenie INT 17H');
   writeln('s podporou kodovej stranky LATIN2 :');

   SetIntVec( $17, Addr(SedemNast)  );
   ResetAlfi;
   writeln('Instalovany...');
   Keep(0);
END.


