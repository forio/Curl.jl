### DEPRECATED - THIS LIBRARY IS NO LONGER MAINTAINED AND MAY DISAPPEAR.

### Please see [Requests.jl](http://github.com/loladiro/Requests.jl) for all your HTTP client needs.

-------

### Curl.jl

A little Julia client HTTP library. Curl.jl supports basic HTTP method usage
(GET, POST, DELETE ...) for making requests to HTTP web servers.

### Installation

* Install Julia
* From the Julia console `Pkg.init()` if not already done so
* `julia> Pkg.update(); Pkg.add("Curl"); using Curl`

### Examples

  ```julia
  julia> using Curl

  julia> using JSON

  julia> Curl.get("http://jsonip.com").text
  "{\"ip\":\"24.4.140.175\",\"about\":\"/about\"}"

  julia> Curl.get("http://jsonip.com").headers[1]
  9-element String Array:
   "HTTP/1.1 200 OK"
   "Server: nginx/1.2.6"
   "Date: Sun, 24 Feb 2013 03:34:17 GMT"
   "Content-Type: application/json"
   "Transfer-Encoding: chunked"
   "Connection: keep-alive"
   "Vary: Accept-Encoding"
   "Access-Control-Allow-Origin: *"
   "Access-Control-Allow-Methods: GET"

  julia> JSON.parse(Curl.get("http://jsonip.com").text)["ip"]
  "24.4.140.175"

  julia> Curl.post("http://requestb.in/181n1gk1", { :arg1 => "var1" }).text
  "ok\n"

  julia> Curl.delete("http://requestb.in/181n1gk1").text
  "ok\n"

  julia> Curl.head("http://requestb.in/181n1gk1").text
  ""

  julia> Curl.get("http://nytimes.com").text[1:92]
  "<!DOCTYPE html>\n<!--[if IE]><![endif]--> \n<html lang=\"en\">\n<head>\n<title>The New York Times "

  julia> Curl.get("http://nytimes.com").headers[2]
  12-element String Array:
   "HTTP/1.1 200 OK"
   "Date: Sun, 24 Feb 2013 03:36:02 GMT"
   "Server: Apache"
   "expires: Thu, 01 Dec 1994 16:00:00 GMT"
   "cache-control: no-cache"
   "pragma: no-cache"
   "Set-Cookie: RMID=007f0100629751298aa2003f; Expires=Mon, 24 Feb 2014 03:36:02 GMT; Path=/; Domain=.nytimes.com;"
   "Set-cookie: adxcs=-; path=/; domain=.nytimes.com"
   "Vary: Host"
   "Content-Length: 168147"
   "Connection: close"
   "Content-Type: text/html; charset=UTF-8"

  julia> Curl.options("http://thestar.com.my").headers[1]
  9-element String Array:
   "HTTP/1.1 200 OK"
   "Cache-Control: max-age=60"
   "Allow: OPTIONS, TRACE, GET, HEAD, POST"
   "Content-Length: 0"
   "Server: Microsoft-IIS/7.5"
   "Public: OPTIONS, TRACE, GET, HEAD, POST"
   "X-Powered-By: ARR/2.5"
   "X-Powered-By: ASP.NET"
   "Date: Thu, 28 Feb 2013 01:28:42 GMT"

  julia> Curl.patch("http://requestb.in/s5sgk7s5", { :arg1 => "var1" }).text

  julia> Curl.put("http://requestb.in/1cvo9dy1", { :arg1 => "var1", :arg2 => "var2" }).text

  ...

  ```

### TODO

 * Curl-multi
 * Promises / callback interface

### Requirements

 * libcurl

