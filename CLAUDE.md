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
./ci.sh                      # Run the same checks as CI locally (before committing)
```

## Git workflow

`main` is branch-protected — never push directly. CI runs `nix flake check` on PRs automatically.

Commit cycle (split between Claude and Jaxxen):
- **Claude**: create the branch (`git checkout -b <branch>`), make changes, run `./ci.sh` (the same checks CI runs) before committing, and commit locally. Stop there — do **not** push or open PRs.
- **Jaxxen**: pushes the branch, opens + merges the PR on GitHub, then deletes ("nukes") the local clone and re-clones fresh.

After committing, hand off to Jaxxen and wait for the fresh re-clone before continuing dependent work.

## Automatic updates

The system tracks `main` hands-off via two weekly jobs:
- **`.github/workflows/flake-update.yml`** (Mon 06:00 UTC) — runs `nix flake update`, opens a PR, and **auto-merges** it (squash) once `flake-check` passes.
- **`nh-os-switch` systemd timer** (`iridium/configuration.nix`, Mon 11:00 local) — pulls `github:jx-wi/vessel` and runs `nh os switch` as root.

So input bumps land and activate with no manual step, gated only by `flake-check` going green (`nix flake check` + the dry-run builds + the statix/deadnix lint). This is deliberate hands-off operation; the trade-off is that unreviewed upstream changes activate as root, which is why keeping that gate meaningful matters. To intervene, merge or close the weekly PR before the timer fires, or run `nh os switch --update` yourself.

## Key Patterns

### Impermanence
Only the `@` (`/`) and `@home` (`/home`) btrfs subvolumes roll back on every boot, via an initrd service defined in `iridium/configuration.nix`. Anything on them that must survive reboots must be declared under `environment.persistence."/persist"`. User-level directories go in `users.jaxxen.directories`.

The other subvolumes are **not** rolled back and persist on their own: `@nix` (`/nix`), `@persist` (`/persist`), `@swap` (`/swap`), and `@var` (`/var`). Because `@var` is never wiped, `/var` persists wholesale — *and* `/var/lib` + `/var/log` are additionally bind-mounted from `/persist`. That overlap is redundant and means paths like `/var/tmp` and `/var/cache` also survive reboots. Reconciling it is an install-time `disks.nix` change, so it is left as-is for now.

### Secrets (sops-nix)
Age decryption key is derived from the SSH host key at `/var/lib/ssh/ssh_host_ed25519_key`. To edit secrets:
```bash
sops secrets/path/to/file.yaml
```
New secret files must be added to `.sops.yaml` and referenced in `iridium/configuration.nix` under `sops.secrets`.

### Unfree packages
Whitelisted explicitly via `nixpkgs.config.allowUnfreePredicate`. System-scope unfree packages go in `iridium/configuration.nix`; user-scope ones go in `jaxxen/home.nix`. Add to the relevant `builtins.elem` list. A `pkgs._cuda.lib.allowUnfreeCudaPredicate` clause is present but **commented out** in `iridium/configuration.nix`: CUDA is not enabled system-wide (`cudaSupport` is unset) and nothing in the closure needs it. Uncomment it if you re-enable a CUDA build such as `services.sunshine`, whose package overrides `cudaSupport = true`.

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
