# プロジェクト構造

## chezmoi apply のライフサイクル

[公式: Application order](https://www.chezmoi.io/reference/application-order/) に基づく実際の適用順:

1. **`.chezmoi.toml.tmpl`** — OS 判定、テンプレート変数（`is_mac`, `is_arch`, `theme_current` 等）、Git ユーザー情報の定義
2. **`run_once_01_install.sh.tmpl`** — 初回のみ実行。OS 検出と情報表示
3. **`run_onchange_*`** (before/after なし) — ファイル展開と並行して実行:
   - `darwin-install-packages` — `dot_Brewfile` 変更時に `brew bundle --global`
   - `arch-install-packages` — `scripts/arch.sh` 変更時に再実行
   - `20-sync-colorscheme` — テーマファイル変更時に `~/.config/themes/` を同期
4. **`dot_*` / `symlink_*` / `*.tmpl`** — ホームディレクトリへファイルまたはシンボリックリンクとして展開
5. **`run_onchange_after_*`** — ファイル展開後に実行:
   - `30-mise-install` — `mise/config.toml` 配置後に `mise install`

## macOS と Arch Linux の違い

| | macOS | Arch Linux |
|---|---|---|
| パッケージ管理 | Homebrew (`dot_Brewfile`) | pacman + paru (`scripts/arch.sh`) |
| セットアップスクリプト | `scripts/darwin.sh` | `scripts/arch.sh` |
| シェルパス | `/bin/zsh` | `/usr/bin/zsh` |

## 除外設定

`.chezmoiignore.tmpl` で `README.md`, `docs/`, `scripts/`, `LICENSE` および OS に応じた不要ファイルを `chezmoi apply` から除外している。
