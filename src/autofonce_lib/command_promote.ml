(**************************************************************************)
(*                                                                        *)
(*  Copyright (c) 2023 OCamlPro SAS                                       *)
(*                                                                        *)
(*  All rights reserved.                                                  *)
(*  This file is distributed under the terms of the GNU General Public    *)
(*  License version 3.0, as described in the LICENSE.md file in the root  *)
(*  directory of this source tree.                                        *)
(*                                                                        *)
(*                                                                        *)
(**************************************************************************)

open Ezcmd.V2
open EZCMD.TYPES
open Ez_file.V1
open EzFile.OP

module Patch_lines = Autofonce_patch.Patch_lines
module Parser = Autofonce_core.Parser
module Misc = Autofonce_misc.Misc
open Types
open Globals

(* TODO: check why the ignore pattern does not work *)
let diff = Patch_lines.Diff { exclude = [ "^# promoted on .*" ]}
let todo = ref diff
let comment = ref true
let not_exit = ref false

let promote rundir p tc suite =
  only_failed := true ;
  Patch_lines.reset ();
  let state = Runner_common.create_state rundir p tc suite in
  Unix.chdir state.state_run_dir ;
  let comment_line =
    let t = Unix.gettimeofday () in
    let tm = Unix.localtime t in
    Printf.sprintf "# promoted on %04d-%02d-%02dT%02d:%02d"
      ( 1900 + tm.tm_year )
      ( 1 + tm.tm_mon )
      tm.tm_mday
      tm.tm_hour
      tm.tm_min
  in
  let promote_test t =
    let file = t.test_loc.file in
    Printf.eprintf "Promoting test %d %s\n%!"
      t.test_id ( Parser.name_of_loc t.test_loc );
    let line_first = t.test_loc.line in
    let line_last =
      match List.rev t.test_actions with
      | AT_CLEANUP { loc } :: _ -> loc.line
      | _ -> Misc.error
               "Last test in %s does not end with AT_CLEANUP ?" file
    in

    let b = Buffer.create 10000 in

    Printf.bprintf b "AT_SETUP(%s)\n" (Parser.m4_escape t.test_name);

    if !comment then
      Printf.bprintf b "%s\n" comment_line;

    begin
      match t.test_keywords with
      | [] -> ()
      | list ->
          Printf.bprintf b "AT_KEYWORDS(%s)\n"
            (Parser.m4_escape (String.concat " " list))
    end;

    let rec print_check check =
      let check_dir = Runner_common.check_dir check in
      let check_prefix = check_dir // Runner_common.check_prefix check in
      Printf.bprintf b "%s" ( Parser.m4_escape check.check_command );
      let continue =
        let check_exit = Printf.sprintf "%s.exit" check_prefix in
        if Sys.file_exists check_exit then
          let s = EzFile.read_file check_exit in
          let retcode = int_of_string s in
          if !not_exit then
            match check.check_retcode with
            | None -> false
            | Some old_retcode ->
                Printf.bprintf b ",\n# EXIT WITH %d\n[%d]"
                  retcode old_retcode ;
                true
          else begin
            Printf.bprintf b ", [%d]" retcode;
            true
          end
        else
          match check.check_retcode with
          | None -> false
          | Some retcode ->
              Printf.bprintf b ", [%d]" retcode;
              true
      in
      let continue =
        continue &&
        match check.check_stdout with
        | Ignore ->
            if check.check_stderr = Ignore &&
               check.check_run_if_pass = [] &&
               check.check_run_if_fail = [] then
              false
            else begin
              Printf.bprintf b ", [ignore]";
              true
            end
        | Content old_content ->
            let check_stdout = Printf.sprintf "%s.out" check_prefix in
            if Sys.file_exists check_stdout then
              let s = EzFile.read_file check_stdout in
              Printf.bprintf b ", %s" (Parser.m4_escape s);
              true
            else begin
              Printf.bprintf b ", %s" (Parser.m4_escape old_content);
              true
            end
      in
      let continue =
        continue &&
        match check.check_stderr with
        | Ignore ->
            if check.check_run_if_pass = [] &&
               check.check_run_if_fail = [] then
              false
            else begin
              Printf.bprintf b ", [ignore]";
              true
            end
        | Content old_content ->
            let check_stderr = Printf.sprintf "%s.err" check_prefix in
            if Sys.file_exists check_stderr then
              let s = EzFile.read_file check_stderr in
              Printf.bprintf b ", %s" (Parser.m4_escape s);
              true
            else begin
              Printf.bprintf b ", %s" (Parser.m4_escape old_content);
              true
            end
      in
      let continue =
        continue &&
        match check.check_run_if_fail with
        | [] ->
            if check.check_run_if_pass = [] then
              false
            else begin
              Printf.bprintf b ", []";
              true
            end
        | actions ->
            Printf.bprintf b ", [\n";
            print_actions actions;
            Printf.bprintf b "]";
            true
      in
      if continue then
        match check.check_run_if_pass with
        | [] -> ()
        | actions ->
            Printf.bprintf b ", [\n";
            print_actions actions;
            Printf.bprintf b "]"

    and print_action action =
      match action with
      | AT_CLEANUP _ -> Printf.bprintf b "\nAT_CLEANUP";
      | AT_DATA { file ; content } ->
          Printf.bprintf b "AT_DATA(%s,%s)\n"
            ( Parser.m4_escape file )
            ( Parser.m4_escape content )
      | AT_ENV string ->
          Printf.bprintf b "AT_ENV(%s)\n"
            ( Parser.m4_escape string )
      | AT_CAPTURE_FILE string ->
          Printf.bprintf b "AT_CAPTURE_FILE(%s)\n"
            ( Parser.m4_escape string )
      | AT_XFAIL ->
          Printf.bprintf b "AT_XFAIL_IF([true])\n"
      | AT_SKIP ->
          Buffer.add_string b "AT_SKIP([true])\n"
      | AT_CHECK  check ->
          Buffer.add_string b "AT_CHECK(";
          print_check check ;
          Buffer.add_string b ")\n"

    and print_actions actions =
      List.iter print_action actions

    in
    print_actions t.test_actions;

    let content = Buffer.contents b in
    Patch_lines.replace_block ~file ~line_first ~line_last content
  in
  Filter.select_tests ~state promote_test suite;

  Patch_lines.commit_to_disk ~action:!todo ();
  ()

