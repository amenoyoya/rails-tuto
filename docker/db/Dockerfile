FROM mysql:5.7

# my.cnf は パーミッション644 である必要があるため、以下のように設定
ADD ./my.cnf /etc/mysql/my.cnf
RUN chmod 644 /etc/mysql/my.cnf

WORKDIR /var/lib/mysql
