;; Este modelo incluye:
;; Botón para seguir a una persona
;; Botón para dejar de seguir a esa persona
;; Botón para ejecutar el modelo cada 30 días (puede continuar cuando se cliquee nuevamente el botón)
;; Un barrio de 4 manzanas iguales, identificada cada una con un color diferente
;;la fumigación sólo puede realizarse cuando la cantidad de mosquitos supera el 50% de los mosquitos iniciales o cuando hay tres veces la cantidad de personas infectadas
;; El tiempo de simulación es de 365 días (365 ticks, 1 ticks = 1 día)
;; Cada mosquito puede picar hasta un máximo de 9 veces
;; Cuando un mosquito coincide espacialmente con una persona tiene un % de probabilidades de picarla que se define segun el sereotipo de mosquito
;; Cuando un mosquito pica, deposita huevos en un cacharro al azar
;; Los mosquitos viven entre 25 y 30 días
;; Se puede fumigar el terreno (en cada fumigación el pesticida dura una semana)
;; En la realidad, el pesticida dura 2hs pero esa fracción de tiempo es imposible de representar en este modelo ya que el tiempo mínimo es 1 tic que equivale a 8hs
;; Cada aplicación de pesticida cubre el 5% del terreno
;; También se puede descacharrizar. Cada evento reduce en un 10% la cantidad de cacharros presentes.
;; Los mosquitos pican en un radio de 5 parcelas
;; Los mosquitos se reproducen sólo si la temperatura es mayor de 15 grados
;; Al inicio se puede elegir el periodo del año a simular (verano-otoño; otoño-invierno; invierno-primavera; primavera-verano)
;; De acuerdo al periodo elegido, el modelo establece una temperatura al azar diaria en base a datos del servicio meteorologico para CABA en 2016
;; Se puede configurar al inicio un cierto porcentaje de personas infectadas y de mosquitos infectados


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;//SE DEFINEN LOS AGENTES Y SUS CARACTERISTICAS//;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
breed [personas persona] ;; la raza de agentes "personas"
breed [mosquitos mosquito] ;; la raza de agentes "mosquitos"
breed [cacharros cacharro] ;; la raza de "cacharros"
breed [pesticidas pesticida] ;; la raza de "pesticida"
breed [climas clima] ;; Define la raza de agentes "clima"

climas-own [
  estacion ;; Define la estación del año (verano, otoño, invierno, primavera)
  lluvia? ;; Booleano que indica si está lloviendo (sí/no)
  probabilidad-lluvia ;; Controla la probabilidad de que llueva durante una estación
  temperatura ;; Temperatura actual
  TminEstacionActual ;; Temperatura mínima de la estación
  TmaxEstacionActual ;; Temperatura máxima de la estación
]

personas-own [infectada? seguida? tiempo-inicio-infeccion recuperada? usando-repelente? tiempo-usando-repelente]
mosquitos-own [infectado? larva? adulto? picaduras vida-media fecha-nac foco-x foco-y puede-hibernar? hibernando? tiempo-hibernando hembra?] ;;un mosquito puede estar sano o infectado, ser larva o adulto y tener una cantidad de picaduras
;; los mosquitos no pueden picar más de 6 veces y viven entre 25 y 30 días;; foco-x y foco-y son las coordenadas donde nació el mosquito
cacharros-own [agua huevos tiempo-adultez tiempo-de-vaciado] ;;tiempo-adultez indica el tiempo que tardan los huevos de ese cacharro en convertirse en adultos
;; el tiempo-de-vaciado guarda el instante en que el cacharro se vacía
patches-own [num-manzana]







;;;;;;;;;;;;;;;;;;;;;;;;;;
;;//VARIABLES GLOBALES//;;
;;;;;;;;;;;;;;;;;;;;;;;;;;
globals
[
  nombre-archivo-out
  ticks-por-dia
  ticks-por-mes
  tiempo-infeccion
  tiempo-limite-ejecucion-modelo ;; el tiempo de ejecución del modelo
  tiempo-transcurrido
  muertos-por-fumigacion
  generaciones ;; cantidad de generaciones de mosquitos que nacieron de cacharros
  virulencia ;; probabilidad de que cuando un mosquito se encuentre con una persona la pique
  fumigacion ;; cuenta la cantidad de veces que se fumiga
  color-persona-sana
  color-persona-infectada
  color-persona-recuperada
  color-cacharros
  color-mosquitos-sanos
  tiempo-max-mosquitos-adultos
  color-mosquitos-infectados
  vida-media-min-mosquitos
  vida-media-max-mosquitos
  duracion-dias-estacion

  Tmin-verano
  Tmax-verano
  probabilidad-lluvia-verano

  Tmin-otoño
  Tmax-otoño
  probabilidad-lluvia-otoño

  Tmin-primavera
  Tmax-primavera
  probabilidad-lluvia-primavera

  Tmin-invierno
  Tmax-invierno
  probabilidad-lluvia-invierno

  probabilidad-mosquitos-hibernar
  tiempo-max-hibernacion

  max-personas-nuevas-por-dia
  max-personas-a-eliminar-por-dia

  porcentaje-reduccion-virulencia-repelente
  porcentaje-a-usar-repelente-personal
  porcentaje-a-usar-repelente-estado
  cant-dias-max-repelente
  new-virulencia

  temperatura-hibernar

  cantidad-dias-inusuales
  cant-grados-inusuales-calor
  cant-grados-inusuales-frio
  probabilidad-dias-inusuales

  temperaturas-inusuales-activas?
  dias-restantes-inusuales

  numMax

  dia-actual
  prox-posible-dia-inusual
  diferencia-entre-dias-inusuales

  max_picaduras_mosquito
  probabilidad-hembra

  min-dif-dias-inusuales
  max-dif-dias-inusuales
]
;; VARIABLES DEFINIDAS POR LOS DESLIZADORES
;;cant-inicial-personas
;;cant-inicial-mosquitos
;;cantidad-cacharros
;;%-inicial-personas-infectadas
;;%-inicial-mosquitos-infectados
;;cant-max-huevos-x-cacharro
;;tipo-dengue
;;estado-repartir-repelente
;;cant-dias-repeat-repelente-estado
;;temperaturas-inusuales


;;;;;;;;;;;;;;;;
;;//BOTONES//;;
;;;;;;;;;;;;;;;;

;; BOTON SETEAR
to setear
  ca ;;borra todo lo que hay en el terreno
  pintar-terreno
  setear-constantes ;; setear las constantes básicas del modelo
  crear-cacharros ;; crear una cierta cantidad de cacharros
  crear-mosquitos-iniciales
  crear-personas
  crear-clima
  setear-clima-inicial
  reset-ticks ;;vuelve a cero la cuenta del tiempo
