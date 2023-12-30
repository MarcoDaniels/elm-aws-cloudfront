# elm-aws-cloudfront

Create [AWS CloudFront Lambda@Edge](https://docs.aws.amazon.com/lambda/latest/dg/lambda-edge.html) functions in Elm.

---

This package uses an [Elm headless worker](https://package.elm-lang.org/packages/elm/core/latest/Platform#worker) under
the hood requiring [ports](https://guide.elm-lang.org/interop/ports) and a small JavaScript snippet to be bundled and
deployed into AWS CloudFront Lambda@Edge.

JavaScript part:
```javascript
const {Elm} = require('./elm');
// optinal flags can be passed on init
// const app = Elm.MyModule.init({token: 'my-token'});
const app = Elm.MyModule.init();
exports.handler = (event, context, callback) => {
    const caller = (output) => {
        callback(null, output);
        app.ports.outputEvent.unsubscribe(caller);
    }
    app.ports.outputEvent.subscribe(caller);
    app.ports.inputEvent.send(event);
}
```

Elm part:
```elm
port module MyModule exposing (main)

import CloudFront exposing (Model, Msg, cloudFront)
import CloudFront.Header exposing (withHeader)
import CloudFront.Lambda exposing (originResponse, toResponse)
import Json.Decode as Decode
import Json.Encode as Encode

port inputEvent : (Decode.Value -> msg) -> Sub msg

port outputEvent : Encode.Value -> Cmd msg

-- Optional flags can be used on init
-- main : Program {token : String} (Model {token : String}) Msg
main : Program () (Model ()) Msg
main =
    ( inputEvent, outputEvent )
        |> (originResponse
                (\{ response, request } _ ->
                    response
                        |> withHeader { key = "cache-control", value = "public, max-age=1000" }
                        |> toResponse
                )
                |> cloudFront
           )
```
