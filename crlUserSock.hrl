
% Se representa a un "usuario"
% con su nombre de registro y un pid de un proceso
% activo mientras este esta conectado

-record(userMind, {nombre,pid}).

% > CONTROLADOR DE USUARIOS asociado a sus SOCKETS <
%    - nombre: nombre del user
%    - pid: proceso "conciencia":
%                    una funcion que estara activo mientras el usuario este conectado al server
%    - structura : MAPA

% ==-FUNCIONES-==
% "permite mantener una estructura de usuarios activos"

%  > usrInit()                      :: inicia el controlador de usuarios
%  > usrGets(nodo)                  :: retorna el mapa de todos los usuarios activos
%  > usrAdd(nodo,SocketId,Data)     :: añade un usuario
%  > usrRmv(nodo,SocketId)          :: elimina un usuario
%  > usrGet(nodo,SocketId)          :: retorna el usuario
%  > usrExist(nodo,UserName)        :: retorna si existe un usuario a partir del nombre


% ==-IMPLEMENTACION-==
% con la misma implementacion se puede reemplazzar la estructura
% para q esta sea mas efciente ejemplo un arbol ABB

userControlador(MapUSER)->
  receive
    {getUser,IdVisit,SOCKET}-> IdVisit!maps:get(SOCKET, MapUSER,null),
                               userControlador(MapUSER);
    {addUser,SOCKET,VALUE}  -> userControlador(maps:put(SOCKET,VALUE,MapUSER));
    {rmvUser,SOCKET}        -> userControlador(maps:remove(SOCKET, MapUSER));
    {getsUser,IdVisit}      -> io:format("peticion GETS a: ~p~n",[IdVisit]),
                               IdVisit!MapUSER,
                               userControlador(MapUSER)
end.

usrMakeData(NAME,PID)->
  #userMind{nombre = NAME,pid=PID}.

usrAdd(NODO,SOCKETID,DATA)->
  {userControladorR,NODO}!{addUser,SOCKETID,DATA}.

usrGet(NODO,SOCKETID)->
  {userControladorR,NODO}!{getUser,self(),SOCKETID},
  receive
    USER -> USER
  end.

usrRmv(NODO,SOCKETID)->
  {userControladorR,NODO}!{rmvUser,SOCKETID}.

usrGets(NODO)->
  {userControladorR,NODO}!{getsUser,self()},
  receive
    USERs -> USERs
  end.

%intentamos usar iterator, pero no esta en el "maplib estandar"
usrExist(NODO,UserName)->
  Map = usrGets(NODO),
  % io:format("se esta buscando un nombre en el nodo ~p~n",[{node(),NODO}]),
  case maps:size(Map) of
        0    -> false;
        _ALL  -> VV  = maps:values(Map),
                LL  = lists:map(fun({_X,Y,_Z})->Y end,VV),
                lists:member(UserName,LL)
  end.

usrInit()->
  register(userControladorR,spawn(?MODULE,userControlador,[maps:new()])).
