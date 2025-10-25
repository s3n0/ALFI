{  AUTHOR:  s3n0, 1999   }
{  Vykreslovanie ciar horizontalnymi a vertikalnymi krokmi + dvihanim/sputanim pera :  (pre Alfik-a)  }
{  Obsluzny program na otestovanie funkcnosti  }

{$M 16384,0,0}

{$N+,E-}


uses
    Crt, Alfi ;              { obsahuje procedury gotoXY, ClrScr, Delay, writeln a este ine co ja potrebujem }


var
     TXA : string;
  KK, JJ : mfloat;


procedure KresliVlny;
var
   h  : array[1..256] of real;
   i  : word;
   z,f1,f2,m,p,w,k1,
   r,g,af,bm,k,c,s,
   xo0,yo0,xo1,yo1,
   x2,  y2, x1, y1,
   dx, dy,
   qx, qy     : mfloat;
   drv, mode  : integer;
label
   Hop1,Hop2;

begin

 asm   mov ax,19;  int $10;  end;

 p:=1080;  k1:=80;
 w:=75;    k:=0.75;
 xo0:=128;  yo0:=83;  bm:=(PI / 180);
 c:=k * COS(w * bm);  s:=k * SIN(w * bm);
 dx:=3;  dy:=5;  af:=p/90;
 for i:=1 to 256 do h[i] := -1000;
 g:=-110;

 repeat
 qy:=g * af;
 m:=-105;
       repeat
       qx:= m * af;
       r:= sqrt(qx * qx + qy * qy) * bm;
       IF r = 0 THEN z:= k1 ELSE z:= k1 * (SIN(r) / r);
       xo1 := INT(xo0 + m + c * g + 0.5);
       yo1 := INT(yo0 + s * g + z + 0.5);
       IF m > -105 THEN GOTO Hop1;
       f1 := 0; i := round(xo1 / dx);
       IF yo1 >= h[i + 1] THEN begin f1 := 1; h[i + 1] := yo1; end;
       x1 := xo1; y1 := yo1;
       GOTO Hop2;
Hop1:  f2 := 0; i := round(xo1 / dx);
       IF yo1 >= h[i + 1] THEN begin f2 := 1; h[i] := yo1; end;
       x2 := xo1; y2 := yo1;
       IF (f1 * f2) = 1 THEN
          begin
                Presun(  x1*3 , y1*3   );
             PeroDole;
                Presun(  x2*3 , y2*3   );
             PeroHore;
          end;
       x1 := x2;  y1 := y2;  f1 := f2;
Hop2:  m:= m + dx;
       until m>105;
 g:= g + dy;
 until g>110;

end;






procedure KresliKruh;
var
  Q : mfloat;
begin
  Q:=2 * PI;
  Presun( 0,0 );
  repeat
      Presun( round(sin(Q)*70) , round(cos(Q)*70)   );
      PeroDole;
      Q:=Q - 0.03;
  until Q <= 0;
  PeroHore;
end;









BEGIN
   ClrScr;
   writeln(' left+    up     +right ');
   writeln('       7   8   9        ');
   writeln('left   4   5   6   right');
   writeln('       1   2   3        ');
   writeln(' left+    down   +right ');
   writeln('~+~ pero pise');
   writeln('~-~ pero nepise');
   writeln('~F1~ reset Alfi-ho (X=0=Y)');
   writeln('~F2~ presun na [ 0; 0 ]');
   writeln('~F3~ kresli zadanu ciaru');
   writeln('~F4~ nakresli kruh');
   writeln('~F5~ testuj kresbu ciary');
   writeln('~F6~ nakresli vlny-obrazok');
   writeln('~F7~ pis daco');
   writeln('~F8~ pis text');
       ResetAlfi;      ciarka:=20;
   writeln('~F9~ velkost pisma = ',ciarka );
   writeln('~ESC~ koniec');


   repeat
       asm  mov ax,$0C00;   int $21;   end;      { reset buferu klavesnice }
       case port[$60] of
              75 : Presun( x-5 , y   );
              77 : Presun( x+5 , y   );
              72 : Presun( x   , y-5 );
              80 : Presun( x   , y+5 );
              78 : PeroDole;
              74 : PeroHore;
              71 : Presun( x-5 , y-5 );
              73 : Presun( x+5 , y-5 );
              79 : Presun( x-5 , y+5 );
              81 : Presun( x+5 , y+5 );
              67 : begin
                      gotoXY(22,16);   write('     ');
                      gotoXY(22,16);   readln( ciarka );
                   end;
              66 : begin
                      gotoXY( 1,22 );
                      write('text > ');
                      readln( TXA );
                      veta( TXA );
                   end;
              65 : veta('Sk£çam'+chr(7)+chr(10)+chr(13)+'O.k.') ;
              64 : KresliVlny;
              63 : begin
                      PeroDole;
                      Presun( x+80, y+50 );
                      PeroHore;
                      PeroDole;
                      Presun(    x, y-50 );
                      PeroHore;
                   end;
              62 : KresliKruh;
              61 : begin
                      gotoXY(1,22);
                      writeln('                  ');
                      writeln('                  ');
                      gotoXY(1,22);
                      write('x=');   readln(KK);
                      write('y=');   readln(JJ);
                      PeroHore;  Presun( 0,0 );
                      PeroDole;  Presun( KK, JJ );
                      PeroHore;
                   end;
              60 : Presun( 0, 0);
              59 : ResetAlfi;
             end ;
       Vysielaj;
       gotoXY( 60, 1  );    writeln('scan kod=',port[$60],'     ');
       gotoXY(  1, 18 );    writeln('             X=',X,'          Y=',Y  );
       for B:=19 to 24 do write('                                                                           ');
   until port[$60] = 01;

   PeroHore;
   port[BA]:=$00;
   writeln('- nastavenie ~Alfika~ naprogramoval:   Michal DLUGOS, s3n0 @ 1999, Poprad');
END.


