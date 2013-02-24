### Curl.jl

A little Julia client HTTP library. Curl.jl supports basic HTTP method usage
(GET, POST, DELETE ...) for making requests to HTTP web servers.

### Examples

  ```julia
  julia> using Curl

  julia> using JSON

  julia> r = Curl.get("http://jsonip.com")
  Response("{\"ip\":\"24.4.140.175\",\"about\":\"/about\"}",["HTTP/1.1 200 OK", "Server: nginx/1.2.6", "Date: Sun, 24 Feb 2013 02:36:34 GMT"  …  "Access-Control-Allow-Origin: *", "Access-Control-Allow-Methods: GET"])

  julia> r.text
  "{\"ip\":\"24.4.140.175\",\"about\":\"/about\"}"

  julia> r.headers[1]
  9-element String Array:
   "HTTP/1.1 200 OK"                    
   "Server: nginx/1.2.6"                
   "Date: Sun, 24 Feb 2013 03:24:08 GMT"
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

  julia> Curl.head("http://requestb.in/181n1gk1")
  Response([["HTTP/1.1 200 OK", "Content-length: 3", "Content-Type: text/html; charset=utf-8", "Date: Sun, 24 Feb 2013 03:27:20 GMT", "Connection: keep-alive"]],"")

  julia> Curl.get("http://nytimes.com").text[1:92]
  "<!DOCTYPE html>\n<!--[if IE]><![endif]--> \n<html lang=\"en\">\n<head>\n<title>The New York Times "

  julia> Curl.get("http://nytimes.com").headers
  2-element Array{String,1} Array:
   ["HTTP/1.1 302 Found", "Date: Sun, 24 Feb 2013 03:29:06 GMT", "Server: Apache"  …  "Connection: close", "Content-Type: text/html; charset=iso-8859-1"]
   ["HTTP/1.1 200 OK", "Date: Sun, 24 Feb 2013 03:29:06 GMT", "Server: Apache"  …  "Connection: close", "Content-Type: text/html; charset=UTF-8"]        

  ```

### TODO

 * Support for PUT

### Requirements

 * LibCurl

