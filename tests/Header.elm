module Header exposing (suite)

import CloudFront.Header exposing (withHeader, withHeaders)
import Dict
import Expect
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Headers"
        [ test "Add Cache-Control header using withHeader" <|
            \_ ->
                let
                    headers =
                        withHeader
                            { key = "cache-control", value = "public, max-age=10000" }
                            { headers = Dict.empty }
                in
                Expect.equal headers
                    { headers =
                        Dict.fromList
                            [ ( "cache-control", [ { key = "Cache-Control", value = "public, max-age=10000" } ] ) ]
                    }
        , test "Add security headers using withHeaders" <|
            \_ ->
                let
                    headers =
                        withHeaders
                            [ { key = "x-frame-options", value = "DENY" }
                            , { key = "content-security-policy", value = "default-src 'self';" }
                            ]
                            { headers = Dict.empty }
                in
                Expect.equal headers
                    { headers =
                        Dict.fromList
                            [ ( "x-frame-options", [ { key = "X-Frame-Options", value = "DENY" } ] )
                            , ( "content-security-policy", [ { key = "Content-Security-Policy", value = "default-src 'self';" } ] )
                            ]
                    }
        ]
