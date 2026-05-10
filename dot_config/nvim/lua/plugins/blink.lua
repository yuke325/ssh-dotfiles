return {
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        preset = "none",

        -- Tab: 候補を上下に移動（候補が無ければ通常の Tab にフォールバック）
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },

        -- Enter: 選択中の候補を確定。未選択なら通常の改行
        ["<CR>"] = { "accept", "fallback" },

        -- Vim 伝統の確定キー。未選択でも先頭候補を選んで確定する
        ["<C-y>"] = { "select_and_accept", "fallback" },

        -- その他 default プリセット相当のキーを維持
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "hide", "fallback" },
        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<C-p>"] = { "select_prev", "fallback_to_mappings" },
        ["<C-n>"] = { "select_next", "fallback_to_mappings" },
        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },
        ["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
      },

      completion = {
        list = {
          selection = {
            preselect = false, -- 起動時に先頭候補を自動選択しない
          },
        },
      },
    },
  },
}
