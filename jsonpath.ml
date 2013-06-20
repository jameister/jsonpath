open Core_kernel.Std

type component =
  | Wildcard
  | Field of string list
  | Search of string list
  | Index of int list
  | Slice of int * int option

type path = component list

(* Depth-first search through a JSON value
   for all values associated with any key in names. *)
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
    List.append results (collect name json)
  )

let all_sub_values = function
  | `Bool _ | `Float _ | `Int _ | `Null | `String _ -> []
  | `Assoc obj -> List.map obj snd
  | `List l -> l

(* Perform a path operation on a single JSON value.
   Each operation may return multiple JSON results. *)
let eval_component operation json =
  let module J = Yojson.Basic.Util in
  match operation with
  | Wildcard ->
      all_sub_values json
  | Field names ->
      List.map names (fun name -> J.member name json)
  | Search names ->
      search names json
  | Index idxs ->
      let a = Array.of_list (J.to_list json) in
      List.map idxs (fun i -> a.(i))
  | Slice (start, maybe_stop) ->
      let l = J.to_list json in
      let max_stop = List.length l in
      let stop = Option.value maybe_stop ~default:max_stop in
      let clip i =
        if i < 0 then 0 else if i > max_stop then max_stop else i
      in
      List.slice l (clip start) (clip stop)

(* Apply the components of the path
   to each JSON value in the list of values returned so far,
   starting from the root. *)
let eval json path =
  let apply jsons oper = List.concat_map jsons (eval_component oper) in
  List.fold path ~init:[json] ~f:apply

let print_component =
  let comma = String.concat ~sep:"','" in
  let json_string s = Yojson.Basic.to_string (`String s) in
  function
  | Wildcard ->
      "[*]"
  | Field names ->
      "['" ^ comma (List.map names json_string) ^ "']"
  | Search names ->
      "..['" ^ comma (List.map names json_string) ^ "']"
  | Index idxs ->
      "[" ^ comma (List.map idxs string_of_int) ^ "]"
  | Slice (start, None) ->
      "[" ^ string_of_int start ^ ":]"
  | Slice (start, Some stop) ->
      "[" ^ string_of_int start ^ ":" ^ string_of_int stop ^ "]"

(* Pretty-print a path (using the more general bracket syntax) *)
let to_string path = "$" ^ String.concat (List.map path print_component)
