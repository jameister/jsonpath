%{
  open Jsonpath
%}

%token <int> INT
%token <string> STRING QSTRING
%token DOLLAR DOT LBRAC RBRAC STAR COLON COMMA
%token EOF

%start path
%type <Jsonpath.path> path

%%

path:
  | DOLLAR? path = component+ EOF    { path }

component:
  | DOT STAR                                       { Wildcard }
  | DOT s = STRING                                 { Field [s] }
  | DOT DOT s = STRING                             { Search [s] }
  | c = delimited(LBRAC, bracketed, RBRAC)         { c }
  | DOT DOT c = delimited(LBRAC, search, RBRAC)    { c }

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
