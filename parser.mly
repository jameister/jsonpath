%{
  open Jsonpath
  open Printf

  let syntax_error msg first last =
    let open Lexing in
    let loc = sprintf "Position %i-%i: " first.pos_cnum last.pos_cnum in
    raise (Syntax_error (loc ^ msg))
%}

%token <int> INT
%token <string> STRING QSTRING
%token DOLLAR DOT LBRAC RBRAC STAR COLON COMMA
%token EOF

%start <Jsonpath.path> path

%%

path:
  | DOLLAR? path = component+ EOF
      { path }

component:
  | DOT STAR
      { Wildcard }
  | DOT s = STRING
      { Field [s] }
  | DOT _e = error
      { syntax_error "expected * or field name" $startpos(_e) $endpos(_e) }
  | DOT DOT s = STRING
      { Search [s] }
  | c = delimited(LBRAC, bracketed, RBRAC)
  | DOT DOT c = delimited(LBRAC, search, RBRAC)
      { c }
  | DOT DOT _e = error
      { syntax_error "expected [ or field name" $startpos(_e) $endpos(_e) }

bracketed:
  | STAR
      { Wildcard }
  | l = separated_nonempty_list(COMMA, QSTRING)
      { Field l }
  | l = separated_nonempty_list(COMMA, INT)
      { Index l }
  | s = slice
      { s }
  | _e = error
      { syntax_error "invalid bracket contents" $startpos(_e) $endpos(_e) }

slice:
  | COLON stop = INT
      { Slice (0, Some stop) }
  | start = INT COLON
      { Slice (start, None) }
  | start = INT COLON stop = INT
      { Slice (start, Some stop) }

search:
  | l = separated_nonempty_list(COMMA, QSTRING)
      { Search l }
  | _e = error
      { syntax_error "invalid search contents" $startpos(_e) $endpos(_e) }
