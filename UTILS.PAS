unit Utils;

interface
type MouseState = record
       X, Y: Integer;
       Button1, Button2: Boolean;
     end;
     MouseStatePtr = ^MouseState;

procedure InitMouse;
procedure ShowMouse;
procedure HideMouse;
function GetMouseState: MouseStatePtr;
function TimeSync(CurrentTimer: Byte): Byte;
function AlignNumber(Number: Word): string;
procedure PlayerSound;
procedure EnemySound;

implementation
uses Crt, Dos;

procedure Cursor; external; {$L CURSOR.OBJ}


procedure InitMouse;
var R: Registers;
begin
  R.AX := 0;    { initialize mouse driver }
  Intr($33, R);

  R.AX := 9;    { define own mouse cursor }
  R.BX := 7;    { horizontal hot spot }
  R.CX := 7;    { vertical hot spot }

  R.ES := Seg(Cursor);
  R.DX := Ofs(Cursor);
  Intr($33, R);
end;


procedure ShowMouse;
var R: Registers;
begin
  R.AX := 1;
  Intr($33, R);
end;


procedure HideMouse;
var R: Registers;
begin
  R.AX := 2;
  Intr($33, R);
end;


function GetMouseState: MouseStatePtr;
var R: Registers;
    Result: MouseState;
begin
  R.AX := 3;    { query mouse state }
  Intr($33, R);
  Result.X := R.CX div 2;    { 0-639 }
  Result.Y := R.DX;          { 0-199 }
  Result.Button1 := (R.BX and 1) <> 0;
  Result.Button2 := (R.BX and 2) <> 0;
  GetMouseState := @Result;
end;


function TimeSync(CurrentTimer: Byte): Byte;
var h, m, s, Counter: Word;
begin
  repeat
    GetTime(h, m, s, Counter);
    Counter := Counter div 4;    { 25 ticks per second }
  until Counter <> CurrentTimer;
  TimeSync := Counter;
end;


function ToString(Number: Word): string;
var S: string;
begin
  Str(Number, S);
  ToString := S;
end;


function AlignNumber(Number: Word): string;
var S: string;
begin
  S := '   ' + ToString(Number);
  AlignNumber := Copy(S, Length(S) - 3, 4);
end;


procedure PlayerSound;
var i: Byte;
begin
  for i := 30 downto 10 do
    begin
      Sound(i * 8);
      Delay(2);
    end;
  NoSound;
end;


procedure EnemySound;
var i: Byte;
begin
  for i := 34 downto 14 do
    begin
      Sound(i * 8);
      Delay(2);
    end;
  NoSound;
end;

end.