end


;; BOTON EJECUTAR
to ejecutar
  tick
  set dia-actual ceiling (ticks / ticks-por-dia)
  evaporar-pesticida
  asignar-virulencia
  personas-moverse
  ask mosquitos [
    mosquitos-reproducirse
    mosquitos-moverse
    mosquitos-infectar
    mosquitos-infectarse
    mosquitos-envenenarse
    mosquitos-envejecer
  ]
  ask climas [
    activar-temperaturas-inusuales
    cambiar-temperatura-diariamente
    generar-lluvia
    cambiar-estacion
  ]
  mosquitos-hibernarnacion
  recuperacion-personas
  agregar-personas
  eliminar-personas-recuperadas
  activar-repelente-estado
  actualizar-repelentes
  exportar-datos
  if ticks > tiempo-limite-ejecucion-modelo [stop] ;;a los tiempo-ejecucion-modelo tics se detiene la ejecución
end



;;BOTON DESCACHARRIZAR
to descacharrizar

  if descacharramiento = "Todo"
  [
      if (count cacharros > 0) ;; solamente se ejecuta si la cantidad de cacharros es mayor que cero

     [
       ask n-of ((cantidad-cacharros) / 10) cacharros [die] ;; cada evento de descacharrizacion (clic en boton), se reduce en un 10% la cantidad de cacharros inicial
     ]
  ]

  if descacharramiento = "Manzana 1"
  [
      if (count cacharros with [pcolor = 62] > 0) ;; solamente se ejecuta si la cantidad de cacharros es mayor que cero

     [
       ask n-of 1 cacharros with [pcolor = 62] [die]
     ]
  ]

  if descacharramiento = "Manzana 2"
  [
      if (count cacharros with [pcolor = 64] > 0) ;; solamente se ejecuta si la cantidad de cacharros es mayor que cero

     [
       ask n-of 1 cacharros with [pcolor = 64] [die]
     ]
  ]

  if descacharramiento = "Manzana 3"
  [
      if (count cacharros with [pcolor = 66] > 0) ;; solamente se ejecuta si la cantidad de cacharros es mayor que cero

     [
       ask n-of 1 cacharros with [pcolor = 66] [die]
     ]
  ]

  if descacharramiento = "Manzana 4"
  [
      if (count cacharros with [pcolor = 68] > 0) ;; solamente se ejecuta si la cantidad de cacharros es mayor que cero

     [
       ask n-of 1 cacharros with [pcolor = 68] [die]
     ]
  ]
end



;;BOTON FUMIGAR
to fumigar
  ;;ask n-of (5 * 101 * 101 / 100) patches [set pcolor pink] // se fumiga el 5% del terreno, y el terreno fumigado aparece de color rosa
  ;; las condiciones de fumigación es que haya más del tercio de las personas infectadas o que haya el quíntuple de mosquitos que la cantidad inicial
  if (((count personas with [infectada?]) > (cant-inicial-personas / 3)) OR (count mosquitos > (cant-inicial-mosquitos * 5))) AND (ticks < 540) AND fumigacion < 3
  [
  if count pesticidas <= 0 [create-pesticidas 500 [set color pink set shape "square" set size 1 setxy random-xcor random-ycor]]
  set fumigacion fumigacion + 1
  ]
end


;;BOTON SEGUIR PERSONA
to seguir-persona
  ask one-of personas [set seguida? true]
  watch one-of personas with [seguida? = true]
end







;;;;;;;;;;;;;;;;;;;;;;
;;//PROCEDIMIENTOS//;;
;;;;;;;;;;;;;;;;;;;;;;


;;;;; UNICA VEZ ;;;;;;

;; AGENTE CLIMA ;;

;; CREAR EL CLIMA
to crear-clima
  create-climas 1 [
    set lluvia? false
  ]
end

;; SETEAR VALORES INICIALES AL CLIMA
to setear-clima-inicial
  ask climas [
    set estacion "verano"
    set TminEstacionActual Tmin-verano
    set TmaxEstacionActual Tmax-verano
    set probabilidad-lluvia probabilidad-lluvia-verano
    set lluvia? false ;; Inicialmente no está lloviendo
    set temperatura (round ((TminEstacionActual + random-float (TmaxEstacionActual - TminEstacionActual)) * 100)) / 100
]

end


;;PINTA LAS MANZANAS
to pintar-terreno
  ;; Manzana 1
  ask patches with [pxcor >= -50 AND pxcor <= 0 AND pycor >= 0 AND pycor <= 50]  [set pcolor 62] ;; verde oscuro
  ;; Manzana 2
  ask patches with [pxcor >= 0 AND pxcor <= 50 AND pycor >= 0 AND pycor <= 50]  [set pcolor 64] ;; verde un poco mas claro
  ;; Manzana 3
  ask patches with [pxcor >= -50 AND pxcor <= 0 AND pycor >= -50 AND pycor <= 0 ]  [set pcolor 66] ;; verde aun mas claro
  ;; Manzana 4
  ask patches with [pxcor >= 0  AND pxcor <= 50 AND pycor >= -50 AND pycor <= 0 ]  [set pcolor 68] ;; verde clarito
end



;;SETEA LAS CONSTANTES
to setear-constantes
  set tiempo-limite-ejecucion-modelo 1095 ;;el modelo se ejecuta durante 365 tics
  set ticks-por-mes tiempo-limite-ejecucion-modelo / 12
  set tiempo-infeccion 7
  set muertos-por-fumigacion 0
  set virulencia 80
  set color-persona-sana white ;;las personas sanas son de color blanco
  set color-persona-infectada red ;;las personas sanas son de color rojo
  set color-cacharros blue
  set color-mosquitos-sanos yellow
  set ticks-por-dia ceiling (tiempo-limite-ejecucion-modelo / 365)
  set tiempo-max-mosquitos-adultos ticks-por-dia * 10 ;;los mosquitos tardan 10 dias en volverse adultos desde el huevo
  set color-mosquitos-infectados orange
  set color-persona-recuperada green
  set vida-media-min-mosquitos 15
  set vida-media-max-mosquitos 30
  set duracion-dias-estacion 92

  set Tmin-verano 19
  set Tmax-verano 39.7
  set probabilidad-lluvia-verano 0.2

  set Tmin-otoño 8.4
  set Tmax-otoño 14.6
  set probabilidad-lluvia-otoño 0.4

  set Tmin-invierno 2.1
  set Tmax-invierno 12.2
  set probabilidad-lluvia-invierno 0.8

  set Tmin-primavera 17.1
  set Tmax-primavera 30.8
  set probabilidad-lluvia-primavera 0.3

  set probabilidad-mosquitos-hibernar 20
  set tiempo-max-hibernacion ticks-por-dia * 390


  set max-personas-nuevas-por-dia 15
  set max-personas-a-eliminar-por-dia 20

  set porcentaje-reduccion-virulencia-repelente 1
  set porcentaje-a-usar-repelente-personal 10
  set porcentaje-a-usar-repelente-estado 100
  set cant-dias-max-repelente 9

  set temperatura-hibernar 15

  set cantidad-dias-inusuales 7
  set cant-grados-inusuales-calor 1
  set cant-grados-inusuales-frio 4
  set probabilidad-dias-inusuales 20

  set temperaturas-inusuales-activas? false
  set dias-restantes-inusuales 0

  set prox-posible-dia-inusual 0

  set max_picaduras_mosquito 9
  set probabilidad-hembra 50

  set min-dif-dias-inusuales 25
  set max-dif-dias-inusuales 300

  set nombre-archivo-out "datos-simulacion.csv"

