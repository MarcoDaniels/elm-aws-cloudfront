module CloudFront.Lambda exposing
    ( Config
    , CustomOrigin
    , CustomOriginData
    , InputEvent
    , InputOrigin(..)
    , Origin(..)
    , OriginRequest
    , OriginResponse
    , OutputEvent(..)
    , Record
    , Request
    , Response
    , S3Origin
    , S3OriginData
    , originRequest
    , originResponse
    )

import CloudFront.Header exposing (Headers)
import Dict



{---- Types ----}


type alias Config =
    { distributionDomainName : String
    , distributionId : String
    , eventType : String
    , requestId : String
    }


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


type alias CustomOrigin =
    { custom : CustomOriginData }


type alias S3OriginData =
    { authMethod : String
    , customHeaders : Headers
    , domainName : String
    , path : String
    , region : String
    }


type alias S3Origin =
    { s3 : S3OriginData }


type Origin
    = OriginS3 S3Origin
    | OriginCustom CustomOrigin
    | OriginUnknown


type alias Request =
    { clientIp : String
    , headers : Headers
    , method : String
    , origin : Origin
    , querystring : Maybe String
    , uri : String
    }


type alias Response =
    { status : String
    , statusDescription : String
    , headers : Headers
    }


type alias OriginRequest =
    { config : Config, request : Request }


type alias OriginResponse =
    { config : Config, request : Request, response : Response }


type InputOrigin
    = InputResponse OriginResponse
    | InputRequest OriginRequest


type alias Record =
    { cf : InputOrigin }


type alias InputEvent =
    { records : List Record }


type OutputEvent
    = OutputResponse Response
    | OutputRequest Request


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
