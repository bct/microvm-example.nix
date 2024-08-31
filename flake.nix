{
  description = "NixOS in MicroVMs";

  inputs.microvm.url = "github:astro/microvm.nix";
  inputs.microvm.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, microvm }:
    let
      system = "x86_64-linux";
    in {
      packages.${system} = {
        default = self.packages.${system}.my-microvm;
        my-microvm = self.nixosConfigurations.my-microvm.config.microvm.declaredRunner;
      };

      nixosConfigurations = {
        my-microvm = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            microvm.nixosModules.microvm
            {
              networking.hostName = "my-microvm";
              services.getty.autologinUser = "root";

              environment.systemPackages = [
                nixpkgs.legacyPackages.${system}.usbutils
              ];

              microvm = {
                shares = [ {
                  # use "virtiofs" for MicroVMs that are started by systemd
                  proto = "9p";
                  tag = "ro-store";
                  # a host's /nix/store will be picked up so that no
                  # squashfs/erofs will be built for it.
                  source = "/nix/store";
                  mountPoint = "/nix/.ro-store";
                } ];

                devices = [
                  {
                    bus = "usb";
                    #path = "vendorid=0x093a,productid=0x2510";
                    #path = "hostbus=1,hostaddr=30";
                    path = "hostbus=1,hostport=1";
                  }
                ];

                hypervisor = "qemu";
                socket = "control.socket";
              };
            }
          ];
        };
      };
    };
}
