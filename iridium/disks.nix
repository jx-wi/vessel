{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "4G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "umask=0077"
                "noatime"
              ];
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              settings = {
                allowDiscards = true;
                bypassWorkqueues = true;
              };
              extraFormatArgs = [
                "--cipher"
                "aes-xts-plain64"
                "--key-size"
                "512"
                "--hash"
                "sha256"
                "--pbkdf"
                "argon2id"
                "--iter-time"
                "5000"
              ];
              content = {
                type = "btrfs";
                extraArgs = [
                  "-L"
                  "nixos"
                  "-f"
                ];
                subvolumes = let
                  mountOptions = [
                    "noatime"
                    "compress=zstd:1"
                    "space_cache=v2"
                    "discard=async"
                  ];
                in {
                  "@" = {
                    mountpoint = "/";
                    inherit mountOptions;
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    inherit mountOptions;
                  };
                  "@home" = {
                    mountpoint = "/home";
                    inherit mountOptions;
                  };
                  "@var" = {
                    mountpoint = "/var";
                    inherit mountOptions;
                  };
                  "@swap" = {
                    mountpoint = "/swap";
                    mountOptions = [
                      "noatime"
                      "nodatacow"
                    ];
                  };
                  "@persist" = {
                    mountpoint = "/persist";
                    inherit mountOptions;
                  };
                  "@blank" = {};
                  "@home-blank" = {};
                };
              };
            };
          };
        };
      };
    };
  };
}
