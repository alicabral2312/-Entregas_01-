% ==============================================================================
% ACTIVIDAD 3: SISTEMA EXPERTO FCI - UNACAR
% Servidor HTTP en SWI-Prolog con endpoints REST (JSON) y vistas HTML
% ==============================================================================

:- use_module(library(http/http_server)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(json)).
:- use_module(library(http/http_parameters)).
:- use_module(library(http/html_write)).

% Iniciar el servidor automáticamente en el puerto 8080 al cargar
:- initialization http_server([port(8080)]).

% ==============================================================================
% SECCIÓN 1: BASE DE CONOCIMIENTO (Hechos)
% ==============================================================================

% profesor(#Empleado, Nombre, Grado, Especialidad, CursosDominadosEnOrden)
profesor(101, 'Dr. Juan Perez', doctorado, 'Inteligencia Artificial', ['IA', 'Machine Learning', 'Logica']).
profesor(102, 'Mtra. Maria Gomez', maestria, 'Ingenieria de Software', ['Ingenieria de Software', 'Bases de Datos', 'POO']).
profesor(103, 'Dr. Carlos Mendoza', doctorado, 'Redes y Ciberseguridad', ['Ciberseguridad', 'Redes', 'Sistemas Operativos']).
profesor(104, 'Ing. Ana Torres', licenciatura, 'Programacion Web', ['Desarrollo Web', 'POO', 'Estructura de Datos']).
profesor(105, 'Mtro. Luis Ramirez', maestria, 'Inteligencia Artificial', ['Logica', 'IA', 'Matematicas Discretas']).

% estudios(#Empleado, Licenciatura, Maestria, Doctorado)
estudios(101, 'Ingenieria en Computacion', 'Mtr. en Ciencias de la Computacion', 'Dr. en Inteligencia Artificial').
estudios(102, 'Licenciatura en Informatica', 'Mtr. en Ingenieria de Software', 'Ninguno').
estudios(103, 'Ingenieria en Telematica', 'Mtr. en Seguridad Informatica', 'Dr. en Redes Avanzadas').
estudios(104, 'Ingenieria en Sistemas Computacionales', 'Ninguno', 'Ninguno').
estudios(105, 'Licenciatura en Matematicas Aplicadas', 'Mtr. en Inteligencia Artificial', 'Ninguno').

% acreditacion(#Empleado, AcreditacionOCertificacion)
acreditacion(101, 'Perfil Deseable PRODEP').
acreditacion(101, 'SNII Candidato').
acreditacion(102, 'Perfil Deseable PRODEP').
acreditacion(103, 'Certificacion Cisco CCNP').
acreditacion(103, 'SNII Nivel I').
acreditacion(104, 'Certificacion Scrum Master').

% capacitacion_tomada(#Empleado, IdCursoCapacitacion)
capacitacion_tomada(101, cap01).
capacitacion_tomada(102, cap02).
capacitacion_tomada(102, cap04).
capacitacion_tomada(103, cap03).
capacitacion_tomada(104, cap02).

% cuerpo_academico(Id, Nombre, LineaInvestigacion, Lider, Estatus)
cuerpo_academico(ca01, 'Tecnologias Inteligentes y Computacion Aplicada', 'Inteligencia Artificial', 101, 'Consolidado').
cuerpo_academico(ca02, 'Ingenieria de Software y Sistemas Distribuidos', 'Ingenieria de Software', 102, 'En Consolidacion').
cuerpo_academico(ca03, 'Redes, Telecomunicaciones y Seguridad', 'Redes y Ciberseguridad', 103, 'En Formacion').

% academia(Id, Nombre, MateriasAsignadas, Lider)
academia(aca01, 'Academia de Inteligencia Artificial y Datos', ['IA', 'Machine Learning', 'Logica'], 101).
academia(aca02, 'Academia de Desarrollo de Software', ['Ingenieria de Software', 'Desarrollo Web', 'POO'], 102).
academia(aca03, 'Academia de Redes y Seguridad', ['Ciberseguridad', 'Redes', 'Sistemas Operativos'], 103).

% curso(Id, Creditos, Nombre, Objetivo, IdAcademia)
curso(cur01, 8, 'IA', 'Modelar agentes inteligentes y resolucion de problemas', aca01).
curso(cur02, 8, 'Machine Learning', 'Algoritmos supervisados y no supervisados', aca01).
curso(cur03, 6, 'Ingenieria de Software', 'Metodologias agiles y diseno de software', aca02).
curso(cur04, 6, 'Desarrollo Web', 'Arquitectura cliente-servidor y APIs REST', aca02).
curso(cur05, 8, 'Ciberseguridad', 'Seguridad en redes y pruebas de penetracion', aca03).

% cursos_capacitacion(Id, Nombre, Objetivo, Horas, FechaInicio, FechaFin)
curso_capacitacion(cap01, 'Deep Learning con PyTorch', 'Modelado con redes neuronales profundas', 40, '2026-06-01', '2026-06-15').
curso_capacitacion(cap02, 'Arquitectura Limpia en Node.js', 'Patrones de diseno para microservicios', 30, '2026-07-01', '2026-07-10').
curso_capacitacion(cap03, 'Seguridad Defensiva en Nube', 'Auditoria y proteccion de servidores', 45, '2026-06-20', '2026-07-05').
curso_capacitacion(cap04, 'Diseno Instruccional por Competencias', 'Formacion pedagogica institucional', 20, '2026-08-01', '2026-08-08').

% proyecto(Id, Nombre, Objetivo, Entregables, Lider, Integrantes, FechaInicio, FechaFin)
proyecto(proy01, 'Agentes IA para Diagnostico Clinico', 'Sistema de clasificacion automatizada', ['API REST', 'Articulo JCR'], 101, [105], '2026-01-15', '2026-12-15').
proyecto(proy02, 'Plataforma Web Institucional FCI', 'Gestion integral de tutorias y alumnos', ['Sistema Web', 'Manual de Usuario'], 102, [104], '2026-02-01', '2026-11-30').

% comision(Id, Nombre, Objetivo)
comision(com01, 'Comision de Acreditacion CACEI', 'Coordinar carpetas de evidencias docentes').
comision(com02, 'Comision de Titulacion y Examenes Profesionales', 'Revision de tesis y jurados de examen').

asignado_comision(101, com01).
asignado_comision(102, com01).
asignado_comision(103, com02).
asignado_comision(105, com02).

% ==============================================================================
% SECCIÓN 2: REGLAS DE INFERENCIA EXPERTA (Las 6 opciones)
% ==============================================================================

% Opción 1: Asignar profesores a academias
apto_para_academia(NumEmp, IdAcademia) :-
    profesor(NumEmp, _, _, EspecialidadProf, CursosDominio),
    academia(IdAcademia, _, MateriasAcademia, _),
    (   sub_string(EspecialidadProf, _, _, _, 'Inteligencia'), IdAcademia = aca01
    ;   sub_string(EspecialidadProf, _, _, _, 'Software'), IdAcademia = aca02
    ;   sub_string(EspecialidadProf, _, _, _, 'Redes'), IdAcademia = aca03
    ;   member(M, MateriasAcademia), member(M, CursosDominio)
    ).

% Opción 2: Asignar profesores a cuerpos académicos (Maestría o Doctorado afín)
apto_para_cuerpo_academico(NumEmp, IdCA) :-
    profesor(NumEmp, _, Grado, Especialidad, _),
    (Grado = maestria ; Grado = doctorado),
    cuerpo_academico(IdCA, _, Linea, _, _),
    (   Especialidad = Linea
    ;   sub_string(Especialidad, _, _, _, 'Inteligencia'), Linea = 'Inteligencia Artificial'
    ;   sub_string(Especialidad, _, _, _, 'Software'), Linea = 'Ingenieria de Software'
    ;   sub_string(Especialidad, _, _, _, 'Redes'), Linea = 'Redes y Ciberseguridad'
    ).

% Opción 3: Asignar profesores a proyectos (Afinidad por especialidad o cursos)
apto_para_proyecto(NumEmp, IdProy) :-
    profesor(NumEmp, _, _, Especialidad, _),
    proyecto(IdProy, _, Objetivo, _, Lider, _, _, _),
    NumEmp \= Lider,
    (   sub_string(Objetivo, _, _, _, 'clasificacion'), sub_string(Especialidad, _, _, _, 'Inteligencia')
    ;   sub_string(Objetivo, _, _, _, 'Web'), (Especialidad = 'Programacion Web' ; Especialidad = 'Ingenieria de Software')
    ;   sub_string(Objetivo, _, _, _, 'Seguridad'), Especialidad = 'Redes y Ciberseguridad'
    ).

% Opción 4: Asignar al MEJOR profesor para un curso (Cálculo de puntaje)
% Criterios de puntuación:
% - Posición en la lista de dominio (1ro: 30 pts, 2do: 20 pts, 3ro: 10 pts)
% - Grado académico (doctorado: 25 pts, maestria: 15 pts, licenciatura: 10 pts)
% - Capacitaciones tomadas (10 pts por cada curso tomado)
puntaje_para_curso(NumEmp, NombreCurso, PtsTotal) :-
    profesor(NumEmp, _, Grado, _, CursosDominio),
    nth1(Pos, CursosDominio, NombreCurso),
    (Pos = 1 -> PtsPos = 30 ; Pos = 2 -> PtsPos = 20 ; PtsPos = 10),
    (Grado = doctorado -> PtsGrado = 25 ; Grado = maestria -> PtsGrado = 15 ; PtsGrado = 10),
    findall(C, capacitacion_tomada(NumEmp, C), Caps),
    length(Caps, TotalCaps),
    PtsCap is TotalCaps * 10,
    PtsTotal is PtsPos + PtsGrado + PtsCap.

mejor_profesor_para_curso(NombreCurso, MejorEmp, MaxPts) :-
    findall(Pts-Emp, puntaje_para_curso(Emp, NombreCurso, Pts), Lista),
    Lista \= [],
    sort(Lista, Ordenados),
    reverse(Ordenados, [MaxPts-MejorEmp|_]).

% Opción 5: Asignar profesores a cursos de capacitación (Detecta necesidad formativa)
requiere_capacitacion(NumEmp, IdCursoCap) :-
    profesor(NumEmp, _, _, Especialidad, _),
    curso_capacitacion(IdCursoCap, _, _, _, _, _),
    \+ capacitacion_tomada(NumEmp, IdCursoCap),
    (   IdCursoCap = cap01, sub_string(Especialidad, _, _, _, 'Inteligencia')
    ;   IdCursoCap = cap02, (Especialidad = 'Programacion Web' ; Especialidad = 'Ingenieria de Software')
    ;   IdCursoCap = cap03, Especialidad = 'Redes y Ciberseguridad'
    ;   IdCursoCap = cap04
    ).

% Opción 6: Buscar un profesor y todas sus asignaciones y expedientes
resumen_profesor(NumEmp, Resumen) :-
    profesor(NumEmp, Nombre, Grado, Especialidad, CursosDom),
    estudios(NumEmp, Lic, Mtr, Doc),
    findall(Acred, acreditacion(NumEmp, Acred), Acreditaciones),
    findall(Cap, capacitacion_tomada(NumEmp, Cap), CapsTomadas),
    findall(Aca, apto_para_academia(NumEmp, Aca), Academias),
    findall(CA, apto_para_cuerpo_academico(NumEmp, CA), CAs),
    findall(Proy, (proyecto(Proy, _, _, _, NumEmp, _, _, _) ; proyecto(Proy, _, _, _, _, Ings, _, _), member(NumEmp, Ings)), Proyectos),
    findall(Com, asignado_comision(NumEmp, Com), Comisiones),
    Resumen = _{
        empleado: NumEmp,
        nombre: Nombre,
        grado: Grado,
        especialidad: Especialidad,
        cursos_dominio: CursosDom,
        estudios: _{licenciatura: Lic, maestria: Mtr, doctorado: Doc},
        acreditaciones: Acreditaciones,
        capacitaciones_tomadas: CapsTomadas,
        academias_aptas: Academias,
        cuerpos_academicos_aptos: CAs,
        proyectos: Proyectos,
        comisiones: Comisiones
    }.

% ==============================================================================
% SECCIÓN 3: RUTAS HTTP Y CONTROLADORES REST (JSON)
% ==============================================================================

:- http_handler(root(.), home_page, []).
:- http_handler(root(home), home_page, []).
:- http_handler(root(api/profesores), api_profesores, []).
:- http_handler(root(api/asignar/academias), api_asignar_academias, []).
:- http_handler(root(api/asignar/cuerpos), api_asignar_cuerpos, []).
:- http_handler(root(api/asignar/proyectos), api_asignar_proyectos, []).
:- http_handler(root(api/asignar/mejor_profesor_curso), api_asignar_curso, []).
:- http_handler(root(api/asignar/capacitacion), api_asignar_capacitacion, []).
:- http_handler(root(api/profesor/asignaciones), api_buscar_profesor, []).

% Vista HTML de inicio
home_page(_Request) :-
    reply_html_page(
        title('Sistema Experto FCI - UNACAR'),
        [
            h1('Facultad de Ciencias de la Informacion - UNACAR'),
            h2('Servidor de Asignacion Docente en SWI-Prolog'),
            p('Endpoints REST disponibles para consulta (en formato JSON):'),
            ul([
                li(a(href('/api/profesores'), 'GET /api/profesores - Listar todos los profesores')),
                li(a(href('/api/asignar/academias'), 'GET /api/asignar/academias - Opcion 1: Asignacion a Academias')),
                li(a(href('/api/asignar/cuerpos'), 'GET /api/asignar/cuerpos - Opcion 2: Asignacion a Cuerpos Academicos')),
                li(a(href('/api/asignar/proyectos'), 'GET /api/asignar/proyectos - Opcion 3: Asignacion a Proyectos')),
                li(a(href('/api/asignar/mejor_profesor_curso?curso=IA'), 'GET /api/asignar/mejor_profesor_curso?curso=IA - Opcion 4: Mejor profesor para un curso')),
                li(a(href('/api/asignar/capacitacion'), 'GET /api/asignar/capacitacion - Opcion 5: Asignacion a Cursos de Capacitacion')),
                li(a(href('/api/profesor/asignaciones?empleado=101'), 'GET /api/profesor/asignaciones?empleado=101 - Opcion 6: Buscar profesor y sus asignaciones'))
            ])
        ]
    ).

% Endpoint: Listar profesores
api_profesores(_Request) :-
    findall(
        _{empleado: NumEmp, nombre: Nom, grado: Grado, especialidad: Esp},
        profesor(NumEmp, Nom, Grado, Esp, _),
        Lista
    ),
    reply_json_dict(Lista).

% Endpoint 1: Asignar a Academias
api_asignar_academias(_Request) :-
    findall(
        _{academia_id: IdAca, academia: NomAca, profesores_aptos: Profs},
        (
            academia(IdAca, NomAca, _, _),
            findall(_{empleado: E, nombre: N}, (apto_para_academia(E, IdAca), profesor(E, N, _, _, _)), Profs)
        ),
        Resultado
    ),
    reply_json_dict(Resultado).

% Endpoint 2: Asignar a Cuerpos Académicos
api_asignar_cuerpos(_Request) :-
    findall(
        _{cuerpo_id: IdCA, nombre: NomCA, linea: Linea, profesores_aptos: Profs},
        (
            cuerpo_academico(IdCA, NomCA, Linea, _, _),
            findall(_{empleado: E, nombre: N, grado: G}, (apto_para_cuerpo_academico(E, IdCA), profesor(E, N, G, _, _)), Profs)
        ),
        Resultado
    ),
    reply_json_dict(Resultado).

% Endpoint 3: Asignar a Proyectos
api_asignar_proyectos(_Request) :-
    findall(
        _{proyecto_id: IdProy, nombre: NomProy, candidatos_sugeridos: Candidatos},
        (
            proyecto(IdProy, NomProy, _, _, _, _, _, _),
            findall(_{empleado: E, nombre: N, especialidad: Esp}, (apto_para_proyecto(E, IdProy), profesor(E, N, _, Esp, _)), Candidatos)
        ),
        Resultado
    ),
    reply_json_dict(Resultado).

% Endpoint 4: Asignar mejor profesor para un curso
api_asignar_curso(Request) :-
    http_parameters(Request, [
        curso(NombreCurso, [atom])
    ]),
    (   mejor_profesor_para_curso(NombreCurso, NumEmp, Puntaje)
    ->  profesor(NumEmp, Nombre, Grado, Esp, _),
        reply_json_dict(_{
            curso: NombreCurso,
            mejor_profesor: _{
                empleado: NumEmp,
                nombre: Nombre,
                grado: Grado,
                especialidad: Esp,
                puntaje_evaluado: Puntaje
            }
        })
    ;   reply_json_dict(_{error: 'No se encontro profesor con dominio para ese curso'}, [status(404)])
    ).

% Endpoint 5: Asignar profesores a cursos de capacitación
api_asignar_capacitacion(_Request) :-
    findall(
        _{curso_capacitacion_id: IdCap, nombre: NomCap, profesores_candidatos: Candidatos},
        (
            curso_capacitacion(IdCap, NomCap, _, _, _, _),
            findall(_{empleado: E, nombre: N}, (requiere_capacitacion(E, IdCap), profesor(E, N, _, _, _)), Candidatos)
        ),
        Resultado
    ),
    reply_json_dict(Resultado).

% Endpoint 6: Buscar profesor y sus asignaciones
api_buscar_profesor(Request) :-
    http_parameters(Request, [
        empleado(NumEmp, [integer])
    ]),
    (   resumen_profesor(NumEmp, Resumen)
    ->  reply_json_dict(Resumen)
    ;   reply_json_dict(_{error: 'Profesor no encontrado con el numero de empleado proporcionado'}, [status(404)])
    ).