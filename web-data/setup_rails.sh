#!/bin/bash

if [ ! -d './app' ]; then
    # Railsプロジェクトが未作成であれば新規作成
    rails new app
fi

# run rails server
cd app
bundle update && bundle install
rails s -p 3000 -b 0.0.0.0
