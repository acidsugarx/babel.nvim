vim.api.nvim_create_user_command("Babel", function(opts)
  local babel = require("babel")

  if opts.args ~= "" then
    babel.translate(opts.args)
  elseif opts.range > 0 then
    babel.translate_range(opts.line1, opts.line2)
  else
    babel.translate_selection()
  end
end, { nargs = "?", range = true, desc = "Translate text" })

vim.api.nvim_create_user_command("BabelWord", function()
  require("babel").translate_word()
end, { desc = "Translate word under cursor" })

vim.api.nvim_create_user_command("BabelRepeat", function()
  require("babel").repeat_last_translation()
end, { desc = "Repeat last translation" })

vim.api.nvim_create_user_command("BabelLang", function()
  require("babel").select_languages()
end, { desc = "Select translation languages" })

vim.api.nvim_create_user_command("BabelSwap", function()
  require("babel").swap_languages()
end, { desc = "Swap source and target languages" })

vim.api.nvim_create_user_command("BabelHistory", function()
  require("babel").show_history()
end, { desc = "Translation history" })

vim.api.nvim_create_user_command("BabelHistoryClear", function()
  require("babel").clear_history()
end, { desc = "Clear translation history" })
