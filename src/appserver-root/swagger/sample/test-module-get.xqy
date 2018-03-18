xquery version "1.0-ml";

(:~
: User: craig
: Date: 2018-03-12
: Time: 9:51 PM
: To change this template use File | Settings | File Templates.
:)

"Simple Module GET",
"Request method: " || xdmp:get-request-method(),
"Original URL: " || xdmp:get-original-url(),
"Request URL: " || xdmp:get-request-url(),
"Request Path: " || xdmp:get-request-path(),
"Query string params: " ||
    fn:string-join(
        for $i in xdmp:get-request-field-names()
        return
            $i || ": " || xdmp:get-request-field($i),
    "   ")