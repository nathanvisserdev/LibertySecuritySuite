#!/bin/bash
# Build and inject tccd hook
# WARNING: Requires SIP disabled!

set -e

echo "=== Building tccd_hook.dylib ==="
cd "$(dirname "$0")"

clang -dynamiclib -o tccd_hook.dylib tccd_hook.c \
    -framework Foundation \
    -framework CoreFoundation \
    -arch arm64 \
    -arch x86_64 \
    -mmacosx-version-min=10.15 \
    -O2

echo "✓ Built tccd_hook.dylib"
echo ""
echo "=== Usage Instructions ==="
echo ""
echo "1. Disable SIP (if not already done):"
echo "   - Reboot into Recovery Mode (Command+R)"
echo "   - Open Terminal"
echo "   - Run: csrutil disable"
echo "   - Reboot normally"
echo ""
echo "2. Kill existing tccd:"
echo "   sudo killall tccd"
echo ""
echo "3. Inject into tccd (choose one):"
echo ""
echo "   a) System tccd:"
echo "   sudo DYLD_INSERT_LIBRARIES=$(pwd)/tccd_hook.dylib /System/Library/PrivateFrameworks/TCC.framework/Support/tccd system &"
echo ""
echo "   b) User tccd:"
echo "   DYLD_INSERT_LIBRARIES=$(pwd)/tccd_hook.dylib /System/Library/PrivateFrameworks/TCC.framework/Support/tccd &"
echo ""
echo "4. Monitor the hook:"
echo "   tail -f /tmp/tccd_hook.log"
echo ""
echo "5. To restore normal operation:"
echo "   sudo killall tccd"
echo "   (tccd will restart automatically without the hook)"
echo ""
echo "=== Security Warning ==="
echo "This is for research/testing only. Running with SIP disabled reduces system security."
echo "Re-enable SIP when done: csrutil enable (in Recovery Mode)"
