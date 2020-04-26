# Ruby on Rails 入門

## Docker

Read [docker-rails.md](./docker-rails.md)

***

## Non Docker

### Environment
- OS:
    - Ubuntu 18.04
- PackageManager:
    - Homebrew (Linuxbrew)

### Setup
rbenv (Rubyのバージョン切り替え仮想環境) を用いて Ruby 環境を構築する

```bash
# ビルドツール導入
## ここでインストールしている ruby は Homebrew (Linuxbrew) インストール用
$ sudo apt install -y build-essential git curl runy openssl libssl-dev zlib1g-dev libsqlite3-devel

# Homebrew（Linuxbrew）インストール
$ sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"
## PATHを通す
$ echo 'export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"' >> ~/.bashrc
$ source ~/.bashrc

# Homebrew で rbenv のインストール
$ brew install rbenv

# ruby 2.7.0 のインストール
$ rbenv install 2.7.0

# 使用する ruby を 2.7.0 に切り替え
$ rbenv global 2.7.0

# rbenv 使用 ruby バージョン確認
$ rbenv versions
  system
* 2.7.0 (set by /home/mint/.rbenv/version)

# 参照している ruby コマンドを確認
$ which ruby
/home/linuxbrew/.linuxbrew/bin/ruby

# SQLite3 インストール
$ brew install sqlite3
$ gem install sqlite3 -v '1.4.2' --source 'https://rubygems.org/'

# nodejs, yarn インストール
$ brew install node
$ npm i -g yarn

# Rails インストール
$ gem install rails
```
