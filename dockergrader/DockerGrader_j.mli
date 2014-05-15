(* Auto-generated from "DockerGrader.atd" *)


type status = DockerGrader_t.status

type statusFile = DockerGrader_t.statusFile

type gradingFile = DockerGrader_t.gradingFile = {
  container: string;
  account: string;
  memory: string option;
  time: string option;
  directory: string;
  command: string;
  outputs: (string * string) list option;
  stdout: string option;
  stderr: string option;
  errors: string option
}

val write_status :
  Bi_outbuf.t -> status -> unit
  (** Output a JSON value of type {!status}. *)

val string_of_status :
  ?len:int -> status -> string
  (** Serialize a value of type {!status}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_status :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> status
  (** Input JSON data of type {!status}. *)

val status_of_string :
  string -> status
  (** Deserialize JSON data of type {!status}. *)

val write_statusFile :
  Bi_outbuf.t -> statusFile -> unit
  (** Output a JSON value of type {!statusFile}. *)

val string_of_statusFile :
  ?len:int -> statusFile -> string
  (** Serialize a value of type {!statusFile}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_statusFile :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> statusFile
  (** Input JSON data of type {!statusFile}. *)

val statusFile_of_string :
  string -> statusFile
  (** Deserialize JSON data of type {!statusFile}. *)

val write_gradingFile :
  Bi_outbuf.t -> gradingFile -> unit
  (** Output a JSON value of type {!gradingFile}. *)

val string_of_gradingFile :
  ?len:int -> gradingFile -> string
  (** Serialize a value of type {!gradingFile}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_gradingFile :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> gradingFile
  (** Input JSON data of type {!gradingFile}. *)

val gradingFile_of_string :
  string -> gradingFile
  (** Deserialize JSON data of type {!gradingFile}. *)

