-module(cli).
-compile(export_all).




% ====================== INTERFAZ GRAFICA
% se podria validar solo los comandos que recibe el servidor
validarCMD(CMD)-> if
  length(CMD) >=3 -> {ok,CMD};
    true           -> {error,"longitud no valida"}
end.

% % permite seleccionar un comando valido
option(NewUser)->

  io:format("\n\n\n\n\n\n>>========================<<
  🖧--SERVER Tateti 1.0 --🖧     👤 ~s

  ComandosValidos:~n
    🔹LSG                >Lista juegos
    🔹NEW idGame         >Crea un nuevo juego
    🔹ACC idGame         >Acepta partida
    🔹OBS idGame         >Observar partida
    🔹PLA idGame JUGADA  >Realizar una jugada
    🔹BYE                >Salir
>>========================<<",[NewUser]),

  Comand  = io:get_line("\n >> "),
  Comand2 = lists:sublist(Comand,length(Comand)-1),
  case validarCMD(Comand2) of
    {ok,CMD} -> {ok,CMD};
    {error,MSJ}-> io:format("\n~s",[MSJ]),
                option(NewUser)
end.


% % parte grafica que pide los comandos
menu(NewUser,Socket)->
  % pido una opcion
  case option(NewUser) of
    {ok,CMD} -> requestSV!{send,self(),Socket,CMD},
                menu(NewUser,Socket);
    {exit,_} -> ok % Salimos del programa
  end.

% ======================



reciveSV(Socket)->
case gen_tcp:recv(Socket, 0) of % se modifico la forma del match con {active, false} ya que no funcionaba con el receive
  {ok, Paquete} -> CMD = binary_to_list(Paquete),
                       case string:tokens(CMD," ") of
                          ["OK",CMDID|ARG]    -> MSJE = lists:append([X++" "|| X <-ARG]),
                                                 list_to_atom(CMDID)!{ok,MSJE};

                          ["ERROR",CMDID|ARG] -> MSJE = lists:append([X++" "|| X <-ARG]),
                                                 list_to_atom(CMDID)!{error,MSJE};

                          ["UPD",CMDID|ARG]   -> MSJE = lists:append([X++" "|| X <-ARG]),
                                                 io:format("~n~s",[MSJE]),
                                                 gen_tcp:send(Socket,"OK "++CMDID);

                          [_,CMDID|ARG]   ->   MSJE = lists:append([X++" "|| X <-ARG]),
                                                 RR = list_to_atom(CMDID),
                                                  case whereis(RR) of
                                                      undefined -> ok;
                                                      _OTRO -> RR!{error,MSJE}
                                                  end;
                          ALL               ->   io:format("~nRPTA SERVER: ~p",[ALL])
                       end;
  {error,enotconn} -> io:format("servidor desconectado",[]),
                      gen_tcp:close(Socket),
                      unregister(requestSV),
                      halt();
          OtraCosa -> io:format("~nconexion Fallida:~p~n",[OtraCosa])

end,
reciveSV(Socket).



% escucha la respuesta de reciveSV asociado a sus respectivos CMID
cmidf(CMID,IdVisit)->
  receive
    {At,RPTA}    -> io:format("Rpta cmd ~p:~s",[CMID,RPTA]),
                    unregister(CMID),
                    IdVisit!{At,RPTA}
  after
    20000 ->
      unregister(CMID),
      io:format("\nEl servidor tardo demasiado en responder a la peticion ~p",[CMID])
  end.

idGenerate(Id)->
  receive
    IdVisit -> IdVisit!("id"++integer_to_list(Id)),
               idGenerate(Id+1)
  end.
getCMID()->
  idGenerateR!self(),
  receive  NewID -> NewID end.

frequestSV() ->
  CMIDTR = getCMID(),
  CMDID = list_to_atom(CMIDTR),
 receive % recepcion del msj a enviar
    {send,IdVisit,Socket,Data} -> case Data of
                                [A,B,C|RESTO] -> CMD = [A,B,C]++" "++CMIDTR++" "++RESTO,
                                                 io:format("\nNew  cmd ~s:~s",[CMIDTR,CMD]),
                                                 register(CMDID,spawn(?MODULE,cmidf,[CMDID,IdVisit])), % B)
                                                 gen_tcp:send(Socket,CMD); % envio del msj al servidor
                                      _OTRO    -> io:format("\nComando Invalido")
                                 end;

    _ALL -> io:format("invalid para el envio")
end,
frequestSV().

% B) esta funcion se quedara escuchando la respuesta del servidor al la peticion CMID


% Permite iniciar session en el server
login(Msj,Socket)->
  io:format("\n\n\n\n\n\n\n\n\n\n\n\n~s~n",[Msj]),
  io:format("por favor ingrese su nick~n"),
  {ok,[Nick]} = io:fread(">> ","~s"),

  %validamos si no existe el user en el servidor
  requestSV!{send,self(),Socket,"CON " ++ Nick},
  receive
    {ok,_MSJE}    -> {ok,Nick};
    {error,MSJE} -> login(MSJE,Socket);
    _OtraCosa     -> {error,"\nNot Found, intentelo mas tarde"}
  end.


% INICIO DEL PROGRAMA
main(PUERTO)->
    % nos conectamos con el servidor
    {ok , Socket} = gen_tcp:connect("localhost"
                                   , PUERTO

                                   , [ binary
                                     , {packet, 0},{active, false}]), % X)

    spawn(?MODULE,reciveSV,[Socket]), % escuchara todos los mensajes que envie el servidor
    register(requestSV,spawn(?MODULE,frequestSV,[])), % permite enviar peticiones
    register(idGenerateR,spawn(?MODULE,idGenerate,[100])), % genera los cmid unicos

    % iniciamos session en el servidor
    case login("BIENVENIDO",Socket) of
      {ok,NewUser}  -> menu(NewUser,Socket); % todo bien podemos mostrar los ComandosValidos
      {error,ERROR} -> io:format("~s",[ERROR]), % el server no responde
                       gen_tcp:close(Socket),
                       unregister(requestSV)
    end.

% X) Puesto que no funciono con el receive,"supongo es porque los msj del socket,
%    llegan al hilo ejecuatndose en la terminal de erl" y no en a la fun :reciveSV(Socket)
%    y para que del lado del cliente funcione el gen_tcp:recv(Socket, 0) añado {active false}
