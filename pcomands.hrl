
% ## PCOMANDOS
% ## SE EJECUTAN EN EL NODO DE MENOR CARGA
% ##########################################

% ##
% # CON ======================================
% ##

rchList(_FBool,[],_BUSQUEDA)-> false;
rchList(FBool,[X|XS],BUSQUEDA)->
  io:format("~p~n",[[FBool,X,XS,BUSQUEDA]]),
  case FBool(X,BUSQUEDA) of
    false  -> rchList(FBool,XS,BUSQUEDA);
    true   -> true
  end.

pcmdCON(IdVisit,Socket,UserName)->
  LN    = [node()]++ nodes(),
  RET = rchList(fun ?MODULE:usrExist/2,LN,UserName),
  case RET of
    true -> IdVisit!{error,"El usuario ya esta registrado"};
    false ->NewPid = spawn(node(),?MODULE,mindUser,[Socket]),
            usrAdd(node(),Socket,usrMakeData(UserName,NewPid)),
            IdVisit!{ok,"se registro correctamente"}
  end.

% ##
% # LSG ======================================
% ##
game_to_str(X)->
  {game,Id,_N,S,_PIDGL} = X,
  "> "++atom_to_list(Id)++" "++S++"\n".

nodo_to_str(X)->
  L = maps:values(gsGets(X)),
  case L of
    [] -> "";
    _Else->lists:concat(lists:map(fun ?MODULE:game_to_str/1,L))
  end.

nodes_to_str()->
  LN  = [node()]++ nodes(),
  lists:map(fun ?MODULE:nodo_to_str/1,LN).

pcmdLSG(IdVisit,_)->
  RET = lists:concat(nodes_to_str()),
  case RET of
    []   ->IdVisit!{ok,"Aun no existen juegos activos"};
    _ELSE ->IdVisit!{ok,"\n    id  estado\n"++RET}
end.

% ##
% # NEW ======================================
% ##
jostickCrlCatchError(J1NAME,J2NAME,MAPOBS,TURNO,PIDtateti,IDDELJUEGO)->
  process_flag(trap_exit, true),
  jostickCrl(J1NAME,J2NAME,MAPOBS,TURNO,PIDtateti,IDDELJUEGO).

pcmdNEW(IdVisit,Socket)->
  % la lista de observadores
  MAPOBS = #{},
  % otenemos el Nombre y la fConcienia a partir del socket
  {userMind,J1NAME,PIDC} = usrGet(node(),Socket), % Tener en cuenta q se pudo crear en en otros nodos usar usrGEtG
  % iniciamos una partida tateti
  PIDtateti= tateti:init(),
  % iniciamos el jostick del juego anterior, puede ser otro juego por simplicidad solo tenemos el tateti
  IDJOSTICK = spawn(node(),?MODULE,jostickCrlCatchError,[J1NAME,"",maps:put(PIDC,PIDC,MAPOBS),J1NAME,PIDtateti,idGameNull]),
  % linkeamos la fConcienia con el controlador anterior para detectar cuando al user se le va la luz y finalizar la partida
  PIDC!{linkear,IDJOSTICK},
  % creamos el juego a partir del PID del jostick
  {game,IDGAMEE,A,B,C} = gsMake(IDJOSTICK),
  % nombramos con el id Generado al nuevo juego creado
  IDJOSTICK!{bautizar,atom_to_list(IDGAMEE)},
  gsAdd(node(),{game,IDGAMEE,A,B,C}), % añadimos a la lista de juegos activos
  IdVisit!{ok,"Nuevo juego creado con exito, en espera de contrincante"}.

% ##
% # ACC ======================================
% ##

