port module MyModule exposing (main)

import CloudFront exposing (Model, Msg, cloudFront)
import CloudFront.Header exposing (withHeader)
import CloudFront.Lambda exposing (originResponse, toResponse)
import Json.Decode as Decode
import Json.Encode as Encode


port inputEvent : (Decode.Value -> msg) -> Sub msg


port outputEvent : Encode.Value -> Cmd msg


main : Program () (Model ()) Msg
main =
    ( inputEvent, outputEvent )
        |> (originResponse
                (\{ response, request } _ ->
                    response
                        |> withHeader { key = "cache-control", value = "public, max-age=31536000" }
                        |> toResponse
                )
                |> cloudFront
           )
