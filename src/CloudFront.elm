module CloudFront exposing (Model, Msg(..), cloudFront, platformWorker)

{-| TODO

@docs Model, Msg, cloudFront, platformWorker

-}

import CloudFront.Core exposing (decodeInputEvent, encodeOutputEvent)
import CloudFront.Lambda exposing (InputEvent, InputOrigin, OutputEvent)
import Json.Decode as Decode exposing (Error)
import Json.Encode as Encode


{-| TODO
-}
type alias Model a =
    { event : Maybe InputEvent, flags : a }


{-| TODO
-}
type Msg
    = Input (Result Error InputEvent)


{-| TODO
-}
cloudFront :
    (flags -> Maybe InputOrigin -> OutputEvent)
    -> ( (Decode.Value -> Msg) -> Sub Msg, Encode.Value -> Cmd Msg )
    -> Program flags (Model flags) Msg
cloudFront originHandler ports =
    platformWorker originHandler ports
        |> Platform.worker


{-| TODO
-}
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
