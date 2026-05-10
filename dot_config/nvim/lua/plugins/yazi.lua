return {
  {
    "mikavilpas/yazi.nvim",
    event = "VeryLazy",
    keys = {
      {
        "<leader>y",
        "<cmd>Yazi<cr>",
        desc = "Yazi (Root Dir)",
      },
      {
        "<leader>Y",
        "<cmd>Yazi cwd<cr>",
        desc = "Yazi (cwd)",
      },
    },
    opts = {
      open_for_directories = false,
      keymaps = {
        show_help = "<f1>",
        open_file_in_vertical_split = "<c-v>",
        open_file_in_horizontal_split = "<c-b>",
        open_file_in_tab = "<c-t>",
        grep_in_directory = "<c-s>",
      },
    },
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = function(_, opts)
      if not opts.spec then
        opts.spec = {}
      end

      table.insert(opts.spec, {
        { "<leader>y", icon = { icon = "󰙅 " } },
        { "<leader>Y", icon = { icon = "󰙅 " } },
      })
    end,
  },
}
