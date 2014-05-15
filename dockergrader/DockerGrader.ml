open Core.Std
open Async.Std
open Docker
open DockerGrader_t

(* TODO(arjun): Given a container with an entrypoint how do I use the API
  to pass it arguments? *)

(* TODO(arjun): No need to validate Gradingfile. Grading user can be root, but
   just warn. *)

(* TODO(arjun): Can I validate that the container is derived from my 
   Dockerfile and that it doesn't override entrypoint, etc.? *)

let gradingfile = "Gradingfile"

let statusfile = "status.json"

let submissions_dir = "submissions"

let mount_point = "/root/dockergrader"

(* Returns the empty list if the file does not exist. *)
let read_statusfile () : statusFile Deferred.t =
  Sys.is_file statusfile
  >>= function
  | `Yes ->
     Reader.file_contents statusfile
     >>| DockerGrader_j.statusFile_of_string
  | _ -> return []

(* Does not return if the file does not exist. *)
let read_gradingfile (prefix : string) : gradingFile Deferred.t  =
  let gradingfile = prefix ^ "/" ^ gradingfile in
  Sys.is_file gradingfile
  >>= function
  | `Yes ->
    Reader.file_contents gradingfile 
    >>| DockerGrader_j.gradingFile_of_string
  | _ ->
    eprintf "Could not find the file %s\n%!" gradingfile;
    exit 1

let is_ungraded (status : statusFile) : string -> bool = 
  let graded_submissions = List.map ~f:fst status in
  fun sub -> not (List.mem graded_submissions sub)

let save_or_display submission maybe_output log =
  match maybe_output with
  | Some filename -> 
    Writer.save (sprintf "%s/%s/%s" submissions_dir submission filename)
      ~contents:log
  | None -> printf "Output:\n"; print_endline log; return ()

let grade (grading : gradingFile) (status : statusFile) (submission : string)
  : unit Deferred.t =
  printf "Grading %s ...\n%!" submission;
  let container = container_with_cmd ~image:grading.container [ submission ] in
  let container = 
    { container with
      networkDisabled = true;
      volumes = [(mount_point, `Assoc [])] } in
  create_container container
  >>= fun status ->
  let container_id = status.id in
  List.iter (Option.value ~default:[] status.warnings)
    ~f:(fun str -> print_endline ("WARNING (from Docker): " ^ str));
  try_with (fun () ->
    Sys.getcwd ()
    >>= fun cwd -> 
    let hostConfig = { simpleHostConfig with binds = [ cwd ^ ":" ^ mount_point ] } in
    start_container ~hostConfig container_id
    >>= fun () ->
    wait_for_container container_id
    >>= fun code ->
    (* Delay is needed to let the logs get in place. *)
    Clock.after (Time.Span.of_sec 2.0)
    >>= fun () ->
    container_logs ~stdout:true container_id
    >>= fun stdout_log ->
    container_logs ~stderr:true container_id
    >>= fun stderr_log ->
    save_or_display submission grading.stdout stdout_log
    >>= fun () ->
    save_or_display submission grading.stderr stderr_log
    >>= fun () ->
    printf "... finished grading %s (code %d).\n%!" submission code;
    return code)
  >>= function
  | Ok 0 -> delete_container ~volumes:true ~force:true container_id
  | Ok exit_code -> 
    let msg = sprintf
       "Fatal error grading %s (container %s, exit code %d)." 
      submission container_id exit_code in
    print_endline msg;
    failwith msg
  | Error exn ->
    printf "Fatal error grading %s.\n%!" submission;
    printf "Trying to delete image %s.\n%!" container_id;
    delete_container ~volumes:true ~force:true container_id >>=
    raise exn

(* In the host: (1) Parse Gradingfile and status.json. (2) Enumerate directories
   in submissions/ and filter by those marked completed in status.json. (3) For
   each submission, in sequence, launch a container to grade. (4) When a
   container terminates (or times out) update status.json, save container logs,
   and move on to the next submission. The executable in the container will save
   outputs to the submission directory. *)
let start () : unit Deferred.t =
  read_gradingfile "."
  >>= fun grading ->
  read_statusfile ()
  >>= fun status ->
  Sys.ls_dir submissions_dir
  >>= fun all_submissions ->
  let ungraded_submissions = 
    List.filter ~f:(is_ungraded status) all_submissions in
  Deferred.List.iter ungraded_submissions 
    ~how:`Sequential ~f:(grade grading status)
  >>= fun () ->
  exit 0

(* In the container: (1) Ensure that the current user is root. (2) Parse the
   submission file to determine run configuration. (3) Run grading script as
   grading user and save exit code. (4) Copy output files to the submission
   directory. (5) Terminate with the exit code returned by the grading script.
   *)
let in_container (submission : string) : unit Deferred.t = 
  let open Unix in
  read_gradingfile mount_point
  >>= fun gradingFile ->
  let dir = gradingFile.directory in
  let uid = gradingFile.account in
  let srcDir = sprintf "%s/%s/%s" mount_point submissions_dir submission in
  system_exn (sprintf "mkdir -p %s" dir) >>= fun () ->
  system_exn (sprintf "cp -r %s/* %s" srcDir dir) >>= fun () ->
  system_exn (sprintf "chown -R %s:%s %s" uid uid dir) >>= fun () ->
  chdir dir >>= fun () ->
  system (sprintf "su %s -c '%s'" uid gradingFile.command) >>= fun result ->
  match result with
  | Ok () -> 
    printf "Completed.\n%!";
    (* FILL(arjun): Return exit code somehow. Copy outputs *)
    exit 0
  | Error (`Exit_non_zero n)  ->
    printf "[docker-grader]: Grading script exited with error %d.\n%!" n;
    exit 0
  | Error _  ->
    printf "[docker-grader]: Grading script killed\n%!";
    exit 0

let _ = match Array.to_list Sys.argv with
  | [ _; "start" ] -> start ()
  | [ _; "in-container"; submission ] -> 
    in_container submission
  | _ -> begin
    printf "Invalid command-line arguments. Read the code for help.\n%!";
    exit 1
  end

let _ = Scheduler.go ()