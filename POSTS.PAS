unit Posts;

interface

type Post = record
       X, Y: Word;
       Free: Boolean;
     end;
     PostPtr = ^Post;
     PostListPtr = ^PostList;
     PostList = record
       Current: PostPtr;
       Next: PostListPtr;
     end;
     PostListPtrPtr = ^PostListPtr;

var Occupied: PostListPtr;

procedure AddOccupied(P: PostPtr);
procedure RemoveOccupied(P: PostPtr);
procedure ClearOccupied;
function RandomOccupied: PostListPtr;


implementation
uses Utils;


function _OccupiedLength: Byte;
var N: Byte;
    Node: PostListPtr;
begin
  N := 0;
  Node := Occupied;
  while Node <> nil do
    begin
      Node := Node^.Next;
      Inc(N);
    end;
  _OccupiedLength := N;
end;


procedure _AddNodeToStart(Start: PostListPtrPtr; P: PostPtr);
var Node: PostListPtr;
begin
  New(Node);
  Node^.Current := P;
  Node^.Next := Start^;
  Start^ := Node;
end;


procedure AddOccupied(P: PostPtr);
begin
  _AddNodeToStart(@Occupied, P);
end;


procedure _RemoveFromStart;
var _N: PostListPtr;
begin
  _N := Occupied;
  Occupied := Occupied^.Next;
  Dispose(_N);
end;


procedure RemoveOccupied(P: PostPtr);
var Node, _N: PostListPtr;
begin
  if Occupied^.Current = P then
    _RemoveFromStart
  else
    begin
      Node := Occupied;
      while Node^.Next^.Current <> P do Node := Node^.Next;
      _N := Node^.Next;
      Node^.Next := Node^.Next^.Next;
      Dispose(_N);
    end;
end;


procedure ClearOccupied;
begin
  while Occupied <> nil do _RemoveFromStart;
end;


function RandomOccupied: PostListPtr;
var N: Byte;
    Node: PostListPtr;
begin
  Node := Occupied;
  N := Random(_OccupiedLength);
  while N > 0 do
    begin
      Node := Node^.Next;
      Dec(N);
    end;
  RandomOccupied := Node;
end;

end.
