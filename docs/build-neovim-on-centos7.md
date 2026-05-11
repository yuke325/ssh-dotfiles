# neovim source build 履歴 (CentOS 7)

## 何を入れたか

[neovim](https://github.com/neovim/neovim) v0.12.2 (stable) を **source build** で `~/.local/` 配下に install した。

## なぜ source build か

- neovim 公式 release は **glibc 動的リンク版のみ**、musl 静的版を配布していない
- 最新 neovim は glibc 2.28+ を要求、CentOS 7 は glibc 2.17 で互換性無し
- aqua-registry の neovim 定義にも musl asset 無し
- → mise 経由でも公式 prebuilt でも CentOS 7 で動かないので、各ホストで source build する

## 配置場所

| 何 | 場所 |
|---|---|
| nvim バイナリ | `~/.local/bin/nvim` |
| nvim ランタイム (init.lua の `vim.uri` 等) | `~/.local/share/nvim/runtime/` |
| build 用 source tree | `~/src/neovim/` (build 後は削除可、ディスク 223 MB) |
| build 用 toolchain (gcc 11, cmake, ninja 等) | `~/.local/miniforge/envs/nvim-build/` ([install-conda.md](install-conda.md) で用意) |

## どう入れたか

### 前提

[install-conda.md](install-conda.md) の手順で `nvim-build` env が用意済みであること (gcc 11, cmake, ninja, gettext 等が入っている)。

### 1. build 用 env を activate

```bash
source $HOME/.local/miniforge/etc/profile.d/conda.sh
conda activate nvim-build
```

確認:

```bash
echo "CC=$CC"           # → conda の x86_64-conda-linux-gnu-cc
$CC --version           # → gcc 11.4
cmake --version         # → 4.x
ninja --version
```

### 2. neovim ソースを clone

```bash
mkdir -p ~/src && cd ~/src
git clone --depth 1 -b stable https://github.com/neovim/neovim.git
cd neovim
```

`stable` ブランチ = LazyVim 動作要件 (0.10+) を満たす最新タグ。実機セットアップ時は v0.12.2 が取得された。

### 3. build & install

```bash
make CMAKE_BUILD_TYPE=Release \
     CMAKE_INSTALL_PREFIX=$HOME/.local \
     -j$(nproc) \
     install
```

- `-j$(nproc)` で CPU 全コア使用、共有ホストなら `-j2` + `nice -n 19` で他人に配慮
- 所要 15〜45 分 (マシン性能 + 並列度次第)
- bundled deps (luv, luajit, lpeg, treesitter ライブラリ, lua-cjson, msgpack-c, ...) を GitHub から download して静的リンク。`gh auth login` 済なら rate limit を踏まない

### 4. 動作確認

```bash
conda deactivate
~/.local/bin/nvim --version
```

期待出力:
```
NVIM v0.12.2
Build type: Release
LuaJIT 2.1.x
```

### 5. 動的依存の確認 (`ldd`)

```bash
ldd ~/.local/bin/nvim
```

実機セットアップ時の依存:

| 依存 lib | 解決先 |
|---|---|
| `libc.so.6`, `libm.so.6`, `libpthread.so.0`, `libdl.so.2`, `librt.so.1`, `libutil.so.1`, `ld-linux-x86-64.so.2` | `/lib64/` (host glibc 2.17) ✅ |
| `libiconv.so.2` | `~/.local/miniforge/envs/nvim-build/lib/` |
| `libgcc_s.so.1` | `~/.local/miniforge/envs/nvim-build/lib/` |

→ glibc 系は host のものを使うので 2.17 でも動く。`libiconv` と `libgcc_s` だけ conda env 経由。

### 6. RPATH が焼き付けられているか確認

```bash
readelf -d ~/.local/bin/nvim | grep -E 'RPATH|RUNPATH'
```

実機:
```
0x000000000000000f (RPATH)  Library rpath: [/home/takaki/.local/miniforge/envs/nvim-build/lib]
```

= バイナリ自身に conda env の lib path が焼き付けられている → `LD_LIBRARY_PATH` の export 不要。**ただし** `~/.local/miniforge/` を削除すると nvim が起動できなくなる (rpath 先が消えるため)。

## バージョン (実機セットアップ時)

```bash
$ nvim --version
NVIM v0.12.2
Build type: Release
LuaJIT 2.1.1774638290
```

## LazyVim 連携時の追加考慮

### nvim-treesitter (main ブランチ)

LazyVim の install_version 8 系は nvim-treesitter **main ブランチ** を pin している。main は parser build に外部 `tree-sitter` CLI を必要とする (master ブランチでは不要だった)。

- conda-forge の `tree-sitter-cli` 0.26.8 を `~/.local/bin/tree-sitter` に symlink する ([install-conda.md](install-conda.md) で対応済)
- nvim-treesitter は PATH 上の tree-sitter を自動検出する仕様

### lazy.nvim plugin clone

lazy.nvim は plugin clone に `git clone --filter=blob:none` (partial clone) を使う。host git 1.8 では非対応 → conda の git 2.x を `~/.local/bin/git` に symlink ([install-conda.md](install-conda.md) で対応済)。

### nvim-treesitter download

nvim-treesitter は parser を curl で download する。host curl 7.29 では一部新 flag (`--no-progress-meter`, `--retry-all-errors` 等) が無い → conda の curl 8.x を `~/.local/bin/curl` に symlink ([install-conda.md](install-conda.md) で対応済)。

### gcc

treesitter parser は **ホストの gcc** でコンパイルされる (nvim-treesitter が `system("gcc ...")` を呼ぶ)。host gcc 4.8 では新しい C 機能が無くてコンパイル失敗するため、conda の gcc 11 を `~/.local/bin/gcc` に symlink ([install-conda.md](install-conda.md) で対応済)。

## ハマリ履歴

1. **初回 nvim 起動で `vim.uri not found` エラー**: 過去のセッションで誤って `rm -rf ~/.local/share/nvim` してしまい、runtime files まで消した。`make install` の再実行で復活
2. **`/lib64/libc.so.6: version GLIBC_2.28 not found`**: 当初 mise install neovim していたときの状態。source build に切り替えて解決
3. **lazy.nvim が `--filter=blob:none` で死亡** → conda git 2.x で解決 (上述)
4. **nvim-treesitter download が curl エラー** → conda curl 8.x で解決 (上述)
5. **nvim-treesitter parser コンパイルが gcc 4.8 で失敗** → conda gcc 11 で解決 (上述)
6. **`is_mac` 未定義 + `zdiff3` 未対応** → リポジトリで対応済

## upgrade

```bash
source $HOME/.local/miniforge/etc/profile.d/conda.sh
conda activate nvim-build

cd ~/src/neovim       # 残してあれば
git pull              # 残してなければ再度 git clone --depth 1 -b stable ...
make install          # build cache が効いて高速

conda deactivate
~/.local/bin/nvim --version
```

## 削除

```bash
# nvim 本体 + runtime
rm -f ~/.local/bin/nvim
rm -rf ~/.local/share/nvim/runtime

# build source (残してあれば、再 build 時に便利)
rm -rf ~/src/neovim

# LazyVim 関連の plugin / parser / state (残すと nvim install 後の初期化に時間がかかる)
rm -rf ~/.local/share/nvim/lazy ~/.local/share/nvim/site ~/.local/share/nvim/tree-sitter
rm -rf ~/.local/state/nvim ~/.cache/nvim

# ⚠️ ~/.local/share/nvim/runtime は nvim 起動に必須、消すと nvim が動かない
```

⚠️ **`~/.local/share/nvim/` を一括 rm するな**: `runtime/` ごと消えて nvim が `vim.uri not found` で死ぬ。個別 path 指定で消すこと (上記の通り)。
