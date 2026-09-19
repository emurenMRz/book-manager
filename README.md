book-manager
============

ISBNを元に蔵書の管理を行うWEBアプリです。

## Requirements

 - Apacheなど適当なhttpd(Proxy機能が必要)
 - Ruby
 - PostgreSQL with PGroonga
 - Node.js(Vite 5 以上のため Node.js 18 以上)

## ディレクトリ構成

```
.
├── ap/    # バックエンド(Sinatra + Puma + Sequel、/api を配信)
├── ui/    # フロントエンド(React + Vite、ui/dist にビルド)
│   ├── index.html   # Vite エントリ(ビルドで ui/dist/index.html が生成される)
│   ├── public/      # 静的ファイル(ogp.jpg、manifest.json、favicon.ico、アイコン群)。
│   │                  # ビルドで ui/dist のルートにコピーされ、そのまま配信される
│   └── src/         # React ソース
└── rc.d/  # FreeBSD rc スクリプト
```

## Usage

### APサーバの準備

1. `ap`ディレクトリに`secret.rb`を作成して、以下の定数を定義します。

|定数|型|内容|要・不要|
|----|--|----|:-:|
|CACHE_DIR|string|書影画像([ISBN].jpg)を保存するディレクトリへの絶対パス|必須|
|RACK_SESSION_SECRET|string|Rackのession secret|必須|
|DB_HOST|string|database address|必須(不要な場合はnilを指定)|
|DB_NAME|string|database名|必須|
|DB_USER|string|DB用ユーザー名|必須|
|DB_PWD|string|DB用パスワード|必須(不要な場合はnilを指定)|
|RAKUTEN_APP_ID|integer|楽天APIのApplication ID|オプション|
|RAKUTEN_AFFILIATE_ID|string|楽天APIのAffiliate ID|オプション|

2. `ap`ディレクトリで以下のコマンドを実行します。

```
> bundle install
> bundle exec pumactl start
```

### フロントエンドのビルド

`ui`ディレクトリで以下のコマンドを実行します。

```
> cd ui
> npm install
> npm run build   # tsc で型チェックし、ui/dist にビルド
```

開発中は `npm run dev` で Vite の開発サーバー(既定 http://localhost:5173)を起動できます。

### WEBサーバの準備

1. Document rootとして`ui/dist`ディレクトリを指定します。
   `ui/public`配下の静的ファイル(ogp.jpg、manifest.json、favicon.ico、アイコン群)はビルド時に`ui/dist`のルートへコピーされるため、別途配置は不要です。
2. Reverse proxy設定等で、`/api`以下へのアクセスを上記APサーバ(`http://localhost:9292`)へ転送するように設定します。

フロントエンドはAPIを相対パス(`api/...`)で呼び出すため、ページはサイトルートで配信する必要があります(変更なし)。