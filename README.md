# servidor distribuido

Chanco Castillo leonid
Barraud Alexis

Ejecución del servidor

### SERVER

**Abrir  dos o más máquinas virtuales de Erlang con sus respectivos nombres:**
```
 name@pc-name:$ erl -sname a
 name@pc-name:$ erl -sname b
```
Procedemos a compilar los archivos del servidor
```
(a@pc-name)1> c(tateti).
(a@pc-name)2> c(server).
```
En cada maquina virtual levantar el servidor  con
su respectivo puerto como parámetro
> puerto por donde escuchara este servidor
```
(a@pc-name)3> server:init(8000).
```
```
(b@pc-name)1> server:init(8001).
```

Conectar los servidores (Nodos) entre si
> permite comunicarse e intercambiar información
```
(b@pc-name)2> server:connect('a@pc-name').
```
> si tiene creo mas nodos puede continuar
(b@pc-name)3> server:connect('c@pc-name').
(b@pc-name)4> server:connect('dpc-name').
 ...

Llegado a este punto tenemos todos una red de servidores
levantados escuchando en su determinado puerto



### CLIENTE
**Abrir  dos o más máquinas virtuales de Erlang**

```
 name@pc-name:$ erl  
 name@pc-name:$ erl
```
 En una de ellas compilar
```
1> c(cli).
```
En cada maquina virtual ejecutar con su respectivo puerto
```
1> cli:main(8000).
```
se le mostrara un login:

_> BIENVENIDO
 por favor ingrese su nick
>> nickName_

Ingresan el nombre de usuario que deseen y se les mostrara un menu
donde podrán realizar las acciones permitidas ahí.

_>>========================<<
  🖧--STEAM TRUCHO--🖧     👤 nickName

  ComandosValidos:

    🔹LSG                >Lista juegos
    🔹NEW idGame         >Crea un nuevo juego
    🔹ACC idGame         >Acepta partida
    🔹OBS idGame         >Observar partida
    🔹PLA idGame JUGADA  >Realizar una jugada
    🔹BYE                >Salir
>>========================<<
 >>_


ARCHIVOS REQUERIDOS

`crlPstat.hrl``crlCarga.hrl``crlUserSock.hrl``crlListGame.hrl``crlJostick.hrl``pcomands.hrl``server.erl``tateti.erl``cli.erl`
