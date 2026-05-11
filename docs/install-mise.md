# mise install 履歴 (CentOS 7)

## 何を入れたか

[mise](https://mise.jdx.dev/) = polyglot dev tool manager (asdf 後継的存在)。

このリポジトリでは **mise が CLI ツール (ripgrep, fd, bat, eza, ...) の install を一手に引き受ける**。設定は `dot_config/mise/config.toml` で、chezmoi apply で `~/.config/mise/config.toml` に配置される。

## 配置場所

| 何 | 場所 |
|---|---|
| mise バイナリ | `~/.local/bin/mise` |
| mise が管理するツール (本体) | `~/.local/share/mise/installs/<tool>/<version>/` |
| mise の shim | `~/.local/share/mise/shims/<tool>` |
| 設定ファイル | `~/.config/mise/config.toml` (chezmoi apply で配置) |

## どう入れたか

### 1. mise 本体 (musl 静的版)

```bash
curl -fsSL https://mise.run | MISE_INSTALL_PATH="$HOME/.local/bin/mise" MISE_INSTALL_MUSL=1 sh
```

`MISE_INSTALL_MUSL=1` が **必須**。理由:

- CentOS 7 の glibc は 2.17 (2014 年版)
- mise の default release は glibc 動的リンクで、起動時に `version GLIBC_2.18 not found` でエラーになる
- mise.run の install script は libc を自動判定するが、glibc 古さの自動 fallback はしない仕様
- `MISE_INSTALL_MUSL=1` で musl 静的版を強制取得 (host glibc に依存しない)

公式ソース:
- [mise installing](https://mise.jdx.dev/installing-mise.html)
- [mise.run install script](https://mise.run) (curl で内容を確認可能)

### 2. PATH 設定

`dot_bashrc` (chezmoi apply で `~/.bashrc` に配置) が以下を行う:

```bash
export PATH="$HOME/.local/bin:$PATH"
command -v mise >/dev/null 2>&1 && eval "$(mise activate --shims bash)"
```

`mise activate --shims` は `~/.local/share/mise/shims` を PATH 先頭に置く。これにより mise で入れたツールが `which <tool>` で解決できる。

### 3. CLI ツール群の install

`~/.config/mise/config.toml` (chezmoi apply で配置済) に記載されたツールを一括 install:

```bash
mise install --yes
```

install されるツール (config.toml より):

| カテゴリ | ツール |
|---|---|
| 検索 / FS | ripgrep, fd, bat, eza, fzf, zoxide, btop, dust, yazi |
| Git / GitHub | gh, delta, lazygit |
| シェル / プロンプト | starship |
| データ操作 | jq, yq, gum |
| ターミナル / エディタ | zellij |
| その他 | tlrc |

これらは aqua-registry が musl asset を提供しているので、CentOS 7 でも動く。

**含めていないもの (CentOS 7 制約):**

- `chezmoi` — aqua-registry に musl asset 無し → get.chezmoi.io 経由 (`install-chezmoi.md`)
- `neovim` — 公式 musl ビルド無し → source build (`build-neovim-on-centos7.md`)
- `tree-sitter` — 公式 prebuilt が glibc 2.29+ 要求 → conda-forge 経由 (`install-conda.md`)

## バージョン (実機セットアップ時)

```bash
$ mise --version
2026.5.5 linux-x64 (2026-05-10)
```

mise 自体は config に pin していない。`curl https://mise.run | ...` を再実行すれば latest に上がる。

## GitHub rate limit 対策

mise が install するツールは多くが GitHub release から download される。各ツールで複数 API 呼び出しが発生するため、未認証 (60 req/h) では途中で 403 を踏む。

**事前に `gh auth login` をやっておく**:

```bash
gh auth login
# → device flow で GitHub にログイン
# (gh CLI が ~/.config/gh/hosts.yml に token を保存し、mise が自動で読む)
```

mise の token 検索順 (公式 docs より):
1. `MISE_GITHUB_TOKEN` env
2. `GITHUB_TOKEN` env
3. `GH_TOKEN` env
4. `gh` CLI の保存済み認証 ← これ
5. `credential_command` 設定

## ハマリ履歴

- 初回 `curl https://mise.run | sh` (`MISE_INSTALL_MUSL=1` 無し) で glibc 動的版が入り、`mise --version` で `GLIBC_2.18 not found` エラー
- 修正: `rm -f ~/.local/bin/mise` で削除 → `MISE_INSTALL_MUSL=1` 付きで再 install

## upgrade

```bash
# mise 本体を upgrade (新 release を再 install で上書き)
curl -fsSL https://mise.run | MISE_INSTALL_PATH="$HOME/.local/bin/mise" MISE_INSTALL_MUSL=1 sh

# 管理ツールを一括 upgrade
mise upgrade
```

## 削除

```bash
# mise 本体
rm -f ~/.local/bin/mise

# 管理ツール + shim (全部)
rm -rf ~/.local/share/mise

# 設定 (chezmoi 管理下なので消すと chezmoi apply で復活)
rm -f ~/.config/mise/config.toml
```
