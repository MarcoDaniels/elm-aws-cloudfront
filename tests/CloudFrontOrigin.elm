port module CloudFrontOrigin exposing (suite)

import CloudFront exposing (Model, Msg(..), platformWorker)
import CloudFront.Core exposing (decodeInputEvent, encodeInputEvent)
import CloudFront.Lambda exposing (InputEvent, InputOrigin(..), Origin(..), OutputEvent, originRequest, originResponse, toRequest, toResponse)
import Dict
import Expect
import Json.Decode as Decode exposing (Error)
import Json.Encode as Encode
import ProgramTest
import SimulatedEffect.Ports
import Test exposing (Test, describe, test)


originRequestExample : InputEvent
originRequestExample =
    { records =
        [ { cf =
                InputRequest
                    { config =
                        { distributionDomainName = "111222333.cloudfront.net"
                        , distributionId = "ABCDEFG"
                        , eventType = "origin-request"
                        , requestId = "123456"
                        }
                    , request =
                        { clientIp = "203.0.113.178"
                        , headers =
                            Dict.fromList
                                [ ( "user-agent", [ { key = "user-agent", value = "Amazon CloudFront" } ] )
                                , ( "host", [ { key = "host", value = "example.org" } ] )
                                , ( "cache-control", [ { key = "cache-control", value = "no-cache, cf-no-cache" } ] )
                                ]
                        , method = "GET"
                        , origin =
                            OriginS3
                                { s3 =
                                    { authMethod = "origin-access-identity"
                                    , customHeaders = Dict.empty
                                    , domainName = "111222333.s3.amazonaws.com"
                                    , path = ""
                                    , region = "us-east-1"
                                    }
                                }
                        , querystring = Just "width=100&q=60"
                        , uri = "/image/api/myAsset.png"
                        }
                    }
          }
        ]
    }


originResponseExample : InputEvent
originResponseExample =
    { records =
        [ { cf =
                InputResponse
                    { config =
                        { distributionDomainName = "111222333.cloudfront.net"
                        , distributionId = "ABCDEFG"
                        , eventType = "origin-request"
                        , requestId = "123456"
                        }
                    , request =
                        { clientIp = "203.0.113.178"
                        , headers =
                            Dict.fromList
                                [ ( "x-forwarded-for", [ { key = "x-forwarded-for", value = "203.0.113.178" } ] )
                                , ( "user-agent", [ { key = "user-agent", value = "Amazon CloudFront" } ] )
                                , ( "host", [ { key = "host", value = "example.org" } ] )
                                ]
                        , method = "GET"
                        , origin =
                            OriginCustom
                                { custom =
                                    { customHeaders = Dict.empty
                                    , domainName = "example.org"
                                    , keepaliveTimeout = 5
                                    , path = ""
                                    , port_ = 443
                                    , protocol = "https"
                                    , readTimeout = 30
                                    , sslProtocols =
                                        [ "TLSv1"
                                        , "TLSv1.1"
                                        , "TLSv1.2"
                                        ]
                                    }
                                }
                        , querystring = Nothing
                        , uri = "/"
                        }
                    , response =
                        { headers =
                            Dict.fromList
                                [ ( "access-control-allow-origin", [ { key = "access-control-allow-origin", value = "*" } ] )
                                , ( "x-content-type-options", [ { key = "x-content-type-options", value = "nosniff" } ] )
                                , ( "x-frame-options", [ { key = "x-frame-options", value = "DENY" } ] )
                                ]
                        , status = "200"
                        , statusDescription = "OK"
                        }
                    }
          }
        ]
    }


port inputEvent : (Decode.Value -> msg) -> Sub msg


port outputEvent : Encode.Value -> Cmd msg


setupTestFor : (() -> Maybe InputOrigin -> OutputEvent) -> InputEvent -> ProgramTest.ProgramTest (Model ()) Msg (Cmd Msg)
setupTestFor updateFunction inputExample =
    let
        platform =
            ( inputEvent, outputEvent ) |> (updateFunction |> platformWorker)
    in
    ProgramTest.createWorker
        { init = platform.init, update = platform.update }
        |> ProgramTest.withSimulatedSubscriptions
            (\_ -> SimulatedEffect.Ports.subscribe "inputEvent" (Decode.oneOf [ decodeInputEvent |> Decode.map Ok ]) Input)
        |> ProgramTest.start ()
        |> ProgramTest.simulateIncomingPort "inputEvent" (encodeInputEvent inputExample)


suite : Test
suite =
    describe "Validate encoder/decoder"
        [ test "Origin Response" <|
            \() ->
                let
                    responseToResponse =
                        originResponse
                            (\{ response, request } _ -> response |> toResponse)
                in
                setupTestFor responseToResponse originResponseExample
                    |> ProgramTest.expectModel
                        (Expect.equal { event = Just originResponseExample, flags = () })
        , test "Origin Request" <|
            \() ->
                let
                    requestToRequest =
                        originRequest (\{ request } _ -> request |> toRequest)
                in
                setupTestFor requestToRequest originRequestExample
                    |> ProgramTest.expectModel
                        (Expect.equal { event = Just originRequestExample, flags = () })
        ]
