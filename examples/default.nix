let
  cloudfront = pkgs.callPackage (pkgs.stdenv.mkDerivation {
    name = "elm-aws-cloudfront";
    src = fetchGit {
      url = "https://github.com/MarcoDaniels/elm-aws-cloudfront.git";
      ref = "refs/tags/nix-1.0.0";
    };
    installPhase = ''
      mkdir -p $out
      cp $src/default.nix $out
    '';
  }) { };

in cloudfront.buildElmAWSCloudFront {
  src = ../../.;
  elmSrc = ../../nix/elm-srcs.nix;
  elmRegistryDat = ../../nix/registry.dat;
  lambdas = [
    { module = ./src/WebsiteRequest.elm; }
    { module = ./src/WebsiteResponse.elm; }
    {
      module = ./src/AssetRequest.elm;
      flags = [ ''token:"token"'' ''domain:"domain"'' ];
    }
    { module = ./src/AssetResponse.elm; }
  ];
}