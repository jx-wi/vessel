{
  config,
  lib,
  pkgs,
  addons,
  ...
}:
let
  zsh = import ./zsh.nix {
    inherit pkgs;
  };
  utils = import ./utils.nix {
    inherit pkgs;
  };
  terminal = {
    name = "ghostty";
    command = "ghostty +new-window -e";
  };
  font = {
    family = "Maple Mono NF";
    size = 12;
    package = pkgs.maple-mono.NF-unhinted; # if resolution >= 1440p, use NF-unhinted, else use NF
  };
in {
  home = {
    stateVersion = "25.11";
    username = "jaxxen";
    homeDirectory = "/home/jaxxen";
    file = {
      ".profile".text = ". ~/.local/state/nix/profile/etc/profile.d/hm-session-vars.sh";
      ".nix-profile".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.local/state/nix/profile";
    };
    activation.monitorInit = lib.hm.dag.entryAfter [ "reloadSystemd" ] "toggle-hdr --on 2>/dev/null || true";
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      PIPEWIRE_LATENCY = "96/48000";
      SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/.local/share/age/keys.txt";
      WINE_FULLSCREEN_FSR = "1";
    };
    pointerCursor = {
      name = "Bibata-Modern-Ice";
      size = 12;
      gtk.enable = true;
      x11.enable = true;
      package = pkgs.bibata-cursors;
    };
    file.".librewolf/native-messaging-hosts/org.keepassxc.keepassxc_browser.json".text = ''
      {
        "allowed_extensions": [ "keepassxc-browser@keepassxc.org" ],
        "description": "KeePassXC integration with native messaging support",
        "name": "org.keepassxc.keepassxc_browser",
        "path": "${pkgs.keepassxc}/bin/keepassxc-proxy",
        "type": "stdio"
      }
    '';
    packages = with pkgs; [
      awww
      font.package
      libreoffice
      playerctl
      qalculate-qt
      trash-cli
      ungoogled-chromium
      wiremix
      wl-clipboard-rs
      xdg-desktop-portal-termfilechooser
      (writers.writeDashBin "wallpaper" ''
        rm -rf ${config.home.homeDirectory}/Pictures/.jxwallpapers ${config.home.homeDirectory}/Pictures/.jxwallpaper
        git clone --depth=1 https://github.com/jx-wi/wallpapers ${config.home.homeDirectory}/Pictures/.jxwallpapers
        mkdir -p ${config.home.homeDirectory}/Pictures/Wallpapers/jxwallpaper
        cp ${config.home.homeDirectory}/Pictures/.jxwallpapers/LICENSE ${config.home.homeDirectory}/Pictures/.jxwallpaper
        cp ${config.home.homeDirectory}/Pictures/.jxwallpapers/README.md ${config.home.homeDirectory}/Pictures/.jxwallpaper
        cp $(
          find ${config.home.homeDirectory}/Pictures/.jxwallpapers -type f -name "*.jpg" -o -name "*.png" -o -name "*.webp" \
          | shuf -n 1
        ) ${config.home.homeDirectory}/Pictures/Wallpapers/jxwallpaper/wallpaper
        rm -rf ${config.home.homeDirectory}/Pictures/.jxwallpapers
        printf '%s' ${config.home.homeDirectory}/Pictures/Wallpapers/jxwallpaper/wallpaper
      '')
      (writers.writeDashBin "toggle-hdr" ''
        on () {
          hyprctl keyword monitor "DP-3,2560x1440@180,0x0,1,bitdepth,10,cm,hdr,sdrbrightness,1.4,vrr,3";
        }
        off () {
          hyprctl keyword monitor "DP-3,2560x1440@180,0x0,1,vrr,3";
        }
        case "$1" in
          --on)
            on
          ;;
          --off)
            off
          ;;
          *)
            if hyprctl monitors | grep -q "hdr"; then
              off
            else
              on
            fi
          ;;
        esac
      '')
    ] ++ zsh.packages ++ utils;
  };
  nixpkgs.config.allowUnfreePredicate = pkgs._cuda.lib.allowUnfreeCudaPredicate;
  news.display = "silent";
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [ font.family ];
      sansSerif = [ font.family ];
      serif = [ font.family ];
    };
  };
  gtk = {
    enable = true;
    theme = {
      name = "Graphite-Dark-compact";
      package = pkgs.graphite-gtk-theme.override {
        colorVariants = [ "dark" ];
        sizeVariants = [ "compact" ];
        tweaks = [
          "black"
          "rimless"
        ];
      };
    };
    gtk4.theme = config.gtk.theme;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    font = {
      name = font.family;
      package = font.package;
      size = font.size;
    };
  };
  qt = {
    enable = true;
    platformTheme.name = "gtk3";
  };
  dconf = {
    enable = true;
    settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
  };
  programs = {
    home-manager.enable = true;
    bat.enable = true;
    bottom.enable = true;
    delta = {
      enable = true;
      enableGitIntegration = true;
    };
    eza = {
      enable = true;
      enableZshIntegration = true;
    };
    fd.enable = true;
    gh.enable = true;
    git = {
      enable = true;
      settings = {
        init.defaultBranch = "main";
        core.editor = "nvim";
        pull.rebase = true;
        push.autoSetupRemote = true;
        user = {
          name = "Jaxxen";
          email = "jxwi@proton.me";
        };
      };
      ignores = [
        "secrets/**/*.yaml.dec"
        "*.swp"
        "result"
        ".direnv"
        "**/.DS_Store"
      ];
    };
    gitui.enable = true;
    ghostty = {
      enable = true;
      enableZshIntegration = true;
      installVimSyntax = true;
      settings = {
        confirm-close-surface = false;
        gtk-single-instance = true;
        quit-after-last-window-closed = false;
        window-decoration = "server";
        background = "#000000";
        background-opacity = 0.7;
        background-blur-radius = 20;
        font-family = font.family;
        font-size = font.size;
        freetype-load-flags = "no-hinting"; # only keep this line if using unhinted font, else comment out
        theme = "TokyoNight Night";
      };
    };
    hyprlock.enable = true;
    hyprshot = {
      enable = true;
      saveLocation = "${config.home.homeDirectory}/Pictures/Screenshots";
    };
    imv = {
      enable = true;
      settings.binds = {
        r = "rotate by 90";
        R = "rotate by -90";
        z = "reset";
      };
    };
    jq.enable = true;
    keepassxc = {
      enable = true;
      settings = {
        SSHAgent.Enabled = true;
        Browser = {
          Enabled = true;
          UpdateBinaryPath = false;
        };
        PasswordGenerator = {
          AdvancedMode = true;
          Braces = true;
          Dashes = true;
          Logograms = true;
          Math = true;
          Punctuation = true;
          Quotes = true;
          WordSeparator = "-";
        };
        GUI = {
          HidePasswords = true;
          AdvancedSettings = true;
          CompactMode = true;
          ApplicationTheme = "dark";
        };
      };
    };
    librewolf = {
      enable = true;
      profiles.${config.home.username} = {
        settings = {
          "browser.toolbars.bookmarks.visibility" = "newtab";
          "widget.use-xdg-desktop-portal.file-picker" = 1;
          "extensions.autoDisableScopes" = 0;
        };
        extensions.packages = with addons; [
          ublock-origin
          keepassxc-browser
          darkreader
          df-youtube
          theater-mode-for-youtube
        ];
        bookmarks = {
          force = true;
          settings = [{
            name = "toolbar";
            toolbar = true;
            bookmarks = let
              bookmark = domain: {
                name = "";
                url = "https://${domain}";
              };
            in [
              (bookmark "mynixos.com")
              (bookmark "nixos.org")
              (bookmark "account.proton.me/switch")
            ];
          }];
        };
      };
    };
    mpv = {
      enable = true;
      config = {
        prefetch-playlist = "yes";
        loop-playlist = "inf";
      };
    };
    nh = {
      enable = true;
      flake = "${config.home.homeDirectory}/Projects/vessel";
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep 3";
      };
    };
    nixvim = {
      enable = true;
      defaultEditor = true;
      imports = [ ./nixvim.nix ];
    };
    prismlauncher = {
      enable = true;
      settings = {
        ApplicationTheme = "system";
        AutoCloseConsole = false;
        AutomaticJavaDownload = false;
        AutomaticJavaSwitch = true;
        BackgroundCat = "rory-flat";
        CatFit = "fit";
        CatOpacity = 100;
        CloseAfterLaunch = true;
        ConfigVersion = 1.3;
        ConsoleMaxLines = 1000;
        ConsoleOverflowStop = true;
        EnableFeralGamemode = true;
        FallbackMRBlockedMods = 2;
        IconTheme = "pe_light";
        IgnoreJavaCompatibility = false;
        IgnoreJavaWizard = true;
        JavaPath = "${pkgs.openjdk}/bin/java";
        Language = "en_US";
        LaunchMaximized = false;
        LowMemWarning = true;
        MaxMemAlloc = 8192;
        MinMemAlloc = 4096;
        MinecraftWinHeight = 1440;
        MinecraftWinWidth = 2560;
        QuitAfterGameStop = true;
        ShowConsole = false;
        ShowConsoleOnError = true;
        UseNativeGLFW = false;
        UseNativeOpenAL = false;
        UseZink = true;
        UserAskedAboutAutomaticJavaDownload = true;
      };
    };
    ripgrep.enable = true;
    rofi = {
      enable = true;
      modes = [ "drun" ];
      terminal = terminal.command;
      font = "${font.family} ${toString font.size}";
      extraConfig = {
        drun-display-format = "{name}";
        display-drun = "drun: ";
      };
      theme = let
        inherit (config.lib.formats.rasi) mkLiteral;
      in {
        configuration.show-icons = true;
        "*" = {
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "#ffffffd1";
        };
        "window" = {
          border-radius = mkLiteral "10px";
          padding = mkLiteral "10px";
          border = mkLiteral "2px";
          border-color = mkLiteral "#ffffffd1";
          background-color = mkLiteral "#000000b3";
        };
        "element".padding = mkLiteral "2px";
        "element-text selected".text-color = mkLiteral "#000000";
        "element-icon selected".text-color = mkLiteral "#000000";
        "element selected normal" = {
          background-color = mkLiteral "#ffffffd1";
          text-color = mkLiteral "#000000";
        };
      };
    };
    skim = {
      enable = true;
      enableZshIntegration = true;
    };
    yazi = {
      enable = true;
      enableZshIntegration = true;
      shellWrapperName = "y";
      settings = {
        preview.cache_dir = "${config.xdg.cacheHome}/yazi";
        mgr = {
          sort_by = "btime";
          sort_reverse = true;
          sort_dir_first = true;
        };
      };
      keymap.mgr.prepend_keymap = [
        {
          run = "cd /run/media/${config.home.username}";
          desc = "Go to media mounts";
          on = [
            "g"
            "m"
          ];
        }
        {
          run = ''shell -- ya emit cd "${config.home.homeDirectory}/Projects/vessel/$(hostname)"'';
          desc = "Go to this system's unique config";
          on = [
            "g"
            "s"
          ];
        }
        {
          run = "cd ${config.home.homeDirectory}/Projects/vessel/${config.home.username}";
          desc = "Go to this user's unique home config";
          on = [
            "g"
            "u"
          ];
        }
        {
          run = "shell --block -- nh home switch ; echo '\nPress enter to exit\n' && read";
          desc = "Update home-manager";
          on = [
            "u"
            "h"
          ];
        }
        {
          run = ''shell --block -- umount "$0"'';
          desc = "Unmount highlighted directory";
          on = [
            "u"
            "m"
          ];
        }
        {
          run = "shell --block -- nh os switch --update ; echo '\nPress enter to exit\n' && read";
          desc = "Update flake & NixOS";
          on = [
            "U"
            "o"
          ];
        }
        {
          run = "shell --block -- nh os switch ; echo '\nPress enter to exit\n' && read";
          desc = "Update NixOS";
          on = [
            "u"
            "o"
          ];
        }
      ];
    };
    zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [ "--cmd cd" ];
    };
    zsh = {
      enable = true;
      initContent = lib.mkMerge [
        (lib.mkOrder 500 zsh.instantPrompt)
        (lib.mkOrder 550 zsh.pluginsAndConfig)
      ];
    };
  };
  services = {
    dunst = {
      enable = true;
      settings = {
        global = {
          font = "${font.family} ${toString font.size}";
          width = "(128, 1024)";
          height = 128;
          origin = "top-right";
          offset = "10x10";
          padding = 15;
          horizontal_padding = 15;
          text_icon_padding = 10;
          frame_width = 3;
          frame_color = "ffffffd1";
          corner_radius = 10;
          background = "#000000b3";
          foreground = "#ffffff";
          transparency = 0;
          icon_position = "left";
          max_icon_size = 32;
          sort = true;
          layer = "overlay";
          show_indicators = false;
          stack_duplicates = true;
          sticky_history = true;
          ignore_dbusclose = true;
        };
        urgency_low.timeout = 0;
        urgency_normal.timeout = 0;
        urgency_critical.timeout = 0;
      };
    };
    ollama = {
      enable = true;
      acceleration = "cuda";
      environmentVariables.OLLAMA_KEEP_ALIVE = "3m";
    };
    ssh-agent.enable = true;
    udiskie.enable = true;
  };
  xdg = {
    portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-termfilechooser
      ];
      config = {
        common."org.freedesktop.impl.portal.FileChooser" = [ "termfilechooser" ];
        hyprland = {
          "org.freedesktop.impl.portal.FileChooser" = [ "termfilechooser" ];
          default = [
            "hyprland"
            "gtk"
          ];
        };
      };
    };
    configFile."xdg-desktop-portal-termfilechooser/config".text = let
    wrapper = pkgs.writers.writeDash "yazi-filechooser" ''
      set -e
      multiple="$1"
      directory="$2"
      save="$3"
      path="$4"
      out="$5"
      if [ "$save" = "1" ]; then
        set -- --chooser-file="$out" "$path"
      elif [ "$directory" = "1" ]; then
        set -- --chooser-file="$out" --cwd-file="$out".1 "$path"
      elif [ "$multiple" = "1" ]; then
        set -- --chooser-file="$out" "$path"
      else
        set -- --chooser-file="$out" "$path"
      fi
      fifo=$(mktemp -u /tmp/tfc-fifo.XXXXXX)
      mkfifo "$fifo"
      inner="yazi"
      for arg in "$@"; do
        escaped=$(printf "%s" "$arg" | sed 's/"/\\"/g')
        inner="$inner \"$escaped\""
      done
      inner="$inner; echo x > \"$fifo\""
      sh -c "$TERMCMD sh -c '$inner'"
      read _ < "$fifo"
      rm -f "$fifo"
      if [ "$directory" = "1" ]; then
        if [ ! -s "$out" ] && [ -s "$out".1 ]; then
          cat "$out".1 > "$out"
          rm "$out".1
        else
          rm "$out".1
        fi
      fi
    '';
    in ''
      [filechooser]
      cmd = ${wrapper}
      default_dir = ${config.home.homeDirectory}
      open_mode = suggested
      save_mode = suggested
      env = TERMCMD=${terminal.command}
      env = PATH=$PATH:${config.home.homeDirectory}/.local/state/nix/profile/bin:/run/current-system/sw/bin
    '';
    desktopEntries = {
      claude = {
        name = "Claude";
        exec = "chromium --app=https://claude.ai --name=claude";
        categories = [
          "Network"
          "Utility"
        ];
      };
      element = {
        name = "Element";
        exec = "chromium --app=https://app.element.io --name=element";
        icon = "element-desktop";
        categories = [
          "Network"
          "InstantMessaging"
        ];
      };
    };
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = [ "librewolf.desktop" ];
        "application/xhtml+xml" = [ "librewolf.desktop" ];
        "x-scheme-handler/http" = [ "librewolf.desktop" ];
        "x-scheme-handler/https" = [ "librewolf.desktop" ];
        "x-scheme-handler/about" = [ "librewolf.desktop" ];
        "x-scheme-handler/unknown" = [ "librewolf.desktop" ];
        "image/jpeg" = [ "imv.desktop" ];
        "image/png" = [ "imv.desktop" ];
        "image/gif" = [ "imv.desktop" ];
        "image/webp" = [ "imv.desktop" ];
        "image/bmp" = [ "imv.desktop" ];
        "image/tiff" = [ "imv.desktop" ];
        "image/svg+xml" = [ "imv.desktop" ];
        "image/*" = [ "imv.desktop" ];
        "audio/*" = [ "mpv.desktop" ];
        "video/*" = [ "mpv.desktop" ];
        "audio/mpeg" = [ "mpv.desktop" ];
        "audio/ogg" = [ "mpv.desktop" ];
        "audio/flac" = [ "mpv.desktop" ];
        "video/mp4" = [ "mpv.desktop" ];
        "video/x-matroska" = [ "mpv.desktop" ];
        "video/webm" = [ "mpv.desktop" ];
        "x-scheme-handler/terminal" = [ terminal.command ];
        "inode/directory" = [ "yazi.desktop" ];
        "application/x-directory" = [ "yazi.desktop" ];
        "text/plain" = [ "neovim.desktop" ];
        "text/*" = [ "neovim.desktop" ];
        "application/json" = [ "neovim.desktop" ];
        "application/xml" = [ "neovim.desktop" ];
        "application/pdf" = [ "libreoffice-writer.desktop" ];
        "application/msword" = [ "libreoffice-writer.desktop" ];
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = [ "libreoffice-writer.desktop" ];
        "application/vnd.oasis.opendocument.text" = [ "libreoffice-writer.desktop" ];
        "application/rtf" = [ "libreoffice-writer.desktop" ];
        "application/vnd.ms-excel" = [ "libreoffice-calc.desktop" ];
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = [ "libreoffice-calc.desktop" ];
        "application/vnd.oasis.opendocument.spreadsheet" = [ "libreoffice-calc.desktop" ];
        "text/csv" = [ "libreoffice-calc.desktop" ];
        "application/vnd.ms-powerpoint" = [ "libreoffice-impress.desktop" ];
        "application/vnd.openxmlformats-officedocument.presentationml.presentation" = [ "libreoffice-impress.desktop" ];
        "application/vnd.oasis.opendocument.presentation" = [ "libreoffice-impress.desktop" ];
      };
    };
  };
  wayland.windowManager.hyprland = {
    enable = true;
    settings = let
      mod = "SUPER";
    in {
      ecosystem.no_update_news = true;
      ecosystem.enforce_permissions = 1;
      permission = [
        "${pkgs.grim}/bin/grim, screencopy, allow"
        "${pkgs.hyprlock}/bin/hyprlock, screencopy, allow"
        "${pkgs.sunshine.override { cudaSupport = true; }}/bin/sunshine, screencopy, allow"
      ];
      exec-once = [
        "awww-daemon"
        "wallpaper ; awww img ${config.home.homeDirectory}/Pictures/Wallpapers/jxwallpaper/wallpaper || awww clear 000000"
        ''[[ -f ${config.home.homeDirectory}/Documents/startup-message.md ]] && cat ${config.home.homeDirectory}/Documents/startup-message.md | while read line; do dunstify "$line"; done''
        "mv ~/ly-session.log ~/.ly-session.log"
        "[workspace special:scratchpad silent] ${terminal.name}"
      ];
      monitor = [ "DP-3,2560x1440@180,0x0,1,bitdepth,10,cm,hdr,sdrbrightness,1.4,vrr,3" ];
      # env = [ "DXVK_HDR,1" ];
      "render:cm_enabled" = true;
      "render:cm_fs_passthrough" = true;
      "render:direct_scanout" = true;
      general = {
        gaps_in = 4;
        gaps_out = 8;
        border_size = 2;
        "col.active_border" = "rgba(ffffffdd) rgba(ffffffcc) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        resize_on_border = false;
        allow_tearing = false;
        layout = "dwindle";
      };
      decoration = {
        rounding = 10;
        rounding_power = 2;
        active_opacity = 1.0;
        inactive_opacity = 1.0;
        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
          vibrancy = 0.1696;
        };
      };
      animations = {
        enabled = true;
        bezier = [
          "linear, 0, 0, 1, 1"
          "easeOut, 0.16, 1, 0.3, 1"
          "easeInOut, 0.42, 0, 0.58, 1"
          "smoothOut, 0.36, 0, 0.66, -0.56"
          "overshot, 0.05, 0.9, 0.1, 1.05"
        ];
        animation = [
          "fade, 1, 4, easeOut"
          "fadeIn, 1, 4, easeOut"
          "fadeOut, 1, 3, easeInOut"
          "fadeDim, 1, 4, easeInOut"
          "fadeShadow, 0"
          "windows, 1, 4, easeOut, slide"
          "windowsIn, 1, 4, easeOut, popin 90%"
          "windowsOut, 1, 3, easeInOut, popin 90%"
          "windowsMove, 1, 4, easeOut"
          "workspaces, 1, 5, easeOut, fade"
          "border, 1, 8, easeOut"
          "borderangle, 0"
        ];
      };
      workspace = [
        "w[tv1], gapsout:0, gapsin:0"
        "f[1], gapsout:0, gapsin:0"
      ];
      windowrule = [
        "border_size 0, match:float 0, match:workspace w[tv1]"
        "rounding 0, match:float 0, match:workspace w[tv1]"
        "border_size 0, match:float 0, match:workspace f[1]"
        "rounding 0, match:float 0, match:workspace f[1]"
        "suppress_event maximize, match:class .*"
        "no_focus on, match:class ^$, match:title ^$, match:xwayland 1, match:float 1, match:fullscreen 0"
        "float 1, match:title ^(scratchpad)$"
        "size 70% 70%, match:title ^(scratchpad)$"
        "center 1, match:title ^(scratchpad)$"
      ];
      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };
      master.new_status = "master";
      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
      };
      input = {
        kb_layout = "us";
        kb_variant = "";
        kb_model = "";
        kb_options = "";
        kb_rules = "";
        follow_mouse = 1;
        sensitivity = 0;
        touchpad = {
          natural_scroll = false;
        };
      };
      cursor = {
        inactive_timeout = 3;
        hide_on_key_press = true;
      };
      cursor.no_hardware_cursors = true;
      gesture = "3, horizontal, workspace";
      bind = [
        "${mod}, return, exec, ${terminal.command}"
        "${mod}, E, exec, ${terminal.command} zsh -c yazi"
        "${mod}, V, exec, ${terminal.command} zsh -c nvim"
        "${mod}, B, exec, ${terminal.command} zsh -c btm"
        "${mod}, P, exec, keepassxc"
        "${mod}, G, exec, steam"
        "${mod}, S, exec, librewolf"
        "${mod} ALT, S, exec, chromium"
        "${mod}, M, exec, chromium --app=https://app.element.io"
        "${mod}, C, exec, chromium --app=https://claude.ai"
        "${mod} ALT, M, exec, ${terminal.command} zsh -c 'nix run nixpkgs##signal-desktop'"
        "${mod}, N, exec, ${terminal.command} zsh -c 'nix run nixpkgs##qbittorrent'"
        "${mod}, T, exec, ${terminal.command} zsh -c 'nix run nixpkgs##tor-browser'"
        "${mod}, R, exec, killall rofi || rofi -show drun"
        "${mod}, A, exec, killall wiremix || ${terminal.command} wiremix"
        "${mod}, equal, exec, killall qalculate-qt || qalculate-qt"
        "${mod}, D, exec, dunstctl close"
        "${mod} SHIFT, D, exec, dunstctl close-all"
        "${mod}, minus, exec, wl-copy -- —"
        "${mod}, I, exec, wl-copy -- ∞"
        "${mod}, Q, killactive"
        "${mod}, F, togglefloating"
        "${mod}, Z, layoutmsg, togglesplit"
        "${mod}, X, swapnext, prev"
        "${mod}, backslash, exec, hyprlock"
        "${mod}, O, exec, toggle-hdr"
        "${mod} ctrl, escape, exit"
        ", print, exec, hyprshot -m output -m active"
        "alt, print, exec, hyprshot -m window -m active"
        "ctrl, print, exec, hyprshot -m region"
        "${mod}, H, movefocus, l"
        "${mod}, J, movefocus, d"
        "${mod}, K, movefocus, u"
        "${mod}, L, movefocus, r"
        "${mod}, left, movefocus, l"
        "${mod}, up, movefocus, u"
        "${mod}, down, movefocus, d"
        "${mod}, right, movefocus, r"
        "${mod}, grave, togglespecialworkspace, scratchpad"
        "${mod}, 1, workspace, 1"
        "${mod}, 2, workspace, 2"
        "${mod}, 3, workspace, 3"
        "${mod}, 4, workspace, 4"
        "${mod}, 5, workspace, 5"
        "${mod}, 6, workspace, 6"
        "${mod}, 7, workspace, 7"
        "${mod}, 8, workspace, 8"
        "${mod}, 9, workspace, 9"
        "${mod}, 0, workspace, 10"
        "${mod} SHIFT, 1, movetoworkspace, 1"
        "${mod} SHIFT, 2, movetoworkspace, 2"
        "${mod} SHIFT, 3, movetoworkspace, 3"
        "${mod} SHIFT, 4, movetoworkspace, 4"
        "${mod} SHIFT, 5, movetoworkspace, 5"
        "${mod} SHIFT, 6, movetoworkspace, 6"
        "${mod} SHIFT, 7, movetoworkspace, 7"
        "${mod} SHIFT, 8, movetoworkspace, 8"
        "${mod} SHIFT, 9, movetoworkspace, 9"
        "${mod} SHIFT, 0, movetoworkspace, 10"
        "${mod}, mouse_down, workspace, e+1"
        "${mod}, mouse_up, workspace, e-1"
      ];
      bindm = [
        "${mod}, mouse:272, movewindow"
        "${mod}, mouse:273, resizewindow"
      ];
      bindel = [
        ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ",XF86MonBrightnessUp, exec, brightnessctl -e4 -n2 set 5%+"
        ",XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-"
      ];
      bindl = [
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPause, exec, playerctl play-pause"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPrev, exec, playerctl previous"
      ];
    };
  };
}
