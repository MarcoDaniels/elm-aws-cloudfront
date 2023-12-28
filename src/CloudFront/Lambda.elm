module CloudFront.Lambda exposing (Config, CustomOrigin, CustomOriginData, InputEvent, InputOrigin(..), Origin(..), OriginRequest, OriginResponse, OutputEvent(..), Record, Request, Response, S3Origin, S3OriginData, originRequest, originResponse, toRequest, toResponse)

{-| TODO:

@docs Config, CustomOrigin, CustomOriginData, InputEvent, InputOrigin, Origin, OriginRequest, OriginResponse, OutputEvent, Record, Request, Response, S3Origin, S3OriginData, originRequest, originResponse, toRequest, toResponse

-}

import CloudFront.Header exposing (Headers)
import Dict



{---- Types ----}


{-| TODO
-}
type alias Config =
    { distributionDomainName : String
    , distributionId : String
    , eventType : String
    , requestId : String
    }


{-| TODO
-}
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


{-| TODO
-}
type alias CustomOrigin =
    { custom : CustomOriginData }


{-| TODO
-}
type alias S3OriginData =
    { authMethod : String
    , customHeaders : Headers
    , domainName : String
    , path : String
    , region : String
    }


{-| TODO
-}
type alias S3Origin =
    { s3 : S3OriginData }


{-| TODO
-}
type Origin
    = OriginS3 S3Origin
    | OriginCustom CustomOrigin
    | OriginUnknown


{-| TODO
-}
type alias Request =
    { clientIp : String
    , headers : Headers
    , method : String
    , origin : Origin
    , querystring : Maybe String
    , uri : String
    }


{-| TODO
-}
type alias Response =
    { status : String
    , statusDescription : String
    , headers : Headers
    }


{-| TODO
-}
type alias OriginRequest =
    { config : Config, request : Request }


{-| TODO
-}
type alias OriginResponse =
    { config : Config, request : Request, response : Response }


{-| TODO
-}
type InputOrigin
    = InputResponse OriginResponse
    | InputRequest OriginRequest


{-| TODO
-}
type alias Record =
    { cf : InputOrigin }


{-| TODO
-}
type alias InputEvent =
    { records : List Record }


{-| TODO
-}
type OutputEvent
    = OutputResponse Response
    | OutputRequest Request


{-| TODO
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


{-| TODO
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


{-| TODO
-}
toRequest : Request -> OutputEvent
toRequest request =
    OutputRequest request


{-| TODO
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
