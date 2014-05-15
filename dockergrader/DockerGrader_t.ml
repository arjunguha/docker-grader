(* Auto-generated from "DockerGrader.atd" *)


type status = [ `Graded | `GradingError | `Ignored ]

type statusFile = (string * status) list

type gradingFile = {
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
