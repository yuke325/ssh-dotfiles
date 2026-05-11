# chezmoi install 履歴 (CentOS 7)

## 何を入れたか

[chezmoi](https://www.chezmoi.io/) = dotfiles 管理ツール。このリポジトリの本体。

## 配置場所

| 何 | 場所 |
|---|---|
| chezmoi バイナリ | `~/.local/bin/chezmoi` |
| dotfiles の source dir (git repo) | `~/.local/share/chezmoi/` |
| chezmoi の動作設定 | `~/.config/chezmoi/chezmoi.toml` |
| chezmoi の state (promptStringOnce 等) | `~/.config/chezmoi/chezmoistate.boltdb` |

## どう入れたか (公式 installer 経由、mise ではない)

### 1. chezmoi 本体

```bash
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$HOME/.local/bin"
```

`-b` でインストール先を `~/.local/bin` に指定。これで `~/.local/bin/chezmoi` ができる。

**なぜ mise 経由ではなく公式 installer を使ったか:**

- mise の aqua-registry の chezmoi 定義 (`pkgs/twpayne/chezmoi/registry.yaml`) は **glibc 動的版の asset pattern のみ**で、musl asset が定義されていない
- そのため `mise install chezmoi@latest` を CentOS 7 で実行すると glibc 動的版が入って起動できない (`GLIBC_2.32 not found`)
- chezmoi の公式 install script (`get.chezmoi.io`) は **host glibc を自動検出して musl 版にフォールバック**する (glibc 2.35 未満で musl 採用)

公式ソース:
- [chezmoi install](https://www.chezmoi.io/install/)
- [chezmoi musl 静的リンク PR #893](https://github.com/twpayne/chezmoi/pull/893)
- [aqua-registry chezmoi 定義](https://github.com/aquaproj/aqua-registry/blob/main/pkgs/twpayne/chezmoi/registry.yaml) (musl asset 無し)

### 2. リポジトリを chezmoi の source dir へ配置

clone を `~/dotfiles` などの場所に置いた場合、chezmoi のデフォルト source `~/.local/share/chezmoi` へ移動:

```bash
mv ~/dotfiles ~/.local/share/chezmoi
```

(初回 clone する場合は最初から `~/.local/share/chezmoi` に clone してもよい)

### 3. chezmoi init --apply

```bash
~/.local/bin/chezmoi init --apply
```

これで:

- `.chezmoi.toml.tmpl` が評価され、対話プロンプトで `git_name` / `git_email` を入力する
- 入力値が `~/.config/chezmoi/chezmoi.toml` (data セクション) に永続化される
- `.chezmoiexternal.toml.tmpl` で `~/.local/share/blesh/` に ble.sh が git clone される
- `dot_bashrc`, `dot_config/*` が `~/.bashrc`, `~/.config/*` へ展開される
- **このブランチでは `run_once_*` / `run_onchange_*` スクリプトを削除しているため**、apply は純粋にファイル配置だけで、何も自動実行されない

## バージョン (実機セットアップ時)

```bash
$ chezmoi --version
chezmoi version v2.70.3
```

## このブランチの設計上の特徴

**apply で script が走らない**:

main ブランチや一般的な chezmoi 運用では `.chezmoiscripts/` 配下に run_once_before / run_onchange_after スクリプトを置いて、apply 中にツールを自動 install することが多い。

このブランチ (CentOS) では、過去にこのアプローチが古い OS の制約 (glibc 2.17, gcc 4.8 等) で連続的に失敗した経緯から、**スクリプトを全廃**して config ファイル管理だけに専念している。

そのため:

```
chezmoi apply
  ├─ .chezmoi.toml.tmpl    → prompt (git_name, git_email)
  ├─ .chezmoiexternal.tmpl → ble.sh を git clone (~/.local/share/blesh/)
  ├─ dot_* ファイル配置     → ~/.bashrc, ~/.config/* へ
  └─ exit 0                (script が無いので失敗経路なし)
```

ツール install は本 docs シリーズ (`install-mise.md`, `install-conda.md`, `build-neovim-on-centos7.md`) に従って **手動で叩く** 構成。

## ハマリ履歴

- 初回 README に `git clone -b ssh https://github.com/yuke325/dotfiles.git` と書いていたが、実際の repo 名は `ssh-dotfiles` で、ブランチも `main` のみ。存在しない repo に HTTPS clone するとGitHub が認証 prompt を出す
- 修正: README を `git clone https://github.com/yuke325/ssh-dotfiles.git ~/dotfiles` に直した
- `dot_config/git/config.tmpl` の `conflictStyle = zdiff3` が host git 1.8 (CentOS 7 標準) で `unknown style` エラー → `diff3` に降格 (リポジトリで対応済)
- `dot_config/git/ignore.tmpl` の `{{ if .is_mac }}...{{ end }}` ブロックが main ブランチ由来の残骸で、SSH 専用ブランチの `.chezmoi.toml.tmpl` には `is_mac` が定義されていない → template 評価エラー → 該当ブロック削除 (リポジトリで対応済)

## upgrade

```bash
# chezmoi 本体を最新に
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$HOME/.local/bin"

# dotfiles を最新の origin/CentOS に
cd ~/.local/share/chezmoi && git pull origin CentOS

# 再 apply (script 無しなので壊れない)
chezmoi apply
```

## 削除

```bash
# chezmoi バイナリ
rm -f ~/.local/bin/chezmoi

# source dir (= dotfiles git repo)
rm -rf ~/.local/share/chezmoi

# 動作設定と state
rm -rf ~/.config/chezmoi

# (~/.bashrc 等は残る、消したい場合は個別に rm)
```
