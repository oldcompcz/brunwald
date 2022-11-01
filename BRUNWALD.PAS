program Brunwald;
uses Crt, Dos, Graph, Posts, Utils;

const WIDTH = 39;
      HEIGHT = 18;
      CASTLE: array[0..HEIGHT, 0..WIDTH] of Char = (
        '  BPBPB                                 ',
        '  BBBBB                                 ',
        '  BBBBB                         BPB BPB ',
        '  BBWBB                         BBBBBBB ',
        '  BB BB                         BBBBBBB ',
        '  BBPBB                         BBBWBBB ',
        '  BBBBB                         BBB BBB ',
        '  BBBBB                         BBBPBBB ',
        '  BBWBB                         BBBBBBB ',
        '  BB BB                         BBBBBBB ',
        '  BBPBB BPBPBPBPBPBPBPBPBPBPBPB BBBWBBB ',
        'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB BBBB',
        'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBPBBBB',
        'BBBBBBBBBBBWBBB    BBBBWBBBBBBBBBBBBBBBB',
        'BBBBBBBBBBB BBB    BBBB BBBBBBBBBBBBBBBB',
        'BBBBBBBBBBBPBBB    BBBBPBBBBBBBBBBBBBBBB',
        'BBBBBBBBBBBBBBB    BBBBBBBBBBBBBBBBBBBBB',
        'BBBBBBBBBBBBBBB    BBBBBBBBBBBBBBBBBBBBB',
        'BBBBBBBBBBBBBBB    BBBBBBBBBBBBBBBBBBBBB'
      );
      NUM_POSTS = 21;
      MAGAZINE = 36;

var Timer, Health, Ammo: Byte;
    Score: Word;
    Key: Char;
    PostArray: array[1..NUM_POSTS] of Post;
    Mouse: MouseState;
    GraphDriver, GraphMode: Integer;


procedure Title; external; {$L TITLE.OBJ}
procedure Brick; external; {$L BRICK.OBJ}
procedure Window; external; {$L WINDOW.OBJ}
procedure Gate; external; {$L GATE.OBJ}
procedure Flag; external; {$L FLAG.OBJ}
procedure Enemy; external; {$L ENEMY.OBJ}
procedure Fire; external; {$L FIRE.OBJ}
procedure CGADriver; external; {$L DRIVER.OBJ}


procedure DisplayHealth;
begin
  SetColor(1);
  HideMouse;
  Bar(7*8, 192, 11*8-1, 199);
  OutTextXY(7*8, 192, AlignNumber(Health));
  ShowMouse;
end;


procedure DisplayAmmo;
begin
  SetColor(2);
  HideMouse;
  Bar(22*8, 192, 26*8-1, 199);
  OutTextXY(22*8, 192, AlignNumber(Ammo));
  ShowMouse;
end;


procedure DisplayScore;
begin
  Bar(36*8, 192, 40*8-1, 199);
  SetColor(3);
  OutTextXY(36*8, 192, AlignNumber(Score));
end;


procedure CenteredText(Txt: string; Y: Byte);
begin
  OutTextXY(8 * (40 - Length(Txt)) div 2, Y, Txt);
end;


procedure TitleScreen;
begin
  Bar(0, 0, 319, 199);
  PutImage(47, 12, @Title^, XORPut);
  SetColor(1);
  OutTextXY(64, 108, 'Mission: kill enemies');
  OutTextXY(64, 124, 'Left click: fire');
  CenteredText('Right click: reload ammo', 133);
  OutTextXY(64, 149, 'Esc: abort');
  SetColor(3);
  CenteredText('Press any key to start', 174);
  CenteredText('or Esc to quit', 184);
end;


procedure GameOverScreen;
begin
  Bar(0, 0, 319, 199);
  SetColor(2);
  if Health > 0 then
    CenteredText('Mission aborted', 56)
  else
    CenteredText('Killed in action', 56);
  CenteredText('Game Over', 76);
  SetColor(1);
  CenteredText('Score: ' + AlignNumber(Score), 108);
  SetColor(3);
  CenteredText('Press any key', 174);
