### Curl.jl

A Julia client HTTP library

### Examples

  julia> using Curl

  julia> using JSON

  julia> Curl.get("http://jsonip.com")
  "{\"ip\":\"24.4.140.175\",\"about\":\"/about\"}"

  julia> JSON.parse(Curl.get("http://jsonip.com"))["ip"]
  "24.4.140.175"

### Requirements

 * LibCurl
