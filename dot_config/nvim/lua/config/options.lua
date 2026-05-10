-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
-- vim.opt.spell = true
-- vim.opt.spelllang = { "en_us" }
vim.opt.mousemodel = "extend"
vim.keymap.set({ "n", "v", "i" }, "<RightMouse>", "<Nop>")
vim.keymap.set({ "n", "v", "i" }, "<RightDrag>", "<Nop>")
vim.keymap.set({ "n", "v", "i" }, "<RightRelease>", "<Nop>")
vim.opt.swapfile = false
vim.opt.matchpairs:append("<:>")
vim.opt.inccommand = "split" -- LazyVim デフォルトの "nosplit" を上書き (置換プレビューを下部分割で表示)
vim.opt.showbreak = "↳ "
if vim.fn.has("linux") == 1 then
  vim.opt.clipboard = vim.env.SSH_CONNECTION and "" or "unnamedplus,unnamed"
end
