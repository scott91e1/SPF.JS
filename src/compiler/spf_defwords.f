\ $Id: spf_defwords.f,v 1.19 2008/12/01 18:46:56 spf Exp $

\ Определяющие слова, создающие словарные статьи в словаре.
\  ОС-независимые определения.
\  Copyright [C] 1992-1999 A.Cherezov ac@forth.org
\  Преобразование из 16-разрядного в 32-разрядный код - 1995-96гг
\  Ревизия - сентябрь 1999


USER LAST-CFA
USER-VALUE LAST-NON

VECT SHEADER

: SHEADER1 ( addr u -- )
  ALIGN
  
  HERE 0 , ( cfa )
  DUP LAST-CFA !
  0 C,     ( flags )
  -ROT WARNING @
  IF 2DUP GET-CURRENT SEARCH-WORDLIST
     IF DROP 2DUP TYPE S"  isn't unique (" TYPE SOURCE-NAME TYPE S" )" TYPE CR THEN
  THEN

  CURRENT @ +SWORD

  ALIGN

  HERE SWAP ! ( заполнили cfa )

;
' SHEADER1 ' SHEADER TC-VECT!

: HEADER ( "name" -- )
  PARSE-NAME SHEADER
;

: CREATED ( addr u -- )
\ Создать определение для c-addr u с семантикой выполнения, описанной ниже.
\ Если указатель пространства данных не выровнен, зарезервировать место
\ для выравнивания. Новый указатель пространства данных определяет
\ поле данных name. CREATE не резервирует место в поле данных name.
\ name Выполнение: ( -- a-addr )
\ a-addr - адрес поля данных name. Семантика выполнения name может
\ быть расширена с помощью DOES>.
  SHEADER

  HERE DUP LAST-CFA @ !
  DOES>A ! ( для DOES )
    
  [ ' (CREATE-CODE) LIT, ] PRIMITIVE,
  0 , \ смещение для does>
;

: CREATE ( "<spaces>name" -- ) \ 94
   PARSE-NAME CREATED
;

: (DOES1) ( -- )
  [ ' (DOES2>) LIT, ] DOES>A @ !
  
  R> DOES>A @ - \ прыгаем после does>
  DOES>A @ CELL+ !
;

: DOES>  \ 94
\ Интерпретация: семантика неопределена.
\ Компиляция: ( C: clon-sys1 -- colon-sys2 )
\ Добавить семантику времени выполнения, данную ниже, к текущему
\ определению. Будет или нет текущее определение сделано видимо
\ для поиска в словаре при компиляции DOES>, зависит от реализации.
\ Поглощает colon-sys1 и производит colon-sys2. Добавляет семантику
\ инициализации, данную ниже, к текущему определению.
\ Время выполнения: ( -- ) ( R: nest-sys1 -- )
\ Заменить семантику выполнения последнего определения name, на семантику
\ выполнения name, данную ниже. Возвратить управление в вызывающее опреде-
\ ление, заданное nest-sys1. Неопределенная ситуация возникает, если name
\ не было определено через CREATE или определенное пользователем слово,
\ вызывающее CREATE.
\ Инициализация: ( i*x -- i*x a-addr ) ( R: -- nest-sys2 )
\ Сохранить зависящую от реализации информацию nest-sys2 о вызывающем
\ определении. Положить адрес поля данных name на стек. Элементы стека
\ i*x представляют аргументы name.
\ name Выполнение: ( i*x -- j*x )
\ Выполнить часть определения, которая начинается с семантики инициализации,
\ добавленной DOES>, которое модифицировало name. Элементы стека i*x и j*x
\ представляют аргументы и результаты слова name, соответственно.

   (DOES1)
   
;

: VOCABULARY ( "<spaces>name" -- )
\ Создать список слов с именем name. Выполнение name заменит первый список
\ в порядке поиска на список с именем name.
  WORDLIST DUP
  CREATE
  ,
  LATEST OVER CELL+ ! ( ссылка на имя словаря )
  GET-CURRENT SWAP PAR! ( словарь-предок )
\  FORTH-WORDLIST SWAP CLASS! ( класс )
  VOC
  ( DOES> не работает в этом ЦК)
  (DOES1) \ так сделал бы DOES>, определенный выше
  @ CONTEXT !
;

: VARIABLE ( "<spaces>name" -- ) \ 94
\ Пропустить ведущие пробелы. Выделить name, ограниченное пробелом.
\ Создать определение для name с семантикой выполнения, данной ниже.
\ Зарезервировать одну ячейку пространства данных с выровненным адресом.
\ name используется как "переменная".
\ name Выполнение: ( -- a-addr )
\ a-addr - адрес зарезервированной ячейки. За инициализацию ячейки отвечает 
\ программа
  CREATE
  0 ,
;

: 2VARIABLE 
   CREATE 0 , 0 ,
;

: CONSTANT ( x "<spaces>name" -- ) \ 94
\ Пропустить ведущие пробелы. Выделить name, ограниченное пробелом.
\ Создать определение для name с семантикой выполнения, данной ниже.
\ name используется как "константа".
\ name Выполнение: ( -- x )
\ Положить x на стек.
  HEADER
  LIT, RET,
;
: 2CONSTANT
  CREATE , , 
  DOES> 2@
;

: VALUE ( x "<spaces>name" -- ) \ 94 CORE EXT
\ Пропустить ведущие пробелы. Выделить name, ограниченное пробелом. Создать 
\ определение для name с семантикой выполнения, определенной ниже, с начальным 
\ значением равным x.
\ name используется как "значение".
\ Выполнение: ( -- x )
\ Положить x на стек. Значение x - то, которое было дано, когда имя создавалось,
\ пока не исполнится фраза x TO name, задав новое значение x, 
\ ассоциированное с name.
  HEADER
  [ ' (VAL) LIT, ] PRIMITIVE, ,
  [ C' TOVAL-CODE LIT, ] ,
;
: VECT ( -> )
  ( создать слово, семантику выполнения которого можно менять, )
  (  записывая в него новый xt по TO)
  HEADER
  [ ' (VECT) LIT, ] PRIMITIVE, ['] NOOP ,
  [ C' TOVAL-CODE LIT, ] ,
;


: ->VARIABLE ( x "<spaces>name" -- ) \ 94
  CREATE ,
;

: USER-ALIGNED ( -- a-addr n )
   USER-HERE 3 + 2 RSHIFT ( 4 / ) 4 * DUP
   USER-HERE -
;

: USER-CREATE ( "<spaces>name" -- )
  HEADER
  HERE DOES>A ! ( для DOES )
  [ ' (USER) LIT, ] PRIMITIVE,
  USER-ALIGNED SWAP ,
  USER-ALLOT
;
: USER ( "<spaces>name" -- ) \ локальные переменные потока
  USER-CREATE
  4 USER-ALLOT
;
: USER-VALUE ( "<spaces>name" -- ) \ 94 CORE EXT
  HEADER
  [ ' (USER-VALUE) LIT, ] PRIMITIVE,
  USER-ALIGNED SWAP ,
  CELL+ USER-ALLOT
  [ C' TOUSERVAL-CODE LIT, ] ,
;

: ->VECT ( x -> )
  HEADER
  [ ' (VECT) LIT, ] PRIMITIVE, ['] ,
  [ C' TOVAL-CODE LIT, ] ,
;

\ : BEHAVIOR ( vect-xt -- assigned-xt )
\ Возвращает xt процедуры, присвоенной VECT-переменной.
\  CFL + @
\ ;
\ : BEHAVIOR! ( xt1 xt2 -- )
\   CFL + !
\ ;
\ В данной реализации слова BEHAVIOR и BEHAVIOR! 
\ не применимы к USER-векторам, а только к обычным.


USER C-SMUDGE \ 12 C,

\ smudge исправлено ~nemnick 29.11.2000
: SMUDGE ( -- )
  LATEST
  IF C-SMUDGE C@
     LATEST 1+ C@ C-SMUDGE C!
     LATEST 1+ C!

     LATEST 1+ C@ 12 = 0= IF LATEST GET-CURRENT CACHE-NAME THEN
  THEN ;

: HIDE
  12 C-SMUDGE C! SMUDGE
;

\ :NONAME исправлено ~nemnick 28.11.2000

: :NONAME ( C: -- colon-sys ) ( S: -- xt ) \ 94 CORE EXT
\ Создать выполнимый токен xt, установить состояние компиляции и 
\ начать текущее определение, произведя colon-sys. Добавить семантику
\ инициализации к текущему определению.
\ Семантика выполнения xt будет задана словами, скомпилированными 
\ в тело определения. Это определение может быть позже выполнено по
\ xt EXECUTE.
\ Если управляющий стек реализован с импользованием стека данных,
\ colon-sys будет верхним элементом на стеке данных.
\ Инициализация: ( i*x -- i*x ) ( R: -- nest-sys )
\ Сохранить зависящую от реализации информацию nest-sys о вызове 
\ определения. Элементы стека i*x представляют аргументы xt.
\ xt Выполнение: ( i*x -- j*x )
\ Выполнить определение, заданное xt. Элементы стека i*x и j*x 
\ представляют аргументы и результаты xt соответственно.
  LATEST ?DUP IF 1+ C@ C-SMUDGE C! SMUDGE THEN
  HERE DUP TO LAST-NON [COMPILE] ]
;


: : ( C: "<spaces>name" -- colon-sys ) \ 94
\ Пропустить ведущие разделители. Выделить имя, ограниченное пробелом.
\ Создать определение для имени, называемое "определение через двоеточие".
\ Установить состояние компиляции и начать текущее определение, получив
\ colon-sys. Добавить семантику инициализации, описанную ниже, в текущее
\ определение. Семантика выполнения будет определена словами, скомпилиро-
\ ванными в тело определения. Текущее определение должно быть невидимо
\ при поиске в словаре до тех пор, пока не будет завершено.
\ Инициализация: ( i*x -- i*x ) ( R: -- nest-sys )
\ Сохранить информацию nest-sys о вызове определения. Состояние стека
\ i*x представляет аргументы имени.
\ Имя Выполнение: ( i*x -- j*x )
\ Выполнить определение имени. Состояния стека i*x и j*x представляют
\ аргументы и результаты имени соответственно.
  HEADER
  ]
  HIDE
;


: MARKER1
  GET-CURRENT DUP @ HERE
  CREATE , , ,
  DOES> >R
  R@ @ DP ! ( here )
  R@ CELL+ @ ( last cfa )
  R> CELL+ CELL+ @ ( wid ) !
;
