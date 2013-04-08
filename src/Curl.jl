# Libcurl Julia bindings

# TODO
#
# * PUTs
# * TRACE
# * tests
# * Method abstraction for libcurl ccall's

module Curl

include("constants.jl")

const DEBUG = false
const version = "0.0.1"

# global
raw_response = { :headers => "", :text => "" }

type Response
  headers::Array{Array{String,1}}
  text::String
end

function read_c_str(c_str::Ptr{Uint8})
  i = 1
  j_str = ""
  while true
    c = char(parseint(base(10, unsafe_ref(c_str, i))))
    if c == '\0'
      break
    end
    j_str = string(j_str, c)
    i += 1
  end
    
  j_str
end

function escape(curl, str::String)
  p = ccall( (:curl_easy_escape, "libcurl"), Ptr{Uint8}, (Ptr{Uint8}, Ptr{Uint8}, Int), curl, str.data, 0)
  read_c_str(p)
end

function dict_to_query_params(curl, d::Dict)
  join([join([string(x), escape(curl, d[x])], "=") for x=keys(d)], "&")
end

function dict_to_query_params(curl, d::Array{Any,1})
  ""
end

function write_function(buf::Ptr{Uint8}, size::Uint32, nmemb::Uint32, userp::Ptr{Void})
  global resp_text
  gen_write_cb(:text, buf, size, nmemb, userp)
  nmemb
end

function header_function(buf::Ptr{Uint8}, size::Uint32, nmemb::Uint32, userp::Ptr{Void})
  gen_write_cb(:headers, buf, size, nmemb, userp)
  nmemb
end

function gen_write_cb(resp_type::Symbol, buf::Ptr{Uint8}, size::Uint32, nmemb::Uint32, userp::Ptr{Void})

  # To test, can call directly as
  # ccall(c_write_function, (Uint32), (Ptr{Uint32}, Uint32, Uint32, Ptr{Void}), 0x00, 0x00, 0x00, 0x00)

  if DEBUG; println("write_function"); end

  # convert size provided in hex to dec
  num_bytes = parseint(base(10, nmemb))
  arr = zeros(Char, num_bytes)
  for i = 1:num_bytes
    c = char(parseint(base(10, unsafe_ref(buf, i))))
    arr[i] = c
  end
  str_val = join(arr)
  global raw_response
  raw_response[resp_type] = string(raw_response[resp_type], str_val)

  if DEBUG
    println("size: $size")
    println("nmemb $nmemb")
    println("num bytes: $num_bytes")
    println("length of str val: $(length(str_val))")
    println("length of resp data: $(length(raw_response[resp_type]))")
  end

  # just report back that we saved what was sent in as input
  return nmemb

end
c_write_function = cfunction(write_function, Uint32, (Ptr{Uint8}, Uint32, Uint32, Ptr{Void}))
c_header_function = cfunction(header_function, Uint32, (Ptr{Uint8}, Uint32, Uint32, Ptr{Void}))

function curl_version()
  curl_ver = bytestring(ccall( (:curl_version, "libcurl"), Ptr{Uint8}, ()))
  curl_ver
end

function setup_curl()

  curl_ver = curl_version()
  if DEBUG; println("curl version: $curl_ver"); end
  curl = ccall( (:curl_easy_init, "libcurl"), Ptr{Uint8}, ())
  
end

function setup_curlopts(curl, url)
  iostr = IOString()

  ccall( (:curl_easy_setopt, "libcurl"), Ptr{Uint8}, (Ptr{Uint8}, Int, Int), curl, CURLOPT_FOLLOWLOCATION, 1)

  # instruct libcurl to not include the headers in the start of the body output
  ccall( (:curl_easy_setopt, "libcurl"), Ptr{Uint8}, (Ptr{Uint8}, Int, Int), curl, CURLOPT_HEADER, 0)
  ccall( (:curl_easy_setopt, "libcurl"), Ptr{Uint8}, (Ptr{Uint8}, Int, Int), curl, CURLOPT_HEADERFUNCTION, c_header_function)

  ccall( (:curl_easy_setopt, "libcurl"), Ptr{Uint8}, (Ptr{Uint8}, Int, Ptr{Uint8}), curl, CURLOPT_URL, url.data)
  ccall( (:curl_easy_setopt, "libcurl"), Ptr{Uint8}, (Ptr{Uint8}, Int, Int), curl, CURLOPT_WRITEFUNCTION, c_write_function)
  ccall( (:curl_easy_setopt, "libcurl"), Ptr{Uint8}, (Ptr{Uint8}, Int, Ptr{Uint8}), curl, CURLOPT_FILE, iostr.data)
