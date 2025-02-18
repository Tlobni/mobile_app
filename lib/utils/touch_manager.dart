class TouchManager {
  static bool isTouchInProgress = false;

  static bool canProcessTouch() {
    if (!isTouchInProgress) {
      isTouchInProgress = true;
      return true;
    }
    return false;
  }

  static void touchProcessed() {
    isTouchInProgress = false;
  }
}
