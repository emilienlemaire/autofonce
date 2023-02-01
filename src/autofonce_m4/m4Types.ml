(**************************************************************************)
(*                                                                        *)
(*  Copyright (c) 2023 OCamlPro SAS                                       *)
(*                                                                        *)
(*  All rights reserved.                                                  *)
(*  This file is distributed under the terms of the                       *)
(*  OCAMLPRO-NON-COMMERCIAL license.                                      *)
(*                                                                        *)
(**************************************************************************)

type location = {
  file : string ;
  line : int ;
  char : int ;
}

exception Error of string * location

type token =
  | SHELL of string
  | IDENT of string
  | ONE_ARG of string
  | FIRST_ARG of string
  | NEXT_ARG of string
  | LAST_ARG of string
  | EOF

type block = statement list

and kind =
  | Macro of string * arg list
  | Shell of string

and statement = {
  kind : kind ;
  loc : location ;
}

and arg = {
  arg : string ;
  arg_loc : location ;
}
