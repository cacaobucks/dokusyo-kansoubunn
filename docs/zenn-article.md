---
title: "生成AIの力で3年前に作った読書感想文アプリを改良してみた"
emoji: "📚"
type: "tech"
topics: ["rails", "claudecode", "tailwindcss", "hotwire", "ai"]
published: false
---

# はじめに

3年前にプログラミングスクールの課題として作成した「読書感想文」アプリがありました。当時はRuby on Railsの基礎を学びながら必死に作ったものでしたが、今見返すと改善点が山ほどあります。

今回、Anthropic社が提供するCLIツール「Claude Code」を使って、このアプリをモダンな技術スタックに一気にアップグレードしてみました。その過程で得られた知見を共有します。

# 改良前の状態

## 技術スタック（Before）

| 項目 | 技術 |
|------|------|
| Ruby | 2.6.x（システムRuby） |
| Rails | 6.x |
| フロントエンド | Webpacker + jQuery |
| CSS | SCSS（個別ファイル） |
| JavaScript | Turbolinks |
| デザイン | Bootstrap（ライトモードのみ） |

## 抱えていた問題

1. **古いRubyバージョン**: macOSのシステムRuby（2.6）に依存しており、`Operation not permitted - getcwd`エラーが頻発
2. **Webpackerの複雑さ**: node_modules、yarn.lock、babel.config.jsなど多数の設定ファイルが必要
3. **SCSSファイルの散乱**: `book_comments.scss`、`books.scss`、`users.scss`など機能ごとにファイルが分散
4. **レガシーなUI**: ダークモード非対応、モバイル対応が不十分
5. **セットアップの煩雑さ**: 新しい環境で動かすのに多くの手順が必要

# 改良後の状態

## 技術スタック（After）

| 項目 | 技術 |
|------|------|
| Ruby | 3.2.2（rbenv管理） |
| Rails | 7.1 |
| フロントエンド | Hotwire（Turbo + Stimulus） |
| CSS | Tailwind CSS 3.x |
| JavaScript | Importmap |
| デザイン | カスタムダークモードUI |

## 追加された機能

- 5段階評価システム
- ブックマーク機能
- フォロー/フォロワー機能
- 通知システム
- タグ機能
- 検索機能
- ダークモード/ライトモード切替

# Claude Codeを使った改良プロセス

## 1. 環境構築の自動化

最初に直面したのはRuby環境の問題でした。macOSのシステムRubyでは権限エラーが発生するため、rbenvでの環境構築が必要です。

Claude Codeに「macOSで動作するセットアップスクリプトを作って」と依頼したところ、以下のようなスクリプトが生成されました。

```bash
#!/bin/bash
# setup.sh - 抜粋

# Homebrewのインストール確認
if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# rbenvのインストール
if ! command -v rbenv &> /dev/null; then
    brew install rbenv ruby-build
    echo 'eval "$(rbenv init -)"' >> ~/.zshrc
fi

# Ruby 3.2.2のインストール
rbenv install 3.2.2
rbenv global 3.2.2
```

これにより、`./setup.sh`を実行するだけで環境構築が完了するようになりました。

## 2. Webpackerからの脱却

Rails 7ではWebpackerが非推奨となり、ImportmapとTailwind CSSの組み合わせが標準になっています。

**削除されたファイル:**
- `package.json`
- `yarn.lock`
- `babel.config.js`
- `postcss.config.js`
- `app/javascript/packs/application.js`

**新たに追加されたファイル:**
- `config/importmap.rb`
- `config/tailwind.config.js`
- `app/javascript/application.js`
- `app/javascript/controllers/`（Stimulusコントローラー）

依存関係がシンプルになり、ビルド時間が大幅に短縮されました。

## 3. ダークモードUIの実装

Tailwind CSSのCSS変数を活用したダークモードを実装しました。

```css
/* app/assets/stylesheets/application.tailwind.css */
@layer base {
  :root {
    --color-bg-primary: #ffffff;
    --color-text-primary: #1a1a1a;
  }

  .dark {
    --color-bg-primary: #0d1117;
    --color-text-primary: #e6edf3;
  }
}
```

Stimulusコントローラーでテーマ切替を実装:

```javascript
// app/javascript/controllers/dark_mode_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle() {
    document.documentElement.classList.toggle('dark')
    localStorage.setItem('theme',
      document.documentElement.classList.contains('dark') ? 'dark' : 'light'
    )
  }
}
```

## 4. Turbo Streamとの格闘

HotwireのTurbo Streamを導入する際、いくつかの問題に遭遇しました。

### 問題: 投稿が作成できない

```
No template found for BooksController#create, rendering head :no_content
Completed 204 No Content
```

**原因**: `respond_to`でturbo_streamフォーマットを指定していたが、対応するテンプレートが存在しなかった

**解決策**: シンプルなリダイレクトに変更

