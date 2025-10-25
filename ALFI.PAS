{  AUTHOR:  s3n0, rok 1999   }
{  Suradnicovy zapisovac - horizontalnymi a vertikalnymi krokmi + nadvihovanie pera:  (pre Alfik-a)  }


Unit Alfi;

{$F+,D-,I-,S-,N+,E-}





interface




uses    Crt ;                   { obsahuje proceduru Delay }

type    mfloat = extended ;     { zakladny typ, ktory sa pouziva pre vypocty s Alfikom }

procedure ResetAlfi;                           { nastavy zakladne hodnoty }
procedure Presun( newX, newY   : mfloat );     { linearny presun pera }
procedure Veta(ss : string);                   { napise na Alfiku vetu }
procedure PeroHore;                            { pero nebude pisat }
procedure PeroDole;                            { pero bude pisat }
{ dalsie procedury uz nenachadzaju vseobecne pouzitie v programoch }
procedure Vysielaj;                            { vykona vystup dat na Alfik }
procedure SetDown;                             { nastavovanie dalsieho kroku }
procedure SetUp;
procedure SetLeft;
procedure SetRight;
procedure Znak(ZN : char);                     { vystup znaku, pouziva sa iba s procedurou Veta }
procedure Pipni;                               { pipnutie reproduktoru PC }


var    X, Y   : mfloat;      { globalne zakladne suradnice Alfiho [pre pero]  }
  newX,newY   : mfloat;      { toto su pomocne suradnice v procedure Presun }
    portRAM   : byte;        { ako docasna bunka pre LPT port - pre posuv oboch motorov !sucasne!  }
     ciarka   : word;        { velkost [vektorov] fontu Alfiku }
        vel   : mfloat;      { pouziva sa pri zmenach a riadeni kreslenia pismen }
    A,B,F,H   : word;        { pouzivam na vselico, napr. ako pocitac cyklov alebo priamo u prikazu FOR }
       RYCH   : word;        { pouzijem na vypocitanie rychlosti vysielania signalov [D0 az D7 = pre krok.motory]  }
         BA   : word;        { adresa I/O portu = LPT1 vystup na Alfika prvy, zakladny bajt,resp.register prvy pre LPT1 port}

  smerX, smerY   : boolean;  { log.0 [false] = krok bude -1   /   log.1 [true] = krok bude +1 }
 schodX, schodY  : integer;  { vypocet velk. jedneho schodu a test, ktory s velkostou 1, bude zacinat posuvanie schodiku }
   pocX,  pocY,              { pocet krokov pre X a Y }
  skokX, skokY,              { posun po osi X a Y - vzdy jedna os je rovna hodnote 1 a druha je vypocitany SkokX/SkokY }
    zaX, zaY     : mfloat;   { toto je na docasne zalohovanie pri kresleni }

    tex : word;
     cq : word;
     bu : word;

{ ukazatele tu niesu, bude sa samo zistovat, kde naposledy skoncil Alfik  }
{ opatovnym citanim / osahavanim portu LPT - ako pomocny bajt (8bit) pre  }
{ LPT port sluzi premenna portRAM, aby som mohol sucasne pohybovat oboma  }
{ krokovymi motormy, az po nastaveni tohoto portRAM ho vysielam na port   }
{ aj spustene/zdvihnute pero sa bude zistovat citanim bitu na porte LPT1  }

const           { hodnoty casovania impulzov do krokovych motorv podla CPU, ako priklad pre Pentium 100 MHz, su nasledovne:  }
     X_RYCH  :  word =   7;          {  15 = pauza pri posuve po osi X    }
     Y_RYCH  :  word =  12;          {  27 = pauza pri posuve po osi Y    }
  dole_RYCH  :  word = 110;          { 160 = pauza PO polozeni pera       }
  hore_RYCH  :  word = 120;          { 430 = pauza PO zdvihnuti pera - lebo pero lahke abo fixa podskoci po uvolneni releee  }
     CIEVKY  :  array[0..9] of byte
             = (  $88 , $99,$11,$55,$44,$66,$22,$AA,$88 , $99  );

