import XCTest

/// Plays a short game end to end through the real web app, exercising the
/// native pieces (alert/confirm/prompt, in-app navigation, persistence) and
/// saving App Store screenshots along the way.
///
/// Expects a fresh install (no saved game). Screenshots are written to
/// $SCREENSHOT_DIR when set — pass it as TEST_RUNNER_SCREENSHOT_DIR.
@MainActor
final class ScorekeeperFlowTests: XCTestCase {
  private var app: XCUIApplication!
  private var web: XCUIElement { app.webViews.firstMatch }

  override func setUp() async throws {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launch()
  }

  func testFullGame() {
    XCTAssertTrue(button("Start Game").waitForExistence(timeout: 30))

    // alert(): starting without names is blocked.
    tap(button("Start Game"))
    let alert = app.alerts.firstMatch
    XCTAssertTrue(alert.waitForExistence(timeout: 5))
    XCTAssertTrue(alert.staticTexts["Enter all 4 player names first."].exists)
    alert.buttons["OK"].tap()

    // prompt(): custom target score.
    tap(buttons("Custom").element(boundBy: 0))
    let prompt = app.alerts.firstMatch
    XCTAssertTrue(prompt.waitForExistence(timeout: 5))
    let field = prompt.textFields.firstMatch
    field.tap()
    field.clearText()
    field.typeText("400")
    prompt.buttons["OK"].tap()
    XCTAssertTrue(button("400").waitForExistence(timeout: 5))
    tap(button("500"))

    // Bundled root-relative link + swipe-back navigation.
    tap(web.links["How to Play"])
    XCTAssertTrue(web.links["← Back"].waitForExistence(timeout: 5))
    snapshot("05-how-to-play")
    tap(web.links["← Back"])
    XCTAssertTrue(button("Start Game").waitForExistence(timeout: 5))

    for (i, name) in ["Patrick", "Dee", "Marcus", "Linda"].enumerated() {
      let input = web.textFields.element(boundBy: i)
      tap(input)
      input.typeText(name)
    }
    dismissKeyboard()
    web.swipeDown()
    snapshot("04-setup")
    tap(button("Start Game"))
    XCTAssertTrue(button("Score Round 1").waitForExistence(timeout: 5))

    // confirm(): Cancel keeps the game going.
    tap(button("End game"))
    XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5))
    app.alerts.firstMatch.buttons["Cancel"].tap()
    XCTAssertTrue(button("Score Round 1").exists)

    playRound(1, bids: ["4", "3", "3", "2"], tricks: ("7", "6"))
    playRound(2, bids: ["5", "Nil", "4", "3"], tricks: ("6", "7"), nilMade: true)
    playRound(3, bids: ["3", "4", "2", "3"], tricks: ("8", "5"))
    XCTAssertTrue(button("Score Round 4").waitForExistence(timeout: 5))
    snapshot("01-scoreboard")

    tap(button("Score Round 4"))
    for (i, bid) in ["4", "2", "3"].enumerated() { tap(buttons(bid).element(boundBy: i)) }
    snapshot("02-bidding")
    tap(button("Cancel"))

    // Game survives a relaunch (localStorage on the custom scheme persists).
    app.terminate()
    app.launch()
    XCTAssertTrue(button("Score Round 4").waitForExistence(timeout: 30))

    // confirm(): OK ends the game.
    tap(button("End game"))
    XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5))
    app.alerts.firstMatch.buttons["OK"].tap()
    XCTAssertFalse(button("Score Round 4").waitForExistence(timeout: 2))
    snapshot("03-game-over")
  }

  private func playRound(_ n: Int, bids: [String], tricks: (String, String), nilMade: Bool = false) {
    tap(button("Score Round \(n)"))
    XCTAssertTrue(button("Next: Tricks").waitForExistence(timeout: 5))
    // Each player has their own 0–13 grid and Nil button, in seat order.
    for (i, bid) in bids.enumerated() { tap(buttons(bid).element(boundBy: i)) }
    tap(button("Next: Tricks"))
    tap(buttons(tricks.0).element(boundBy: 0))
    tap(buttons(tricks.1).element(boundBy: 1))
    if nilMade { tap(button("Yes ✓")) }
    tap(button("Preview Score"))
    tap(button("Confirm"))
  }

  // MARK: - Helpers

  private func button(_ label: String) -> XCUIElement { buttons(label).firstMatch }
  private func buttons(_ label: String) -> XCUIElementQuery {
    web.buttons.matching(NSPredicate(format: "label == %@", label))
  }

  private func tap(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertTrue(element.waitForExistence(timeout: 5), "missing \(element)", file: file, line: line)
    var swipes = 0
    while !element.isHittable && swipes < 8 {
      web.swipeUp(velocity: .slow)
      swipes += 1
    }
    element.tap()
  }

  private func dismissKeyboard() {
    // iPhone: "Done" on the input accessory bar. iPad: the keyboard's hide key.
    for label in ["Done", "Hide keyboard"] where app.buttons[label].exists {
      app.buttons[label].tap()
      break
    }
    XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5))
  }

  private func snapshot(_ name: String) {
    sleep(1)
    let shot = XCUIScreen.main.screenshot()
    let attachment = XCTAttachment(screenshot: shot)
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
    if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
      let device = UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone"
      try? shot.pngRepresentation.write(to: URL(fileURLWithPath: "\(dir)/\(device)-\(name).png"))
    }
  }
}

@MainActor
private extension XCUIElement {
  func clearText() {
    guard let value = value as? String, !value.isEmpty else { return }
    typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count))
  }
}
