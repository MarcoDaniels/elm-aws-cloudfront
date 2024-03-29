module CloudFront.Lambda exposing
    ( originRequest, originResponse
    , toRequest, toResponse
    , InputEvent, Record, InputOrigin(..), OriginResponse, OriginRequest
    , Config, Request, Response
    , Origin(..), S3Origin, S3OriginData, CustomOrigin, CustomOriginData
    , OutputEvent(..)
    )

{-| Edge@Lambda handlers for AWS CloudFront request and response events.

Read more about [Edge@Lambda event structure](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-event-structure.html).


## Handlers

@docs originRequest, originResponse


## Output

@docs toRequest, toResponse


## Types

Types for the [lambda event structure](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-event-structure.html).

@docs InputEvent, Record, InputOrigin, OriginResponse, OriginRequest
@docs Config, Request, Response
@docs Origin, S3Origin, S3OriginData, CustomOrigin, CustomOriginData
@docs OutputEvent

-}

import CloudFront.Header exposing (Headers)
import Dict


{-| -}
type alias Config =
    { distributionDomainName : String
    , distributionId : String
    , eventType : String
    , requestId : String
    }


{-| -}
type alias CustomOriginData =
    { customHeaders : Headers
    , domainName : String
    , keepaliveTimeout : Int
    , path : String
    , port_ : Int
    , protocol : String
    , readTimeout : Int
    , sslProtocols : List String
    }


{-| -}
type alias CustomOrigin =
    { custom : CustomOriginData }


{-| -}
type alias S3OriginData =
    { authMethod : String
    , customHeaders : Headers
    , domainName : String
    , path : String
    , region : String
    }


{-| -}
type alias S3Origin =
    { s3 : S3OriginData }


{-| -}
type Origin
    = OriginS3 S3Origin
    | OriginCustom CustomOrigin
    | OriginUnknown


{-| -}
type alias Request =
    { clientIp : String
    , headers : Headers
    , method : String
    , origin : Origin
    , querystring : Maybe String
    , uri : String
    }


{-| -}
type alias Response =
    { status : String
    , statusDescription : String
    , headers : Headers
    }


{-| -}
type alias OriginRequest =
    { config : Config, request : Request }


{-| -}
type alias OriginResponse =
    { config : Config, request : Request, response : Response }


{-| -}
type InputOrigin
    = InputResponse OriginResponse
    | InputRequest OriginRequest


{-| -}
type alias Record =
    { cf : InputOrigin }


{-| -}
type alias InputEvent =
    { records : List Record }


{-| -}
type OutputEvent
    = OutputResponse Response
    | OutputRequest Request


{-| Handler for [origin request events](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-event-structure.html#example-origin-request)

    originRequest
        (\{ request } flags ->
            { request | uri = "new-uri" }
                |> toRequest
        )

-}
originRequest :
    (OriginRequest -> flags -> OutputEvent)
    -> flags
    -> Maybe InputOrigin
    -> OutputEvent
originRequest origin flags maybeCloudFront =
    case maybeCloudFront of
        Just cf ->
            case cf of
                InputRequest inputRequest ->
                    origin inputRequest flags

                _ ->
                    origin defaultOriginRequest flags

        _ ->
            origin defaultOriginRequest flags


{-| Handler for [origin response events](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-event-structure.html#lambda-event-structure-response-origin)

    originResponse
        (\{ response, request } _ ->
            response
                |> withHeader
                    { key = "cache-control", value = "public, max-age=31536000" }
                |> toResponse
        )

-}
originResponse :
    (OriginResponse -> flags -> OutputEvent)
    -> flags
    -> Maybe InputOrigin
    -> OutputEvent
originResponse origin flags maybeCloudFront =
    case maybeCloudFront of
        Just cf ->
            case cf of
                InputResponse inputResponse ->
                    origin inputResponse flags

                _ ->
                    origin defaultOriginResponse flags

        _ ->
            origin defaultOriginResponse flags


{-| Map request to output event, to be used with [`originRequest`](#originRequest) or [`originResponse`](#originResponse)
-}
toRequest : Request -> OutputEvent
toRequest request =
    OutputRequest request


{-| Map response to output event, to be used with [`originResponse`](#originResponse)
-}
toResponse : Response -> OutputEvent
toResponse response =
    OutputResponse response



{---- Defaults ----}


defaultConfig : Config
defaultConfig =
    { distributionDomainName = ""
    , distributionId = ""
    , eventType = ""
    , requestId = ""
    }


defaultRequest : Request
defaultRequest =
    { clientIp = ""
    , headers = Dict.empty
    , method = ""
    , origin = OriginUnknown
    , querystring = Nothing
    , uri = ""
    }


defaultOriginRequest : OriginRequest
defaultOriginRequest =
    { request = defaultRequest, config = defaultConfig }


defaultResponse : Response
defaultResponse =
    { status = ""
    , statusDescription = ""
    , headers = Dict.empty
    }


defaultOriginResponse : OriginResponse
defaultOriginResponse =
    { request = defaultRequest, response = defaultResponse, config = defaultConfig }
