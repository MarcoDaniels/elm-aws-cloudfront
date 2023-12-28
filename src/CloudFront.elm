port module CloudFront exposing (Model, Msg(..), cloudFront, platformWorker, toRequest, toResponse)

import CloudFront.Core exposing (decodeInputEvent, encodeOutputEvent)
import CloudFront.Lambda exposing (InputEvent, InputOrigin, OutputEvent(..), Request, Response)
import Json.Decode as Decode exposing (Error)
import Json.Encode as Encode


port inputEvent : (Decode.Value -> msg) -> Sub msg


port outputEvent : Encode.Value -> Cmd msg


type alias Model a =
    { event : Maybe InputEvent, flags : a }


type Msg
    = Input (Result Error InputEvent)


toRequest : Request -> OutputEvent
toRequest request =
    OutputRequest request


toResponse : Response -> OutputEvent
toResponse response =
    OutputResponse response


cloudFront : (flags -> Maybe InputOrigin -> OutputEvent) -> Program flags (Model flags) Msg
cloudFront originHandler =
    platformWorker originHandler
        |> Platform.worker


platformWorker :
    (flags -> Maybe InputOrigin -> OutputEvent)
    ->
        { init : flags -> ( { event : Maybe InputEvent, flags : flags }, Cmd Msg )
        , update : Msg -> { event : Maybe InputEvent, flags : flags } -> ( { event : Maybe InputEvent, flags : flags }, Cmd Msg )
        , subscriptions : { event : Maybe InputEvent, flags : flags } -> Sub Msg
        }
platformWorker originHandler =
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
