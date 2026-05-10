# Build neovim on old-glibc hosts (CentOS 7 etc.)

このリポジトリでは neovim を mise の管理対象から外している。理由:

- neovim 公式 release は glibc 動的リンク版のみで musl 静的版は未提供
- 最新 neovim は glibc 2.28+ を要求するが、CentOS 7 は glibc 2.17
- aqua-registry の neovim 定義に musl asset が無く、mise 経由で回避できない

各ホストで source build する。所要 30〜60 分、ディスク 約 2 GB。

## 前提

- bash, git, curl, ca-certificates が distro 標準で入っていること
- ネットワーク到達: GitHub, conda-forge
- `gh auth login` 済み (build 中の GitHub rate limit を回避)

## 手順

### 1. Miniforge を user-space に install

```bash
curl -fsSL https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -o /tmp/miniforge.sh
bash /tmp/miniforge.sh -b -p $HOME/.local/miniforge
rm /tmp/miniforge.sh
source $HOME/.local/miniforge/etc/profile.d/conda.sh
```

### 2. build 用 env を作る (gcc 11, cmake, ninja, gettext)

```bash
conda create -y -n nvim-build -c conda-forge \
    gcc_linux-64=11 gxx_linux-64=11 \
    cmake ninja gettext pkg-config \
    m4 libtool autoconf automake \
    patch unzip
conda activate nvim-build
```

### 3. neovim ソースを取得

```bash
mkdir -p ~/src && cd ~/src
git clone --depth 1 -b stable https://github.com/neovim/neovim.git
cd neovim
```

### 4. build & install (~/.local 配下に配置)

```bash
make CMAKE_BUILD_TYPE=Release \
     CMAKE_INSTALL_PREFIX=$HOME/.local \
     -j$(nproc) \
     install
```

### 5. 動作確認

```bash
conda deactivate
~/.local/bin/nvim --version
```

`NVIM v0.10.x` のような出力が出れば成功。

### 6. conda の lib に依存していた場合の対処

```bash
ldd ~/.local/bin/nvim
```

出力に `~/.local/miniforge/envs/nvim-build/lib/...` への参照があれば、その path を `LD_LIBRARY_PATH` に通す:

```bash
echo 'export LD_LIBRARY_PATH="$HOME/.local/miniforge/envs/nvim-build/lib:$LD_LIBRARY_PATH"' >> ~/.bashrc.local
chmod 600 ~/.bashrc.local
```

`~/.bashrc.local` は `dot_bashrc` 末尾で source される (chezmoi 管理外、ホスト固有設定用)。

## 既存の壊れた neovim を掃除

過去に mise が glibc 版 neovim を入れていた場合は除去:

```bash
rm -rf ~/.local/share/mise/installs/neovim
rm -f  ~/.local/share/mise/shims/nvim
mise reshim
which nvim   # ~/.local/bin/nvim が解決されれば OK
```
