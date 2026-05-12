# README

サーバーサイドチャレンジ用 Rails 7 (API only) アプリケーション。

## 環境

- Ruby 3.1.2
- Rails 7.0.8
- PostgreSQL 18
- Docker / Docker Compose

## 初回セットアップ

```sh
# イメージのビルド
docker compose build

# DB 起動
docker compose up -d db

# DB 作成 (development / test)
docker compose run --rm web bin/rails db:create

# マイグレーション (まだ存在しないが今後の運用用)
docker compose run --rm web bin/rails db:migrate
```

## 開発サーバー

```sh
docker compose up
# http://localhost:3000
```

## テスト (RSpec)

```sh
docker compose run --rm web bundle exec rspec
```

## Lint / Format (Rubocop)

```sh
# チェックのみ
docker compose run --rm web bundle exec rubocop

# 自動整形 (安全な修正のみ)
docker compose run --rm web bundle exec rubocop -a

# 自動整形 (unsafe な修正も含む)
docker compose run --rm web bundle exec rubocop -A
```
