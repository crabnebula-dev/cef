// Copyright (c) 2025 The Chromium Embedded Framework Authors. All rights
// reserved. Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.

#include "tests/cefclient/browser/util_mac.h"

#include "include/cef_browser.h"

namespace client {

std::optional<CefRect> GetWindowBoundsInScreen(NSWindow* window) {
  if ([window isMiniaturized] or [window isZoomed]) {
    return std::nullopt;
  }

  auto screen = [window screen];
  if (screen == nil) {
    screen = [NSScreen mainScreen];
  }

  const auto bounds = [window frame];
  const auto screen_bounds = [screen frame];

  if (NSEqualRects(bounds, screen_bounds)) {
    // Don't include windows that are transitioning to fullscreen.
    return std::nullopt;
  }

  CefRect dip_bounds{static_cast<int>(bounds.origin.x),
                     static_cast<int>(bounds.origin.y),
                     static_cast<int>(bounds.size.width),
                     static_cast<int>(bounds.size.height)};

  // Convert from macOS coordinates (bottom-left origin) to DIP coordinates
  // (top-left origin).
  dip_bounds.y = static_cast<int>(screen_bounds.size.height) -
                 dip_bounds.height - dip_bounds.y;

  return dip_bounds;
}

}  // namespace client

namespace client::extension_demo_test {

CefWindowHandle GetTabParentView(CefRefPtr<CefBrowser> main_browser) {
  if (!main_browser) {
    return nullptr;
  }

  NSView* browser_view = CAST_CEF_WINDOW_HANDLE_TO_NSVIEW(
      main_browser->GetHost()->GetWindowHandle());
  if (!browser_view) {
    return nullptr;
  }

  NSView* parent_view = [browser_view superview];
  if (!parent_view) {
    return nullptr;
  }

  return CAST_NSVIEW_TO_CEF_WINDOW_HANDLE(parent_view);
}

void LayoutTabBrowser(CefRefPtr<CefBrowser> main_browser,
                      CefRefPtr<CefBrowser> tab_browser,
                      int viewport_h_px,
                      const CefRect& tab_rect_px) {
  if (!main_browser || !tab_browser) {
    return;
  }

  NSView* browser_view = CAST_CEF_WINDOW_HANDLE_TO_NSVIEW(
      main_browser->GetHost()->GetWindowHandle());
  NSView* tab_view = CAST_CEF_WINDOW_HANDLE_TO_NSVIEW(
      tab_browser->GetHost()->GetWindowHandle());
  if (!browser_view || !tab_view) {
    return;
  }

  NSView* parent_view = [browser_view superview];
  if (!parent_view) {
    return;
  }

  [tab_view removeFromSuperview];
  [parent_view addSubview:tab_view positioned:NSWindowAbove relativeTo:nil];

  const NSRect browser_frame = [browser_view frame];
  const CGFloat viewport_h = viewport_h_px > 0
                                 ? static_cast<CGFloat>(viewport_h_px)
                                 : browser_frame.size.height;
  const CGFloat x = browser_frame.origin.x + tab_rect_px.x;
  const CGFloat y =
      browser_frame.origin.y + viewport_h - tab_rect_px.y - tab_rect_px.height;
  const NSRect tab_frame =
      NSMakeRect(x, y, tab_rect_px.width, tab_rect_px.height);

  [tab_view setFrame:tab_frame];
  [tab_view setAutoresizingMask:NSViewNotSizable];
}

}  // namespace client::extension_demo_test
