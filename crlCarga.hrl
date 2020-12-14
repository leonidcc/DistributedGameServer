
%   CONTROLADOR DE CARGA DE LOS NODOS
%    - nombre de Registro: nodeController

-define(UPDATECARGA, 5000). % tiempo de actualizacion de cargas

% ==-FUNCIONES-==
% "permite mantener y saber el estado de los nodos"

% > nodesInit()         :: Inicializa el controlador de carga
% > nodesMinCarg()      :: Retorna el nodo con menor carga
% > nodesListCarga()    :: Retorna lista de todos los nodos
%                          con sus respectiva carga
% > nodesUpdateNow()    :: Auctaliza el estado de carga de los nodos al invocarse

% ==-IMPLEMENTACION-==
nodesControlador(NODOSCARGASort)->
    receive
        {minNodo,IDvisit} ->
            IDvisit!lists:nth(1,NODOSCARGASort),
            nodesControlador(NODOSCARGASort);
        {listNodesCarga,IDvisit} ->
            IDvisit!NODOSCARGASort,
            nodesControlador(NODOSCARGASort);
        {update,NODOSCARGASortUp} ->io:format("\n CARGA DE NODOS actual:\n~p\n",[NODOSCARGASortUp]),
            nodesControlador(NODOSCARGASortUp)
    end.


nodesListCarga()->
    nodeController!{listNodesCarga,self()},
    receive
        MinNodoLsit-> MinNodoLsit
    end.

% pregunta la carga al nodo NODENAME y lo retorna
cargaCalc(NODENAME)->
    % io:format("\n\npregutamos a~p",[NODENAME]),
    register(cargaCalcT,self()), % esto porque no funciona con el pid, y lo tuvimos que registrar
    {pstat,NODENAME}!{carga,cargaCalcT,node()},
    receive
        RPTA ->
        unregister(cargaCalcT),% esto para poder registralo en otra llamada
        RPTA
    end.




% Pregunta a los nodos conectados a el cual es su carga
% construye un arreglo con de {nodoX,cargaNdoX}
nodesUpdateNow()->
    LISTNODES =  [node()]++nodes(),
    NODOSCARGA =  [{X,cargaCalc(X)} || X <- LISTNODES],
    NODOSCARGASort = lists:sort(fun({_A,B},{_C,D}) -> B =< D end,NODOSCARGA),
    nodeController!{update,NODOSCARGASort}.

% esto cada UPDATECARGA milisegundos
nodesUpdate()->
    nodesUpdateNow(),
    pause(?UPDATECARGA),
    nodesUpdate().


nodesMinCarg()->
    nodeController!{minNodo,self()},
    receive
        MinNodo -> {Node,_Carga} = MinNodo,Node
    end.

pause(MLSEG)->
    receive
    after MLSEG -> ok end.

nodesInit()->
    CARGA = statistics(run_queue),
    register(nodeController,spawn(?MODULE,nodesControlador,[[{node(),CARGA}]])),
    spawn(?MODULE,nodesUpdate,[]).
