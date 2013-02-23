# LibCurl Julia bindings

# TODO
# * Method abstraction for libcurl ccall's
# * tests
# * PUTs
# * response format that gives body and headers

module Curl

resp_data = ""
include("constants.jl")

const DEBUG = false
const version = "0.0.1"

function read_c_str(c_str::Ptr{Uint8})

  j_str = ""
  i = 1
  while true
    c = char(parse_int(base(10, unsafe_ref(c_str, i))))
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

function write_function(buf::Ptr{Uint8}, size::Uint32, nmemb::Uint32, userp::Ptr{Void})

  # To test, can call directly as:
  # ccall(c_write_function, (Uint32), (Ptr{Uint32}, Uint32, Uint32, Ptr{Void}), 0x00, 0x00, 0x00, 0x00)

  if DEBUG; println("write_function"); end

  # convert size provided in hex to dec
  num_bytes = parse_int(base(10, nmemb))
  arr = zeros(Char, num_bytes)
  for i = 1:num_bytes
    c = char(parse_int(base(10, unsafe_ref(buf, i))))
    arr[i] = c
  end
  str_val = join(arr)
  global resp_data = "$resp_data$str_val"

  if DEBUG
    println("size: $size")
    println("nmemb $nmemb")
    println("num bytes: $num_bytes")
    println("length of str val: $(length(str_val))")
    println("length of resp data: $(length(resp_data))")
  end

  # just report back that we 
  # saved what was sent in as input
  return nmemb

end
c_write_function = cfunction(write_function, Uint32, (Ptr{Uint8}, Uint32, Uint32, Ptr{Void}))

function curl_version()
  curl_ver = bytestring(ccall( (:curl_version, "libcurl"), Ptr{Uint8}, ()))
  curl_ver
end

function setup_curl()
  global resp_data = ""
  curl_ver = curl_version()
  if DEBUG; println("curl version: $curl_ver"); end
  curl = ccall( (:curl_easy_init, "libcurl"), Ptr{Uint8}, ())
  curl
end

function setup_curlopts(curl, url)

  ccall( (:curl_easy_setopt, "libcurl"), Ptr{Uint8}, (Ptr{Uint8}, Int, Int), curl, CURLOPT_FOLLOWLOCATION, 1)
  # ccall( (:curl_easy_setopt, "libcurl"), Ptr{Uint8}, (Ptr{Uint8}, Int, Ptr{Uint8}), curl, CURLOPT_URL, "http://jsonip.com".data)
  # ccall( (:curl_easy_setopt, "libcurl"), Ptr{Uint8}, (Ptr{Uint8}, Int, Ptr{Uint8}), curl, CURLOPT_URL, "http://hckrn.ws".data)
  ccall( (:curl_easy_setopt, "libcurl"), Ptr{Uint8}, (Ptr{Uint8}, Int, Ptr{Uint8}), curl, CURLOPT_URL, url.data)
  iostr = IOString()
  ccall( (:curl_easy_setopt, "libcurl"), Ptr{Uint8}, (Ptr{Uint8}, Int, Int), curl, CURLOPT_WRITEFUNCTION, c_write_function)
  ccall( (:curl_easy_setopt, "libcurl"), Ptr{Uint8}, (Ptr{Uint8}, Int, Ptr{Uint8}), curl, CURLOPT_FILE, iostr.data)

  # to file
  # fh = ccall( (:fopen, "libc"), Ptr{Uint8}, (Ptr{Uint8}, Ptr{Uint8}), "out".data, "wb".data)
  # ccall( (:curl_easy_setopt, "libcurl"), Ptr{Uint8}, (Ptr{Uint8}, Int, Int), curl, CURLOPT_WRITEFUNCTION, C_NULL)
  # ccall( (:curl_easy_setopt, "libcurl"), Ptr{Uint8}, (Ptr{Uint8}, Int, Ptr{Uint8}), curl, CURLOPT_FILE, fh)
  # ccall( (:fclose, "libc"), Ptr{Uint8}, (Ptr{Uint8},), fh)

end

function do_curl(curl)

  res = ccall( (:curl_easy_perform, "libcurl"), Ptr{Uint8}, (Ptr{Uint8},), curl)
  global resp_data
  # resp_data is now ready
  if DEBUG; println("result: $res"); end

  res

end

function cleanup_curl(curl, res)
  err = ccall( (:curl_easy_strerror, "libcurl"), Ptr{Uint8}, (Ptr{Uint8},), res)
  if DEBUG; println("error: $(bytestring(err))"); end
  ccall( (:curl_easy_cleanup, "libcurl"), Ptr, (Ptr{Uint8},), curl)
end

function set_ua(curl)
  ua_str = "Curl.jl Ver. $version - $(curl_version())"
  ccall((:curl_easy_setopt, "libcurl"), Ptr{Uint8}, (Ptr{Uint8}, Int, Ptr{Uint8}), curl, CURLOPT_USERAGENT, ua_str.data)
end

macro run_with_block(expr)
  quote

    curl = setup_curl()
    setup_curlopts(curl, url)
    set_ua(curl)

    # $(esc(expr))
    $expr

    res = do_curl(curl)
    cleanup_curl(curl, res)

  end
end

function head(url)
  @run_with_block begin 
    ccall((:curl_easy_setopt, "libcurl"), Ptr{Uint8}, (Ptr{Uint8}, Int, Int), curl, CURLOPT_NOBODY, 1)
    # ccall((:curl_easy_setopt, "libcurl"), Ptr{Uint8}, (Ptr{Uint8}, Int, Ptr{Uint8}), curl, CURLOPT_CUSTOMREQUEST, "HEAD".data)
  end
  resp_data
end

function get(url)
  @run_with_block begin end
  resp_data
end

function post(url, params)

  @run_with_block begin
    escaped_params = dict_to_query_params(curl, params)
    # curl_easy_setopt(curl, CURLOPT_POSTFIELDS, "name=daniel&project=curl");
    ccall((:curl_easy_setopt, "libcurl"), Ptr{Uint8}, (Ptr{Uint8}, Int, Ptr{Uint8}), curl, CURLOPT_POSTFIELDS, escaped_params.data)
  end
  resp_data

end

function delete(url)

  @run_with_block begin
    # curl_easy_setopt(handle, CURLOPT_CUSTOMREQUEST, "DELETE"); 
    ccall((:curl_easy_setopt, "libcurl"), Ptr{Uint8}, (Ptr{Uint8}, Int, Ptr{Uint8}), curl, CURLOPT_CUSTOMREQUEST, "DELETE".data)
  end
  resp_data

end

end
