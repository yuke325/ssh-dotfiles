# テーマ管理

## 仕組み

`~/.config/themes/<theme>/` にテーマバンドル（ツールごとの設定ファイル一式）を格納し、`current` シムリンクでアクティブテーマを切り替える。各ツールは `current/` 内のファイルを symlink または include で参照するため、テーマ切り替え時は `current` の差し替えだけで全ツールに反映される。

- テーマソース: `dot_config/themes/<theme_name>/`
- デプロイ: `run_onchange_20-sync-colorscheme.sh.tmpl` が同期と `current` シムリンクを作成
- アクティブテーマ: `.chezmoi.toml.tmpl` の `$currentTheme` で指定（デフォルト: `catppuccin`）

## テーマバンドルの構成

新しいテーマを追加する場合、以下のファイルを `dot_config/themes/<theme_name>/` に用意する。

```
<theme_name>/
  neovim.lua           # neovim カラースキーム
  ghostty.conf         # ghostty テーマ
  zellij.kdl           # zellij テーマ
  yazi.toml.tmpl       # yazi テーマ
  syntect.tmTheme      # yazi シンタックスハイライト
  eza.yml              # eza ファイルカラー
  delta.gitconfig      # git-delta テーマ (features system)
  btop.theme           # btop テーマ
  starship.toml        # starship パレット
  hyprland.conf        # Hyprland ボーダーカラー
  hyprlock.conf        # hyprlock カラー
  waybar.css           # waybar スタイル
  mako.ini             # mako 通知カラー
  swayosd.css          # swayosd スタイル
  walker.css           # walker スタイル
  backgrounds/         # 壁紙画像
```

## 設計判断

- **lazygit / lazydocker / fzf / bat** — ANSI カラーを使用し、ターミナルテーマに自動追従させる。テーマバンドルでは管理しない
- **git-delta** — features system で管理。動作設定とカラー設定を分離するため
