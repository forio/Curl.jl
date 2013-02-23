### Curl.jl

A Julia client HTTP library.

Curl.jl supports basic HTTP method usage (GET, POST, DELETE ...) for making
requests to HTTP web servers.

### Examples

  ```julia
  julia> using Curl

  julia> using JSON

  julia> Curl.get("http://jsonip.com")
  "{\"ip\":\"24.4.140.175\",\"about\":\"/about\"}"

  julia> JSON.parse(Curl.get("http://jsonip.com"))["ip"]
  "24.4.140.175"

  julia> Curl.post("http://requestb.in/181n1gk1", { :arg1 => "var1" })
  "ok\n"

  julia> Curl.delete("http://requestb.in/181n1gk1")
  "ok\n"

  julia> Curl.head("http://requestb.in/181n1gk1")
  ""
  ```

### TODO

 * Support for PUT
 * Setting / getting headers

### Requirements

 * LibCurl

