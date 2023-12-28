module CloudFront.Header exposing (Header, Headers, withHeader, withHeaders)

{-| TODO:

@docs Header, Headers, withHeader, withHeaders

-}

import Dict


{-| TODO
-}
type alias Header =
    { key : String, value : String }


{-| TODO
-}
type alias Headers =
    Dict.Dict String (List Header)


{-| TODO
-}
withHeader :
    Header
    -> { event | headers : Headers }
    -> { event | headers : Headers }
withHeader header event =
    { event | headers = Dict.union (headerBuilder header Dict.empty) event.headers }


{-| TODO
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
