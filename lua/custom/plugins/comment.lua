return {
  'numToStr/Comment.nvim',
  dependencies = { 'JoosepAlviste/nvim-ts-context-commentstring' },
  config = function()
    local context_commentstring = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook()

    require('Comment').setup {
      pre_hook = function(ctx)
        return context_commentstring(ctx) or vim.bo.commentstring
      end,
    }
  end,
}