{ no... v datovej premennej CIEVKY je ulozene 4-bitove riadenie krokoveho }
{ motora pouziteho v Alfiku, a pretoze pri posuvani motora na dalsi krok  }
{ vyuzivam port, z ktoreho si zistim posledny krok [posledne nastavenie   }
{ 4-bitov cize 4-cievok] a potom po najdeni 4-och, naposledy zapisanych   }
{ bitov, nastavujem na vystupe portu LPT1 krok z dalsieho, nasledujuceho  }
{ kroku, a teda ak sa stane, ze zisteny bol uz posledny krok v datovom poli,  }
{ tak som este na konci pola zaradil jeden krok, rovnaky ako je prvy, aby }
{ som nemusel vsetko mozne menit (otestovat poslednu polozku a z osmej    }
{ preskocit na prvu) tak aj pri zapisovani noveho kroku je pouzite jednoduche }
{ precitanie z pola ako - posledna polozka + 1  a presne tak aj jeden     }
{ bajt na zaciatku je okopirovany, ktory by mal nasledovat pri odcitavani,}
{ poloziek v poli - totizto vzdy sa vykonava hladanie a porovnavanie s    }
{ s LPT portom smerom doprava od polozky 1 do 8 - ak sa najde uz polozka  }
{ cislo 1 a bude treba na motor poslat predchadzajuci krok , tak sa aj    }
{ precita polozka cislo 0, a ak opacne bude uz posledna polozka cislo 8   }
{ na porte LPT, tak pripadny krok ak treba nasledujuci, tak sa odoberie s }
{ polozky cislo 9   }

    MekcenStred : string = ('ÁüúßÂ     sctzn');       { prevodne tabulky pre:  LATIN 2  <=>  ASCII }
     MekcenHore : string = ('Ê¨õ¶’ñ‘   SCTZNld');
     DlzenStred : string = ('Ï†Ç¢£°    yaeou'+chr(25) );
      DlzenHore : string = ('Ìµ÷ê‡Èëí   YAIEOULl');

      pocet = 1734 ;

       TAB  : array[1..pocet] of byte = (

{a}   97, 8,13, 6, 5,13, 6, 6,12, 2, 2, 4, 4,13, 8, 9, 6, 6, 0, 2, 2,255
{b}  ,98, 8, 8, 5, 2, 2,13, 6, 6, 9, 8, 7, 4, 4, 0, 3, 3, 2, 6,255
{c}  ,99,13, 6,12, 6, 5, 4,13, 7, 8, 9,12, 6, 0,13, 2, 2, 2,255
{d} ,100,12, 6,13, 6,11, 8, 8, 5, 2, 2,13, 4, 4, 7, 8, 9, 6, 6, 0, 2, 2, 2,255
{e} ,101,13, 6, 8, 8, 5, 6, 6, 7, 4, 1, 2, 3, 6, 6, 0,255
{f} ,102,13, 5, 8, 8, 8, 6, 6, 4, 4, 8, 8, 9, 6, 0, 2, 2, 2, 2, 2, 2,255
{g} ,103,13, 2, 5, 6, 6, 6, 8, 8, 8, 8, 4, 4, 1, 2, 3, 6, 6, 0,255
{h} ,104, 8, 8, 5, 2, 2,13, 8, 8, 9, 6, 3, 2, 2, 0,255
{i} ,105,13, 6, 5,   12, 8,13, 8, 0, 8, 8, 5, 0, 2, 2, 3,12, 2,255
{j} ,106,13, 5, 3, 8,12, 8,13, 8, 0, 8, 8, 5, 0, 2, 2, 3,12, 2,255
{k} ,107, 5, 8, 8, 0, 2,12, 6, 5, 1, 3, 0,255
{l} ,108, 8, 8,13, 6,11, 5, 2, 2, 0,13, 6,255
{m} ,109,13, 5, 8, 8, 9, 6, 2, 2, 2, 8, 8, 9, 6, 2, 2, 2, 0,255
{n} ,110,13, 5, 8, 8, 8, 6, 6, 3, 2, 2, 0,255
{o} ,111,13, 6, 5, 6, 9, 8, 7, 4, 1, 2, 3, 0, 6, 6,255
{p} ,112,13, 5, 2, 2, 8, 8, 8, 8, 8, 6, 6, 3, 2, 1, 4, 4, 0, 6, 6, 6,255
{q} ,113,13, 6, 6, 6, 5, 4, 4, 7, 8, 9, 6, 3, 2, 2, 2, 2, 0, 8, 8,255
{r} ,114, 5, 8,13, 2, 2, 9, 9,12, 2, 0, 2,255
{s} ,115,13, 5, 6, 9, 7, 4, 9, 6, 0, 2, 2, 2,255
{t} ,116,13, 6, 6, 5,13, 4, 7, 8, 8, 8, 8, 2, 1, 6, 6, 0, 3, 2, 2, 255
{u} ,117,13, 8, 8, 8, 5, 2, 2, 2, 8, 3, 6, 8, 8, 8, 0, 2, 2, 2, 0,255
{v} ,118,15, 8, 8, 8, 8, 8, 5, 3, 2, 3, 2, 3, 9, 8, 9, 8, 9, 0, 2, 2, 2, 2, 2,255
{w} ,119,15, 8, 8, 8, 8, 8, 5, 3, 2, 3, 2, 3, 9, 8, 9, 8, 9, 0, 4, 4, 4, 4, 5, 3, 2, 3, 2, 3, 9, 8, 9, 8, 9, 0,2,2,2,2,2,255
{x} ,120,13, 5, 9, 9, 9, 0, 4, 4, 4, 5, 3, 3, 3, 0,255
{y} ,121,13, 8, 8, 8, 5, 2, 2, 3, 6, 9, 8, 8, 2, 2, 2, 1, 4, 4, 0, 6, 6, 9,255
{z} ,122,13, 8, 8, 8, 5, 6, 6, 1, 1, 2, 6, 6, 0,255
{}  ,123,13, 6, 6, 5, 4, 8, 8, 7, 9, 8, 8, 6, 0, 2, 2, 2, 2, 2, 2,255       {zatvorka}
{|} ,124,13, 5, 8, 8, 0, 8, 5, 8, 8, 0, 2, 2, 2, 2, 2,255
{}  ,125,13, 5, 6, 8, 8, 9, 7, 8, 8, 4, 0, 3, 3, 2, 2, 2, 2,255     {zatvorka}
{~} ,126,12, 8,13, 8, 5, 9, 3, 9, 0, 2, 2,12, 2,255

{ } ,$20, 6,255
{!} ,$21,12, 6, 5, 5, 0,13, 8,12, 8, 5, 8, 8, 0, 2, 2, 2,13, 2,255    {predlzujem cas bodky, bude vecsia ak sa kresli fixou}
{"} ,$22, 8, 8,13, 6, 5,12, 2, 0,13, 6, 5,12, 8, 0,11, 2, 2,255
{#} ,$23,12, 6, 5, 8, 8, 8, 8, 0, 1, 5, 6, 6, 6, 0, 7, 5, 2, 2, 2, 2, 0, 9, 5, 4, 4, 4, 0, 3, 6, 6,255
{}  ,$24,12, 8, 5, 6, 6, 8, 4, 4, 8, 6, 6, 4, 8, 2, 2, 2, 2, 0, 6,255     {dollar}
{%} ,$25,13, 5, 8, 9, 8, 9, 8, 0, 4, 4, 5, 0, 2, 6, 2, 6, 2, 2, 2, 5, 0,255
{&} ,$26,13,6,6,6,5,7,8,7,7,8,6,2,2,1,2,3,9,9,0,2,2,255
{'} ,$27,13, 6,12, 8, 8, 8, 5, 9, 0,13, 6,11, 2, 2,255
{(} ,$28,12, 6, 5, 7, 8, 8, 9, 0, 2, 2, 2, 3,255
{)} ,$29,12, 5, 9, 8, 8, 7, 0, 2, 2, 2, 3, 6,255
{*} ,$2A,12, 8, 8, 5, 6, 6, 0, 8, 5, 1, 1, 0, 6, 6, 5, 7, 7, 0, 6, 5, 2, 2, 0, 3,255
{+} ,$2B, 8, 5, 6, 0,12, 7, 5, 2, 2, 0, 3,255
{,} ,$2C,13, 9, 8, 6, 5, 2, 2, 1, 0, 9, 6,255
{-} ,$2D, 8, 5, 6, 0, 2,255
{.} ,$2E,12, 6, 5, 5, 0, 6,255
{/} ,$2F,12, 8, 5, 9, 9, 0, 8, 2, 2, 2, 2,255
{0} ,$30, 5, 8, 8, 6, 2, 2, 4,12, 8, 5, 9, 9, 0, 2, 2, 2,255
{1} ,$31,12, 6, 5, 8, 8, 8, 4, 6, 8, 0,11, 2, 2, 255
{2} ,$32, 8,12, 8, 5, 8,11, 6, 2, 1, 6, 0,255
{3} ,$33,12, 8, 5, 2, 6, 6, 8, 8, 4, 6, 8, 8, 4, 4, 2, 0, 2, 3, 3,255
{4} ,$34,12, 6, 5, 8, 8, 0, 3, 5, 4, 4, 8, 8, 8, 0, 3, 2, 3, 2,255
{5} ,$35,12, 8, 5, 2,11, 6, 8, 4, 8, 6, 0, 2, 2,255
{6} ,$36, 9, 8, 5, 4, 2, 2, 6, 8, 4, 0, 3,255
{7} ,$37, 8,12, 8, 5, 8,11, 6, 2, 1, 0, 6,255
{8} ,$38, 6, 5, 4, 8, 6, 8, 4, 2, 6, 2, 0,255
{9} ,$39, 5, 9, 8, 4, 2, 6, 0, 2,255
{:}  ,58,12, 9, 5, 0, 8, 8, 5, 0, 2, 2, 3,255
{;}  ,59,13, 9, 8, 6, 8, 8, 5, 0, 2, 2, 5, 2, 2, 1, 0, 9, 6,255
{<}  ,60,12, 6, 5, 7, 9, 0, 3, 2,255
{=}  ,61, 6,12, 8, 5, 4, 4, 0, 8, 5, 6, 6, 0, 2, 2,255
{>}  ,62,12, 6, 5, 9, 7, 0, 2, 3,255
{?}  ,63,12, 6, 5, 0, 8,13, 8, 5, 8,12, 9,13, 7, 4, 1, 0, 6, 6, 6, 2, 2,12, 2, 2,255
{@}  ,64,13, 9, 9, 5, 8, 8, 8, 4, 1, 2, 2, 6, 6, 6, 9, 8, 8, 7, 4, 4, 4, 1, 2, 2, 2, 2, 3, 6, 6, 0, 6, 255
{A}  ,65, 5, 8, 8, 6, 2, 2, 0, 7, 5, 6, 0, 2,255
{B}  ,66, 5, 6, 8, 4,13, 6, 6,11, 8,13, 4, 4,11, 2, 2, 0, 6,255
{C}  ,67, 6,13, 8, 5, 2,11, 4, 8, 8, 6,13, 2, 0, 8,11, 2, 2,255
{D}  ,68,13, 5, 6,11, 8, 8,13, 4, 6,11, 6, 2, 2, 4, 0, 6,255
{E}  ,69, 6, 5, 4, 8,12, 6, 4,11, 8, 6, 0, 2, 2, 255
{F}  ,70, 5, 8,12, 6, 4,11, 8, 6, 0, 2, 2,255
{G}  ,71, 5, 6, 8,12, 4, 6, 0,11, 8,13, 5, 2, 8,11, 4, 2, 2, 0, 6,255
{H}  ,72, 5, 8, 8, 0, 6, 5, 2, 4, 6, 2, 0,255
{I}  ,73, 5, 8, 8, 0, 2, 2,255
{J}  ,74,12, 8, 5, 2,11, 6, 8, 8, 0, 2, 2,255
{K}  ,75, 5, 8, 8, 0, 6, 5, 1, 3, 0,255
{L}  ,76, 8, 8, 5, 2, 2, 6, 0,255
{M}  ,77, 5, 8, 8,12, 2, 3, 9, 8,11, 2, 2, 0,255
{N}  ,78, 5, 8, 8,12, 2,11, 3,12, 8,11, 8, 2, 2, 0,255
{O}  ,79, 5, 6, 8, 8, 4, 2, 2, 0, 6,255
{P}  ,80, 5, 8, 8, 6, 2, 4, 0, 3,255
{Q}  ,81, 5, 8, 8, 6, 2, 2, 4, 0,12, 9, 5, 3, 0,255
{R}  ,82, 5, 8, 8, 6, 2, 4, 3, 0,255
{S}  ,83,12, 8, 5, 2,11, 6, 8, 4, 8, 6,12, 2, 0, 2,11, 2,255
{T}  ,84,12, 6,11, 5, 8, 8,12, 4,11, 6, 0, 2, 2,255
{U}  ,85, 5, 8, 8, 0, 6, 5, 2, 2, 4, 0, 6,255
{V}  ,86, 8, 8, 5, 2,12, 2, 3, 9, 8,11, 8, 0, 2, 2,255
{W}  ,87, 8, 8, 5, 2,12, 2, 3, 9, 8, 0, 4, 5, 2, 3, 9, 8,11, 8, 0, 2, 2,255
{X}  ,88,12, 5, 8, 9, 9, 8, 0, 4, 4, 5, 2, 3, 3, 2, 0,255
{Y}  ,89,12, 6, 5, 8, 8, 7, 8, 0, 6, 6, 5, 2, 1, 0, 6, 2, 2,255
{Z}  ,90, 8, 8, 5, 6,12, 2,11, 1,12, 2,11, 6, 0,255
{[}  ,91,12, 6,13, 6, 5, 4,11, 8, 8,13, 6, 0, 6,11, 2, 2,255
{\}  ,92, 8, 8,12, 2, 5, 3, 3, 0, 2,255
{]}  ,93,12, 6,13, 4, 5, 6,11, 8, 8,13, 4, 0, 6, 6,11, 2, 2,255
{^}  ,94, 8,12, 8, 5, 9, 3, 0, 2, 2, 2,255
{_}  ,95, 5, 6, 0,255
{`}  ,96, 6, 5, 4,13, 6,11, 8,13, 4, 6, 6, 4, 8, 9, 3, 0, 8,11, 2,255      { fenig }
              { +++++++ slovenska diakritika ++++++++ }
{°}  ,25,13, 6, 5,12, 8,13, 8, 0, 3, 6,12, 2,255                   { kreslim male i bez bodky, aby bol pekne umiestneny dlzen }
{Á}  ,16, 8,13, 8, 8, 5, 3, 9, 0, 1, 1,11, 2,255                { mekcen na male pismo }
{Ê}  ,17, 8, 8,12, 6,13, 9, 5, 1, 7, 0, 3,12, 4,11, 2, 2,255    { mekcen na velke psimo }
{†}  ,18, 8,13, 9, 5, 9, 0, 1, 1,11, 2,255                      { dlzen na male pismo }
{µ}  ,19, 8, 8,13, 6, 5, 9, 0, 1, 4,11, 2, 2,255                { dlzen na velke pismo }
{Ñ}  ,20, 8,13, 9, 5, 5, 0, 6, 6, 5, 5, 0, 1, 4, 4,11, 2,255    { dve bodky pre male siroke a }
{é}  ,21, 8, 8,13, 9, 5, 5, 0, 6, 5, 5, 0, 4, 1,11, 2, 2,255    { dve bodky pre velke siroke A }
{‚}  ,23, 8, 8,12, 6,13, 4, 5, 9, 3, 0, 4,12, 4,11, 2, 2,255    { vokativ velkeho O }
{ì}  ,22, 8,12, 6,13, 9, 5, 7, 1, 0, 3,12, 4,11, 2,255          { vokativ maleho o }
);






implementation






procedure Pipni;
begin
   Sound(4800);    delay(200);     NoSound;
end;






procedure PeroDole;
begin

   asm
   push es
   xor  ax,ax
   mov  es,ax
   mov  ax,es:word ptr [$408]    { vyberem adresu pre LPT1 port - data bits }
   pop  es
   mov  BA,ax
   end;

   port[BA+2]:= 8;
   delay(DOLE_RYCH);         { pockam, aby stihol atrament z fixy prejst do papiera }
end;



procedure PeroHore;
begin

   asm
   push es
   xor  ax,ax
   mov  es,ax
   mov  ax,es:word ptr [$408]    { vyberem adresu pre LPT1 port - data bits }
   pop  es
   mov  BA,ax
   end;

   delay(1);         { dokreslim az uplny koniec ciarky, aby tu nezostali nedotiahnute konce }
   port[BA+2]:= 0;
   delay(hore_RYCH);     { pockam, lebo lahka fixa obycajne [bez pouzitia zavazia] podskoci po zdvihnuti }
end;

  {  !!! NASTAVENIE VELKOSTI CAKACYCH SMICIEK ZAVISI OD TOHO AKY JE HROT  }
  {  !!! KRESLIACEHO PERA, RYCHLY DOST NA TO, ABY VSETKO STIHAL BEZ       }
  {  !!! POCIATOCNYCH A KONCOVYCH NEDOTIAHNUTYCH, NEDOKRESLENYCH CIAR CI  }
  {  !!! VELKYCH, MACHULOVITYCH BODOV [PRI POUZIVANI FIXY]                }
  {  !!! A POTOM VELKOST PAUZI ZALEZI AJ OD RYCHLOSTI POSUVU MOTOROV !!!  }







procedure Vysielaj;         { procedurka pre vysilanie 8-bitoveho kodu na vystup BA portu }
begin

   asm
   push es
   xor  ax,ax
   mov  es,ax
   mov  ax,es:word ptr [$408]    { vyberem adresu pre LPT1 port - data bits }
   pop  es
   mov  BA,ax
   end;

   if (port[BA] and $F0) <> (portRAM and $F0) then RYCH:=Y_RYCH else RYCH:=X_RYCH ;
  {  if 8 = (8 and port[BA+2]) then RYCH:=RYCH+2 ;    }
   { ak sa bude hybat motorom pre posuv papiera, tak rychlost pripadneho     }
   { opakovania procedury Vysielaj musim spomalit, nakolko motor posuvajuci  }
   { papier kona vecsiu pracu lebo musi tlacit na papier a jeho cievky       }
   { potrebuju viacej elektrickej energie, dalej otestujem zdvih/spustenie   }
   { pera a aj podla toho upravujem rychlost a nakoniec uz vysielam pametovu }
   { bunku na vystup }
   port[BA] := portRAM;
   delay(RYCH);
end;





procedure SetDown;
begin

   asm
   push es
   xor  ax,ax
   mov  es,ax
   mov  ax,es:word ptr [$408]    { vyberem adresu pre LPT1 port - data bits }
   pop  es
   mov  BA,ax
   end;

    for A:= 1 to 8 do
      if (port[BA] and $F0) = (cievky[A] and $F0)
      then   portRAM := (portRAM and $0F)  or  (cievky[A-1] and $F0) ;
end;



procedure SetUp;
begin

   asm
   push es
   xor  ax,ax
   mov  es,ax
   mov  ax,es:word ptr [$408]    { vyberem adresu pre LPT1 port - data bits }
   pop  es
   mov  BA,ax
   end;

    for A:=1 to 8 do
      if (port[BA] and $F0)  =  (cievky[A] and $F0)
      then   portRAM := (portRAM and $0F)  or  (cievky[A+1] and $F0) ;
end;



procedure SetRight;
begin

   asm
   push es
   xor  ax,ax
   mov  es,ax
   mov  ax,es:word ptr [$408]    { vyberem adresu pre LPT1 port - data bits }
   pop  es
   mov  BA,ax
   end;

    for A:=1 to 8 do
      if (port[BA] and $0F) = (cievky[A] and $0F)
      then   portRAM := (portRAM and $F0)  or  (cievky[A+1] and $0F) ;
end;



procedure SetLeft;
begin

   asm
   push es
   xor  ax,ax
   mov  es,ax
   mov  ax,es:word ptr [408h]    { vyberem adresu pre LPT1 port - data bits }
   pop  es
   mov  BA,ax
   end;

    for A:=1 to 8 do
      if (port[BA] and $0F) = (cievky[A] and $0F)
      then   portRAM := (portRAM and $F0)  or  (cievky[A-1] and $0F) ;
end;









procedure ResetAlfi;
begin

   asm
   push es
   xor  ax,ax
   mov  es,ax
   mov  ax,es:word ptr [$408]    { vyberem adresu pre LPT1 port - data bits }
   pop  es
   mov  BA,ax
   end;

   Pipni;
   X:=0;
   Y:=0;
   PeroHore;
   ciarka:= 12;
   portRAM:= $99;
   port[BA]:=$99;
   Vysielaj;
end;










procedure Presun( newX, newY   : mfloat );
begin

   asm
   push es
   xor  ax,ax
   mov  es,ax
   mov  ax,es:word ptr [$408]    { vyberem adresu pre LPT1 port - data bits }
   pop  es
   mov  BA,ax
   end;

{ treba zistit, ktorym SMERom sa uskutocni posuv motorov pre X aj Y }
{ True=log.1=smer bude +1    alebo    False=log.0=smer bude -1  }

   if newX < X then  smerX:=False  else  smerX:=True;
   if newY < Y then  smerY:=False  else  smerY:=True;

{ treba vypocitat, o kolko krokov sa bude posuvat os X aj os Y }
{ teda ROZDIEL medzi osou X a newX, potom aj rozdiel medzi Y-newY }
{ [nie podiel !!!] a to negovanim znamienka [nasobenim s -1] na jednej }
{ strane, scitanim, a nakoniec, v prikazoch cyklu, ako su FOR a ine, }
{ odobranim vysledneho nepotrebneho znamieka Abs-olutnou hodnotou }

{ sko som vyssie spominal a vykonal, premenne smeru X a Y, odobrane }
{ znamienko sa ulozi do premennych smerX, smerY, aby bolo riadeniu }
{ jasne, ktorym smerom ideme pero posunut }

   pocX := Abs( X + (-1*newX)  );
   pocY := Abs( Y + (-1*newY)  );

{ dalej sa vypocita HODNOTA PRE LINEARNU FUNKCIU ; v matematike by sa     }
{ mohla definovat ako y=x+b [hodnota x je rastuca po jednom cisle]        }
{ a teda hodnota b sa teraz vypocita [skokX a skokY - jeden z tychto      }
{ dvoch bude po jednom cisle rastuca suradnica a ta druha bude hodnotou b }
{ a tiez tu musim kontrolovat nulu [aby nedoslo k deleniu nulou] kedy     }
{ sa jedna suradnica pri posuvani vobec nemeni [kolma ci zvysla ciara ]   }

{ tento skokX ci skokY vsak nemusi byt vypocitany velmi presne; ak totiz    }
{ vychadza desatinne cislo, ktore nahodou presahuje pohyblivu radovu ciarku }
{ t.j. ciselny typ premennej s max. presnostou je extended a vysledok este  }
{ potrebuje viac desatinnych miest, potom pri skakani v premennych pre      }
{ suradnice o skokX ci skokY [ - alebo + ; podla smeruX/Y ] bude az pri     }
{ poslednych suradniciach, pred koncom, mozna nepresnost o nejake tie       }
{ 1-milion-tiny ci 100-tisiciny, ale to sa vyriesy pri ukonceni tejto       }
{ procedury Presun }

{ nasleduje vypocet skokov pre X aj Y s ohladom na pripadny nulovy skok }

   if (pocY > pocX) then                     { musim osetrit pripadny posuv  }
     if pocX=0 then begin                    { po konstantnej suradnici, t.j.}
                       skokX:= 0;            { ked jedna suradnica sa nemeni }
                       skokY:= 1;            { a jej velkost posuvu v skok?  }
                    end                      { musi byt potom 0, takze musim }
               else begin                    { kontrolovat nulu a podla toho }
                       skokX:= 1;            { zvlast vykonat vypocet oboch  }
                       skokY:= (pocY / pocX);{ krokov pre x aj y aby nedoslo }
                    end;                     { ku chybe delenia nulou [v tomto}
                                             { pripade, aby 0 nebola v pocX] }
   if (pocX > pocY) then
     if pocY=0 then begin
                       skokY:= 0;
                       skokX:= 1;
                    end
               else begin
                       skokY:= 1;
                       skokX:= (pocX / pocY);
                    end;

   if (pocX = pocY) then                { orestujem, ci niesu obe hodnoty  }
     if pocX = 0 then begin             { rovnake, najprv ci to niesu nuly }
                         skokX:= 0;     { ak to su nuly, tak skokY a skokX }
                         skokY:= 0;     { budu nastavene na 0, ak su to ine}
                      end               { dve rovnake dlzky suradnic X a Y,}
                 else begin             { tak sa jedna o diagonalny skok,  }
                         skokX:= 1;     { teda pre obe suradnice rovnaky   }
                         skokY:= 1;
                      end;

{ tu sa moze zacat samotne KRESLENIE, t.j. linearna funkcia         }
{ vzdy najprv sa vsak musia nastavit nove suradnice a az potom      }
{ sa vykona cely jeden posuv kuzora [na Alfik-u je to posuv pera]   }

  H := 1;                  { hociake cislo, len aby nebolo H rovne 0 }

  while H <> 0   do        { musim takto vykonat test, cez pomocnu        }
  begin                    { pemennu H lebo priamo vo while mi to nepojde }

       { posuniem motor Alfiku o jeden krok, ak uz je splnena podmienka,   }
       { kedy sa testuje zmena suradnice, ale zaokruhlenej, cize len test  }
       { celeho cisla bez destinnych miest [IQ=bez zlomku] a ak sa tato    }
       { posunie o jedno cislo, tak aj alfikov motor sa podla toho stale   }
       { posuva po jednom kroku }

       { teda cely algoritmus procedury pre presun zo suradnic X, Y na       }
       { suradnice newX, newY je zalozeny na presnych vypoctoch linearnej    }
       { funkcie a na nevsimavosti desatinnych miest - t.j., pre este lepsie }
       { pochopenie: cele cislo znamena suradnicu,na ktoru sa treba z motormi}
       { posunut kreslenim tzv. schodov -> vid premenna skokX a skokY cez    }
       { ktoru sa vypocita F, co je pocet krokov z aktualnej pozicie na novu }
       { a nakolko nemozno posuvat krokovy motor po desatinach, tak ja to    }
       { robim po celych schodoch, ktorych dlzka sa vypocitava dalej vo F    }

      zaX:=trunc(X);        { odlozim stare suradnice, bez desatin }
      zaY:=trunc(Y);        { a dalej sa posuvam smerom k novym suradnicam }

      if smerX = TRUE then  x:=x+skokX
                      else  x:=x-skokX ;
      if smerY = TRUE then  y:=y+skokY
                      else  y:=y-skokY ;

      { vopred si pripravym do schodX a schodY velkost, aku ma jeden  }
      { potrebny schodik, resp. na jednej suradnici sa zrobi ciarka   }
      { a na druhej len jeden bod [velkost=1]   }

      schodX := round(Abs(  (-1*zaX) + int(X)   ) );
      schodY := round(Abs(  (-1*zaY) + int(Y)   ) );

      if schodX=1 then begin
                         schodX := 0;      { dam tu 0, lebo uz posuvanie     }
                         if smerX=TRUE     { po schode X viac nechcem robit  }
                            then  SetRight { nakolko onen jeden krocik uz    }
                            else  SetLeft; { tu pripravym a aj na osi Y,ak...}
                       end;
      if schodY=1 then begin
                         schodY := 0;      { posuvanie motoru Y je tymto     }
                         if smerY=TRUE     { ukoncene [!iba v tomto jednom   }
                            then  SetDown  { schodiku!] po nastaveni dalsieho}
                            else  SetUp;   { kroku na sur. Y t.j. hore/dole  }
                       end;
      if (schodX=0) and (schodY=0) then Vysielaj;    { pokial ide len o jeden krok oboma motormi [45 uhlovych stupnov]   }


      while schodX <> 0 do        { tento cyklus robi ciarku na suradnici X }
      begin                                   { robim tolko krokov, kolko   }
         if smerX=TRUE                        { vypocitam bez desatinnych   }
            then  SetRight                    { miest, len s celymi cislami }
            else  SetLeft ;                   { kym skutocne suradnice X, Y }
         Vysielaj;                            { su pocitane uz s presnostou }
         dec( schodX );                       { desatinnych miest [npu typ  }
      end;                                    { extended]    }

      while schodY <> 0 do        { tento cyklus robi ciarku na suradnici Y }
      begin
         if smerY=TRUE
            then  SetDown
            else  SetUp ;
         Vysielaj;
         dec( schodY );
      end;

      H := Abs(  Trunc(  Abs(newX-X) + Abs(newY-Y)   ));

   end;

      { pretoze nemozu byt presne vypocitane dlzky skokX a skokY, kedy ma   }
      { vysledok prilis vela desatinnymi miest, stane sa ze nevyjde napr. na}
      { presnost 1-milion-tin tento vysledok, ale ja potrebujem mat vzdy    }
      { vystup suradnic velmi presny, preto je tu osetrenie dokreslenych    }
      { vystupnych zmenenych suradnic :    }
      { P.S. inac by mohlo dost pri poctoch posledneho kroku motormi ku     }
      {      preteceniu a vysledok by bol celkom od veci [iny exponent]     }

  X:= newX;
  Y:= newY;
end;






{ procedura ZNAK vykona LEN vykreslenie ASCII znaku, ktory si vyhlada v     }
{ tabulke TAB[] ale inac logicke riadenie tlaciarne je urobene v procedure  }
{ VETA, kde sa zistuju a nasledne vykreslia znaky kodovej stranky, riadiace }
{ kody pre tlaciaren, tzv. ESC sekvencia [napr.nastavenie velkosti pisma]   }


procedure Znak(ZN : char);
begin
   for bu:=1 to pocet do
    if TAB[bu] = ord(ZN)
       then  begin
             vel:=ciarka;
                 repeat
                 case TAB[bu] of
                          9 : begin   Presun(x+vel, y-vel);    end;
                          8 :         Presun(x    , y-vel);
                          7 : begin   Presun(x-vel, y-vel);    end;
                          6 :         Presun(x+vel, y    );
                          4 :         Presun(x-vel, y    );
                          3 : begin   Presun(x+vel, y+vel);    end;
                          2 :         Presun(x    , y+vel);
                          1 : begin   Presun(x-vel, y+vel);    end;
                         15 :         vel:=int(ciarka/5);   {-   }
                         13 :         vel:=int(ciarka/3);   {-.  }
                         12 :         vel:=int(ciarka/2);   {--  }
                         11 :         vel:=int(ciarka/1);   {----}
                          0 :         PeroHore;
                          5 :         PeroDole;
                         end;
                 inc(bu);
                 until TAB[bu] = 255 ;

             if (ord(ZN) > 31) and (ord(ZN) < 128) then Presun( X+(ciarka/3), Y );
                 { medzera medzi znakmi, nie ak sa jedna o riadiace kody }
             end;
end;








procedure Veta(ss : string);
begin
   for Tex:=1 to Length(ss) do
   begin

       if 27 = ord( ss[tex-1] ) then
           begin   Ciarka:=ord( ss[tex] );    ss[tex]:=chr(0);    end;

       for cq:=1 to 5 do  if ss[tex] = MekcenStred[cq]  then
           begin   Znak( chr(16) );    Znak( MekcenStred[cq+10] );  end;
       for cq:=1 to 7 do  if ss[tex] = MekcenHore[cq]   then
           begin   Znak( chr(17) );    Znak( MekcenHore[cq+10]  );  end;
       for cq:=1 to 6 do  if ss[tex] = DlzenStred[cq]   then
           begin   Znak( chr(18) );    Znak( DlzenStred[cq+10]  );  end;
       for cq:=1 to 8 do  if ss[tex] = DlzenHore[cq]    then
           begin   Znak( chr(19) );    Znak( DlzenHore[cq+10]   );  end;
       if (ord(ss[tex]) > 31) and (ord(ss[tex]) < 127)  then Znak( ss[tex] );

       case ord( ss[tex] )  of
         ord('Ñ') : begin  Znak( chr(20) );  Znak('a');   end;
         ord('é') : begin  Znak( chr(21) );  Znak('A');   end;
         ord('ì') : begin  Znak( chr(22) );  Znak('o');   end;
         ord('‚') : begin  Znak( chr(23) );  Znak('O');   end;
               10 :        Presun( X, Y+(ciarka*2)+(2*(ciarka/3))  );    { hodnota ciarka/3 je dodatocna medzera medzi riadky }
               13 :        Presun( 0, Y);
                7 :        Pipni ;               { BEL - zvoncek tlaciarne }
              end ;

   end;
end;



BEGIN

END.
