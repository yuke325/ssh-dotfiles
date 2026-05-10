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

chezmoi も mise も入っていないまっさらな SSH 先で、`git clone` してから同梱の `bootstrap.sh` を実行するだけで完結する。

```bash
# 1) clone (好きな場所で OK、例: ~/dotfiles)
git clone https://github.com/yuke325/ssh-dotfiles.git ~/dotfiles

# 2) bootstrap (内部で repo を ~/.local/share/chezmoi へ移動した後、mise → chezmoi → apply まで一気通貫)
~/dotfiles/bootstrap.sh

# 3) PATH を通して新シェルを起動
export PATH="$HOME/.local/bin:$PATH"
exec bash
```

`bootstrap.sh` は最初に repo そのものを chezmoi デフォルト source dir である `~/.local/share/chezmoi` へ **`mv` で移動** する (clone 先の `~/dotfiles` は無くなる)。`rm` ではないので git 履歴・未 push 変更も全部 `~/.local/share/chezmoi` 配下に移される。

これにより以後は `chezmoi apply` / `chezmoi edit` / `chezmoi cd` などをパス指定なしのデフォルト挙動で利用できる。

> `~/.local/share/chezmoi` に別物が既存の場合、bootstrap.sh は `abort` する。事前に手動で退避してから再実行する。

## init 時のプロンプト

`bootstrap.sh` 実行中に以下を入力する:

| 項目 | 説明 |
|---|---|
| `git_name` | Git のユーザー名 |
| `git_email` | Git のメールアドレス |

## 自動で実行される処理

`bootstrap.sh` → `chezmoi init --apply` の流れで以下が連続実行される:

1. **`bootstrap.sh`** — repo を `~/.local/share/chezmoi` へ `mv` → `~/.local/bin/mise` が無ければ `curl https://mise.run | sh` (musl 強制) で導入 → `~/.local/bin/chezmoi` が無ければ `get.chezmoi.io` 公式インストーラ (musl 自動検出) で導入 → その chezmoi で `init --apply` を呼ぶ
2. **`run_once_before_00-bootstrap-mise.sh`** — fallback。`bootstrap.sh` を経由せず `chezmoi update` 後の apply で mise が消えていた場合のみ動作する安全網
3. **dotfiles 配置** — `dot_bashrc`, `dot_config/*` を `$HOME` へ展開
4. **`run_onchange_after_30-mise-install.sh`** — `mise install` で `dot_config/mise/config.toml` 記載の全 CLI ツールを user-space に導入し、shim を生成 (chezmoi は mise 管理外なのでこの対象外)

## 管理対象（mise で導入される CLI）

| カテゴリ | ツール |
|---|---|
| 検索 / FS | ripgrep, fd, bat, eza, fzf, zoxide, dust, yazi, btop |
| Git / GitHub | gh, delta, lazygit |
| シェル / プロンプト | starship |
| データ操作 | jq, yq, gum |
| ターミナル / エディタ | zellij |
| その他 | tlrc (tldr), tree-sitter |

chezmoi と neovim は古い glibc ホスト (CentOS 7 等) の制約で mise 経由では入らないため、別ルートで配置している:

- **chezmoi**: `bootstrap.sh` から公式インストーラ (get.chezmoi.io) で `~/.local/bin/chezmoi` に直接配置 (公式 installer が musl を自動検出)
- **neovim**: musl ビルドが存在しないため、各ホストで source build する。手順: [`docs/build-neovim-on-centos7.md`](docs/build-neovim-on-centos7.md)

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