end




to asignar-virulencia
  if tipo-dengue = "DEN-1" [
    set virulencia 70
  ]
  if tipo-dengue = "DEN-2" [
    set virulencia 80
  ]
  if tipo-dengue = "DEN-3" [
    set virulencia 65
  ]
  if tipo-dengue = "DEN-4" [
    set virulencia 60
  ]
end












;; CREA A LAS PERSONAS
to crear-personas
  create-personas cant-inicial-personas ;;crear la cantidad de personas indicadas por el deslizador
  [
    setxy random-xcor random-ycor ;;ubicación al azar
    set shape "persona" ;;forma de persona
    set infectada? false ;;las personas nacen no infectadas ("sanas")
    set seguida? false ;;las personas NO son seguidas por default
    set recuperada? false
    set size 4.5 ;;más fácil de ver
    set color color-persona-sana
    set usando-repelente? false
    set tiempo-usando-repelente 0
  ]
  ask n-of ((%-inicial-personas-infectadas * cant-inicial-personas) / 100) personas [set infectada? true set color color-persona-infectada] ;; crea una cantidad de personas infectadas iniciales
end

;; CREA LOS CACHARROS
to crear-cacharros ;;crea la cantidad de cacharros especificada en el deslizador y los distribuye al azar en el terreno
   ask n-of cantidad-cacharros patches with [pcolor >= 62 AND pcolor <= 68]
   [
    sprout-cacharros 1 ;; cada parcela dentro de las manzanas crea la cantidad de cacharros indicada por el deslizador
    [
    set shape "redondel" ;;forma de redondel
    set size 2
    set color color-cacharros ;; los cacharros son de color azul
    set agua true ;; cuando se crean, los cacharros tienen agua
    set huevos random cant-max-huevos-x-cacharro ;; cada cacharro tiene inicialmente una cantidad de huevos al azar
    set tiempo-adultez tiempo-max-mosquitos-adultos
    set tiempo-de-vaciado 0
    ]
   ]
end

;; CREA LOS MOSQUITOS
to crear-mosquitos-iniciales
  create-mosquitos cant-inicial-mosquitos ;;crear la cantidad de mosquitos indicada por el deslizador
  [
    setxy random-xcor random-ycor
    set foco-x xcor ;;la coordenada en X donde nació el mosquito
    set foco-y ycor ;;la coordenada en Y donde nació el mosquito
    ;;set centro-mosquito patch-here ;;el patch donde nace el mosquito
    set shape "mosquito"
    set infectado? false ;;todos los mosquitos nacen sanos
    set larva? false ;;todos los mosquitos nacen adultos
    set adulto? true ;;todos los mosquitos que se crean al principio nacen adultos
    set picaduras 0 ;;cuando nacen todavía no picaron nunca
    set vida-media ((ticks-por-dia * vida-media-min-mosquitos) + random (ticks-por-dia * vida-media-max-mosquitos)) ;;los mosquitos viven entre 25 y 30 días
    set fecha-nac 0 ;;
    set size 3 ;; tamaño 2
    set color color-mosquitos-sanos ;;los mosquitos sanos son de color amarillo
    ifelse random-float 100 < probabilidad-mosquitos-hibernar [
      set puede-hibernar? true
      set hibernando? false
      set tiempo-hibernando 0
    ][
      set puede-hibernar? false
      set hibernando? false
      set tiempo-hibernando 0
     ]

    ifelse random-float 100 < probabilidad-hembra [
      set hembra? true
    ]
    [
      set hembra? false
    ]
  ]
 ask n-of (cant-inicial-mosquitos * %-inicial-mosquitos-infectados / 100) mosquitos ;; la cantidad inicial de mosquitos infectados dado por el deslizador
  [
 set infectado? true ;;están infectados al inicio de la simulación
set color color-mosquitos-infectados ;;y los mosquitos infectados son de color naranja
  ]
end








;;;;;;;; PROCEDIMIENTOS RECURRENTES ;;;;;;;;;

;; AGENTE PESTICIDA

;; EVAPORA EL PESTICIDA
to evaporar-pesticida
  if (count pesticidas)  > 0
  [
    if remainder ticks 21 = 0
    [
      ask pesticidas [die]
    ]
  ]
end


;; AGENTE CLIMA

;; CAMBIA LA ESTACION DEL AÑO
to cambiar-estacion
  if ticks mod (ticks-por-dia * duracion-dias-estacion) = 0 [ ;; Cambia cada estacion
    let climaActual one-of climas ;; Obtiene el único agente clima
    if [estacion] of climaActual = "verano" [
      ask climas [
        set estacion "otoño"
        set TminEstacionActual Tmin-otoño
        set TmaxEstacionActual Tmax-otoño
        set probabilidad-lluvia probabilidad-lluvia-otoño
      ]
      stop
    ]
    if [estacion] of climaActual = "otoño" [
        ask climas [
          set estacion "invierno"
          set TminEstacionActual Tmin-invierno
          set TmaxEstacionActual Tmax-invierno
          set probabilidad-lluvia probabilidad-lluvia-invierno
        ]
      stop
      ]
    if [estacion] of climaActual = "invierno" [
        ask climas [
          set estacion "primavera"
          set TminEstacionActual Tmin-primavera
          set TmaxEstacionActual Tmax-primavera
          set probabilidad-lluvia probabilidad-lluvia-primavera
        ]
        stop
      ]
    if [estacion] of climaActual = "primavera" [
        ask climas [
          set estacion "verano"
          set TminEstacionActual Tmin-verano
          set TmaxEstacionActual Tmax-verano
          set probabilidad-lluvia probabilidad-lluvia-verano
        ]
      stop
      ]
  ]
end



;; Genera lluvia
to generar-lluvia
  ifelse random-float 1 < probabilidad-lluvia [
    set lluvia? true ;; Se establece que está lloviendo
    ;; al estar lloviendo se llenan los cacharros
    ask cacharros with [agua = false] [
      set agua true ;; Llena cacharros vacíos con agua
    ]
  ] [
    set lluvia? false ;; No está lloviendo
  ]
