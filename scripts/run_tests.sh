#!/bin/ba# Clean previous builds
echo "🧽 Cleaning build directory..."
rm -rf build/
xcodebuild clean -scheme "doc-bot" -destination "platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5"

# Run tests with coverage
echo "🏃 Running tests..."
set -o pipefail
xcodebuild test \
  -scheme "doc-bot" \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5" \ test script for doc-bot
# This script runs the same commands as the CI pipeline locally

set -e

echo "🧪 Running local tests with coverage..."

# Clean previous builds
echo "🧽 Cleaning build directory..."
rm -rf build/
xcodebuild clean -scheme "doc-bot" -destination "platform=iOS Simulator,name=iPhone 16 Pro,OS=18.0"

# Run tests with coverage
echo "🏃 Running tests..."
set -o pipefail
xcodebuild test \
  -scheme "doc-bot" \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro,OS=18.0" \
  -enableCodeCoverage YES \
  -derivedDataPath ./build/DerivedData \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  ONLY_ACTIVE_ARCH=NO \
  | xcpretty --report junit --output ./build/reports/junit.xml

# Generate coverage report
echo "📊 Generating coverage report..."
mkdir -p ./build/reports
bundle exec slather coverage

echo "✅ Tests completed!"
echo "📈 Coverage report generated at: ./build/reports/cobertura.xml"
echo "📋 JUnit report generated at: ./build/reports/junit.xml"

# Open coverage report if on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
  if command -v open &> /dev/null; then
    echo "🔍 Opening coverage report..."
    open ./build/reports/cobertura.xml
  fi
fi
