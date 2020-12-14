
% Se representa a un "game"

-record(game, {idGlobalGame,name,status,pidControl}).

% > CONTROLADOR DE GAME asociado a sus GAMEID <
%    - idGlobalGame: GAMEID                            ej: 'matrix-0'.
%    - name: nombre del juego                          ej: "tateti"
%    - status : estado del juego                           "Activo"|"Espera"
%    - pidControl : PID del juego "name"

%    - estructura : MAPA
%      #{'a-12' =>{game,'a-12',"tateti","Espera",<<1.22.01>>}}


% ==-FUNCIONES-==
% "permite mantener una estructura de usuarios activos"

%  > gameInit()                     :: inicia el controlador de usuarios
%  > gsGets(nodo)                   :: retorna el mapa de todos los juegos registrados
%  > gsGet(NODO,IdGame)             :: retorna un juego IdGame
%  > gsAdd(nodo,idGame)             :: añade un juego al mapa
%  > gsMake(PIDJOSTICK)             :: crea un juego "en principio solo tipo tateti"
%  > gsRmv(NODO,IdGame)             :: elimina el  juego IdGame del mapa
%  > gsGetG(IdGame)                 :: retorna un juego de manera global
%  > gsUPDSTATE(NODO,IDGAME)        :: actualiza un juego a su estado "Activo"


% ==-IMPLEMENTACION-==
% con la misma implementacion se puede reemplazzar la estructura
% para q esta sea mas efciente ejemplo un arbol ABB



idGameGenerate(Id)->
  [X|_XS] = string:split(atom_to_list(node()),"@"),
  receive
    IdVisit -> IdVisit!list_to_atom(X++"-"++integer_to_list(Id)),idGameGenerate(Id+1)
  end.


gsEjecControlador(MapGame)->
  receive
    % obtiene una estructura de un juego "DatosJostick"
    {getGame,IdVisit,IdGame}-> IdVisit!maps:get(IdGame,MapGame,null),
                               gsEjecControlador(MapGame);
    % añade un juego que se inicio a jugar
    {addGame,IdGame,Game}  -> gsEjecControlador(maps:put(IdGame,Game,MapGame));

    % quita de la lista de Juuegos activos
    {rmvGame,IdGame}-> gsEjecControlador(maps:remove(IdGame, MapGame));

    % retorna la lista de Juegos Activos
    {getGames,IdVisit}-> IdVisit!MapGame, gsEjecControlador(MapGame)
end.


gsGetG(IdGame)-> %La ideas es formar a partir de nodename-23 -> nodename@nombre-del-pc
  [NODENAME,_] = string:split(IdGame,"-"),
  [_,NAMEPC]   = string:split(atom_to_list(node()),"@"),
  % ya tenemos el nodo donde esta registrado el juego
  NODOdelIdGame = list_to_atom(NODENAME++"@"++NAMEPC),
  %obtenemos el jeugo retornamos el nodo y la estructura jeugo
  {NODOdelIdGame,gsGet(NODOdelIdGame,list_to_atom(IdGame))}.

gsUPDSTATE(NODO,IDGAME)->
  {game,ID,NAME,_ST,PIDJOSTICK} =  gsGet(NODO,IDGAME),
  {gsEjecControladorAtom,NODO}!{addGame,IDGAME,{game,ID,NAME,"Activo",PIDJOSTICK}}.


% Crea un jeugo a partir de un pid Jostick
gsMake(PIDJOSTICK)->
  idGameGenerateR!self(),
  receive
    NewID-> #game{idGlobalGame = NewID,name="tateti",status="Espera",pidControl=PIDJOSTICK}
  end.

gsAdd(NODO,NewGame)->
  {gsEjecControladorAtom,NODO}!{addGame,NewGame#game.idGlobalGame,NewGame}.

gsGet(NODO,IdGame)->
  %reCORDAR Q EL NODO NO EXISTA EN TAL CASO CAPTURAR EL ERROR Y RETORNAR NULL!!!
  {gsEjecControladorAtom,NODO}!{getGame,self(),IdGame},
  receive
    Game -> Game
  end.

gsRmv(NODO,IdGame)->
  {gsEjecControladorAtom,NODO}!{rmvGame,IdGame}.

gsGets(NODO)->
  {gsEjecControladorAtom,NODO}!{getGames,self()},
  receive
    Game -> Game
  end.

gameInit()->
  register(idGameGenerateR,spawn(?MODULE,idGameGenerate,[0])),
  register(gsEjecControladorAtom,spawn(?MODULE,gsEjecControlador,[maps:new()])).
