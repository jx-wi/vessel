{ ... }:
{
  colorschemes.catppuccin = {
    enable = true;
    settings = {
      flavour = "mocha";
      transparent_background = true;
    };
  };
  opts = {
    comments = "sO:*\\ -,mO:*\\ \\ ,exO:*/,s1:/*,mb:*,ex:*/,://,b:#,:%,:XCOMM,n:>,fb:-";
    cursorline = true;
    expandtab = true;
    formatoptions = "jcroql";
    number = true;
    relativenumber = true;
    shiftwidth = 2;
    signcolumn = "yes";
    smartindent = true;
    softtabstop = 2;
    tabstop = 2;
  };
  keymaps = [{
    action = ":%y+<CR>";
    mode = "n";
    key = "<A-c>";
    options = {
      desc = "Copy entire buffer to system clipboard";
      silent = true;
    };
  }];
  plugins = {
    cmp = {
      enable = true;
      settings = {
        sources = [
          { name = "nvim_lsp"; }
          { name = "path"; }
          { name = "buffer"; }
        ];
        mapping = {
          "<Tab>" = ''
            cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.confirm({ select = true })
              else
                fallback()
              end
            end, {"i", "s"})
          '';
          "<S-Tab>" = "cmp.mapping.select_prev_item()";
          "<CR>" = "cmp.mapping.confirm({ select = false })";
        };
      };
    };
    cmp-ai = {
      enable = true;
      callSetup = false;
    };
    indent-blankline.enable = true;
    lsp = {
      enable = true;
      servers = {
        eslint.enable = true;
        markdown_oxide.enable = true;
        nixd.enable = true;
        pyright.enable = true;
        ts_ls.enable = true;
      };
    };
    lualine.enable = true;
    treesitter = {
      enable = true;
      nixGrammars = true;
      settings = {
        highlight.enable = true;
        incremental_selection.enable = true;
        indent.enable = false;
      };
    };
  };
  extraConfigLua = ''
    vim.fn.jobstart({'curl', '-sf', 'http://localhost:11434'}, {
      on_exit = function(_, code)
        if code == 0 then
          require('cmp_ai.config'):setup({
            max_lines = 100,
            provider = 'Ollama',
            provider_options = {
              model = 'qwen2.5-coder:14b',
              suffix = function(lines_after)
                return lines_after
              end,
            },
            notify = false,
            run_on_every_keystroke = false,
          })
          local cmp = require('cmp')
          local sources = cmp.get_config().sources
          table.insert(sources, 1, { name = 'cmp_ai' })
          cmp.setup({ sources = sources })
        end
      end,
    })
  '';
}
