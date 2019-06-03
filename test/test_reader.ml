open Utils

let test ~name ~input ~expected_parts =
  ( name
  , `Quick
  , fun () ->
    let request =
      { Multipart_form_data.Request.headers = test_headers
      ; body = Lwt_stream.of_list [ input ]
      }
    in
    let (callback, read) = testable_callback_factory () in
    let result = Multipart_form_data.read ~request ~handle_part:callback in
    let resulting_parts =
      read ()
      |> List.map part_to_testable
    in
    let expected_parts =
      expected_parts
      |> List.map part_to_testable
    in
    Alcotest.(check (result unit string)) (name ^ " result") (Ok ()) result;
    Alcotest.(check int)
      (name ^ " part count")
      (List.length expected_parts)
      (List.length resulting_parts);
    Alcotest.(check (list (pair (list string) (option int64))))
      (name ^ "parts")
      expected_parts
      resulting_parts
  )

let reader_tests =
  [ test
      ~name:"Simple form"
      ~input:("\r\n--" ^ separator
              ^ "\r\n"
              ^ "Content-Disposition: form-data; name=\"key\""
              ^ "\r\n" ^ "\r\n"
              ^ "value"
              ^ "\r\n"
              ^ "--" ^ separator ^ "--"
              ^ "\r\n"
             )
      ~expected_parts:[{ Multipart_form_data.Part.name = "key"
                       ; value = Variable "value"
                       }]
  ; test
      ~name:"File"
      ~input:("\r\n--" ^ separator
              ^ "\r\n"
              ^ "Content-Disposition: form-data; name=\"filename\"; filename=\"originalname\""
              ^ "\r\n"
              ^ "Content-Type: application/octet-stream"
              ^ "\r\n" ^ "\r\n"
              ^ "this is the content of our file\r\n"
              ^ "\r\n"
              ^ "--" ^ separator ^ "--"
              ^ "\r\n"
             )
      ~expected_parts:[{ Multipart_form_data.Part.name = "filename"
                       ; value = File { filename = "originalname"
                                      ; content = Lwt_stream.of_list ["this is the content of our file\r\n"]
                                      ; length = None
                                      }
                       }]

  ; test
      ~name:"Mixed"
      ~input:("\r\n--" ^ separator
              ^ "\r\n"
              ^ "Content-Disposition: form-data; name=\"var1\""
              ^ "\r\n" ^ "\r\n"
              ^ "\r\ntest\r\n"
              ^ "\r\n"
              ^ "--" ^ separator
              ^ "\r\n"
              ^ "Content-Disposition: form-data; name=\"filename\"; filename=\"originalname\""
              ^ "\r\n"
              ^ "Content-Type: application/octet-stream"
              ^ "\r\n" ^ "\r\n"
              ^ "this is \r\nthe content of our file\r\n"
              ^ "\r\n"
              ^ "--" ^ separator
              ^ "\r\n"
              ^ "Content-Disposition: form-data; name=\"var2\""
              ^ "\r\n" ^ "\r\n"
              ^ "end===stuff"
              ^ "\r\n"
              ^ "--" ^ separator ^ "--"
              ^ "\r\n"
             )
      ~expected_parts:[ { Multipart_form_data.Part.name = "var2"
                        ; value = Variable "end===stuff"
                        }
                      ; { Multipart_form_data.Part.name = "filename"
                        ; value = File { filename = "originalname"
                                       ; content = Lwt_stream.of_list ["this is \r\nthe content of our file\r\n"]
                                       ; length = None
                                       }
                        }
                      ; { Multipart_form_data.Part.name = "var1"
                        ; value = Variable "\r\ntest\r\n"
                        }
                      ]

  ]
