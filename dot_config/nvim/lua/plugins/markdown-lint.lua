return {
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      opts.linters = opts.linters or {}

      local ignored_codes = {
        MD013 = true,
        MD022 = true,
        MD031 = true,
        MD032 = true,
        MD041 = true,
        MD024 = true,
        MD034 = true,
      }

      local parse = require("lint.parser").from_errorformat("stdin:%l:%c %m,stdin:%l %m", {
        source = "markdownlint",
        severity = vim.diagnostic.severity.WARN,
      })

      opts.linters["markdownlint-cli2"] = vim.tbl_deep_extend("force", opts.linters["markdownlint-cli2"] or {}, {
        parser = function(output, bufnr, linter_cwd)
          local diagnostics = parse(output, bufnr, linter_cwd)
          return vim.tbl_filter(function(diagnostic)
            local code = diagnostic.message:match("^(MD%d+)")
            return not ignored_codes[code]
          end, diagnostics)
        end,
      })
    end,
  },
}
