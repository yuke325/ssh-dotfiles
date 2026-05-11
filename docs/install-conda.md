# conda (Miniforge) install 履歴 (CentOS 7)

## 何を入れたか

[Miniforge](https://github.com/conda-forge/miniforge) = コミュニティ運用の minimal conda distribution。デフォルト channel が `conda-forge`。

**なぜ conda が必要か**: CentOS 7 (glibc 2.17) で動く新しい gcc / git / curl / tree-sitter-cli を user-space で入れる現実的な手段が conda 以外にほぼ無いから。conda-forge の build farm は CentOS 7 sysroot で焼いているため、生成バイナリの最低 glibc 要件 = 2.17 で host とぴったり噛み合う。

詳細は [setup-overview.md](setup-overview.md#ホストへの依存関係まとめ) 参照。

## 配置場所

| 何 | 場所 |
|---|---|
| Miniforge 本体 | `~/.local/miniforge/` |
| conda env (build 用) | `~/.local/miniforge/envs/nvim-build/` |
| env 内のツール実体 | `~/.local/miniforge/envs/nvim-build/bin/<tool>` |
| `~/.local/bin/` 経由の symlink | `~/.local/bin/{gcc,g++,cc,git,curl,tree-sitter}` |

## どう入れたか

### 1. Miniforge を install

```bash
curl -fsSL https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -o /tmp/miniforge.sh
bash /tmp/miniforge.sh -b -p $HOME/.local/miniforge
rm /tmp/miniforge.sh
```

- `-b` で非対話モード (`~/.bashrc` を勝手に書き換えない)
- `-p` で install 先を `~/.local/miniforge` に固定
- 約 500 MB のディスク使用

### 2. conda コマンドを有効化 (現在シェルだけ、永続化しない)

```bash
source $HOME/.local/miniforge/etc/profile.d/conda.sh
```

これで `conda` コマンドが PATH に乗る。新シェルでは再度 source が必要だが、後述の `~/.local/bin/` symlink で日常的には conda activate なしで使える設計にしている。

### 3. build 用 env を作る (nvim-build)

```bash
conda create -y -n nvim-build -c conda-forge \
    gcc_linux-64=11 gxx_linux-64=11 \
    cmake ninja gettext pkg-config \
    m4 libtool autoconf automake \
    patch unzip \
    git curl tree-sitter-cli
```

入る packages とその役割:

| package | 役割 | 配置 |
|---|---|---|
| `gcc_linux-64=11` | nvim / treesitter parser ビルド用 gcc 11.4 | `~/.local/miniforge/envs/nvim-build/bin/x86_64-conda-linux-gnu-gcc` |
| `gxx_linux-64=11` | C++ ビルド用 g++ 11.4 | 同上 (`x86_64-conda-linux-gnu-g++`) |
| `cmake` | nvim ビルド orchestrator | `<env>/bin/cmake` |
| `ninja` | 高速 make 代替 | `<env>/bin/ninja` |
| `gettext` | nvim ビルド時の msgfmt 必須 | `<env>/bin/msgfmt` |
| `pkg-config`, `m4`, `libtool`, `autoconf`, `automake`, `patch`, `unzip` | nvim 内部ビルドの依存 | `<env>/bin/*` |
| `git` | host 1.8 が `--filter=blob:none` 非対応のため 2.x | `<env>/bin/git` |
| `curl` | host 7.29 が新 flag 非対応のため 8.x | `<env>/bin/curl` |
| `tree-sitter-cli` | nvim-treesitter (main) parser build 用、conda-forge は 0.26.8 が CentOS 7 sysroot で焼かれているため動く | `<env>/bin/tree-sitter` |

ディスク使用は env 1 つで約 1.5 GB。

### 4. `~/.local/bin/` に symlink を作る

`conda activate nvim-build` しなくても日常的に新しい gcc / git / curl / tree-sitter を使えるようにするため、`~/.local/bin/` に symlink を張る:

```bash
ln -sf ~/.local/miniforge/envs/nvim-build/bin/x86_64-conda-linux-gnu-gcc ~/.local/bin/gcc
ln -sf ~/.local/miniforge/envs/nvim-build/bin/x86_64-conda-linux-gnu-g++ ~/.local/bin/g++
ln -sf ~/.local/miniforge/envs/nvim-build/bin/x86_64-conda-linux-gnu-gcc ~/.local/bin/cc
ln -sf ~/.local/miniforge/envs/nvim-build/bin/git ~/.local/bin/git
ln -sf ~/.local/miniforge/envs/nvim-build/bin/curl ~/.local/bin/curl
ln -sf ~/.local/miniforge/envs/nvim-build/bin/tree-sitter ~/.local/bin/tree-sitter
```

`~/.local/bin` は `dot_bashrc` で PATH 先頭に置かれるので、これで:

- `which gcc` → `~/.local/bin/gcc` → conda の gcc 11
- `which git` → `~/.local/bin/git` → conda の git 2.x
- `which curl` → `~/.local/bin/curl` → conda の curl 8.x
- `which tree-sitter` → `~/.local/bin/tree-sitter` → conda の tree-sitter 0.26.8

### 5. 動作確認

```bash
gcc --version          # gcc 11.4
git --version          # git 2.x
curl --version         # curl 8.x
tree-sitter --version  # 0.26.8

# host のものを上書きしてないことを確認 (linker は host のものを使う)
ldd ~/.local/bin/git | grep libc       # /lib64/libc.so.6 → host glibc 2.17 経由 → OK
ldd ~/.local/bin/curl | grep libc      # 同上
ldd ~/.local/bin/tree-sitter | grep libc  # 同上
```

conda の build farm が CentOS 7 sysroot で焼いているので、これらのバイナリは host glibc 2.17 で動く。conda env の lib に rpath 経由で依存することはある (`libstdc++`, `libgcc_s` 等) が、`~/.local/miniforge/` を消さない限り問題ない。

## バージョン (実機セットアップ時)

```bash
$ conda --version
conda 26.3.2

$ ~/.local/miniforge/envs/nvim-build/bin/gcc --version
gcc (conda-forge gcc 11.4.0-13) 11.4.0

$ ~/.local/miniforge/envs/nvim-build/bin/git --version
git 2.x (確認時の latest)

$ ~/.local/miniforge/envs/nvim-build/bin/curl --version
curl 8.x

$ ~/.local/miniforge/envs/nvim-build/bin/tree-sitter --version
tree-sitter 0.26.8
```

## ハマリ履歴

1. **gcc symlink を作る前に nvim-treesitter parser build を試して大量 fail**: `which gcc` が `/usr/bin/gcc` (4.8) を返す状態だった。conda の gcc は cross-compiler 命名 `x86_64-conda-linux-gnu-gcc` で、conda activate しても `gcc` という symlink は作られない仕様 → 手動で `~/.local/bin/gcc` symlink を作って解決
2. **lazy.nvim が `--filter=blob:none` で死亡**: host git 1.8 では未対応の partial clone option。conda の git 2.x を symlink で勝たせて解決
3. **nvim-treesitter の `curl: (4) CURLE_NOT_BUILT_IN`**: host curl 7.29 が指定 flag 非対応。conda の curl 8.x で解決
4. **tree-sitter CLI が `GLIBC_2.29 not found`**: 公式 prebuilt は CentOS 7 で動かない。conda の tree-sitter-cli を直接 download (cargo build より早かった)

## upgrade

```bash
# env 内の全 package を最新に
source $HOME/.local/miniforge/etc/profile.d/conda.sh
conda update -n nvim-build --all -c conda-forge

# Miniforge 本体を最新に (rare)
# (再 install で上書き、ただし env は残るので注意)
```

## 削除

```bash
# Miniforge 全削除 (env も含む)
rm -rf ~/.local/miniforge

# ~/.local/bin の symlink 群 (壊れたリンクになるので)
rm -f ~/.local/bin/gcc ~/.local/bin/g++ ~/.local/bin/cc
rm -f ~/.local/bin/git ~/.local/bin/curl ~/.local/bin/tree-sitter

# 注意: ~/.local/bin/nvim は別 (source build した実体)、消さない
```

⚠️ **`~/.local/miniforge/` を消すと**: nvim (source build) の rpath が conda env 内 lib (`libstdc++`, `libgcc_s`, `libiconv` 等) を指しているので、nvim が起動できなくなる。Miniforge を削除する前に `ldd ~/.local/bin/nvim` で依存 lib を確認し、必要なら `~/.local/lib/` 等にコピーしてから rpath を patchelf で書き換えるか、nvim を静的リンクで再 build する。
