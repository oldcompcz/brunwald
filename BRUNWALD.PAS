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
      MAX_HEALTH = 100;
      MAX_AMMO = 36;
      MAX_ENEMIES = 100;

type STATUS = (WIN, KIA, ABORT);

var Timer, Health, Ammo, EnemiesLeft: Byte;
    Score: Word;
    Key: Char;
    GameStatus: STATUS;
    Mouse: MouseState;
    GraphDriver, GraphMode: Integer;


procedure Title; external; {$L TITLE.OBJ}
procedure Brick; external; {$L BRICK.OBJ}
procedure Window; external; {$L WINDOW.OBJ}
procedure Gate; external; {$L GATE.OBJ}
procedure Flag; external; {$L FLAG.OBJ}
procedure Enemy; external; {$L ENEMY.OBJ}
procedure Enemy2; external; {$L ENEMY2.OBJ}
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


procedure GameOverScreen(GameStatus: STATUS);
begin
  Bar(0, 0, 319, 199);
  SetColor(2);
  case GameStatus of
    WIN:
      begin
        CenteredText('Mission completed', 56);
        CenteredText('Congratulations', 76);
      end;
    KIA:
      begin
        CenteredText('Killed in action', 56);
        CenteredText('Game Over', 76);
      end;
    ABORT:
      begin
        CenteredText('Mission aborted', 56);
        CenteredText('Game Over', 76);
      end;
  end;
  SetColor(1);
  CenteredText('Score: ' + AlignNumber(Score), 108);
  SetColor(3);
  CenteredText('Press any key', 174);
end;


procedure ReloadAmmo;
begin
  Ammo := MAX_AMMO;
  DisplayAmmo;
end;


procedure InitPosts;
var i, j: Byte;
    _P: PostPtr;
begin
  for j := 0 to HEIGHT do
    for i := 0 to WIDTH do
      if CASTLE[j, i] = 'P' then
        begin
          New(_P);
          _P^.X := i*8;
          _P^.Y := j*8 + 10;
          _P^.Free := True;
          AddPost(_P);
        end;
end;


procedure InitGame;
var i, j: Byte;
begin
  Bar(0, 0, 319, 199);
  Health := MAX_HEALTH;
  DisplayHealth;
  OutTextXY(0, 192, 'Health:     %');
  ReloadAmmo;
  OutTextXY(17*8, 192, 'Ammo:');
  Score := 0;
  DisplayScore;
  OutTextXY(30*8, 192, 'Score:');
  EnemiesLeft := MAX_ENEMIES;

  for j := 0 to HEIGHT do
    for i := 0 to WIDTH do
      case CASTLE[j, i] of
        'B': PutImage(i*8, j*8 + 16, @Brick^, XORPut);
        'W': PutImage(i*8, j*8 + 16, @Window^, XORPut);
      end;

  PutImage(120, 114, @Gate^, NormalPut);
  PutImage(283, 10, @Flag^, XORPut);
end;


procedure AddEnemy;
var P: PostPtr;
begin
  P := RandomPost^.Current;
  if P^.Free then
    begin
      AddOccupied(P);
      HideMouse;
      if Random(100) < 80 then
        PutImage(P^.X, P^.Y, @Enemy^, XORPut)
      else
        PutImage(P^.X, P^.Y, @Enemy2^, XORPut);
      ShowMouse;
      Dec(EnemiesLeft);
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
var X, Y: Word;
    P: PostPtr;
    Occ: PostListPtr;
begin
  PlayerSound;
  Dec(Ammo);
  DisplayAmmo;
  Occ := OccupiedPosts;
  while Occ <> nil do
    begin
      P := Occ^.Current;
      X := P^.X;
      Y := P^.Y;
      if (Mouse.X >= X) and (Mouse.X < X + 8)
          and (Mouse.Y >= Y) and (Mouse.Y < Y + 14) then
        begin
          HideMouse;
          Bar(X, Y, X + 7, Y + 13);
          ShowMouse;
          RemoveOccupied(P);
          Inc(Score);
          DisplayScore;
          Exit;
        end;
      Occ := Occ^.Next;
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
  InitPosts;

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
      if Mouse.Button1 and (Ammo > 0) then
        begin
          PlayerFire;
          if Score = MAX_ENEMIES then
            begin
              GameStatus := WIN;
              Break;
            end;
        end;
      if Mouse.Button2 and (Ammo = 0) then ReloadAmmo;
      if (EnemiesLeft > 0) and (Random(1000) < (50 + Score)) then AddEnemy;
      if (NumOccupied > 0) and (Random(1000) < (50 + Score)) then
        begin
          EnemyFire;
          if Health = 0 then
            begin
              GameStatus := KIA;
              Break;
            end;
        end;
      if KeyPressed then
        begin
          Key := ReadKey;
          if Key = #27 then
            begin
              GameStatus := ABORT;
              Break;
            end;
        end;
    until False;

    HideMouse;
    ClearOccupied;
    GameOverScreen(GameStatus);
    while KeyPressed do ReadKey;
    repeat until KeyPressed;
  until False;
  RestoreCrtMode;

end.
