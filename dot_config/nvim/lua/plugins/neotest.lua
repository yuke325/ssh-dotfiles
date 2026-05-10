return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "zidhuss/neotest-minitest",
    },
    opts = function(_, opts)
      opts.adapters = opts.adapters or {}
      vim.g.neotest_minitest_docker_mode = false

      table.insert(
        opts.adapters,
        require("neotest-minitest")({
          test_cmd = function(script)
            return {
              "env",
              "PARALLEL_WORKERS=1",
              "RAILS_ENV=test",
              "DISABLE_SPRING=1",

              "bundle",
              "exec",
              "ruby",
              "-e",
              "require 'minitest/reporters'; module Minitest::Reporters; def self.use!(*); end; end; load 'bin/rails'",

              "test",
              "-v",
              script,
            }
          end,
        })
      )
    end,
  },
}
