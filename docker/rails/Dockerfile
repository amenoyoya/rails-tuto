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

# 作業ディレクトリ: ../app/ => docker://rails:/var/www/app/
WORKDIR /var/www/app/

# コンテナ内 PATH 設定
ENV PATH=/var/www/.linuxbrew/bin:$PATH

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