```ruby
# Before（問題あり）
def create
  @book = current_user.books.build(book_params)
  respond_to do |format|
    if @book.save
      format.turbo_stream { flash.now[:notice] = "投稿しました" }
      format.html { redirect_to @book }
    end
  end
end

# After（解決）
def create
  @book = current_user.books.build(book_params)
  if @book.save
    redirect_to @book, notice: "投稿しました"
  else
    @books = Book.with_associations.recent.page(params[:page]).per(12)
    render :index, status: :unprocessable_entity
  end
end
```

### 問題: 削除ボタンが動作しない

Turboを使用している場合、従来の`button_to`での削除が正しく動作しないケースがありました。

**解決策**: `link_to`と`data-turbo-method`を使用

```erb
<%= link_to book_path(@book),
      class: "btn-danger",
      data: { turbo_method: :delete,
              turbo_confirm: "削除しますか？" } do %>
  削除
<% end %>
```

## 5. 便利なシェルスクリプト

開発効率を上げるため、以下のスクリプトを作成しました。

| スクリプト | 機能 |
|-----------|------|
| `setup.sh` | 環境構築（Ruby、gems、DB） |
| `start.sh` | サーバー起動（依存関係チェック付き） |
| `stop.sh` | サーバー停止（プロセス強制終了対応） |

これにより、新しいマシンでも以下のコマンドだけで開発を開始できます:

```bash
git clone https://github.com/username/dokusyo-kansoubunn.git
cd dokusyo-kansoubunn
./setup.sh
./start.sh
```

# Before/After 比較表

| 項目 | Before | After |
|------|--------|-------|
| Ruby | 2.6（システム） | 3.2.2（rbenv） |
| Rails | 6.x | 7.1 |
| JS管理 | Webpacker | Importmap |
| CSS | SCSS + Bootstrap | Tailwind CSS |
| 動的UI | jQuery + Turbolinks | Hotwire（Turbo + Stimulus） |
| テーマ | ライトのみ | ダーク/ライト切替 |
| セットアップ | 手動（10ステップ以上） | `./setup.sh`のみ |
| 設定ファイル数 | 多数（node_modules含む） | 最小限 |

# ディレクトリ構成の変化

**Before:**
```
bookers2/
├── app/
│   ├── assets/
│   │   └── stylesheets/
│   │       ├── book_comments.scss
│   │       ├── books.scss
│   │       ├── favorites.scss
│   │       ├── homes.scss
│   │       └── users.scss
│   └── javascript/
│       ├── channels/
│       ├── packs/
│       └── stylesheets/
├── node_modules/        # 大量の依存関係
├── babel.config.js
├── package.json
├── postcss.config.js
└── yarn.lock
```

**After:**
```
dokusyo-kansoubunn/
├── app/
│   ├── assets/
│   │   ├── builds/          # Tailwind出力
│   │   ├── stylesheets/
│   │   │   └── application.tailwind.css
│   │   └── tailwind/
│   └── javascript/
│       ├── application.js
│       └── controllers/     # Stimulus
├── config/
│   ├── importmap.rb
│   └── tailwind.config.js
├── setup.sh
├── start.sh
└── stop.sh
```

# Claude Codeを使って感じたこと

## 良かった点

1. **大規模なリファクタリングが高速**: 複数ファイルにまたがる変更を一貫性を保ちながら実行できた
2. **エラー解決が的確**: エラーメッセージを伝えると、原因と解決策を即座に提示してくれた
3. **ベストプラクティスの適用**: Rails 7の標準的な書き方を自然に適用してくれた
4. **ドキュメント作成**: README.mdやシェルスクリプトのコメントも適切に生成

## 注意が必要な点

1. **Turbo Streamの扱い**: テンプレートの有無を考慮せずにコードを生成することがあった
2. **動作確認は必須**: 生成されたコードは必ず手動でテストする必要がある
3. **コンテキストの継続**: 長いセッションでは過去の変更を忘れることがある

# まとめ

3年前に作ったレガシーなRailsアプリを、Claude Codeの力を借りて最新の技術スタックにアップグレードできました。

主な成果:
- **Ruby 2.6 → 3.2.2**: 最新のRubyで安定動作
- **Webpacker → Importmap**: シンプルな依存関係管理
- **Bootstrap → Tailwind CSS**: モダンなダークモードUI
- **手動セットアップ → シェルスクリプト**: 環境構築の自動化

生成AIは万能ではありませんが、「何をしたいか」を明確に伝えれば、かなりの部分を自動化できます。特にRailsのようなフレームワークでは、ベストプラクティスに沿ったコードを生成してくれるため、学習コストを抑えながらモダンな開発手法を取り入れることができました。

レガシーなプロジェクトを抱えている方は、一度Claude Codeを試してみてはいかがでしょうか。

# 参考リンク

- [Rails 7.1 リリースノート](https://edgeguides.rubyonrails.org/7_1_release_notes.html)
- [Hotwire公式ドキュメント](https://hotwired.dev/)
- [Tailwind CSS公式ドキュメント](https://tailwindcss.com/docs)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
