module CloudFront exposing
    ( cloudFront
    , Model, Msg(..)
    , platformWorker
    )

{-| The `cloudFront` function requires an **input** and **output** ports as a tuple parameter
in order to communicate with the JavaScript handler code.

    port module MyModule exposing (..)

    import CloudFront exposing (cloudFront)
    import Json.Decode as Decode
    import Json.Encode as Encode

    port inputEvent : (Decode.Value -> msg) -> Sub msg

    port outputEvent : Encode.Value -> Cmd msg

The ports must have the same type as the example.

@docs cloudFront


## Core Model and Msg

@docs Model, Msg

@docs platformWorker

-}

import CloudFront.Core exposing (decodeInputEvent, encodeOutputEvent)
import CloudFront.Lambda exposing (InputEvent, InputOrigin, OutputEvent)
import Json.Decode as Decode exposing (Error)
import Json.Encode as Encode


{-| Model contains the decoded [InputEvent](./CloudFront-Lambda#InputEvent) and the
optional flags passed on init.
-}
type alias Model a =
    { event : Maybe InputEvent, flags : a }


{-| Msg is used to contain the result/error of decoding the input event from ports.
-}
type Msg
    = Input (Result Error InputEvent)


{-| Create a CloudFront origin handler to handle the request/response
of your CloudFront distribution:

    import CloudFront.Lambda exposing (originRequest, toRequest)

    ( inputPort, outputPort )
        |> (originRequest
                (\{ request } _ -> request |> toRequest)
                |> cloudFront
           )

-}
cloudFront :
    (flags -> Maybe InputOrigin -> OutputEvent)
    -> ( (Decode.Value -> Msg) -> Sub Msg, Encode.Value -> Cmd Msg )
    -> Program flags (Model flags) Msg
cloudFront originHandler ports =
    platformWorker originHandler ports
        |> Platform.worker


{-| -}
platformWorker :
    (flags -> Maybe InputOrigin -> OutputEvent)
    -> ( (Decode.Value -> Msg) -> Sub Msg, Encode.Value -> Cmd Msg )
    ->
        { init : flags -> ( Model flags, Cmd Msg )
        , update : Msg -> Model flags -> ( Model flags, Cmd Msg )
        , subscriptions : Model flags -> Sub Msg
        }
platformWorker originHandler ( inputEvent, outputEvent ) =
    { init = \flags -> ( { event = Nothing, flags = flags }, Cmd.none )
    , update =
        \msg model ->
            case msg of
                Input result ->
                    case result of
                        Ok event ->
                            ( { event = Just event, flags = model.flags }
                            , originHandler model.flags (event.records |> List.head |> Maybe.map (\{ cf } -> cf))
                                |> encodeOutputEvent
                                |> outputEvent
                            )

                        Err _ ->
                            ( model, Cmd.none )
    , subscriptions =
        \_ ->
            Decode.decodeValue decodeInputEvent
                >> Input
                |> inputEvent
    }
