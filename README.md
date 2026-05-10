# dotfiles (ssh branch)

[chezmoi](https://www.chezmoi.io/) で管理された **SSH 接続先専用** dotfiles。
Linux ホスト・**非特権ユーザー（sudo 不可）** での運用を前提に、CLI ツールは全て [mise](https://mise.jdx.dev/) で `~/.local/share/mise/` 配下に user-space インストールする。

このブランチは macOS と main ブランチの汎用構成を捨て、headless Linux + bash + mise 一元管理に最適化されている。

## 前提

SSH 先サーバーに以下が distro 標準で入っていること（ほぼ全 distro で OK）:

- `bash`
- `git`
- `curl`
- `ca-certificates`

ネットワーク：GitHub と https://mise.run / https://mise.jdx.dev に到達できること。

## セットアップ

```bash
# 1) chezmoi を ~/.local/bin に導入し、ssh ブランチを apply
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin init --apply yuke325/dotfiles --branch ssh

# 2) PATH を通して新シェルを起動
export PATH="$HOME/.local/bin:$PATH"
exec bash
```

## init 時のプロンプト

初回実行時に以下を入力する:

| 項目 | 説明 |
|---|---|
| `git_name` | Git のユーザー名 |
| `git_email` | Git のメールアドレス |

## 自動で実行される処理

`chezmoi apply` の流れで以下が連続実行される:

1. **`run_once_before_00-bootstrap-mise.sh`** — mise が無ければ `curl https://mise.run | sh` で `~/.local/bin/mise` に導入
2. **dotfiles 配置** — `dot_bashrc`, `dot_config/*` を `$HOME` へ展開
3. **`run_onchange_after_30-mise-install.sh`** — `mise install` で `dot_config/mise/config.toml` 記載の全 CLI ツールを user-space に導入

## 管理対象（mise で導入される CLI）

| カテゴリ | ツール |
|---|---|
| 検索 / FS | ripgrep, fd, bat, eza, fzf, zoxide, dust, yazi, btop |
| Git / GitHub | gh, delta, lazygit |
| シェル / プロンプト | starship |
| データ操作 | jq, yq, gum |
| ターミナル / エディタ | zellij, neovim |
| その他 | chezmoi, tlrc (tldr), tree-sitter |

言語ランタイム（go/node/python/ruby/rust）は SSH 先で開発しない方針のため入れていない。必要になったら `dot_config/mise/config.toml` に追記する。

## テーマ

catppuccin (mocha) を各 config ファイルに直書きしている（中央 theme 機構は撤去済み）:

- `dot_config/starship.toml` — starship パレット定義
- `dot_config/yazi/theme.toml` — yazi UI
- `dot_config/eza/config.yml` — eza 配色
- `dot_config/zellij/themes/current.kdl` — zellij テーマ
- `dot_config/btop/themes/current.theme` — btop テーマ
- `dot_config/nvim/lua/plugins/theme.lua` — neovim catppuccin
- `dot_config/git/config.tmpl` — git-delta の `[delta "catppuccin-mocha"]` セクション

別テーマに変えたい場合は各ファイルを直接編集する。

## SSH 先で意図的に**入れない**もの

- GUI ツール（ghostty, mpv, imv, satty, evince, obsidian など）
- IME（fcitx5, mozc）
- フォント（noto-fonts, nerd-fonts 等）
- オーディオスタック（pipewire, wireplumber）
- カーネル / ファイルシステム（linux-headers, ntfs-3g, exfatprogs, kernel-modules-hook）
- Docker / lazydocker（rootless docker は別途構築が必要）
- AI CLI（Claude Code, Codex, Gemini CLI — ローカル専用）
- Markdown viewer (glow)
- 言語ランタイム（go/node/python/ruby/rust — 必要時に都度追加）

## セットアップ後の確認

```bash
mise --version
mise ls
which rg fd bat eza fzf lazygit gh delta zellij nvim chezmoi yazi starship
bash -ic 'echo OK'
nvim --version
starship --version
```
