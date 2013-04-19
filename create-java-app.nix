{ nixpkgs ? ../nixpkgs
, webdsl ? {outPath = builtins.storePath /nix/store/fsvgski1a52w9373yq09qraa77r666ij-webdsl-java-0pre5668;}
, nixos ? ../nixos
, reposearchSrc ? { outPath = ../reposearch; rev = 1234; }
}:
let

  pkgs = import nixpkgs { system = "i686-linux"; };

  build = appname : src :
    pkgs.stdenv.mkDerivation rec {
      name = "${appname}-r${toString src.rev}";
      buildInputs = [webdsl pkgs.ant pkgs.zip];
      buildCommand = ''
        ensureDir $out/nix-support
        ulimit -s unlimited
        export ANT_ARGS="-lib `ls ${pkgs.hydraAntLogger}/lib/java/*.jar | head -1`"
        export ANT_LOGGER="org.hydra.ant.HydraLogger"

        header "Copying sources"
        cp -vR ${src}/* .
        chmod -R 755 .
        ./create-java-app.sh

        zip -r $out/reposearch-app.zip reposearch-app/
        echo "file zip $out/reposearch-app.zip" > $out/nix-support/hydra-build-products
      '';
  };

in
{
  reposearch-app = build "reposearch-app" reposearchSrc;
}
