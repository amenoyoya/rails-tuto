# Ruby on Rails | Docker構成

## Environment

- OS:
    - Ubuntu 18.04
- Docker: 19.03.5
    - DockerCompose: 1.24.0

### Structure
```bash
./
|_ docker/ # Dockerコンテナビルド設定
|   |_ certs/ # SSL証明書が格納されるディレクトリ
|   |_ db/ # dbコンテナビルド設定
|   |   |_ dump/ # => docker://db:/var/dump/ にマウント
|   |   |_ initdb.d/ # 格納された *.sql ファイルが初期DBとして流し込まれる
|   |   |_ Dockerfile # dbコンテナビルドファイル
|   |   |_ my.cnf # MySQL設定ファイル => docker://db:/etc/mysql/my.cnf
|   |
|   |_ rails/ # railsコンテナビルド設定
|       |_ Dockerfile # railsコンテナビルドファイル
|_ app/ # プロジェクトディレクトリ
|_ docker-compose.yml # Docker構成
                      ## railsコンテナ: ruby:2.7
                      ##   | https://rails.localhost => docker://rails:3000
                      ## dbコンテナ: mysql:5.7
                      ## pmaコンテナ: phpmyadmin:latest
                      ##   | http://pma.rails.localhost => docker://pma:80
                      ## nginx-proxyコンテナ: jwilder/nginx-proxy
                      ##   | vhostsリバースプロキシ
                      ## letsencryptコンテナ: jrcs/letsencrypt-nginx-proxy-companion
                      ##   | nginx-proxyと連動して vhosts をSSL化
```

***

## 1st step: Railsプロジェクト作成用Docker

### docker/rails/Dockerfile
```bash
FROM ruby:2.7

# Docker実行ユーザID取得
ARG UID

RUN : 'install bundler' && \
    apt-get update && \
    apt-get install -y build-essential git && \
    gem install bundler && \
    \
    : 'install rails' && \
    gem install rails && \
    \
    : 'www-data ユーザの UID をDocker実行ユーザのものに合わせる' && \
    usermod -o -u $UID www-data && groupmod -o -g $UID www-data && \
    : 'www-data ユーザで sudo 実行可能に' && \
    apt-get install sudo && \
    echo 'www-data ALL=NOPASSWD: ALL' >> '/etc/sudoers' && \
    \
    : 'ホームディレクトリ作成' && \
    mkdir -p /var/www/ && \
    chown -R www-data:www-data /var/www/ && \
    \
    : 'apt lists 削除' && \
    rm -rf /var/lib/apt/lists/*

# 作業者: www-dataユーザ = Docker実行ユーザ
USER www-data

# 作業ディレクトリ
WORKDIR /var/www/

# コンテナ内 PATH 設定
ENV PATH=/var/www/.linuxbrew/bin:$PATH

RUN : 'install Linuxbrew' && \
    git clone https://github.com/Homebrew/brew ~/.linuxbrew/Homebrew && \
    mkdir ~/.linuxbrew/bin && \
    ln -s ~/.linuxbrew/Homebrew/bin/brew ~/.linuxbrew/bin/ && \
    echo 'export PATH="~/.linuxbrew/bin:$PATH"' >> ~/.bashrc && \
    \
    : 'install nodejs' && \
    brew install nodejs && \
    npm i -g yarn && \
```

