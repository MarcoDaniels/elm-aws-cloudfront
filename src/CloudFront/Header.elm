module CloudFront.Header exposing
    ( withHeader, withHeaders
    , Header, Headers
    )

{-| Handle AWS CloudFront request and response headers.

For more documentation see [working with policies in AWS CloudFront developer guide
](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/working-with-policies.html).


## Handlers

@docs withHeader, withHeaders


## Types

@docs Header, Headers

-}

import Dict


{-| A single header is defined as key value type

    header : Header
    header =
        { key = "user-agent", value = "Amazon CloudFront" }

-}
type alias Header =
    { key : String, value : String }


{-| A group of headers are defined as a dictionary of key -> key value type

    header : Headers
    header =
        Dict.singleton "user-agent" [ { key = "user-agent", value = "Amazon CloudFront" } ]

    headers : Headers
    headers =
        Dict.fromList
            [ ( "user-agent", [ { key = "user-agent", value = "Amazon CloudFront" } ] )
            , ( "host", [ { key = "host", value = "example.org" } ] )
            ]

-}
type alias Headers =
    Dict.Dict String (List Header)


{-| Append a new header to the existing headers dictionary

    headers : { headers : Headers } -> { headers : Headers }
    headers =
        withHeader
            { key = "cache-control", value = "public, max-age=10000" }

-}
withHeader :
    Header
    -> { event | headers : Headers }
    -> { event | headers : Headers }
withHeader header event =
    { event | headers = Dict.union (headerBuilder header Dict.empty) event.headers }


{-| Append multiple headers to the exising headers dictionary

    headers : { headers : Headers } -> { headers : Headers }
    headers =
        withHeaders
            [ { key = "x-frame-options", value = "DENY" }
            , { key = "content-security-policy", value = "default-src 'self';" }
            ]

-}
withHeaders :
    List Header
    -> { event | headers : Headers }
    -> { event | headers : Headers }
withHeaders headers event =
    { event | headers = Dict.union (headers |> List.foldr headerBuilder Dict.empty) event.headers }


headerBuilder : Header -> Headers -> Headers
headerBuilder header =
    let
        caseSensitive : String -> String
        caseSensitive key =
            String.split "-" key
                |> List.map
                    (\word ->
                        String.uncons word
                            |> Maybe.map (\( first, rest ) -> String.cons (Char.toUpper first) rest)
                            |> Maybe.withDefault ""
                    )
                |> String.join "-"
    in
    Dict.insert header.key
        [ { key = caseSensitive header.key, value = header.value } ]
