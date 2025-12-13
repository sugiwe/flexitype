#!/bin/bash
# デプロイ前チェックスクリプト
# Kamalでデプロイする前に実行して、必要な設定が整っているか確認する

set -e

echo "=========================================="
echo "Typnix デプロイ前チェック"
echo "=========================================="
echo ""

ERRORS=0

# 1. config/master.key の存在確認
echo ">>> config/master.key の確認..."
if [ -f "config/master.key" ]; then
    echo "✅ config/master.key が存在します"
else
    echo "❌ config/master.key が見つかりません"
    ERRORS=$((ERRORS + 1))
fi

# 2. .kamal/secrets の存在確認
echo ">>> .kamal/secrets の確認..."
if [ -f ".kamal/secrets" ]; then
    echo "✅ .kamal/secrets が存在します"

    # 必要な環境変数の確認
    if grep -q "RAILS_MASTER_KEY=" ".kamal/secrets"; then
        echo "  ✅ RAILS_MASTER_KEY が設定されています"
    else
        echo "  ❌ RAILS_MASTER_KEY が設定されていません"
        ERRORS=$((ERRORS + 1))
    fi

    if grep -q "FLEXITYPE_DATABASE_PASSWORD=" ".kamal/secrets"; then
        echo "  ✅ FLEXITYPE_DATABASE_PASSWORD が設定されています"
    else
        echo "  ❌ FLEXITYPE_DATABASE_PASSWORD が設定されていません"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "❌ .kamal/secrets が見つかりません"
    echo "   .kamal/secrets.example を参考に作成してください"
    ERRORS=$((ERRORS + 1))
fi

# 3. config/deploy.yml の確認
echo ">>> config/deploy.yml の確認..."
if [ -f "config/deploy.yml" ]; then
    echo "✅ config/deploy.yml が存在します"

    # VPS IPアドレスの確認
    if grep -q "YOUR_VPS_IP_ADDRESS" "config/deploy.yml"; then
        echo "  ⚠️  VPS IPアドレスが未設定です (YOUR_VPS_IP_ADDRESS)"
        echo "     実際のVPS IPアドレスに置き換えてください"
        ERRORS=$((ERRORS + 1))
    else
        echo "  ✅ VPS IPアドレスが設定されています"
    fi
else
    echo "❌ config/deploy.yml が見つかりません"
    ERRORS=$((ERRORS + 1))
fi

# 4. Dockerの起動確認
echo ">>> Dockerの確認..."
if command -v docker &> /dev/null; then
    if docker info &> /dev/null; then
        echo "✅ Dockerが起動しています"
    else
        echo "❌ Dockerが起動していません"
        echo "   Docker Desktopを起動してください"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "❌ Dockerがインストールされていません"
    ERRORS=$((ERRORS + 1))
fi

# 5. Kamalの確認
echo ">>> Kamalの確認..."
if command -v kamal &> /dev/null; then
    KAMAL_VERSION=$(kamal version)
    echo "✅ Kamal ${KAMAL_VERSION} がインストールされています"
else
    echo "❌ Kamalがインストールされていません"
    echo "   gem install kamal を実行してください"
    ERRORS=$((ERRORS + 1))
fi

# 6. RuboCopチェック
echo ">>> RuboCopチェック..."
if bundle exec rubocop > /dev/null 2>&1; then
    echo "✅ RuboCopチェックに合格しました"
else
    echo "⚠️  RuboCopで警告があります"
    echo "   bundle exec rubocop を実行して確認してください"
    # RuboCopは警告でもデプロイは可能なのでエラーカウントしない
fi

# 7. Brakemanチェック
echo ">>> Brakemanチェック..."
if bundle exec brakeman --no-pager -q > /dev/null 2>&1; then
    echo "✅ Brakemanチェックに合格しました"
else
    echo "⚠️  Brakemanで警告があります"
    echo "   bundle exec brakeman --no-pager を実行して確認してください"
    # Brakemanは警告でもデプロイは可能なのでエラーカウントしない
fi

# 8. Gitの状態確認
echo ">>> Gitの状態確認..."
if git diff-index --quiet HEAD --; then
    echo "✅ コミットされていない変更はありません"
else
    echo "⚠️  コミットされていない変更があります"
    echo "   デプロイ前にコミットすることを推奨します"
fi

# 結果サマリー
echo ""
echo "=========================================="
if [ $ERRORS -eq 0 ]; then
    echo "✅ すべてのチェックに合格しました"
    echo "=========================================="
    echo ""
    echo "次のコマンドでデプロイできます："
    echo "  kamal setup  # 初回デプロイの場合"
    echo "  kamal deploy # 2回目以降のデプロイ"
    echo ""
    exit 0
else
    echo "❌ ${ERRORS} 件のエラーがあります"
    echo "=========================================="
    echo ""
    echo "上記のエラーを修正してから再度実行してください。"
    echo ""
    exit 1
fi
