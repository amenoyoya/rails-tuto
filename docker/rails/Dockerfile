FROM ruby:2.7

# Docker実行ユーザID取得
ARG UID

RUN : 'install bundler' && \
    apt-get update && \
    apt-get install -y build-essential libpq-dev && \
    gem install bundler && \
    : 'install nodejs' && \
    apt-get install -y nodejs npm && \
    npm i -g yarn && \
    : 'install rails' && \
    gem install rails mysql2 && \
    rails webpacker:install && \
    : 'www-data ユーザの UID をDocker実行ユーザのものに合わせる' && \
    usermod -o -u $UID www-data && groupmod -o -g $UID www-data && \
    : 'www-data ユーザで sudo 実行可能に' && \
    apt-get install sudo && \
    echo 'www-data ALL=NOPASSWD: ALL' >> '/etc/sudoers' && \
    : 'ドキュメントルートを www-data ユーザ所有に変更' && \
    mkdir -p /var/www/ && \
    chown -R www-data:www-data /var/www/ && \
    : 'apt lists 削除' && \
    rm -rf /var/lib/apt/lists/*

# 作業者: www-dataユーザ = Docker実行ユーザ
USER www-data

# 作業ディレクトリ: ../web-data/ => docker://rails:/var/www/
WORKDIR /var/www/

# Railsをセットアップし Rails サーバ起動
ENTRYPOINT ["bash", "setup_rails.sh"]

# Rails サーバ実行ポートを公開
EXPOSE 3000
