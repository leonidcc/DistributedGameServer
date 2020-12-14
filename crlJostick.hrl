
% Envia las actualizaciones a cada observador
sendUpdate(Update,OBS)->
  io:format("UPDARTE~p",[OBS]),
  maps:map(fun (_X,Y)-> Y!{renderGame,Update} end,OBS).

% El joestick es el encargado de procesar las siguientes acciones:
% - añadir jugador, realizar jugada,  añadir observadores, quitar observadores.
% Este interactua direcamente con el juego ademas de caprurar si un jugador u observador se desconecta
jostickCrl(J1,J2,OBS,Turn,PIDtateti,IDGAME)->
  receive
    % Actualiza a IDGAMEE con el codigo que se genero al ser creado el juego
    {bautizar,IDGAMEE}->jostickCrl(J1,J2,OBS,Turn,PIDtateti,IDGAMEE);

    % Cuando alguien se une
    {unirse,IdVisit,J2NAME,IDGAMENEW,PIDC} ->
       case {J2,J2NAME} of
                      % si coincide con el jugador 1
            {_,J1} -> IdVisit!{error,"YA sos parte de la partida"},
                      jostickCrl(J1,J2,OBS,Turn,PIDtateti,IDGAME);

                      % si esta disponibleun 2do jugador
            {"",_} -> io:format("Se unio0 ~s~n",[J2NAME]),
                      OBSN = maps:put(PIDC,PIDC,OBS),
                      PIDtateti!{getTab,self()},
                      receive
                        TABLERO -> sendUpdate(J1++" VS "++J2NAME++"\n"++TABLERO,OBSN),
                                   IdVisit!{ok,"Usted se unio a la partida "++ IDGAMENEW }
                      end,
                      TURNO = J2NAME, %calcular el turno al azar
                      sendUpdate("\nTurno de "++TURNO,OBSN),
                      jostickCrl(J1,J2NAME,OBSN,{TURNO,j1},PIDtateti,IDGAMENEW); % es el turno del q se unio

                      % otro caso
            {_,_}  -> IdVisit!{error,"La partida esta completa"},
                      jostickCrl(J1,J2,OBS,Turn,PIDtateti,IDGAME)
       end;

    % Cuando alguien quiere jugar
    {jugada,IdVisit,UserName,Jugada}->
      {TURNAME,JT} = Turn,
      case TURNAME == UserName of
           false -> IdVisit!{ok,"Por favor espere su turno"},
                    jostickCrl(J1,J2,OBS,Turn,PIDtateti,IDGAME);
           true  -> PIDtateti!{JT, self(), Jugada},
                    receive
                      {ok,Update} -> case Turn of
                                          {J1,_} ->IdVisit!{ok,"bien"},sendUpdate("GAME:"++IDGAME++"\n"++Update,OBS),
                                                   jostickCrl(J1,J2,OBS,{J2,j1},PIDtateti,IDGAME);
                                          {J2,_} ->IdVisit!{ok,"bien"},sendUpdate("GAME:"++IDGAME++"\n"++Update,OBS),
                                                  jostickCrl(J1,J2,OBS,{J1,j2},PIDtateti,IDGAME)
                                     end;
                      {win,Update}   ->IdVisit!{ok,"bien"},sendUpdate("GANO!!"++UserName++"\n"++Update,OBS);
                      {full,Update}  ->IdVisit!{ok,"bien"},sendUpdate("EMPATE!!\n"++Update,OBS);
                      {invalid,MSJ}  ->IdVisit!{error,MSJ},jostickCrl(J1,J2,OBS,Turn,PIDtateti,IDGAME)
                    end
      end;

    {obsGAME,IdVisit,PIDC}-> PIDtateti!{getTab,self()},
                            receive
                              TABLERO -> RPTA = ("\n"++J1++" VS "++J2++"\n"++TABLERO),
                                         IdVisit!{ok,RPTA}
                            end,
                           jostickCrl(J1,J2,maps:put(PIDC,PIDC,OBS),Turn,PIDtateti,IDGAME);

    {unObs,IdVisit,PIDC}-> IdVisit!{ok,"es removido"},
                           jostickCrl(J1,J2,maps:remove(PIDC,OBS),Turn,PIDtateti,IDGAME);

    % MANEJO DE DESCONEXIONES
    {'EXIT',PID,NOMBRE} -> case NOMBRE of
                                  J1 -> sendUpdate("GAME:"++IDGAME++" finalizo por abandono de "++J1,OBS),
                                        io:format("============>removemos a ~p",[IDGAME]),
                                        gsRmv(node(),list_to_atom(IDGAME)),
                                        io:format("============>removemos 2 a ~p",[IDGAME]),
                                        exit(PIDtateti), %Termino al tateti game
                                        exit(finGame); %Termino el jostick
                                  J2 -> sendUpdate("GAME:"++IDGAME++" finalizo por abandono de "++J2,OBS),
                                        io:format("============>removemos a ~p",[IDGAME]),
                                        gsRmv(node(),list_to_atom(IDGAME)),
                                        exit(PIDtateti), %Termino al tateti game
                                        exit(finGame); %Termino el jostick
                                  OBS-> jostickCrl(J1,J2,maps:remove(PID,OBS),Turn,PIDtateti,IDGAME)
                                end
  end.





% ESTO NNO TIENE SENTIDO AHRE
%  {obs,IdVisit,PIDC}->  OBSN = maps:put(PIDC,PIDC,OBS),
%                        PIDtateti!{getTab,self()},
%                        IdVisit!{ok,"es añadido como observador"},
%                        % receive
%                        %   TABLERO -> %RPTA = ("\n"++J1++" VS "++J2++"\n"++TABLERO),
%                        %              IdVisit!{ok,"OBS ADD PELOTUDO"}
%                        % end,
%                        jostickCrl(J1,J2,OBSN,Turn,PIDtateti,IDGAME);
%
% % Al dejar de ver
