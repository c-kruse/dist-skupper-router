{
  stdenv,
  cmake,
  pkg-config,
  python3,
  openssl,
  cyrus_sasl,
  libunwind,
  libnghttp2,
  libwebsockets,
  qpid-proton,
  fetchFromGitHub,
}:

let
  pythonEnv = python3.withPackages (
    ps: [
      qpid-proton.py
      ps.cffi
    ]
  );
in
stdenv.mkDerivation rec {
  pname = "skupper-router";
  version = "3.3.0";

  nativeBuildInputs = [
    cmake
    pkg-config
  ];
  buildInputs = [
    openssl
    cyrus_sasl
    libunwind
    libnghttp2
    qpid-proton
    pythonEnv
  ];
  propagatedBuildInputs = [
    pythonEnv
  ];
  cmakeFlags = [
  ];
  PKG_CONFIG_PATH = "${libnghttp2.dev}/lib/pkgconfig;${libunwind.dev}/lib/pkgconfig;${libwebsockets.dev}/lib/pkgconfig";
  src = fetchFromGitHub {
    owner = "skupperproject";
    repo = "${pname}";
    rev = "${version}";
    hash = "sha256-H92eu13CHOQN7IGiHRJTC3XwUYbTy2363arjlLnkXzM=";
  };
}
