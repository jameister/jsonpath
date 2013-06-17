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
  | path EOF    { $1 }

path:
  |                                         { [] }
  | DOLLAR                                  { [] }
  | path dot_component                      { $2 :: $1 }
  | path LBRAC brac_list RBRAC              { $3 :: $1 }
  | path DOT DOT LBRAC search_list RBRAC    { $5 :: $1 }

dot_component:
  | DOT STAR          { Wildcard }
  | DOT STRING        { Field [$2] }
  | DOT DOT STAR      { Search [] }
  | DOT DOT STRING    { Search [$3] }

brac_list:
  | STAR             { Wildcard }
  | string_list      { Field $1 }
  | int_list         { Index $1 }
  | INT COLON        { Slice ($1, None) }
  | COLON INT        { Slice (0, Some $2) }
  | INT COLON INT    { Slice ($1, Some $3) }

search_list:
  | string_list    { Search $1 }

string_list:
  | QSTRING                      { [$1] }
  | string_list COMMA QSTRING    { $3 :: $1 }

int_list:
  | INT                   { [$1] }
  | int_list COMMA INT    { $3 :: $1 }
