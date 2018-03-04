(:
	Copyright 2013-2018 OverStory Ltd <copyright@overstory.co.uk> and other contributors
	(see the CONTRIBUTORS file).

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
		You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
:)

xquery version "1.0-ml";

declare variable $path := xdmp:get-request-path();
declare variable $accept := xdmp:get-request-header ("Accept", "text/html");
declare variable $want-yaml as xs:boolean := fn:matches ($accept, "text/yaml|text/x-yaml");


xdmp:add-response-header ("Cache-Control", "no-cache"),
if (fn:matches ($path, "^/api(/)?$") or fn:matches ($path, "^/api/swagger\.yaml$"))
then (
	if ($want-yaml or fn:matches ($path, "^/api/swagger\.yaml$"))
	then (
		xdmp:set-response-content-type ("text/x-yaml"),
		"/swagger/api/swagger.yaml"
	) else "/swagger/api/swagger-ui/"
) else
if (fn:matches ($path, "^/api.+"))
then fn:replace ($path, "^/api(.*)", "/swagger/api/swagger-ui$1")
else xdmp:get-request-url()	(: This is where the Swagger parsing bit would go :)



(:
	Unoptimized, on each request:
		Open swagger file
			If none, return 500 error because no API configured
			(How to find this file?  Look at appserver config via admin API?  That's expensive, need to cache location)
		Parse it to find the endpoint matching the request verb, content type and path pattern
		Invoke the XQuery (or JavaScript?) module named in the x-marklogic-handler field
			If none, return 500 error because no handler configured

	Optimized, on each request:
		Open swagger file
			If none, return 500 error because no API configured
		Get timestamp of swagger file
		Get cached dispatch map from server variable, which will include a timestamp
			If no cached map, or if timestamp of swagger file is newer
				Parse swagger.yaml and build dispatch map, with current timestamp
					If syntax errors or missing module path
						Return 500 because swagger spec is invalid
				Store dispatch map in server variable
		Invoke the XQuery (or JavaScript?) module named in the x-marklogic-handler field
			If none, return 500 error because no handler configured
:)
