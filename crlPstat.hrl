

% Se ejecuta una funcion registrado como:
% >> ptast
% que al enviarle un msj este responde con la carga del nodo

% Para desarrollos practicos implementamos como la carga de un nodo a la rpta. de statistics(run_queue),
% sin embargo esto se puede complejizar al nivel que el implementador lo desee,
% teniendo en cuenta que pstat siempre responda un numero.

% ==-IMPLEMENTACION-==

% responde con la carga de su nodo
fpstat()->
    receive
        {carga,IDPID,NODO} ->
            % RPTA = statistics(total_active_tasks), 
            RPTA = statistics(run_queue),
            {IDPID,NODO}!RPTA,fpstat()
    end.

pstatInit()->
    register(pstat,spawn(?MODULE,fpstat,[])).
