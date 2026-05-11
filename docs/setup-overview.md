# CentOS 7 ホストでのセットアップ手順 (全体)

このブランチは **CentOS 7 (glibc 2.17, gcc 4.8, git 1.8, curl 7.29) ホスト** で使うことを前提にした dotfiles。`chezmoi apply` は config ファイル配置だけを行い、ツールの install は自動化していない (= 何度 apply しても壊れない構造)。

ツールは各ホストで手動 install する。実機セットアップで踏んだ罠と解決策を本ファイル及び個別 docs に履歴として残してある。

## 前提

- bash / git / curl / ca-certificates が distro 標準で入っていること
- GitHub、https://mise.run、https://conda-forge.org、https://get.chezmoi.io に到達可能なネットワーク
- sudo 不可・非特権ユーザーで運用 (ホームディレクトリのみ書き換え)

## install 順序

依存関係上、この順番で叩く:

| 順 | 対象 | 何で入れるか | 配置 | docs |
|---|---|---|---|---|
| 1 | mise | mise.run 公式 install script (musl 強制) | `~/.local/bin/mise` | [`install-mise.md`](install-mise.md) |
| 2 | Miniforge + conda env (gcc/g++/cmake/ninja/gettext/git/curl/tree-sitter-cli) | conda-forge | `~/.local/miniforge/envs/nvim-build/` | [`install-conda.md`](install-conda.md) |
| 3 | chezmoi 本体 + dotfiles 配置 | get.chezmoi.io 公式 installer + `chezmoi init --apply` | `~/.local/bin/chezmoi` + `~/.config/*`, `~/.bashrc` etc. | [`install-chezmoi.md`](install-chezmoi.md) |
| 4 | mise で管理する CLI ツール (ripgrep, fd, bat, eza, ...) | `mise install --yes` | `~/.local/share/mise/installs/` | [`install-mise.md`](install-mise.md) 末尾 |
| 5 | neovim | source build (conda env の gcc 11 で) | `~/.local/bin/nvim` + `~/.local/share/nvim/runtime/` | [`build-neovim-on-centos7.md`](build-neovim-on-centos7.md) |

順序の理由:
- (1) mise を先に入れるのは、(4) で必要だから
- (2) Miniforge を入れるのは、(5) の neovim build に gcc 11 が必要なため + (3) の chezmoi apply で配置される dot_config/git/config が新しい git (2.x) を要求するため (`merge.conflictstyle = diff3` は 1.8 でも OK だが、`pull.rebase` 等で `--filter=blob:none` 系が使われると 1.8 で詰む)
- (3) で chezmoi を入れて dotfiles を配置 (`~/.config/git/`, `~/.bashrc` 等)
- (4) で残りの CLI ツール (mise の config.toml 記載) を入れる
- (5) は時間がかかる (30〜45 分) ので最後

## ホストへの依存関係まとめ

| ツール | host のものを使うか | 理由 |
|---|---|---|
| bash | host | distro 標準で 4.2 以上、十分 |
| git | **conda 経由 (~/.local/bin/git に symlink)** | host 1.8 は `--filter=blob:none` 非対応で lazy.nvim plugin clone が失敗 |
| curl | **conda 経由 (~/.local/bin/curl に symlink)** | host 7.29 は nvim-treesitter の新 flag に非対応 |
| gcc | **conda 経由 (~/.local/bin/gcc に symlink)** | host 4.8 は nvim / treesitter parser build に古すぎる |
| tree-sitter CLI | **conda 経由 (~/.local/bin/tree-sitter に symlink)** | 公式 prebuilt は glibc 2.29+ 必須、CentOS 7 では動かない |
| その他の CLI (ripgrep, fd, bat, ...) | mise (musl 静的) | aqua-registry が musl asset を提供している |
| chezmoi | get.chezmoi.io (musl 自動検出) | aqua-registry に musl asset 定義無し |
| neovim | source build | musl 静的 build が公式提供されていない |

## 認証

`gh auth login` を **install 前にやっておく** ことを強く推奨。

- 未認証だと GitHub API rate limit = 60 req/hour
- 認証ありなら 5000 req/hour
- mise install や nvim-treesitter の parser download で大量の API 呼び出しが走るので、未認証だと途中で 403 を踏む
- gh CLI の認証情報は mise が自動で読む (`~/.config/gh/hosts.yml` 経由)

```bash
# 順序的には install-mise.md で mise を入れてから、その後すぐに:
gh auth login
# → device flow で web 認証
```

## ハマったポイント (履歴)

実機セッションで実際に踏んだ落とし穴。詳細は個別 docs に。

1. **mise default が glibc 動的版**: `MISE_INSTALL_MUSL=1` で musl 静的版を強制しないと CentOS 7 で起動できない (`/lib64/libc.so.6: version GLIBC_2.18 not found`)
2. **mise install chezmoi が glibc 版を引いてくる**: aqua-registry の chezmoi 定義が musl 無し。get.chezmoi.io 経由に切り替えで解決
3. **lazy.nvim の git clone が `--filter=blob:none` 非対応エラー**: host git 1.8 では使えない、conda の git 2.x を symlink で勝たせる
4. **nvim-treesitter の curl が `unrecognized option`**: host curl 7.29 では新 flag 非対応、conda の curl 8.x を symlink
5. **nvim-treesitter parser build が gcc 4.8 でコンパイル失敗**: conda の gcc 11 を symlink で勝たせる
6. **tree-sitter CLI が glibc 2.29 要求**: 公式 prebuilt は CentOS 7 で動かない、conda-forge の tree-sitter-cli 0.26.8 を symlink
7. **`merge.conflictstyle = zdiff3` が host git 1.8 で `unknown style` エラー**: `diff3` に降格で対応 (リポジトリで対応済)
8. **`is_mac` template 変数が未定義**: SSH 専用ブランチには不要な main ブランチ残骸、削除済
9. **`chezmoi apply` 中の `mise install --yes` が exit 1 → apply 全体失敗**: 自動化スクリプトを全て削除して回避 (このブランチの設計判断)
10. **`~/.local/share/nvim/runtime/` を誤って削除**: nvim 本体が動かなくなる。掃除する際は `runtime/` に触らない (個別 path 指定)

## メンテナンス

- ツールを upgrade したいときは、各 docs の「実行コマンド」を再度叩く
- mise が管理する CLI は `mise upgrade` で一括更新可
- neovim は `cd ~/src/neovim && git pull && make install` で再 build (要 conda activate)
- conda env のツールは `conda update -n nvim-build --all` で更新
