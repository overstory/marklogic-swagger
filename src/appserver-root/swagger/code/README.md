This directory will contain the code to implement the dynamic MarkLogic API
dispatcher that will operate directly from the Swagger spec.

The MarkLogic HTTP appserver should be configured with its root pointing at the
parent "appserver-root" directory.

The rewriter for the appserver should be set to /swagger/code/rewriter.xqy

The error handler for the appserver should be set to /swagger/code/error-handler.xqy