end


;;Cambia la temperatura diariamente
to cambiar-temperatura-diariamente
  if ticks mod (ticks-por-dia) = 0 [ ;; Cada dia
    set diferencia-entre-dias-inusuales min-dif-dias-inusuales + random (max-dif-dias-inusuales - min-dif-dias-inusuales)

    ifelse temperaturas-inusuales-activas? [
      ;; Generar temperatura inusual
      let climaActual one-of climas
      ifelse [estacion] of climaActual = "verano" or [estacion] of climaActual = "primavera" [
        ;; Temperatura inusual menor a Tmin de la estación
        set temperatura round (generar-numero-aleatorio (TminEstacionActual - cant-grados-inusuales-calor) TminEstacionActual)
      ] [
        ;; Temperatura inusual mayor a Tmax de la estación
        set temperatura round (generar-numero-aleatorio TmaxEstacionActual (TmaxEstacionActual + cant-grados-inusuales-frio))
      ]
      set dias-restantes-inusuales dias-restantes-inusuales - 1 ;; Decrementar el contador
      if dias-restantes-inusuales <= 0 [
        set temperaturas-inusuales-activas? false ;; Desactivar temperaturas inusuales
        set prox-posible-dia-inusual dia-actual + diferencia-entre-dias-inusuales
      ]
    ]
    [
      ;; Generar temperatura normal según la estación
      ask climas [
        set temperatura (round ((TminEstacionActual + random-float (TmaxEstacionActual - TminEstacionActual)) * 100)) / 100
      ]
    ]
  ]
end


to activar-temperaturas-inusuales
  if ticks mod (ticks-por-dia) = 0 [ ;; Cada dia
    if temperaturas-inusuales = "Si" AND random-float 100 < probabilidad-dias-inusuales AND dia-actual >= prox-posible-dia-inusual AND not temperaturas-inusuales-activas? [
      set temperaturas-inusuales-activas? true
      set dias-restantes-inusuales cantidad-dias-inusuales
    ]
  ]
end




;;PERSONAS

;; MUEVE LAS PERSONAS
to personas-moverse ;;las personas se mueven al azar
  ask personas [rt random 100 lt random 100 fd 0.1 ] ;;gira a la derecha y a la izquierda de 0 a 100 grados y avanza un paso
end

;; SE RECUPERAN LAS PERSONAS
to recuperacion-personas ;; Actualiza los estados de las personas
  ask personas with [infectada? = true] [
    if ticks - tiempo-inicio-infeccion >= tiempo-infeccion [ ;; Verifica si ha pasado el tiempo de infección
      set infectada? false
      set recuperada? true
      set color color-persona-recuperada ; Cambia el color a verde para indicar recuperación
    ]
  ]
end


;; MOSQUITOS

;; REPRODUCE LOS MOSQUITOS
to mosquitos-reproducirse ;; los mosquitos se reproducen a partir de la cantidad de huevos en los cacharros
  let climaActual one-of climas ;; Obtiene el único agente clima
  if [temperatura] of climaActual > 15 ;; se reproducen sólo si la temperatura es mayor de 15 grados
   [
     ask cacharros with [huevos > 0 AND (ticks + tiempo-adultez - tiempo-de-vaciado) >= 30] ;; los cacharros que tienen huevos cuyo tiempo de incubacion es mayor o igual a 10 dias
       [
        hatch-mosquitos huevos ;; de cada cacharro nacen una cantidad al azar de mosquitos determinada por el deslizador
          [
            set shape "mosquito"
            set foco-x xcor ;;la coordenada en X donde nació el mosquito
            set foco-y ycor ;;la coordenada en Y donde nació el mosquito
            set infectado? false ;;todos los mosquitos nacen sanos
            set larva? false ;;todos los mosquitos nacen adultos
            set adulto? true ;;todos los mosquitos que se crean al principio nacen adultos
            set picaduras 0 ;;cuando nacen todavía no picaron nunca
            set vida-media ((ticks-por-dia * vida-media-min-mosquitos) + random (ticks-por-dia * vida-media-max-mosquitos)) ;;los mosquitos viven entre 25 y 30 días
            set fecha-nac ticks ;; la fecha de nacimiento es el tick actual
            set size 3
            set color yellow ;;los mosquitos nacidos de cacharros nacen sanos y son de color amarillo
            ifelse random-float 100 < probabilidad-mosquitos-hibernar [
              set puede-hibernar? true
              set hibernando? false
              set tiempo-hibernando 0
            ][
              set puede-hibernar? false
              set hibernando? false
              set tiempo-hibernando 0
            ]

            ifelse random-float 100 < probabilidad-hembra [
               set hembra? true
              ]
              [
               set hembra? false
              ]
            ]
       set huevos 0 ;; nacieron los mosquitos y el cacharro se quedó sin huevos
       set tiempo-adultez 0
       set tiempo-de-vaciado ticks
      ]
   ]
end

;; MUEVE LOS MOSQUITOS
to mosquitos-moverse ;;los mosquitos se mueven cerca de donde nacieron
  ask mosquitos with [hibernando? = false] [
    setxy (foco-x + (10 - random 20)) (foco-y + (10 - random 20))
  ]
end


;; LOS MOSQUITOS INFECTAN A LAS PERSONAS
to mosquitos-infectar ;;cuando los mosquitos encuentran una persona en la misma parcela, tienen cierta probabilidad de picarla, si la pican, la infectan
  ask mosquitos with [infectado? = true AND picaduras < max_picaduras_mosquito AND hibernando? = false AND hembra? = true] ;;sólo los mosquitos infectados y que hayan picado menos de seis veces pueden transmitir el virus
  [
    let numero-de-manzana pcolor ;;guarda el color de la parcela donde picó
    ask personas in-radius 20 with [infectada? = false AND recuperada? = false] ;;se fija si hay personas que no estén infectadas ni que se hayan recuperado
        [
          ifelse usando-repelente?
          [
            set new-virulencia virulencia - (virulencia * porcentaje-reduccion-virulencia-repelente)
          ]
          [
            set new-virulencia virulencia
          ]
          let num_aleatorio random 100
          if num_aleatorio < new-virulencia ;;probabilidad de que infecte de acuerdo al grado de virulencia del virus
              [
                set infectada? true ;; la persona es infectada
                set tiempo-inicio-infeccion ticks ;; Registra el tiempo en que la persona fue infectada
                set color red ;; las personas infectadas se vuelven de color rojo
                ask mosquitos-here [set picaduras picaduras + 1] ;; aumenta en 1 la cantidad de picaduras
                if (count cacharros with [numero-de-manzana = pcolor]) > 0
                [
                  ask n-of 1 cacharros with [numero-de-manzana = pcolor] ;;elige al azar un cacharro de la manzana donde estaba el mosquito cuando picó
                  [
                    set huevos (1 + random cant-max-huevos-x-cacharro)
                    set tiempo-adultez 0
                    set tiempo-de-vaciado ticks
                  ]
                ] ;; después de picar, el mosquito pone una cantidad de huevos al azar en un cacharro al azar
              ]
        ]
  ]
