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

var AllPosts, OccupiedPosts: PostListPtr;

function NumOccupied: Byte;
procedure AddPost(P: PostPtr);
procedure AddOccupied(P: PostPtr);
procedure RemoveOccupied(P: PostPtr);
procedure ClearOccupied;
function RandomPost: PostListPtr;
function RandomOccupied: PostListPtr;

implementation
uses Utils;


function _DynLength(Start: PostListPtrPtr): Byte;
var N: Byte;
    Node: PostListPtr;
begin
  N := 0;
  Node := Start^;
  while Node <> nil do
    begin
      Node := Node^.Next;
      Inc(N);
    end;
  _DynLength := N;
end;


function NumOccupied: Byte;
begin
  NumOccupied := _DynLength(@OccupiedPosts);
end;


procedure _AddNodeToStart(Start: PostListPtrPtr; P: PostPtr);
var Node: PostListPtr;
begin
  New(Node);
  Node^.Current := P;
  Node^.Next := Start^;
  Start^ := Node;
end;


procedure AddPost(P: PostPtr);
begin
  _AddNodeToStart(@AllPosts, P);
end;


procedure AddOccupied(P: PostPtr);
begin
  _AddNodeToStart(@OccupiedPosts, P);
end;


procedure _RemoveFromStart;
var _N: PostListPtr;
begin
  _N := OccupiedPosts;
  OccupiedPosts := OccupiedPosts^.Next;
  Dispose(_N);
end;


procedure RemoveOccupied(P: PostPtr);
var Node, _N: PostListPtr;
begin
  if OccupiedPosts^.Current = P then
    _RemoveFromStart
  else
    begin
      Node := OccupiedPosts;
      while Node^.Next^.Current <> P do Node := Node^.Next;
      _N := Node^.Next;
      Node^.Next := Node^.Next^.Next;
      Dispose(_N);
    end;
end;


procedure ClearOccupied;
begin
  while OccupiedPosts <> nil do _RemoveFromStart;
end;


function _PickRandom(Start: PostListPtrPtr): PostListPtr;
var N: Byte;
    Node: PostListPtr;
begin
  Node := Start^;
  N := Random(_DynLength(Start));
  while N > 0 do
    begin
      Node := Node^.Next;
      Dec(N);
    end;
  _PickRandom := Node;
end;


function RandomPost: PostListPtr;
begin
  RandomPost := _PickRandom(@AllPosts);
end;


function RandomOccupied: PostListPtr;
begin
  RandomOccupied := _PickRandom(@OccupiedPosts);
end;


begin
  AllPosts := nil;
  OccupiedPosts := nil;
end.
