{
  open Parser
  open Printf

  let json_string s =
    let open Yojson.Basic in
    let lexbuf = Lexing.from_string ("\"" ^ s ^ "\"") in
    read_string (init_lexer ()) lexbuf

  let syntax_error pos c =
    let msg = sprintf "Unexpected character '%c' at position %i" c pos in
    raise (Jsonpath.Syntax_error msg)
}

let letter = ['A'-'Z' 'a'-'z']
let digit = ['0'-'9']
let ident = letter | digit | '_'
let quote = ['"' '\'']

let number = '-'? digit+
let identifier = (letter | '_') ident*

rule token = parse
  | '$'                { DOLLAR }
  | '.'                { DOT }
  | '['                { LBRAC }
  | ']'                { RBRAC }
  | '*'                { STAR }
  | ':'                { COLON }
  | ','                { COMMA }
  | quote as c         { QSTRING (qstring c (Buffer.create 64) lexbuf) }
  | number as s        { INT (int_of_string s) }
  | identifier as s    { STRING s }
  | eof                { EOF }
  | _ as c             { syntax_error (Lexing.lexeme_start lexbuf) c }

and qstring q buf = parse
  | quote as c           { if c = q then json_string (Buffer.contents buf)
                           else begin
                             Buffer.add_char buf c;
                             qstring q buf lexbuf
                           end }
  | '\\' (quote as c)    { Buffer.add_char buf c; qstring q buf lexbuf }
  | _ as c               { Buffer.add_char buf c; qstring q buf lexbuf }
