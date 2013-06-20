%{
  open Jsonpath
%}

%token <int> INT
%token <string> STRING QSTRING
%token DOLLAR DOT LBRAC RBRAC STAR COLON COMMA
%token EOF

%start main
%type <Jsonpath.path> main

%%

main:
  | p = path; EOF    { p }

path:
  |                                                    { [] }
  | DOLLAR                                             { [] }
  | t = path; h = dot_component                        { h :: t }
  | t = path; LBRAC; h = bracketed; RBRAC              { h :: t }
  | t = path; DOT DOT LBRAC; h = search; RBRAC         { h :: t }

dot_component:
  | DOT STAR               { Wildcard }
  | DOT; s = STRING        { Field [s] }
  | DOT DOT; s = STRING    { Search [s] }

bracketed:
  | STAR                                           { Wildcard }
  | l = separated_nonempty_list(COMMA, QSTRING)    { Field l }
  | l = separated_nonempty_list(COMMA, INT)        { Index l }
  | s = slice                                      { s }

slice:
  | COLON; stop = INT                 { Slice (0, Some stop) }
  | start = INT; COLON                { Slice (start, None) }
  | start = INT; COLON; stop = INT    { Slice (start, Some stop) }

search:
  | l = separated_nonempty_list(COMMA, QSTRING)    { Search l }
