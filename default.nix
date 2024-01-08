{ stdenv, lib, pkgs }: {
  buildElmAWSCloudFront = { src, lambdas, elmSrc, elmRegistryDat }@attrs:
    stdenv.mkDerivation {
      name = "elm-aws-cloudfront";
      src = src;
      buildInputs = [ pkgs.elmPackages.elm pkgs.esbuild ];

      buildPhase = pkgs.elmPackages.fetchElmDeps {
        elmPackages = import elmSrc;
        elmVersion = "0.19.1";
        registryDat = elmRegistryDat;
      };

      installPhase = let
        buildFlags = flags: "{flags: {${lib.concatStringsSep ", " flags}}}";
        moduleName = module: lib.removeSuffix ".elm" (baseNameOf module);
        jsHandler = lambda:
          pkgs.writeText "${moduleName lambda.module}.js" ''
            const {Elm} = require('./elm.tmp');
            const app = Elm.${moduleName lambda.module}.init(${
              if lambda ? "flags" then buildFlags lambda.flags else ""
            });
            exports.handler = (event, context, callback) => {
                const caller = (output) => {
                    callback(null, output);
                    app.ports.outputEvent.unsubscribe(caller);
                }
                app.ports.outputEvent.subscribe(caller);
                app.ports.inputEvent.send(event);
            }
          '';
      in "${lib.concatStrings (map (lambda: ''
        mkdir -p $out

        echo "creating js handler for ${baseNameOf lambda.module}"
        cp ${jsHandler lambda} $out/${moduleName lambda.module}.tmp.js

        echo "compiling ${baseNameOf lambda.module}"
        ${pkgs.elmPackages.elm}/bin/elm make ${lambda.module} --optimize --output $out/elm.tmp.js

        echo "bundle ${moduleName lambda.module}"
        ${pkgs.esbuild}/bin/esbuild --bundle --minify --pure:A2 --pure:A3 --pure:A4 --pure:A5 --pure:A6 --pure:A7 --pure:A8 --pure:A9 --pure:F2 --pure:F3 --pure:F3 --pure:F4 --pure:F5 --pure:F6 --pure:F7 --pure:F8 --pure:F9 --platform=node --outfile=$out/${
          moduleName lambda.module
        }.js $out/${moduleName lambda.module}.tmp.js

        echo "cleanup temporary files"
        rm $out/*.tmp.js
      '') lambdas)}";
    };
}
