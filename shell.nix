let
  pkgs = import (fetchTarball {
    name = "nixpkgs-23.05-darwin";
    url = "https://github.com/NixOS/nixpkgs/archive/fc541b860a28.tar.gz";
    sha256 = "0929i9d331zgv86imvsdzyfsrnr7zwhb7sdh8sw5zzsp7qsxycja";
  }) { };

in pkgs.mkShell rec {
  buildInputs = with pkgs.elmPackages; [
    elm
    elm-test
    elm-format
    elm-coverage
  ];
}