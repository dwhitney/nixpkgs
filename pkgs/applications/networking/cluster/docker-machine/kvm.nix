# This file was generated by go2nix.
{ stdenv, buildGoPackage, fetchFromGitHub, libvirt }:

buildGoPackage rec {
  name = "docker-machine-kvm-${version}";
  version = "0.7.0";

  goPackagePath = "github.com/dhiltgen/docker-machine-kvm";
  goDeps = ./kvm-deps.nix;

  src = fetchFromGitHub {
    rev = "v${version}";
    owner = "dhiltgen";
    repo = "docker-machine-kvm";
    sha256 = "0zkwwkx74vsfd7v38y9sidi759mhdcpm4409l9y4cx0wmkpavlv6";
  };

  buildInputs = [ libvirt ];

  postInstall = ''
    mv $bin/bin/bin $bin/bin/docker-machine-driver-kvm
  '';

  meta = with stdenv.lib; {
    homepage = https://github.com/dhiltgen/docker-machine-kvm;
    description = "KVM driver for docker-machine.";
    license = licenses.asl20;
    maintainers = with maintainers; [ offline ];
    platforms = platforms.unix;
  };
}
