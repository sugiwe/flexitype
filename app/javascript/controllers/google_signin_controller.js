import { Controller } from "@hotwired/stimulus"

// Turbo対応のGoogle Identity Services (GIS) コントローラー
export default class extends Controller {
  static values = {
    clientId: String
  }

  connect() {
    // 既に初期化済みの場合はスキップ（重複初期化を防止）
    if (this.element.dataset.googleSigninInitialized === 'true') {
      return
    }

    // Turboのページ遷移後、GISが既に読み込まれているか確認
    if (window.google?.accounts?.id) {
      this.initializeGoogleSignIn()
    } else {
      // GISスクリプトの読み込みを待つ
      this.waitForGoogleScript()
    }
  }

  disconnect() {
    // クリーンアップ（必要に応じて）
    this.element.dataset.googleSigninInitialized = 'false'
  }

  waitForGoogleScript() {
    // GISが読み込まれるまで待機（最大5秒）
    let attempts = 0
    const maxAttempts = 50 // 50 * 100ms = 5秒

    const checkInterval = setInterval(() => {
      if (window.google?.accounts?.id) {
        clearInterval(checkInterval)
        this.initializeGoogleSignIn()
      } else if (++attempts >= maxAttempts) {
        clearInterval(checkInterval)
        console.error('Google Identity Services の読み込みに失敗しました')
      }
    }, 100)
  }

  initializeGoogleSignIn() {
    const buttonElement = this.element.querySelector('.g_id_signin')
    if (!buttonElement) {
      console.error('Google Sign-In button element not found')
      return
    }

    // Google Identity Servicesの初期化（先に実行）
    window.google.accounts.id.initialize({
      client_id: this.clientIdValue,
      callback: this.handleCredentialResponse.bind(this),
      auto_select: false
    })

    // 初期化後にボタンをレンダリング
    window.google.accounts.id.renderButton(
      buttonElement,
      {
        type: 'standard',
        size: 'medium',
        theme: 'outline',
        text: 'sign_in_with',
        shape: 'rectangular',
        logo_alignment: 'left'
      }
    )

    // 初期化完了フラグをセット
    this.element.dataset.googleSigninInitialized = 'true'
  }

  handleCredentialResponse(response) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    fetch('/auth/google', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken
      },
      body: JSON.stringify({ credential: response.credential })
    })
    .then(res => res.json())
    .then(data => {
      if (data.success) {
        window.location.href = data.redirect_url
      } else {
        alert('ログインに失敗しました: ' + (data.error || '不明なエラー'))
      }
    })
    .catch(error => {
      console.error('Error:', error)
      alert('ログインエラーが発生しました')
    })
  }
}
