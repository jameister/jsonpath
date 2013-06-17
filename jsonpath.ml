open Core_kernel.Std
open Printf
module Json = Yojson.Basic
module J = Json.Util

(* All lists are in reverse order of user entry.
   Example: $.foo[1,2,3] is parsed to [Index [3; 2; 1]; Field ["foo"]] *)

type component =
  | Wildcard
  | Field of string list
  | Search of string list
  | Index of int list
  | Slice of int * int option

type path = component list

(* Depth-first search through a JSON value
   for all sub-values associated with any key in names. *)
let search names json =
  let rec collect name = function
    | `Bool _ | `Float _ | `Int _ | `Null | `String _ ->
        []
    | `Assoc obj ->
        List.concat_map obj (fun (key, value) ->
          let found = collect name value in
          if key = name then value :: found else found
        )
    | `List l ->
        List.concat_map l (collect name)
  in
  List.fold names ~init:[] ~f:(fun results name ->
    List.append (collect name json) results
  )

(* Perform a path operation on a single JSON value.
   Each operation may return multiple JSON results. *)
let eval_component operation json =
  match operation with
  | Wildcard ->
      J.to_list json
  | Field names ->
      List.rev_map names (fun name -> J.member name json)
  | Search [] ->
      [json] (* Does nothing *)
  | Search names ->
      search names json
  | Index idxs ->
      List.rev_map idxs (fun i -> J.index i json)
  | Slice (start, maybe_stop) ->
      let l = J.to_list json in
      let stop = Option.value maybe_stop ~default:(List.length l) in
      List.slice l start stop (* Core does JS-style slicing *)

(* Apply the components of the path
   to each JSON value in the list of values returned so far,
   starting from the root. *)
let eval json path =
  let apply oper jsons = List.concat_map jsons (eval_component oper) in
  List.fold_right path ~f:apply ~init:[json]

(* Pretty-print a path (using the more general bracket syntax) *)
let to_string path =
  let comma = String.concat ~sep:"," in
  let print_oper = function
    | Wildcard ->
        "[*]"
    | Field names ->
        "[" ^ comma (List.rev names) ^ "]"
    | Search [] ->
        "..*"
    | Search names ->
        "..[" ^ comma (List.rev names) ^ "]"
    | Index idxs ->
        "[" ^ comma (List.rev_map idxs string_of_int) ^ "]"
    | Slice (start, None) ->
        "[" ^ string_of_int start ^ ":]"
    | Slice (start, Some stop) ->
        "[" ^ string_of_int start ^ ":" ^ string_of_int stop ^ "]"
  in
  "$" ^ String.concat (List.rev_map path print_oper)