end


;; SE INFECTAN LOS MOSQUITOS
to mosquitos-infectarse ;;cuando los mosquitos sanos pican a una persona infectada, tienen un 100% de probabilidades de infectarse también.
  ask personas with [infectada? = true] ;; las personas que están infectadas
  [
    ask mosquitos-here with [infectado? = false] ;;los mosquitos que NO están infectados
      [
        set infectado? true ;; se infecta el mosquito
        set color orange ;;los mosquitos infectados por picar a una persona infectada son de color naranja
      ]
  ]
end

;; SE ENVENENAN LOS MOSQUITOS
to mosquitos-envenenarse ;; los mosquitos tienen cierta probabilidad de morir al ser fumigados

  ask pesticidas
  [
    ask mosquitos-here
    [
      if random 100 <= 10
      [
      set muertos-por-fumigacion muertos-por-fumigacion + 1
      die ;; hay un 10% de probabilidades que el mosquito muera al tocarse con los cuadrados rosa (agente pesticida)
      ]
    ]
  ]
end


;; ENVEJECEN LOS MOSQUITOS
to mosquitos-envejecer
  ask mosquitos with [hibernando? = true]
  [
      set tiempo-hibernando tiempo-hibernando + 1
  ]

  ask mosquitos with [hibernando? = false]
  [
      if ((ticks - fecha-nac) / ticks-por-dia) >= vida-media [
        die
       ] ;; si la edad supera la vida media, el mosquito muere
  ]
end









to agregar-personas
  if ticks mod (ticks-por-dia) = 0 [ ;; Cada dia agrega personas nuevas
    let climaActual one-of climas ;; Obtiene el único agente clima
    if [estacion] of climaActual  = "verano" OR [estacion] of climaActual  = "primavera"
    [
      let n-new-personas random (max-personas-nuevas-por-dia + 1) ;; +1 para incluir el máximo
      create-personas n-new-personas [
        setxy random-xcor random-ycor
        set shape "persona"
        set infectada? false
        set seguida? false
        set recuperada? false
        set size 4.5
        set color color-persona-sana
        set usando-repelente? false
        set tiempo-usando-repelente 0
      ]
    ]
  ]
end




to eliminar-personas-recuperadas
  if ticks mod (ticks-por-dia) = 0 [ ;; Cada día elimina personas
    let climaActual one-of climas ;; Obtiene el único agente clima
     let n-personas-a-eliminar random (max-personas-a-eliminar-por-dia + 1) ;; +1 para incluir el máximo
      ;; Asegurarse de que no se intenten eliminar más personas de las que existen
      let personas-recuperadas count personas with [recuperada? = true]
      if n-personas-a-eliminar > personas-recuperadas [
        set n-personas-a-eliminar personas-recuperadas ;; Ajustar si hay menos recuperadas
      ]
      ask n-of n-personas-a-eliminar personas with [recuperada? = true] [
        die ;; Elimina a la persona recuperada
      ]
  ]
end




;; Activación del uso de repelente personal
to activar-repelente-personal
  let numero-personas (count personas) ;; Cuenta el total de personas
  let cantidad-repelente round (numero-personas / porcentaje-a-usar-repelente-personal) ;; Calcula el %

  ;; Selecciona aleatoriamente al % de las personas
  ask n-of cantidad-repelente personas [
    set usando-repelente? true ;; Aplica el repelente
    set tiempo-usando-repelente 0 ;; Inicializa el contador
  ]
end


;; Activación del uso de repelente por parte del estado
to activar-repelente-estado
  if estado-repartir-repelente = "Si"
  [
    if ticks mod (ticks-por-dia * cant-dias-repeat-repelente-estado) = 0 [
     let climaActual one-of climas
     if [estacion] of climaActual = "verano" OR [estacion] of climaActual = "primavera"
     [
      let numero-personas (count personas with [usando-repelente? = false]) ;; Cuenta el total de personas
      let cantidad-repelente round ((numero-personas * porcentaje-a-usar-repelente-estado) / 100)

      ;; Selecciona aleatoriamente al % de las personas
      ask n-of cantidad-repelente personas with [usando-repelente? = false] [
        set usando-repelente? true ;; Aplica el repelente
        set tiempo-usando-repelente 0 ;; Inicializa el contador
      ]
     ]
   ]
  ]
end


to actualizar-repelentes
    if ticks mod (ticks-por-dia) = 0 [ ;; Cada día actualiza
      ask personas with [usando-repelente? = true]
      [
        set tiempo-usando-repelente tiempo-usando-repelente + 1 ;; Incrementa el contador cada día (tick)
        if tiempo-usando-repelente >= cant-dias-max-repelente [
          set usando-repelente? false ;; Se quita el repelente
          set tiempo-usando-repelente 0 ;; Reinicia el contador
        ]
      ]
   ]
end



