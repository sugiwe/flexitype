#!/bin/bash
# VPS初期セットアップスクリプト
# さくらVPS（Ubuntu 22.04）での使用を想定

set -e

echo "=========================================="
echo "Typnix VPS Setup Script"
echo "=========================================="
echo ""

# 必要なパッケージのインストール
echo ">>> 基本パッケージのインストール..."
sudo apt update
sudo apt install -y curl git wget build-essential

# Dockerのインストール
echo ">>> Dockerのインストール..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh

    # 現在のユーザーをdockerグループに追加
    sudo usermod -aG docker $USER
    echo "Dockerをインストールしました。グループ変更を反映するため、一度ログアウト・再ログインしてください。"
else
    echo "Dockerは既にインストールされています。"
fi

# PostgreSQLのインストール
echo ">>> PostgreSQLのインストール..."
if ! command -v psql &> /dev/null; then
    sudo apt install -y postgresql postgresql-contrib
    sudo systemctl enable postgresql
    sudo systemctl start postgresql
    echo "PostgreSQLをインストールしました。"
else
    echo "PostgreSQLは既にインストールされています。"
fi

# PostgreSQLの設定
echo ""
echo "=========================================="
echo "PostgreSQLの設定"
echo "=========================================="
echo "次のステップでPostgreSQLユーザーとデータベースを作成します。"
echo "安全なパスワードを設定してください。"
echo ""
read -p "続行しますか？ (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "次のSQLコマンドをPostgreSQLコンソールで実行してください："
    echo ""
    echo "sudo -u postgres psql"
    echo ""
    echo "-- PostgreSQLコンソール内で実行"
    echo "CREATE USER flexitype WITH PASSWORD 'your-secure-password';"
    echo "CREATE DATABASE flexitype_production OWNER flexitype;"
    echo "CREATE DATABASE flexitype_production_cache OWNER flexitype;"
    echo "CREATE DATABASE flexitype_production_queue OWNER flexitype;"
    echo "CREATE DATABASE flexitype_production_cable OWNER flexitype;"
    echo "\\q"
    echo ""
fi

# ファイアウォール設定（ufw）
echo ""
echo "=========================================="
echo "ファイアウォール設定"
echo "=========================================="
echo "HTTP(80)、HTTPS(443)ポートを開放します。"
echo ""
read -p "ファイアウォールを設定しますか？ (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo ufw allow OpenSSH
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw --force enable
    sudo ufw status
    echo "ファイアウォールを設定しました。"
fi

# セットアップ完了
echo ""
echo "=========================================="
echo "セットアップ完了"
echo "=========================================="
echo ""
echo "次のステップ："
echo "1. 一度ログアウト・再ログインしてDockerグループ変更を反映"
echo "2. PostgreSQLユーザー・データベースの作成"
echo "3. ローカルマシンから 'kamal setup' を実行"
echo ""
echo "詳細は docs/deployment_guide.md を参照してください。"
