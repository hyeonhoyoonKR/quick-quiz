#!/bin/bash
# ============================================================
#  Quiz Flashcards — Capacitor 초기화 & 빌드 세팅 스크립트
#  사용법: bash setup.sh [android|ios|both]
#  기본값: both
# ============================================================

set -e  # 에러 발생 시 즉시 중단

PLATFORM=${1:-both}   # 인자 없으면 both
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()   { echo -e "${GREEN}[✔] $1${NC}"; }
warn()  { echo -e "${YELLOW}[!] $1${NC}"; }
error() { echo -e "${RED}[✘] $1${NC}"; exit 1; }

# ──────────────────────────────────────────────
# 0. 사전 확인
# ──────────────────────────────────────────────
echo ""
echo "======================================"
echo "  Capacitor 프로젝트 초기화 시작"
echo "======================================"
echo ""

command -v node  >/dev/null 2>&1 || error "Node.js가 설치되어 있지 않습니다. https://nodejs.org 에서 설치하세요."
command -v npm   >/dev/null 2>&1 || error "npm이 설치되어 있지 않습니다."

NODE_VER=$(node -v | sed 's/v//' | cut -d. -f1)
if [ "$NODE_VER" -lt 18 ]; then
    error "Node.js 18 이상이 필요합니다. 현재: $(node -v)"
fi

log "Node.js $(node -v) / npm $(npm -v) 확인 완료"

# ──────────────────────────────────────────────
# 1. package.json이 없으면 복사
# ──────────────────────────────────────────────
if [ ! -f "package.json" ]; then
    warn "package.json이 없습니다. 기본 파일을 생성합니다."
    cat > package.json << 'EOF'
{
  "name": "quiz-flashcards",
  "version": "1.0.0",
  "description": "Quiz Flashcard App",
  "scripts": {
    "sync": "npx cap sync",
    "open:android": "npx cap open android",
    "open:ios": "npx cap open ios",
    "build:android": "npx cap sync android && npx cap open android",
    "build:ios": "npx cap sync ios && npx cap open ios",
    "add:android": "npx cap add android",
    "add:ios": "npx cap add ios"
  },
  "devDependencies": {
    "@capacitor/cli": "^6.0.0"
  },
  "dependencies": {
    "@capacitor/core": "^6.0.0",
    "@capacitor/android": "^6.0.0",
    "@capacitor/ios": "^6.0.0"
  }
}
EOF
    log "package.json 생성 완료"
else
    log "package.json 이미 존재 — 스킵"
fi

# ──────────────────────────────────────────────
# 2. capacitor.config.json이 없으면 생성
# ──────────────────────────────────────────────
if [ ! -f "capacitor.config.json" ]; then
    warn "capacitor.config.json이 없습니다. 기본 설정을 생성합니다."
    cat > capacitor.config.json << 'EOF'
{
  "appId": "com.yourname.quizflashcards",
  "appName": "Quiz Flashcards",
  "webDir": ".",
  "server": {
    "androidScheme": "https"
  }
}
EOF
    log "capacitor.config.json 생성 완료"
    warn "⚠️  capacitor.config.json의 appId를 본인 도메인으로 변경하세요 (예: com.홍길동.quizapp)"
else
    log "capacitor.config.json 이미 존재 — 스킵"
fi

# ──────────────────────────────────────────────
# 3. npm install
# ──────────────────────────────────────────────
echo ""
log "npm 패키지 설치 중..."
npm install
log "패키지 설치 완료"

# ──────────────────────────────────────────────
# 4. Capacitor 초기화 (이미 초기화되어 있으면 스킵)
# ──────────────────────────────────────────────
# cap init은 package.json과 capacitor.config.json이 이미 있으면 불필요
# node_modules/.bin/cap 존재 여부로 초기화 완료 확인
if [ ! -d "node_modules/@capacitor/core" ]; then
    error "@capacitor/core 설치에 실패했습니다. npm install 로그를 확인하세요."
fi
log "Capacitor 패키지 설치 확인 완료"

# ──────────────────────────────────────────────
# 5. 플랫폼 추가
# ──────────────────────────────────────────────
add_platform() {
    local PLAT=$1
    if [ -d "$PLAT" ]; then
        warn "$PLAT 폴더가 이미 존재합니다 — 플랫폼 추가 스킵 (sync만 실행)"
    else
        echo ""
        log "$PLAT 플랫폼 추가 중..."
        npx cap add "$PLAT"
        log "$PLAT 추가 완료"
    fi

    log "$PLAT sync 실행 중..."
    npx cap sync "$PLAT"
    log "$PLAT sync 완료"
}

if   [ "$PLATFORM" = "android" ]; then
    add_platform android
elif [ "$PLATFORM" = "ios" ]; then
    add_platform ios
else
    add_platform android
    add_platform ios
fi

# ──────────────────────────────────────────────
# 6. 완료 안내
# ──────────────────────────────────────────────
echo ""
echo "======================================"
echo -e "${GREEN}  🎉 Capacitor 설정 완료!${NC}"
echo "======================================"
echo ""

if [ "$PLATFORM" = "android" ] || [ "$PLATFORM" = "both" ]; then
    echo "  📱 Android 빌드하려면:"
    echo "     npm run open:android"
    echo "     → Android Studio에서 Run 버튼 클릭"
    echo ""
    echo "  ⚠️  사전 요구사항: Android Studio + JDK 17 설치 필요"
    echo "     https://developer.android.com/studio"
    echo ""
fi

if [ "$PLATFORM" = "ios" ] || [ "$PLATFORM" = "both" ]; then
    echo "  🍎 iOS 빌드하려면 (macOS 전용):"
    echo "     npm run open:ios"
    echo "     → Xcode에서 Run 버튼 클릭"
    echo ""
    echo "  ⚠️  사전 요구사항: Xcode + CocoaPods 설치 필요"
    echo "     sudo gem install cocoapods"
    echo ""
fi

echo "  🔄 웹 파일 수정 후 네이티브에 반영하려면:"
echo "     npm run sync"
echo ""