pcmdACC(IdVisit,Socket,IdGame)->
  {userMind,J2NAME,PIDC}     = usrGet(node(),Socket), % NO olvidar el global get
  {NODOdelGAME,GAMESTRUCT}   = gsGetG(IdGame),

  % -record(game, {idGlobalGame,name,status,pidControl}).
  case GAMESTRUCT of
    {game,_,_,"Activo",_IDJOSTICK} -> IdVisit!{error,"El juego esta completo"};
    {game,_,_,_,IDJOSTICK}        ->
                                      % Envaimos un msj al jostic para tratar de conectarnos
                                      IDJOSTICK!{unirse,self(),J2NAME,IdGame,PIDC},
                                      receive
                                        {ok,MSJ}    -> gsUPDSTATE(NODOdelGAME,list_to_atom(IdGame)),
                                                       PIDC!{linkear,IDJOSTICK}, % linkeamos la fConcienia con el controlador
                                                       IdVisit!{ok,MSJ};
                                        {error,MSJ} -> IdVisit!{error,MSJ}
                                      after 5000  -> IdVisit!{error,"El jostick no responde"}
                                      end;
        null                      -> IdVisit!{error,"No existe el juego con la clave "++IdGame}
    end.

% ##
% # PLA ======================================
% ##

pcmdPLA(IdVisit,Socket,IdGame,JUGADA)->
  {userMind,NAME,_PID} = usrGet(node(),Socket), % otenemos el Nombre y la fConcienia a partir del socket
  {_NODOdelGAME,GAMESTRUCT}   = gsGetG(IdGame),

  case  GAMESTRUCT of
    {game,_,_,"Espera",_IDJOSTICK}   -> IdVisit!{error,"Esperando contrincante"};
    {game,_,_,"Activo",IDJOSTICK}   -> IDJOSTICK!{jugada,self(),NAME,list_to_integer(JUGADA)},
                                        receive
                                          {ok,MSJ}    -> IdVisit!{ok,MSJ};
                                          {error,MSJ} -> IdVisit!{error,MSJ}
                                        after 5000  -> IdVisit!{error,"El jostick no responde"}
                                        end;
      null                          -> IdVisit!{error,"No existe el juego con la clave "++IdGame}
  end.

% % ##
% % # OBS ======================================
% % ##

pcmdOBS(IdVisit,Socket,GAMEID)->
  {userMind,_NAME,PID} = usrGet(node(),Socket), % otenemos el Nombre y la fConcienia a partir del socket
  {_NODOdelGAME,GAMESTRUCT}   = gsGetG(GAMEID),
  case  GAMESTRUCT of
    {game,_,_,  "Espera",_IDJOSTICK} -> IdVisit!{error,"Aun no incio la partida"};
    {game,_,_,"Activo",IDJOSTICK} -> IDJOSTICK!{obsGAME,self(),PID},
                                        receive
                                          {ok,MSJ}    -> PID!{linkear,IDJOSTICK},
                                                         IdVisit!{ok,MSJ}

                                        after 5000  -> IdVisit!{error,"El jostick no responde"}
                                        end;
      null                          -> IdVisit!{ok,"No existe el juego con la clave "++GAMEID}
  end.

% % ##
% % # LEA ======================================
% % ##

pcmdLEA(IdVisit,Socket,GAMEID)->
  {userMind,_NAME,PID} = usrGet(node(),Socket), % otenemos el Nombre y la fConcienia a partir del socket
  {_NODOdelGAME,GAMESTRUCT}   = gsGetG(GAMEID),
  case  GAMESTRUCT of
    {game,_,_,  "Espera",_IDJOSTICK} -> IdVisit!{error,"Aun no incio la partida"};
    {game,_,_,"Activo",IDJOSTICK} -> IDJOSTICK!{unObs,self(),PID},
                                        receive
                                          {ok,MSJ}    -> PID!{unlinkear,IDJOSTICK},
                                                         IdVisit!{ok,MSJ}

                                        after 5000  -> IdVisit!{error,"El jostick no responde"}
                                        end;
      null                          -> IdVisit!{ok,"No existe el juego con la clave "++GAMEID}
  end.
