# PowerShell REST API

## Description
This is a REST API implementation written in PowerShell. The purpose is to provide a method for executing prepared PowerShell commands from a web endpoint.

## Concept
This module was designed to accept HTTP requests to invoke predefined script blocks to execute and return the results. For a GET method, the expected user input is to be provided as a query string. The name-value pair can be parsed from inside the script block. For other request methods, a JSON body can be sent containing any name-value pairs. These too can be referenced in the Endpoint script block.

The Endpoints are declared using `Router.psm1`. A new Endpoint object should be created to include more API calls.

## Parsing Input
Values sent in a query string using a GET method can be referenced in a script block by using `$args`. They are passed into the script block as a hash table. Reference values accordingly.

Values sent in a JSON body can be referenced once similarly with `$args`. Values are passed as an object.

All request types should allow parsing of name-value pairs identically.

See sample Endpoints for an example.

## Running
`Start-Server.ps1 -Hostname <hostname> -Port <port> -Path <path>`

Default values are provided.

Variable | Default Value
---| -----
Hostname | localhost
Port | 8080
Path | /

#### Notes
- Serialization functions can likely be improved. Minimum required functionality was implemented. If using this API for large volumes, quantity, or utilizing File I/O, they must be improved.
- If being used in a production environment HTTPS and/or authentication should be implemented by enhancing this code or by use of a reverse proxy.
