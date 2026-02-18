return {
  'neovim/nvim-lspconfig',
  dependencies = {
    { 'mason-org/mason.nvim', opts = {} },
    'mason-org/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    { 'j-hui/fidget.nvim', opts = {} },
    'saghen/blink.cmp',
  },
  config = function()
    -- Keymaps applied when an LSP attaches to a buffer
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc, mode)
          mode = mode or 'n'
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        -- Navigation
        map('gd', vim.lsp.buf.definition, 'Go to definition')
        map('gt', vim.lsp.buf.type_definition, 'Go to type definition')
        map('gD', vim.lsp.buf.declaration, 'Go to declaration')
        map('gi', vim.lsp.buf.implementation, 'Go to implementation')
        map('gw', vim.lsp.buf.document_symbol, 'Document symbols')
        map('gW', vim.lsp.buf.workspace_symbol, 'Workspace symbols')
        map('gr', vim.lsp.buf.references, 'Show references')

        -- Info
        map('K', vim.lsp.buf.hover, 'Hover')
        map('<C-k>', vim.lsp.buf.signature_help, 'Signature help')
        map('<leader>ls', vim.diagnostic.open_float, 'Show diagnostic')

        -- Actions
        map('<leader>af', vim.lsp.buf.code_action, 'Code action')
        map('<leader>rn', vim.lsp.buf.rename, 'Rename')
        map('<leader>p', function() vim.lsp.buf.format { async = false, timeout_ms = 2500 } end, 'Format buffer')

        -- Highlight references on CursorHold
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client:supports_method('textDocument/documentHighlight', event.buf) then
          local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })
          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })
          vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
            end,
          })
        end

        -- TypeScript: Organize imports
        if client and client.name == 'ts_ls' then
          vim.api.nvim_buf_create_user_command(event.buf, 'OrganizeImports', function()
            vim.lsp.buf.execute_command {
              command = '_typescript.organizeImports',
              arguments = { vim.api.nvim_buf_get_name(event.buf) },
              title = '',
            }
          end, { desc = 'Organize Imports' })
          map('<Leader>oi', '<Cmd>OrganizeImports<CR>', 'Organize Imports [TS]')
        end

        -- Toggle inlay hints
        if client and client:supports_method('textDocument/inlayHint', event.buf) then
          map('<leader>th',
            function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end,
            '[T]oggle Inlay [H]ints')
        end
      end,
    })

    -- Capabilities from blink.cmp
    local capabilities = require('blink.cmp').get_lsp_capabilities()

    -- Language servers to enable
    local servers = {
      ts_ls = {},
      eslint = {},
      pylsp = {},
      rust_analyzer = {},
      bashls = {},
      cssls = {},
      dockerls = {},
      html = {},
      jsonls = {},
      yamlls = {},
      tailwindcss = {},
    }

    -- Mason package names (these differ from LSP server names)
    local ensure_installed = {
      'lua-language-server',
      'typescript-language-server',
      'eslint-lsp',
      'python-lsp-server',
      'rust-analyzer',
      'bash-language-server',
      'css-lsp',
      'dockerfile-language-server',
      'html-lsp',
      'json-lsp',
      'yaml-language-server',
      'tailwindcss-language-server',
      'stylua',
      'prettier',
    }

    require('mason-tool-installer').setup { ensure_installed = ensure_installed }
    require('mason-lspconfig').setup {
      handlers = {
        function(server_name)
          local server = servers[server_name] or {}
          server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
          require('lspconfig')[server_name].setup(server)
        end,
      },
    }

    -- Lua
    require('lspconfig').lua_ls.setup {
      capabilities = capabilities,
      on_init = function(client)
        if client.workspace_folders then
          local path = client.workspace_folders[1].name
          if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
        end

        client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
          runtime = {
            version = 'LuaJIT',
            path = { 'lua/?.lua', 'lua/?/init.lua' },
          },
          workspace = {
            checkThirdParty = false,
            library = vim.api.nvim_get_runtime_file('', true),
          },
        })
      end,
      settings = {
        Lua = {},
      },
    }
  end,
}