to exportar-datos
  ;; Verifica si el archivo ya existe y lo elimina
  if ticks = 1 [
    if file-exists? nombre-archivo-out [
      file-delete nombre-archivo-out
    ]
  ]


  ;; Abre o crea el archivo CSV
  file-open nombre-archivo-out

  ;; Escribe la cabecera si es la primera vez
  if ticks = 1 [
    file-print (word
                  "ticks,"
                  "poblacion,"
                  "poblacion-sana,"
                  "poblacion-infectada,"
                  "cantidad-mosquitos,"
                  "cantidad-cacharros,"
                  "temperatura,"
                  "estacion,"
                  "lluvia,"
                  "dia,"
                  "virulencia,"
                  "tipo-dengue,"
                  "mosquitos-pueden-hibernar,"
                  "mosquitos-hibernando,"
                  "cant-mosquitos,"
                  "mosquitos-sanos,"
                  "mosquitos-infectados,"
                  "mosquitos-macho,"
                  "mosquitos-hembra,"
                  "cant-repelente,"
                  "temperaturas-inusuales,"
                  )
  ]

  ;; Recolecta los datos actuales
  let export-poblacion count personas
  let export-poblacion-sana count personas with [not infectada?]
  let export-poblacion-infectada count personas with [infectada?]
  let export-cantidad-mosquitos count mosquitos
  let export-cantidad-cacharros count cacharros
  let export-temperatura [temperatura] of one-of climas
  let export-estacion [estacion] of one-of climas
  let export-lluvia? [lluvia?] of one-of climas
  let export-dia ceiling (ticks / ticks-por-dia)
  let export-virulencia virulencia
  let export-tipo-dengue tipo-dengue
  let export-mosquitos-pueden-hibernar count mosquitos with [puede-hibernar?]
  let export-mosquitos-hibernando count mosquitos with [hibernando?]
  let export-cant-mosquitos count mosquitos
  let export-mosquitos-sanos count mosquitos with [not infectado?]
  let export-mosquitos-infectados count mosquitos with [infectado?]
  let export-mosquitos-macho count mosquitos with [hembra?]
  let export-mosquitos-hembra count mosquitos with [not hembra?]
  let export-cant-repelente count personas with [usando-repelente?]
  let export-temperaturas-inusuales temperaturas-inusuales



  ;; Escribe los datos en el archivo
  file-print (word ticks ","
                   export-poblacion ","
                   export-poblacion-sana ","
                   export-poblacion-infectada ","
                   export-cantidad-mosquitos ","
                   export-cantidad-cacharros ","
                   export-temperatura ","
                   export-estacion ","
                   export-lluvia? ","
                   export-dia ","
                   export-virulencia ","
                   export-tipo-dengue ","
                   export-mosquitos-pueden-hibernar ","
                   export-mosquitos-hibernando ","
                   export-cant-mosquitos ","
                   export-mosquitos-sanos ","
                   export-mosquitos-infectados ","
                   export-mosquitos-macho ","
                   export-mosquitos-hembra ","
                   export-cant-repelente ","
                   temperaturas-inusuales
                   )
  file-close
end


to mosquitos-hibernarnacion
  let climaActual one-of climas
  ifelse [temperatura] of climaActual <= temperatura-hibernar
   [
      ask mosquitos with [puede-hibernar? = true] [
        set hibernando? true
        set tiempo-hibernando 0
      ]
  ]
  [
    ask mosquitos with [hibernando? = true] [
        set hibernando? false
        set fecha-nac ticks
      ]
  ]
end


to-report generar-numero-aleatorio [minimo maximo]
  report minimo + random (maximo - minimo + 1)
end


@#$#@#$#@
GRAPHICS-WINDOW
732
10
1476
755
-1
-1
7.29
1
10
1
1
1
0
1
1
1
-50
50
-50
50
0
0
1
tics
30.0

BUTTON
0
124
70
157
NIL
setear
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
74
124
170
157
NIL
ejecutar
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
1
10
196
43
cant-inicial-personas
cant-inicial-personas
0
500
122.0
1
1
NIL
HORIZONTAL

SLIDER
1
47
196
80
cant-inicial-mosquitos
cant-inicial-mosquitos
0
100
14.0
1
1
NIL
HORIZONTAL

PLOT
3
265
354
480
SIR Personas
días
personas
0.0
365.0
0.0
300.0
true
true
"" ""
PENS
"Susceptibles" 1.0 0 -14439633 true "set-plot-pen-interval 0.33" "plot count personas with [not infectada? AND not recuperada?]"
"Infectadas" 1.0 0 -5298144 true "set-plot-pen-interval 0.33" "plot count personas with [infectada?]"

MONITOR
332
162
451
207
mosquitos sanos
count mosquitos with [not infectado?]
17
1
11

MONITOR
455
163
576
208
mosquitos infectados
count mosquitos with [infectado? = true]
17
1
11

MONITOR
96
160
179
205
personas infectadas
count personas with [infectada?]
17
1
11

SLIDER
202
48
414
81
%-inicial-mosquitos-infectados
%-inicial-mosquitos-infectados
0
100
18.0
1
1
NIL
HORIZONTAL

MONITOR
267
213
446
258
mosquitos muertos por fumigación
muertos-por-fumigacion
0
1
11

BUTTON
396
123
468
156
NIL
fumigar
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
1
85
196
118
cantidad-cacharros
cantidad-cacharros
0
22
11.0
1
1
NIL
HORIZONTAL

SLIDER
204
84
412
117
cant-max-huevos-x-cacharro
cant-max-huevos-x-cacharro
0
50
8.0
1
1
NIL
HORIZONTAL

PLOT
361
264
656
478
Mosquitos
días
cantidad
0.0
365.0
0.0
2000.0
false
false
"" ""
PENS
"mosquitos" 1.0 0 -10899396 true "set-plot-pen-interval (1 / 3)" "plot count mosquitos"

SLIDER
202
10
441
43
%-inicial-personas-infectadas
%-inicial-personas-infectadas
0
100
44.0
1
1
NIL
HORIZONTAL

MONITOR
0
161
90
206
personas sanas
count personas with [infectada? = false AND recuperada? = false]
17
1
11

CHOOSER
444
10
569
55
DESCACHARRAMIENTO
DESCACHARRAMIENTO
"Manzana 1" "Manzana 2" "Manzana 3" "Manzana 4" "Todo"
4

BUTTON
472
123
568
156
NIL
descacharrizar
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
172
124
296
157
Seguir a una persona
seguir-persona
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
298
123
394
156
Dejar de seguir
reset-perspective
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
25
518
146
563
Temperatura actual
[temperatura] of one-of climas
17
1
11

MONITOR
23
569
140
614
Estacion actual
[estacion] of one-of climas
17
1
11

MONITOR
1
211
67
256
estacion
[estacion] of one-of climas
17
1
11

MONITOR
71
211
143
256
temperatura
[temperatura] of one-of climas
17
1
11

PLOT
3
486
214
678
Hibernando
dias
cant mosquitos
0.0
1500.0
0.0
600.0
false
false
"" ""
PENS
"default" 1.0 0 -5204280 true "" " plot count mosquitos with [hibernando? = true]"

PLOT
218
485
445
677
Personas en el parque
Dias
Cantidad
0.0
1500.0
0.0
1000.0
false
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count personas"

MONITOR
150
213
207
258
Dia
round (ticks / ticks-por-dia)
17
1
11

MONITOR
265
160
325
205
Mosquitos
count mosquitos
17
1
11

CHOOSER
444
58
570
103
tipo-dengue
tipo-dengue
"DEN-1" "DEN-2" "DEN-3" "DEN-4"
1

MONITOR
456
213
528
258
Virulencia %
virulencia
17
1
11

CHOOSER
575
10
710
55
estado-repartir-repelente
estado-repartir-repelente
"Si" "No"
1

CHOOSER
577
61
711
106
cant-dias-repeat-repelente-estado
cant-dias-repeat-repelente-estado
1 5 10 20 30
1

