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

"Pathed match POST",
"Request method: " || xdmp:get-request-method(),
"Original URL: " || xdmp:get-original-url(),
"Request URL: " || xdmp:get-request-url(),
"Request Path: " || xdmp:get-request-path(),
"Query string params: " ||
    fn:string-join(
        for $i in xdmp:get-request-field-names()
        return
            $i || ": " || xdmp:get-request-field($i),
    "   "),
"Request Body: ", xdmp:get-request-body("xml")
