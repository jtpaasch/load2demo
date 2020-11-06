(* Demo: load two binaries into BAP *)

open !Core_kernel
open Bap_main
open Bap.Std

module Cmd = Extension.Command
module Typ = Extension.Type

let loader = "llvm"

let load (filename : string) : Project.t =
  let input = Project.Input.file ~loader ~filename in
  let proj = Project.create input ~package:filename in
  match proj with
  | Ok p -> p
  | Error e -> failwith @@ Error.to_string_hum e

let get_sub (prog : Program.t) (name : string) : Sub.t =
  let subs = Term.enum sub_t prog in
  Seq.find_exn ~f:(fun s -> String.equal (Sub.name s) name) subs

module Cli = struct

  let name = "load2demo"
  let doc = "Demo: load two binaries into BAP"

  let merge = Cmd.flag "merge" ~doc:"Let BAP merge the executables?"

  let exe_1 = Cmd.argument Typ.file ~doc:"Path to exe 1"
  let exe_2 = Cmd.argument Typ.file ~doc:"Path to exe 2"

  let grammar = Cmd.(args $ merge $ exe_1 $ exe_2)

  let callback (merge : bool) (exe_1 : string) (exe_2 : string)
      (ctxt : ctxt) : (unit, error) result =

    let prog_1, prog_2 = match merge with
      | true ->
        begin

          let proj_1 = load exe_1 in
          let proj_2 = load exe_2 in

          let prog_1 = Project.program proj_1 in
          let prog_2 = Project.program proj_2 in

          (prog_1, prog_2)

        end
      | false ->
        begin

          let proj_1 = load exe_1 in
          let prog_1 = Project.program proj_1 in

          let proj_2 = load exe_2 in
          let prog_2 = Project.program proj_2 in

          (prog_1, prog_2)

        end
    in

    let main_1 = get_sub prog_1 "main" in
    let main_2 = get_sub prog_2 "main" in

    print_endline "=== MAIN (First EXE) ============================";
    Format.printf "%a\n%!" Sub.pp main_1;
    print_endline "=== MAIN (Second EXE) ===========================";
    Format.printf "%a%!" Sub.pp main_2;

    Ok ()

end

let () = Cmd.declare Cli.name Cli.grammar Cli.callback ~doc:Cli.doc