BUTTON
591
123
695
156
Repelente Personal
activar-repelente-personal
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
451
487
690
676
Repelente
dias
personas
0.0
1500.0
0.0
500.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" " plot count personas with [usando-repelente? = true]"

MONITOR
181
161
253
206
Reciperadas
count personas with [recuperada?]
17
1
11

CHOOSER
583
167
728
212
temperaturas-inusuales
temperaturas-inusuales
"Si" "No"
0

@#$#@#$#@
##QUÉ ES?
Este modelo simula la transmisión del virus del dengue en un barrio de cuatro manzanas durante 180 (ciento ochenta) días.
El vector del virus es el mosquito Aedes egyptii.
La simulación muestra un gráfico con la evolución del brote (el cambio en la cantidad de personas sanas y de personas infectadas), otro gráfico con la evolución de la población de mosquitos y unos monitores que indican el estado de la población de mosquitos y de personas (cuántos individuos sanos, cuántos infectados, etc.).
El modelo tiene en cuenta la temperatura y ésta es generada al azar pero tomando en cuenta los valores de 2016 de la Ciudad de Buenos Aires.

##CÓMO FUNCIONA?
Las personas y los mosquitos se mueven al azar por el barrio (cuatro manzanas) interactuando entre sí. Los mosquitos se mueven de manera más limitada respecto del lugar donde nacieron (en un radio de cinco parcelas).Tanto entre la población de personas como de mosquitos, inicialmente hay algunos individuos (personas y mosquitos) sanos y otros infectados con el virus del dengue.
Los individuos sanos son de color blanco y los que están infectados, de color rojo.
Los mosquitos sanos son de color amarillo y los que están infectados, de color naranja.
Los mosquitos que se infectan a partir de picar individuos infectados, también son de color naranja.

Si un mosquito infectado se encuentra con una persona sana, al picarla tiene una probabilidad de infectarla del 80%. Si un mosquito “sano” (que no está infectado con el virus) pica a una persona infectada, el mosquito se infecta también.
Cuando un mosquito pica, elige un cacharro al azar y deposita sus huevos allí.
Un mosquito puede picar hasta un máximo de 6 veces y vive entre 25 y 30 días.
La temperatura es la misma durante todo un día pero cambia cada nuevo día generándose al azar entre los valores máximo y mínimo para ese mes según datos de 2016 para la Ciudad de Buenos Aires. Esto influye en el modelo ya que los mosquitos se reproducen solamente si la temperatura es mayor a 15 grados Celsius.
En el barrio hay una cantidad de recipientes con agua (“cacharros”), los cuales contienen huevos de mosquito que se transforman en adultos a los 10 días.
El barrio puede fumigarse. Cuando un mosquito entra en contacto con el área fumigada, muere. El pesticida se representa de color rosa y se va evaporando a ritmo constante aunque se pueden repetir las acciones de fumigación antes o durante la ejecución del modelo (pueden realizarse hasta tres acciones de fumigación ya que más sería contraproducente para la salud de la población).
Durante la ejecución también se pueden realizar eventos de descacharrización, es decir quitar cacharros de las manzanas. En cada evento de descacharrización se reduce la cantidad de cacharros presentes en una manzana dada o en cualquier manzana al azar.

##CÓMO SE UTILIZA EL MODELO?
En este modelo, un día está representado por 3 tics.

El deslizado %-INICIAL-MOSQUITOS-INFECTADOS determina la cantidad (porcentaje del total) de mosquitos infectados que hay al principio de la simulación.
El deslizado CANT-INICIAL-PERSONAS determina la cantidad de personas (1,000 como máximo) que habrá al inicio de la simulación.
El deslizado %-INICIAL-PERSONAS-INFECTADAS determina la cantidad (porcentaje del total) de personas infectadas que hay al principio de la simulación.
El deslizador CANT-INICIAL-MOSQUITOS determina la cantidad inicial de mosquitos antes de comenzar con la simulación.
El selector ESTACIONES permite seleccionar el período del año en que se realizará la simulación y de acuerdo a esto, el modelo seteará una temperatura diaria al azar pero de acuerdo a valores de tablas máximos y mínimos referidos a 2016 en Ciudad de Buenos Aires. Esto es importante porque los mosquitos sólo se reproducen si la temperatura es mayor de 15 grados Celsius.
El deslizador CANTIDAD-CACHARROS determina la cantidad de cacharros con agua que habrá durante la simulación.
El deslizador CANT-MAX-HUEVOS-X-CACHARRO determina la cantidad máxima de huevos que podrá haber inicialmente en cada cacharro. Cuando se configura la simulación (al dar clic en el botón “sesear”), en cada cacharro habrá una cantidad de huevos determinada al azar, teniendo como límite máximo el valor de este deslizador.
El selector DESCACHARRAMIENTO permite elegir cuál manzana (1, 2, 3 ó 4) se va a descacharrizar cada vez que se haga clic sobre el botón DESCACHARRIZAR. Si en el selector se elige "Todo", entonces cada evento de descacharrización se realizará sobre una manzana al azar.

El botón SETEAR configura los valores iniciales de la simulación y el botón EJECUTAR pone a andar la simulación. También el botón EJECUTAR sirve para detener la simulación una vez que la misma se encuentre en ejecución. Cuando se está ejecutando la simulación, el botón EJECUTAR está hundido.
El botón EJECUTAR UN MES sirve para ejecutar la simulación y que se detenga a los 30 días simulados (90 tics).
El botón FUMIGAR sirve para fumigar una porción del terreno. Las parcelas fumigadas aparecen de color rosa y cuando un mosquito entra en contacto con esa parcela, muere.
El botón DESCACHARRIZAR remueve de a un cacharro sobre la manzana elegida con el selector DESCACHARRAMIENTO. Si se elige "Todo" en el selector DESCACHARRAMIENTO, la descacharrización se realiza al azar sobre cualquier manzana cada vez que se da clic en el botón.
El botón SEGUIR A UNA PERSONA sirve para realizar un seguimiento del movimiento (en qué lugar de la manzana está) y el estado de una persona (sana o infectada) elegida al azar. La persona seguida aparece dentro de un círculo claro como si estuviera iluminada con una linterna. El botón DEJAR DE SEGUIR remueve automáticamente el círculo de seguimiento.
El seguimiento no afecta en nada el funcionamiento del modelo.

