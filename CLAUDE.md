# vessel

NixOS configuration for Iridium workstation and Jaxxen's home-manager environment.

## Repository Layout

```
flake.nix                    — Inputs and outputs
iridium/
  configuration.nix          — NixOS system config (boot, hardware, services, users, persistence)
  disks.nix                  — Disko LUKS2 → btrfs partition layout
  hardware-configuration.nix — Hardware scan output
jaxxen/
  home.nix                   — Home-manager config (packages, programs, services, Hyprland, XDG)
  nixvim.nix                 — Neovim (LSP, treesitter, completion, theme)
  utils.nix                  — Extra CLI packages list
  zsh.nix                    — Zsh (Powerlevel10k, plugins)
secrets/                     — sops-encrypted secrets (age-encrypted YAML files)
shell.nix                    — Dev shell with Nixvim + Zsh
```

## Commands

```bash
nh home switch               # Apply home-manager changes
nh os switch                 # Apply NixOS changes
nh os switch --update        # Update flake inputs + apply NixOS
nix flake check              # Check the flake
```

## Key Patterns

### Impermanence
`@` and `@home` btrfs subvolumes roll back on every boot via an initrd service defined in `iridium/configuration.nix`. Anything that must survive reboots must be declared under `environment.persistence."/persist"`. User-level directories go in `users.jaxxen.directories`.

### Secrets (sops-nix)
Age decryption key is derived from the SSH host key at `/var/lib/ssh/ssh_host_ed25519_key`. To edit secrets:
```bash
sops secrets/path/to/file.yaml
```
New secret files must be added to `.sops.yaml` and referenced in `iridium/configuration.nix` under `sops.secrets`.

### Unfree packages
Whitelisted explicitly via `nixpkgs.config.allowUnfreePredicate`. System-scope unfree packages go in `iridium/configuration.nix`; user-scope ones go in `jaxxen/home.nix`. Add to the relevant `builtins.elem` list. `jaxxen/home.nix` also includes `pkgs._cuda.lib.allowUnfreeCudaPredicate` because `sunshine` is built with `cudaSupport = true`.

### Home-manager standalone
Jaxxen's home-manager runs standalone via Rehomify — no system-level home-manager integration. Changes to `jaxxen/` only require `nh home switch`, not a full system rebuild.

### Hyprland keybinds (mod = Super)
- `Super+C` — Web Claude (chromium app)
- `Super+Return` — Ghostty terminal
- `Super+V` — Neovim
- `Super+E` — Yazi file manager
- `Super+S` — LibreWolf browser
- `Super+R` — Rofi launcher
- `Super+grave` — Scratchpad terminal toggle