let args auto_promote_arg = [

  [ "no-comment" ], Arg.Clear comment,
  EZCMD.info ~env:(EZCMD.env "AUTOFONCE_PROMOTE_NO_COMMENT")
    "Do not add a comment with the promotion date";

  [ "not-exit" ], Arg.Set not_exit,
  EZCMD.info "Do not promote exit code" ;

  [ auto_promote_arg ], Arg.Int (fun n ->
      auto_promote := n ;
      todo := Apply ;
    ),
  EZCMD.info
    "Promote and run until all tests have been promoted"

]

let rec action rundir p tc suite =
  promote rundir p tc suite ;
  if !auto_promote > 0 then begin
    only_failed := true ;
    clean_tests_dir := false ;
    let n = Testsuite.exec rundir p tc suite in
    decr auto_promote;
    if n>0 then
      let (rundir, p, tc, suite) = Testsuite.read rundir p tc in
      action rundir p tc suite
  end

let cmd =
  let args =
    Testsuite.args @
    Filter.args @
    args "auto-run" @
    [

      [ "apply" ], Arg.Unit (fun () -> todo := Apply),
      EZCMD.info "Apply promotion (default is to diff)" ;

      [ "diff" ], Arg.Unit (fun () -> todo := diff),
      EZCMD.info "Diff promotion (default)" ;

      [ "fake" ], Arg.String (fun ext -> todo := Fake ext),
      EZCMD.info ~docv:".EXT"
        "Apply promotion to create new files with extension $(docv)" ;

    ]
  in
  EZCMD.sub
    "promote"
    (fun () ->
       let rundir, p, tc, suite = Testsuite.find () in
       action rundir p tc suite
    )
    ~args
    ~doc: "Promote tests results as expected results"
    ~man:[
      `S "DESCRIPTION";
      `Blocks [
        `P {|After an unsucessful testsuite run, use this command to promote the results of tests to expected status.|} ;
      ];
    ]