end

function parse_headers(raw_headers)
  raw_header_groups = filter((x)->length(x) > 0, split(raw_headers, "\r\n\r\n"))
  [split(group, "\r\n") for group in raw_header_groups]
end

function do_curl(curl)

  global raw_response = { :headers => "", :text => "" }
  curl_resp = ccall( (:curl_easy_perform, "libcurl"), Ptr{Uint8}, (Ptr{Uint8},), curl)

  global raw_response
  # response values are now ready
  if DEBUG; println("result: $curl_resp"); end

  headers = parse_headers(raw_response[:headers])
  response = Response(headers, raw_response[:text])

  err = ccall( (:curl_easy_strerror, "libcurl"), Ptr{Uint8}, (Ptr{Uint8},), curl_resp)
  if DEBUG; println("error: $(bytestring(err))"); end

  response
end

function cleanup_curl(curl)
  ccall( (:curl_easy_cleanup, "libcurl"), Ptr, (Ptr{Uint8},), curl)
end
# finalizer(curl, cleanup_curl)

function set_ua(curl)
  ua_str = "Curl.jl Ver. $version - $(curl_version())"
  ccall((:curl_easy_setopt, "libcurl"), Ptr{Uint8}, (Ptr{Uint8}, Int, Ptr{Uint8}), curl, CURLOPT_USERAGENT, ua_str.data)
end

macro run_with_block(expr)
  quote
    curl = setup_curl()
    setup_curlopts(curl, url)
    set_ua(curl)

    $expr

    response = do_curl(curl)
    response

  end
end

# Http methods
function head(url)
  response = @run_with_block begin 
    ccall((:curl_easy_setopt, "libcurl"), Ptr{Uint8}, (Ptr{Uint8}, Int, Int), curl, CURLOPT_NOBODY, 1)
  end
  response
end

function get(url)
  @run_with_block begin end
end

function post(url, params)
  @run_with_block begin
    escaped_params = dict_to_query_params(curl, params)
    # curl_easy_setopt(curl, CURLOPT_POSTFIELDS, "name=daniel&project=curl");
    ccall((:curl_easy_setopt, "libcurl"), Ptr{Uint8}, (Ptr{Uint8}, Int, Ptr{Uint8}), curl, CURLOPT_POSTFIELDS, escaped_params.data)
  end
end

function delete(url)
  @run_with_block begin
    # curl_easy_setopt(handle, CURLOPT_CUSTOMREQUEST, "DELETE"); 
    ccall((:curl_easy_setopt, "libcurl"), Ptr{Uint8}, (Ptr{Uint8}, Int, Ptr{Uint8}), curl, CURLOPT_CUSTOMREQUEST, "DELETE".data)
  end
end

function options(url)
  @run_with_block begin
    # curl_easy_setopt(handle, CURLOPT_CUSTOMREQUEST, "OPTIONS"); 
    ccall((:curl_easy_setopt, "libcurl"), Ptr{Uint8}, (Ptr{Uint8}, Int, Int), curl, CURLOPT_NOBODY, 1)
    ccall((:curl_easy_setopt, "libcurl"), Ptr{Uint8}, (Ptr{Uint8}, Int, Ptr{Uint8}), curl, CURLOPT_CUSTOMREQUEST, "OPTIONS".data)
  end
end

function trace(url)
  @run_with_block begin
    # curl_easy_setopt(handle, CURLOPT_CUSTOMREQUEST, "OPTIONS"); 
    ccall((:curl_easy_setopt, "libcurl"), Ptr{Uint8}, (Ptr{Uint8}, Int, Ptr{Uint8}), curl, CURLOPT_CUSTOMREQUEST, "TRACE".data)
  end
end

end
