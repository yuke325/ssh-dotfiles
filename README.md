# ssh-dotfiles (CentOS ブランチ)

[chezmoi](https://www.chezmoi.io/) で管理された **CentOS 7 専用 SSH 接続先 dotfiles**。glibc 2.17 という古い環境向けに、`main` ブランチ (自動セットアップ重視・現代的 distro 向け) から分岐した。

## main ブランチとの違い

| | main | **CentOS (this branch)** |
|---|---|---|
| 想定 distro | AlmaLinux/Rocky 9, Ubuntu 22.04+ 等 (glibc 2.31+) | **CentOS 7 (glibc 2.17)** |
| install 自動化 | `bootstrap.sh` で 1 コマンド | **無し (docs を見て手動)** |
| `.chezmoiscripts/` 配下 script | mise を bootstrap, 全 CLI を一括 install | **無し (apply は config 配置のみ)** |
| chezmoi apply の挙動 | script が走り、ツール install まで連動 | **ファイル配置だけ、何も自動実行しない** |
| トラブル時の切り分け | script ブラックボックスあり | **明示的、ステップ毎に独立** |
| 補助ツール | 不要 (host のものでカバー) | **conda 経由で gcc/git/curl/tree-sitter を入れ替え** |

CentOS 7 で main ブランチを使うと、bootstrap の自動化が古い OS の制約と衝突して連続的に失敗する。このブランチは**自動化を諦め、明示性と確実性を優先**した。

## セットアップ手順

`docs/` 配下の手順書を順番に読んで手動で実行する:

```bash
# 1) リポジトリ clone (好きな場所で OK、後で chezmoi のデフォルト dir へ移動する)
git clone -b CentOS https://github.com/yuke325/ssh-dotfiles.git ~/dotfiles

# 2) docs を順に読んで実行
#    a) docs/setup-overview.md       — 全体の流れと依存関係
#    b) docs/install-mise.md         — mise (musl 強制) を ~/.local/bin/mise に
#    c) docs/install-conda.md        — Miniforge + nvim-build env + ~/.local/bin/ への symlink
#    d) docs/install-chezmoi.md      — chezmoi 本体 + repo を ~/.local/share/chezmoi へ + chezmoi init --apply
#    e) docs/build-neovim-on-centos7.md — neovim を source build (30〜45 分)

# 3) 新シェル起動
export PATH="$HOME/.local/bin:$PATH"
exec bash
```

詳細は [`docs/setup-overview.md`](docs/setup-overview.md) を参照。

## chezmoi apply で何が起こるか

このブランチは **`run_once_*` / `run_onchange_*` スクリプトを全廃**しているので、apply は純粋にファイル配置だけ:

```
chezmoi apply
  ├─ .chezmoi.toml.tmpl    → prompt (git_name, git_email)
  ├─ .chezmoiexternal.tmpl → ble.sh を ~/.local/share/blesh/ に git clone
  └─ dot_* ファイル配置     → ~/.bashrc, ~/.config/* へ
       └─ exit 0 (script が無いので失敗経路なし)
```

何度 `chezmoi apply` を叩いても**物理的に壊れない**設計。

## 管理対象 (config ファイルのみ)

chezmoi で管理される config ファイル:

- `~/.bashrc` — bash 設定 (mise activate, starship init, ble.sh, alias 等)
- `~/.config/mise/config.toml` — mise が install する CLI ツール一覧
- `~/.config/git/config`, `~/.config/git/ignore` — git 設定
- `~/.config/starship.toml` — starship プロンプト
- `~/.config/nvim/` — LazyVim 設定一式
- `~/.config/yazi/`, `~/.config/zellij/`, `~/.config/btop/`, `~/.config/bat/`, `~/.config/eza/`, `~/.config/lazygit/` — 各 CLI ツール設定

ツール本体 (mise / chezmoi / conda / nvim 等) はこのリポジトリの管理外で、docs を見て手動 install する。

## ツール管理マトリクス (実機セットアップで決まった構成)

| ツール | 何で入れたか | 配置 | 詳細 docs |
|---|---|---|---|
| mise | mise.run (`MISE_INSTALL_MUSL=1` 必須) | `~/.local/bin/mise` | [install-mise.md](docs/install-mise.md) |
| chezmoi | get.chezmoi.io (musl 自動検出) | `~/.local/bin/chezmoi` | [install-chezmoi.md](docs/install-chezmoi.md) |
| Miniforge + conda env | conda-forge | `~/.local/miniforge/envs/nvim-build/` | [install-conda.md](docs/install-conda.md) |
| gcc 11 / g++ / cc | conda-forge (symlink) | `~/.local/bin/{gcc,g++,cc}` | [install-conda.md](docs/install-conda.md) |
| git 2.x | conda-forge (symlink) | `~/.local/bin/git` | [install-conda.md](docs/install-conda.md) |
| curl 8.x | conda-forge (symlink) | `~/.local/bin/curl` | [install-conda.md](docs/install-conda.md) |
| tree-sitter CLI 0.26.8 | conda-forge (symlink) | `~/.local/bin/tree-sitter` | [install-conda.md](docs/install-conda.md) |
| neovim 0.12.2 | source build (conda gcc 11) | `~/.local/bin/nvim` + `~/.local/share/nvim/runtime/` | [build-neovim-on-centos7.md](docs/build-neovim-on-centos7.md) |
| ripgrep, fd, bat, eza, fzf, zoxide, btop, dust, yazi, gh, delta, lazygit, starship, jq, yq, gum, zellij, tlrc | mise (`mise install --yes`) | `~/.local/share/mise/installs/*/*/` | [install-mise.md](docs/install-mise.md) |

## 前提

SSH 先サーバーに以下が distro 標準で入っていること:

- bash 4.0+
- git (1.8 でも OK、conda で 2.x を入れ直すので)
- curl (7.29 でも OK、conda で 8.x を入れ直すので)
- ca-certificates

ネットワーク到達: GitHub、https://mise.run、https://conda-forge.org、https://get.chezmoi.io

sudo 不可・非特権ユーザーで運用可能 (全部 `~/` 配下に閉じる)。

## init 時のプロンプト

`chezmoi init --apply` 実行中 (= [install-chezmoi.md](docs/install-chezmoi.md) の最後) に以下を対話入力する:

| 項目 | 説明 |
|---|---|
| `git_name` | Git のユーザー名 |
| `git_email` | Git のメールアドレス |

入力値は `~/.config/chezmoi/chezmoi.toml` に永続化される。

## テーマ

catppuccin (mocha) を各 config ファイルに直書きしている (中央 theme 機構は撤去済み):

- `dot_config/starship.toml` — starship パレット定義
- `dot_config/yazi/theme.toml` — yazi UI
- `dot_config/eza/config.yml` — eza 配色
- `dot_config/zellij/themes/current.kdl` — zellij テーマ
- `dot_config/btop/themes/current.theme` — btop テーマ
- `dot_config/nvim/lua/plugins/theme.lua` — neovim catppuccin
- `dot_config/git/config.tmpl` — git-delta の `[delta "catppuccin-mocha"]` セクション

## SSH 先で意図的に**入れない**もの

- GUI ツール (ghostty, mpv, imv, satty, evince, obsidian など)
- IME (fcitx5, mozc)
- フォント (noto-fonts, nerd-fonts 等)
- オーディオスタック (pipewire, wireplumber)
- カーネル / ファイルシステム (linux-headers, ntfs-3g, exfatprogs 等)
- Docker / lazydocker
- AI CLI (Claude Code, Codex, Gemini CLI — ローカル専用)
- Markdown viewer (glow)
- 言語ランタイム (go/node/python/ruby/rust — 必要時に都度追加)

## セットアップ後の確認

```bash
mise --version
mise ls
which rg fd bat eza fzf lazygit gh delta zellij nvim chezmoi yazi starship tlrc tree-sitter
bash -ic 'echo OK'
nvim --version
starship --version
```
