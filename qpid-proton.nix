{
  lib,
  stdenv,
  cmake,
  pkg-config,
  python3,
  python3Packages,
  openssl,
  cyrus_sasl,
  fetchFromGitHub,
  enablePython ? true,
}:

stdenv.mkDerivation rec {
  pname = "qpid-proton";
  version = "0.40.0";

  outputs = [ "out" ] ++ lib.optional enablePython "py";
  nativeBuildInputs = [ cmake pkg-config python3 ];
  pythonModule = python3;
  buildInputs = [
    openssl
    cyrus_sasl
  ] ++ lib.optional enablePython [
    python3
    python3Packages.build
    python3Packages.cffi
    python3Packages.pip
    python3Packages.setuptools
    python3Packages.wheel
  ];
  postBuild = lib.optionalString enablePython ''
    cd python
    ${python3}/bin/python -m pip install --prefix=../pythonlib ./dist/*.whl
    cd -
  '';

  postFixup = lib.optionalString enablePython ''
    mv "pythonlib/" "$py"
  '';


  cmakeFlags = [
    "-DBUILD_TLS=ON"
  ] ++ lib.optional enablePython "-DBUILD_BINDINGS=python";
  src = fetchFromGitHub {
    owner = "apache";
    repo = "${pname}";
    rev = "${version}";
    hash = "sha256-ssCu6AifjsL8QoxjRHx7/fWYCnapmhX/c/VokU+XI90=";
  };
}