end;


procedure ReloadAmmo;
begin
  Ammo := MAGAZINE;
  DisplayAmmo;
end;


procedure InitGame;
var i, j, k: Byte;
begin
  Bar(0, 0, 319, 199);
  Health := 100;
  DisplayHealth;
  OutTextXY(0, 192, 'Health:     %');
  ReloadAmmo;
  OutTextXY(17*8, 192, 'Ammo:');
  Score := 0;
  DisplayScore;
  OutTextXY(30*8, 192, 'Score:');

  k := 1;
  for j := 0 to HEIGHT do
    for i := 0 to WIDTH do
      begin
        case CASTLE[j, i] of
          'B': PutImage(i*8, j*8 + 16, @Brick^, XORPut);
          'W': PutImage(i*8, j*8 + 16, @Window^, XORPut);
          'P': begin
                 PostArray[k].X := i*8;
                 PostArray[k].Y := j*8 + 10;
                 PostArray[k].Free := True;
                 Inc(k);
               end;
        end;
      end;

  PutImage(120, 114, @Gate^, NormalPut);
  PutImage(283, 10, @Flag^, XORPut);
  ClearOccupied;
end;


procedure AddEnemy;
var i: Byte;
    P: PostPtr;
begin
  i := Succ(Random(NUM_POSTS));
  P := @PostArray[i];
  if P^.Free then
    begin
      P^.Free := False;
      AddOccupied(P);
      HideMouse;
      PutImage(P^.X, P^.Y, @Enemy^, XORPut);
      ShowMouse;
    end;
end;


procedure EnemyFire;
var P: PostPtr;
begin
  P := RandomOccupied^.Current;
  HideMouse;
  PutImage(P^.X - 3, P^.Y + 2, @Fire^, XORPut);
  ShowMouse;
  EnemySound;
  HideMouse;
  PutImage(P^.X - 3, P^.Y + 2, @Fire^, XORPut);
  ShowMouse;
  Dec(Health);
  DisplayHealth;
end;


procedure PlayerFire;
var i: Byte;
    P: PostPtr;
begin
  PlayerSound;
  Dec(Ammo);
  DisplayAmmo;
  for i := 1 to NUM_POSTS do
    begin
      P := @PostArray[i];
      if P^.Free or (Mouse.X < P^.X) or (Mouse.X > P^.X + 7)
         or (Mouse.Y < P^.Y) or (Mouse.Y > P^.Y + 13) then Continue;
      HideMouse;
      Bar(P^.X, P^.Y, P^.X + 7, P^.Y + 13);
      ShowMouse;
      P^.Free := True;
      RemoveOccupied(P);
      Inc(Score);
      DisplayScore;
      Break;
    end;
end;


begin
  RegisterBGIdriver(@CGADriver);
  GraphDriver := CGA;
  GraphMode := CGAC2;
  InitGraph(GraphDriver, GraphMode, '');
  InitMouse;
  Randomize;
  SetFillStyle(SolidFill, 0);

  repeat
    TitleScreen;
    while KeyPressed do ReadKey;
    Key := ReadKey;
    if Key = #27 { Esc } then Break;
    InitGame;
    ShowMouse;

    repeat
      Timer := TimeSync(Timer);
      Mouse := GetMouseState^;
      if Mouse.Button1 and (Ammo > 0) then PlayerFire;
      if Mouse.Button2 and (Ammo = 0) then ReloadAmmo;
      if Random(1000) < (50 + Score) then AddEnemy;
      if (OccupiedLength > 0) and (Random(1000) < (50 + Score)) then EnemyFire;
      if KeyPressed then Key := ReadKey;
    until (Health = 0) or (Key = #27 { Esc } );

    HideMouse;
    GameOverScreen;
    while KeyPressed do ReadKey;
    repeat until KeyPressed;
  until False;
  RestoreCrtMode;

end.
