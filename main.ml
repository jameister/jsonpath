open Core_kernel.Std
open Printf
module Json = Yojson.Basic

let () =
  match Array.to_list Sys.argv with
  | [] -> assert false
  | [program_name] ->
      eprintf "Usage: %s <path> [path2 ...]\n" program_name;
      exit (-1)
  | _ :: path_args ->
      In_channel.iter_lines stdin (fun line ->
        let json = Json.from_string line in
        let process results path_str =
          let lexbuf = Lexing.from_string path_str in
          let path = Parser.path Lexer.token lexbuf in
          List.append results (Jsonpath.eval json path)
        in
        let results = List.fold path_args ~init:[] ~f:process in
        print_endline (Json.to_string (`List results))
      ) 