### docker-compose.yml
```yaml
version: "3"

# サービスコンテナ
services:
  # Ruby on Rails コンテナ
  rails:
    build:
      context: ./docker/rails # ./docker/rails/Dockerfile でビルド
      args:
        # Docker実行ユーザIDをビルド時に使用
        UID: $UID
    tty: true # 標準入出力有効化＆コンテナ起動したままに
    links:
      - db
    volumes:
      # 作業ディレクトリ: ./app/ => docker://rails:/var/www/app/
      - ./app/:/var/www/app/
    environment:
      RAILS_ENV: development
      LANG: C.UTF-8
      TZ: Asia/Tokyo
      DATABASE_URL: mysql2://root:root@db:3306
      # VIRTUAL_HOST設定（nginx-proxy）
      VIRTUAL_HOST: rails.localhost # https://rails.localhost/ で稼働
      VIRTUAL_PORT: 3000
      CERT_NAME: default
  
  # MySQL コンテナ
  db:
    build: ./docker/db
    volumes:
      # DB永続化: db-dataボリュームコンテナをマウント
      - db-data:/var/lib/mysql/
      # 起動時にinitdb.d内で定義されたデータベースを構築する
      - ./docker/db/initdb.d/:/docker-entrypoint-initdb.d/
      # ダンプデータ共有用ディレクトリ
      - ./docker/db/dump/:/var/dump/
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: rails_development
  
  # phpMyAdmin コンテナ
  pma:
    image: phpmyadmin/phpmyadmin:latest
    links:
      - db
    volumes:
      - /sessions
    environment:
      PMA_ARBITRARY: 1
      PMA_HOST: db
      PMA_USER: root
      PMA_PASSWORD: root
      # VIRTUAL_HOST設定（nginx-proxy）
      VIRTUAL_HOST: pma.rails.localhost # http://pma.rails.localhost/ で稼働
      VIRTUAL_PORT: 80
      CERT_NAME: default

  # プロキシサーバ
  nginx-proxy:
    image: jwilder/nginx-proxy
    privileged: true # ルート権限
    ports:
      - "80:80" # http
      - "443:443" # https
    volumes:
      - /var/run/docker.sock:/tmp/docker.sock:ro
      - /usr/share/nginx/html
      - /etc/nginx/vhost.d
      - ./docker/certs/:/etc/nginx/certs:ro # letsencryptコンテナが ./docker/certs/ に作成したSSL証明書を読む
    environment:
      DHPARAM_GENERATION: "false"
    labels:
      com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy: "true"

  # 無料SSL証明書発行コンテナ
  letsencrypt:
    image: jrcs/letsencrypt-nginx-proxy-companion
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /usr/share/nginx/html
      - /etc/nginx/vhost.d
      - ./docker/certs/:/etc/nginx/certs:rw # ./docker/certs/ にSSL証明書を書き込めるように rw モードで共有
    depends_on:
      - nginx-proxy # nginx-proxyコンテナの後で起動
    environment:
      NGINX_PROXY_CONTAINER: nginx-proxy
  
# ボリュームコンテナ
volumes:
  db-data:
    driver: local
```

### Railsプロジェクト作成
```bash
# Docker実行ユーザIDを合わせてコンテナ起動
$ export UID && docker-compose up -d

# railsコンテナにアタッチ
$ export UID && docker-compose exec rails bash

# -- www-data@docker://rails

# /var/www/app/ にプロジェクト作成
$ rails new app
```

***

## 2nd step: bundle install を Dockerfile に追加

### docker/rails/Dockerfile
```bash
# ..(前半省略)..

# Gemfile をコンテナ内にコピー
ADD ./Gemfile /var/www/app/
ADD ./Gemfile.lock /var/www/app/

RUN : 'install Linuxbrew' && \
    git clone https://github.com/Homebrew/brew ~/.linuxbrew/Homebrew && \
    mkdir ~/.linuxbrew/bin && \
    ln -s ~/.linuxbrew/Homebrew/bin/brew ~/.linuxbrew/bin/ && \
    echo 'export PATH="~/.linuxbrew/bin:$PATH"' >> ~/.bashrc && \
    \
    : 'install nodejs' && \
    brew install nodejs && \
    npm i -g yarn && \
    : 'Gemfile のパーミッション修正' && \
    sudo chown www-data:www-data ~/app/Gemfile ~/app/Gemfile.lock && \
    : 'install rails project gem files' && \
    bundle install --gemfile=~/app/Gemfile

# Rails サーバ起動
EXPOSE 3000
ENTRYPOINT [ "bash", "-c", "rails s -p 3000 -b 0.0.0.0" ]
```

`./app/Gemfile` と `./app/Gemfile.lock` を `./docker/rails/` ディレクトリにコピーしておく

これらはDockerコンテナビルド時の `bundle install` 用に使う

`./app/` プロジェクトディレクトリ側にある `Gemfile`, `Gemfile.lock` はコンテナ起動時の `rails s -p 3000 -b 0.0.0.0` で使用される

### docker/rails/Gemfile
データベースに MySQL を使用するため、Gemfile を修正する

```diff
+ gem 'mysql2', '~> 0.5.3', '>= 0.5'
```

### app/config/database.yml
データベースに MySQL を使用するため、database.yml を修正する

```yaml
default: &default
  adapter: mysql2
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000

development:
  <<: *default
  database: rails_development

# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run "rake".
# Do not set this db to the same as development or production.
test:
  <<: *default
  database: rails_test

production:
  <<: *default
  database: rails_production
```

### Railsサーバ起動
```bash
# 一旦コンテナを削除
$ export UID && docker-compose down

# コンテナ再ビルド＆起動
$ export UID && docker-compose build
$ export UID && docker-compose up -d
```

https://rails.localhost にアクセスして Rails の画面が表示されればOK
