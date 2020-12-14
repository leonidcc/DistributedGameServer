-module(server).
-include("crlPstat.hrl").
-include("crlCarga.hrl").
-include("crlUserSock.hrl").
-include("crlListGame.hrl").
-include("crlJostick.hrl").
-include("pcomands.hrl").

-compile(export_all).


  % FUN DE RESPUESTA A LOS CLIENTES

  fRUPD(Socket,CMID,MSJ)->
      io:format("se envia UPD\n",[]),
      gen_tcp:send(Socket,"UPD "++CMID++" "++MSJ).

  fRERROR(Socket,CMID,MSJ)->
      io:format("se envia ~p~n",["OK "++CMID++" "++MSJ]),
      gen_tcp:send(Socket,"ERROR "++CMID++" "++MSJ).

  fR(Socket,CMID,MSJ)->
     io:format("se envia ~p~n",["OK "++CMID++" "++MSJ]),
      gen_tcp:send(Socket,"OK "++CMID++" "++MSJ).


%esta Activo siempre que el user asociado a el este conectado
mindUser(SOCK)->
    receive
        {linkear,PIP}       -> link(PIP), % crea un link con los juegos que participa "como jugador u observador"
                               mindUser(SOCK);
        {unlinkear,PIP}     -> unlink(PIP),
                               mindUser(SOCK);
        {renderGame,Update} -> fRUPD(SOCK,"000",Update), % envia las actualizaciones de los juegos que participa
                               mindUser(SOCK);
        {kill,NAME,Socket}  -> usrRmv(node(),Socket), % Quitamos de la lista de usuarios
                               io:format("\n se desconecto:~s",[NAME]),
                               exit(NAME) % matamos el proceso para que cada juego vinculado a el se entere
    end.

pcomandlisten(Socket,CMDID,Pcomand,ARG)->
   MinNode = nodesMinCarg(),
  spawn_link(MinNode,?MODULE,Pcomand,[self(),Socket]++ARG),
    receive
      {ok,RPTA}       -> fR(Socket,CMDID,RPTA); % el comando fue exitoso
      {error,RPTA}    -> fRERROR(Socket,CMDID,RPTA); % el comando fue exitoso pero no realizo lo q tenia que hacer
      {'ERROR',_,_MSJ} -> nodesUpdateNow(), %esto por si el nodo q se rompio era el de menor carga
                         pcomandlisten(Socket,CMDID,Pcomand,ARG)
   after
     10000 -> fRERROR(Socket,CMDID,"El servidor no pudo procesar la solicitud")
   end.


laparca(Socket)->
  % obtenemos el usuario al q se le fue la luz o se puso BYE
  USRKill = usrGet(node(),Socket), % recordar un get GLOBAL
  case USRKill of
      null -> none;
      _ALL -> USRKill#userMind.pid!{kill,USRKill#userMind.nombre,Socket} % le avisamos a la f conciencia que se perdio la conexion
  end.

% SE RECIBEN LAS PETICIONES ===================================================
psocket(Socket)->
    case gen_tcp:recv(Socket, 0) of
        {ok, Paquete} ->
              io:format("~n->llego: ~p",[Paquete]),
              CMD  = binary_to_list(Paquete),
              case string:tokens(CMD," ")  of
                  ["OK" ,CMDID]            ->  io:format("se actualizó correctamente ~p",[CMDID]);
                  ["CON",CMDID,NAME]       ->  pcomandlisten(Socket,CMDID,pcmdCON,[NAME]);
                  ["LSG",CMDID]            ->  pcomandlisten(Socket,CMDID,pcmdLSG,[]);
                  ["ACC",CMDID,GAMEID]     ->  pcomandlisten(Socket,CMDID,pcmdACC,[GAMEID]);
                  ["NEW",CMDID]            ->  pcomandlisten(Socket,CMDID,pcmdNEW,[]);
                  ["PLA",CMDID,GAMEID,ARG] ->  pcomandlisten(Socket,CMDID,pcmdPLA,[GAMEID,ARG]);
                  ["OBS",CMDID,GAMEID]     ->  pcomandlisten(Socket,CMDID,pcmdOBS,[GAMEID]);
                  ["LEA",CMDID,GAMEID]     ->  pcomandlisten(Socket,CMDID,pcmdLEA,[GAMEID]);
                  ["BYE",CMDID]            ->  laparca(Socket),
                                               fRERROR(Socket,CMDID,"Adiosito :)"),
                                               exit(userDisconnect);
                  [_ALL,CMDID|_ARG]        ->  gen_tcp:send(Socket,"ERR "++CMDID++" COMANDO DESCONOCIDO");
                  _ALL                     ->  gen_tcp:send(Socket,"FUERA DE PROTOCOLO")
              end,
            psocket(Socket);
        {error, closed} ->%si a un usuario se le va la LUZ
                          laparca(Socket),
                          exit(userDisconnect)
    end.


dispatcher(LSocket)->
      io:format("ONLINE~n"),
      {ok, Socket} = gen_tcp:accept(LSocket),
      io:format(" :: new concct desde ~p~n",[Socket]),
      spawn(?MODULE, psocket,[Socket]),
      dispatcher(LSocket).


% PASO 1: evantara un servidor y escuchara en el puerto "PUERTO"
init(PUERTO)->
    spawn(?MODULE,start,[PUERTO]).

% PASO 2: concctar a la red de NODOS del servidor
connect(NodoAconectarse)->
      net_kernel:connect_node(NodoAconectarse).


% INICIO DEL PROGRAMA
start(PUERTO) ->
  % Se inica la conexion en el puerto
  {ok, LSocket} = gen_tcp:listen( PUERTO
                                , [ binary
                                , {packet, 0}
                                , {active, false}]),

 pstatInit(), % se inicializa el respondedor de carga del nodo
 nodesInit(), % Se inica  Controlador de carga
 usrInit(),   % Se inica  Controlador de usuario locales
 gameInit(),  % Se inica  Controlador de juegos locales
 dispatcher(LSocket).
