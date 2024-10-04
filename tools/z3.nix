{ lib, fetchFromGitHub, z3 }:

z3.overrideAttrs (old: rec {
  version = "4.12.5";
  src = fetchFromGitHub {
    owner = "Z3Prover";
    repo = "z3";
    rev = "z3-${version}";
    hash = "sha256-Qj9w5s02OSMQ2qA7HG7xNqQGaUacA1d4zbOHynq5k+A=";
  };
})
