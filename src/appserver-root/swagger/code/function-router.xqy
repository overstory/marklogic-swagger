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

let $module-name := xdmp:get-request-field("module-name")
let $function := xdmp:get-request-field("function-name")
let $ns := xdmp:get-request-field("function-ns")

let $_ := xdmp:log(fn:concat("router.xqy -- library-module:  ", $module-name), "debug")
let $_ := xdmp:log(fn:concat("router.xqy -- ns:  ", $ns), "debug")
let $_ := xdmp:log(fn:concat("router.xqy -- function:  ", $function), "debug")

return
    xdmp:eval(fn:concat("
      import module namespace x = '", $ns, "' at '", $module-name, "';
      x:", $function, "()
    "
    ))
