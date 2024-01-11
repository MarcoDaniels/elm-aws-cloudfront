{ stdenv, lib, pkgs }: {
  buildElmAWSCloudFront = { src, lambdas, elmSrc, elmRegistryDat }@attrs:
    stdenv.mkDerivation {
      name = "elm-aws-cloudfront";
      src = src;
      buildInputs =
        [ pkgs.elmPackages.elm pkgs.esbuild pkgs.nodePackages.uglify-js ];

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
        ${pkgs.esbuild}/bin/esbuild --bundle --minify --platform=node --log-level=silent --outfile=$out/${
          moduleName lambda.module
        }.js $out/${moduleName lambda.module}.tmp.js

        echo "minimize ${moduleName lambda.module}"
        ${pkgs.nodePackages.uglify-js}/bin/uglifyjs $out/${
          moduleName lambda.module
        }.js --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe'\
        | ${pkgs.nodePackages.uglify-js}/bin/uglifyjs --mangle --output $out/${
          moduleName lambda.module
        }.js

        echo "cleanup temporary files"
        rm $out/*.tmp.js

        echo "module output ${moduleName lambda.module}.js"
      '') lambdas)}";
    };
}
