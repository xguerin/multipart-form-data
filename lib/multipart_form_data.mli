module Request : sig
  type t =
    { headers : (string * string) list
    ; body : string Lwt_stream.t
    }
end

module Part : sig
  module Value : sig
    type t =
      | Variable of string
      | File of {filename : string; content : string Lwt_stream.t; length : int64 option}
  end

  type t =
    { name: string
    ; value: Value.t
    }
end

val read :
  request:Request.t
  -> handle_part:(Part.t -> unit Lwt.t)
  -> (unit, string) result

val write_with_separator :
  separator:string
  -> request:Part.t Seq.t
  -> (Request.t, string) result

val write :
  request:Part.t Seq.t
  -> (Request.t, string) result