El modelo también contiene una serie de “instrumentos” de color amarillento, ubicados en la parte inferior de la pantalla, que van midiendo algunas variables de la simulación a medida que ésta transcurre.
Estos instrumentos son básicamente de dos tipos: los recuadros que muestran números que son llamados “monitores” y los gráficos.
El monitor “mosquitos muertos por fumigación” va indicando la cantidad de mosquitos muertos por acción del pesticida.
Los monitores “personas infectadas” y "personas sanas" van registrando la cantidad de personas que se van infectando y que permanecen sanas (respectivamente) a medida que transcurre la simulación.
Luego están los monitores que registran la cantidad de mosquitos sanos e infectados y el que registra la cantidad de días que van transcurriendo. Este monitor es útil en caso de que se quiera detener la simulación antes de tiempo y poder ver allí en qué día se detuvo.
También hay un monitor que va indicando la temperatura cada día ya que ésta varía al azar de acuerdo a las estaciones y a los valores de tablas para la Ciudad Autónoma de Buenos Aires durante 2016 (fuente: Servicio Meteorológico Nacional).

##COSAS A TENER EN CUENTA
En la vida real, el mosquito hembra es el que transmite el dengue, en este modelo asumimos que todos los mosquitos tienen la capacidad de transmitir el virus, aunque para ello deben estar infectados (portadores del virus).
En este modelo, cuando un mosquito infectado pica, después de picar se dirige a un cacharro al azar (de la manzana donde estaba cuando picó, la cual mayormente será aquella donde nació) para depositar sus huevos.
Las manzanas están identificadas con colores diferentes pero están contiguas, con lo cual, puede suceder que un mosquito que nació de un cacharro en la manzana 1 (la primera de arriba a la izquierda), si dicho cacharro está cerca del límite con la manzana 2 (la de arriba a la derecha) vaya a poner huevo en un cacharro de la manzana 2 ya que el modelo está programado para que los mosquitos pongan huevos en los cacharros cercannos a la manzana donde se encuentran cuando picaron.
Los mosquitos que nacen de estos huevos están sanos.
En este modelo, la fumigación tiene un impacto concreto y directo sobre la población de mosquitos aunque no contempla efectos colaterales del pesticida sobre la población.
La fumigación puede aplicarse solamente durante la ejecución de la simulación.
Los selectores de estaciones o de descacharramiento en cambio pueden accionarse antes o durante la ejecución del modelo.
Si se observa el gráfico de la población de mosquitos se observan picos de crecimiento y decrecimiento que tienen que ver con los distintos momentos en que los huevos eclosionan y se transforman en mosquitos adultos.

##COSAS A PROBAR
Si no tienen experiencia con modelos de simulación, la sugerencia es comenzar a probar variando parámetros sencillos para ver qué sucede con la población de mosquitos y la cantidad de personas infectadas.
O también pueden comenzar variando solamente la cantidad de personas para probar con cantidades bien diferentes y ver si realmente hay un cambio y cuál es.
Luego de adquirir destreza en el manejo básico, se puede comenzar a probar diferentes hipótesis.
¿En qué época del año es más crítico el problema del brote? ¿Qué sucederá con el impacto de la fumigación y la disminución de cacharros? ¿Qué será más eficiente en términos de reducción del brote? ¿Qué valores tendremos en cuenta para definir esto? ¿La cantidad de personas infectadas? ¿La cantidad de personas sanas? ¿La cantidad de mosquitos?
¿Cuán importante es la cantidad de huevos por cacharro y de qué depende este valor en la realidad?
¿Qué cosas NO tiene en cuenta este modelo y sería bueno que contemplara? ¿Por qué?
¿Cómo influye en los resultados del brote la cantidad inicial de personas? ¿Y de mosquitos?
¿Qué experimentos podemos diseñar para contestar estas preguntas?

##EXTENDIENDO EL MODELO
Contemplar la posibilidad de que los cacharros se queden sin agua y que con la lluvia se active el ciclo de crecimiento del mosquito.
Hacer que los mosquitos pongan huevos en cacharros diferentes, no en uno sólo.
Establecer mosquitos macho y hembra y tener en cuenta que sólo las hembras pican.
Hacer que el pesticida utilizado en la fumigación se pierda en función de la temperatura (a mayor temperatura mayor ritmo de evaporación).
Acortar el tiempo del modelo en un mes para poder modelizar la acción del pesticida con tiempos más reales.

##MODELOS RELACIONADOS
Dengue v1.14 Virus

##CREDITOS Y REFERENCIAS
Este modelo fue desarrollado en el marco de un trabajo del Ministerio de Educación de la Ciudad de Buenos Aires, Argentina. El equipo de trabajo está conformado por: Hernán Miguel; Florencia Monzón; Gabriela Jiménez; Patricia Moreno y Cristián Rizzi Iribarren. La programación del modelo fue realizada por Cristián Rizzi Iribarren utilizando NetLogo 5.3.1. Abril 2017.-
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

hawk
true
0
Polygon -7500403 true true 151 170 136 170 123 229 143 244 156 244 179 229 166 170
Polygon -16777216 true false 152 154 137 154 125 213 140 229 159 229 179 214 167 154
Polygon -7500403 true true 151 140 136 140 126 202 139 214 159 214 176 200 166 140
Polygon -16777216 true false 151 125 134 124 128 188 140 198 161 197 174 188 166 125
Polygon -7500403 true true 152 86 227 72 286 97 272 101 294 117 276 118 287 131 270 131 278 141 264 138 267 145 228 150 153 147
Polygon -7500403 true true 160 74 159 61 149 54 130 53 139 62 133 81 127 113 129 149 134 177 150 206 168 179 172 147 169 111
Circle -16777216 true false 144 55 7
Polygon -16777216 true false 129 53 135 58 139 54
Polygon -7500403 true true 148 86 73 72 14 97 28 101 6 117 24 118 13 131 30 131 22 141 36 138 33 145 72 150 147 147

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

mosquito
false
0
Polygon -7500403 true true 117 105 165 60 210 45 240 45 255 60 240 75 210 90 180 105 150 105 117 120
Polygon -7500403 true true 60 135 45 120 45 105 45 90
Polygon -7500403 true true 60 135 45 150 30 165 15 180 45 165 60 150
Circle -7500403 true true 45 120 30
Polygon -7500403 true true 60 135 75 120 90 105 120 90 150 90 165 105 180 120 180 135 165 150 150 150 120 150 105 150 75 150
Polygon -7500403 true true 120 105 135 120 135 135 150 150 180 165 210 180 255 210 240 165 210 135 180 120 180 105 165 90 150 90 120 105
Polygon -7500403 true true 75 150 60 180 45 195 15 210 30 210 60 195 75 180 90 165 90 150
Polygon -7500403 true true 105 150 105 180 90 195 75 210 75 225 60 240 45 240 30 240 60 240 60 255 75 240 90 225 90 210 105 195 105 210 105 195 120 180 120 165 120 150 105 150
Polygon -7500403 true true 135 150 150 180 165 195 180 210 195 225 225 240 255 255 225 225 195 210 180 195 165 180 150 165 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

persona
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

redondel
false
0
Circle -7500403 true true 0 0 300

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
