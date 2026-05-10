return {
  {
    "catgoose/nvim-colorizer.lua",
    event = "BufReadPre",
    opts = {
      filetypes = { "*" },
      user_default_options = {
        mode = "background",
        RGB = false,
        RRGGBB = false,
        names = false,
        RRGGBBAA = true,
        css = true,
        css_fn = true,
        tailwind = true,
        always_update = true,
      },
    },
  },
}
