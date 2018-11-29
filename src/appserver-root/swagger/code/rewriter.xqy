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

declare namespace s = "http://www.w3.org/2005/xpath-functions";

declare variable $SWAGGER-PATH := "/swagger/api/swagger.yaml";

declare variable $MAIN-MODULE-PROPERTY-NAME := "x-marklogic-main-module";
declare variable $LIBRARY-MODULE-PROPERTY-NAME := "x-marklogic-library-module";
declare variable $FUNCTION-NS-PROPERTY-NAME := "x-marklogic-function-ns";
declare variable $FUNCTION-NAME-PROPERTY-NAME := "x-marklogic-function-name";

declare variable $path := xdmp:get-request-path();
declare variable $request-method := fn:lower-case(xdmp:get-request-method());
declare variable $accept := xdmp:get-request-header("Accept", "text/html");
declare variable $want-yaml as xs:boolean := fn:matches($accept, "text/yaml|text/x-yaml");

declare function local:extract-path-params($path-pattern as xs:string, $path as xs:string) as xs:string*
{
    fn:string-join(
            let $path-parts := fn:tokenize($path, "/")
            for $part at $x in fn:tokenize($path-pattern, "/")
            return
                let $analyzed-string := fn:analyze-string($part, "\{([\w\d_-]+)\}")
                return
                    if ($analyzed-string/s:match) then
                        $analyzed-string/s:match/s:group/fn:string() || "=" || $path-parts[$x]
                    else
                        ()
            , "&amp;")
};

declare function local:path-matches($path-pattern as xs:string, $path as xs:string) as xs:boolean {
    let $parts :=
        for $part in fn:tokenize($path-pattern, "/")
        return
            if (fn:matches($part, "\{[\w\d_-]+\}")) then
                "[\w\d_-]+"
            else
                $part
    let $regex := "^" || fn:string-join($parts, "/") || "$"
    return fn:matches($path, $regex)
};


declare function local:redirect() {
    let $yaml-from-file :=
        if (xdmp:modules-database()) then
        (: Modules on database :)
            xdmp:eval("
          declare variable $swagger-file as xs:string external;
          fn:doc($swagger-file)
        ", (xs:QName("swagger-file"), $SWAGGER-PATH), <options xmlns="xdmp:eval"><database>{xdmp:modules-database()}</database></options>)
        else
        (: Modules on filesystem :)
            let $full-file-path := xdmp:modules-root() || $SWAGGER-PATH
            return xdmp:filesystem-file($full-file-path)
    let $yaml :=
        xdmp:to-json(
                xdmp:javascript-eval("
                  const yaml = require('/swagger/lib/js-yaml');
                  yaml.safeLoad(yamlString);
                ", ("yamlString", $yaml-from-file)))

    let $redirect-path :=
        let $library-module-path := xdmp:value("$yaml/paths/*[local:path-matches(fn:name(.), $path)]/" || $request-method || "/" || $LIBRARY-MODULE-PROPERTY-NAME)
        return
            if ($library-module-path) then
                let $module-name := $library-module-path
                let $function-ns := xdmp:value("$yaml/paths/*[local:path-matches(fn:name(.), $path)]/" || $request-method || "/" || $FUNCTION-NS-PROPERTY-NAME)
                let $function-name := xdmp:value("$yaml/paths/*[local:path-matches(fn:name(.), $path)]/" || $request-method || "/" || $FUNCTION-NAME-PROPERTY-NAME)
                let $qs-pairs := ("module-name=" || $module-name, "function-ns=" || $function-ns, "function-name=" || $function-name)
                return
                    "/swagger/code/function-router.xqy?" || fn:string-join($qs-pairs, "&amp;")
            else
                xdmp:value("$yaml/paths/*[local:path-matches(fn:name(.), $path)]/" || $request-method || "/" || $MAIN-MODULE-PROPERTY-NAME)

    let $query-string := fn:substring-after(xdmp:get-request-url(), "?")
    let $_ := xdmp:log("rewriter.xqy -- query-string: " || $query-string, "debug")
    let $path-params := local:extract-path-params($yaml/paths/*[local:path-matches(fn:name(.), $path)]/fn:name(), $path)
    let $_ := xdmp:log("rewriter.xqy -- path params: " || $path-params, "debug")
    let $redirect-path :=
        if (($query-string or $path-params) and $redirect-path) then
            if (fn:contains($redirect-path, "?")) then
                $redirect-path || "&amp;" || fn:string-join(($query-string, $path-params), "&amp;")
            else
                $redirect-path || "?" || fn:string-join(($query-string, $path-params), "&amp;")
        else
            $redirect-path
    let $_ := xdmp:log("rewriter.xqy -- redirect-path: " || $redirect-path, "debug")
    return $redirect-path

};

if (fn:matches($path, "^/api(/)?$") or fn:matches($path, "^/api/swagger\.ya?ml$")) then
    (
        if ($want-yaml or fn:matches($path, "^/api/swagger\.ya?ml$")) then
            (
                xdmp:set-response-content-type("text/x-yaml"),
                $SWAGGER-PATH
            )
        else "/swagger/api/swagger-ui/"
    )
else
    if (fn:matches($path, "^/api.+")) then
        fn:replace($path, "^/api(.*)", "/swagger/api/swagger-ui$1")
    else
        let $redirect-path := local:redirect()
        return
            if ($redirect-path) then
                $redirect-path
            else
                xdmp:get-request-path(),
xdmp:log("rewriter.xqy -- elapsed time: " || xdmp:elapsed-time(), "debug")



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
