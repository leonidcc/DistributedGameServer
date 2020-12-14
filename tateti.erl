-module(tateti).
-compile(export_all).


convert([],Iterador)-> "\n";
convert([X|XS],Iterador)->

  if (Iterador rem 4) == 0 ->
      "\n" ++ convert([X|XS], Iterador+1);
    true ->
      case X of
        j1 ->
          " X " ++ convert(XS, Iterador+1);

        j2 ->
          " O " ++ convert(XS, Iterador+1);

        _  -> " - " ++ convert(XS, Iterador+1)
      end
end.




change_player(Jugador,Lista) ->
    case Jugador of
        j1  -> movem(j2,Lista);
        j2  -> movem(j1,Lista);
        _   -> error("algo se rompio")
    end.


movem(Jugador,Lista) ->
	receive
		{getTab,IdVisit}-> IdVisit!(convert(Lista,0)++"\nJUGADA: <n° entre 1 y 9>"),movem(Jugador,Lista);
		{Jugador, Pid_J, Jugada} when Jugada >= 1; Jugada =< 9 ->
    		{status, St, ListaN} = meter(Jugador,Jugada, Lista),
				case St of
				    0   -> Pid_J ! {ok,convert(ListaN,0)},change_player(Jugador,ListaN);
            1   -> Pid_J ! {win, convert(ListaN,0)};
					 -1   -> Pid_J ! {full, convert(ListaN,0)};
            2   -> Pid_J ! {invalid,convert(ListaN,0)},movem(Jugador,ListaN)
				end;
		{KK,Pid_J,K} -> io:format("invalida~p",[{KK,Pid_J,K}]),
            Pid_J ! {invalid, "Indice malo"},
            movem(Jugador,Lista)
	end.

init() ->
	TABLERO = [0,0,0,0,0,0,0,0,0],
	spawn(?MODULE, movem, [j1,TABLERO]).


isfull(ListaN) ->
	case lists:member(0, ListaN) of
        true  -> {status, 0, ListaN};
		false -> {status, -1, ListaN}
	end.

meter(Pl,Jugada ,Lista) ->
	case lists:nth(Jugada, Lista) == 0 of		% Pregunta si el lugar esta vacio
		true ->
			ListaN = lists:sublist(Lista, Jugada-1) ++ [Pl] ++ lists:nthtail(Jugada, Lista),
			case ListaN of
				[Pl,Pl,Pl,_,_,_,_,_,_] -> {status, 1, ListaN};
				[_,_,_,Pl,Pl,Pl,_,_,_] -> {status, 1, ListaN};
				[_,_,_,_,_,_,Pl,Pl,Pl] -> {status, 1, ListaN};
				[Pl,_,_,Pl,_,_,Pl,_,_] -> {status, 1, ListaN};
				[_,Pl,_,_,Pl,_,_,Pl,_] -> {status, 1, ListaN};
				[_,_,Pl,_,_,Pl,_,_,Pl] -> {status, 1, ListaN};
				[Pl,_,_,_,Pl,_,_,_,Pl] -> {status, 1, ListaN};
				[_,_,Pl,_,Pl,_,Pl,_,_] -> {status, 1, ListaN};
				_                      -> isfull(ListaN)
			end;
		false ->  {status, 2,Lista}%% Repetir jugada en otro lugar
	end.

% funcion(A) ->
%     receive
%     {A,_} -> io:format("EXITO"),funcion(j2);
%     _   -> io:format("FRACASO"),funcion(A)
% end.
