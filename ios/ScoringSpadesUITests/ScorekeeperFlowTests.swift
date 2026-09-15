import XCTest

/// Plays a short game end to end: setup, custom values, How to Play, three
/// scored rounds (one with a nil), relaunch persistence, and game over.
/// Saves App Store screenshots to $SCREENSHOT_DIR when set
/// (pass it as TEST_RUNNER_SCREENSHOT_DIR).
@MainActor
final class ScorekeeperFlowTests: XCTestCase {
  private var app: XCUIApplication!

  override func setUp() async throws {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments = ["-uiTestFreshState"]
    app.launch()
  }

  func testFullGame() {
    let start = app.buttons["Start Game"]
    XCTAssertTrue(start.waitForExistence(timeout: 30))
    XCTAssertFalse(start.isEnabled, "can't start without names")

    // Custom target score.
    tap(app.buttons["Custom"].firstMatch)
    let alert = app.alerts["Target score?"]
    XCTAssertTrue(alert.waitForExistence(timeout: 5))
    let field = alert.textFields.firstMatch
    field.tap()
    field.clearText()
    field.typeText("400")
    alert.buttons["OK"].tap()
    XCTAssertTrue(app.buttons["Custom, 400"].waitForExistence(timeout: 5))
    tap(app.buttons["500"])

    // House rules live on their own screen.
    tap(app.buttons["House Rules"])
    XCTAssertTrue(app.navigationBars["House Rules"].waitForExistence(timeout: 5))
    tap(app.buttons["4"])
    snapshot("06-house-rules")
    app.navigationBars.buttons.firstMatch.tap()
    XCTAssertTrue(start.waitForExistence(timeout: 5))
    XCTAssertEqual(app.buttons["House Rules"].value as? String, "Nil 100 · Blind nil 200 · Partner min 4")

    for (label, name) in [("Team 1 Player 1", "Patrick"), ("Team 1 Partner", "Dee"),
                          ("Team 2 Player 3", "Marcus"), ("Team 2 Partner", "Linda")] {
      let input = app.textFields[label]
      tap(input)
      input.typeText(name)
    }
    app.typeText("\n")  // "Done" on the last field dismisses the keyboard
    XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5))

    // How to Play and back.
    tap(app.buttons["How to Play"])
    XCTAssertTrue(app.navigationBars["How to Play"].waitForExistence(timeout: 5))
    snapshot("05-how-to-play")
    app.navigationBars.buttons.firstMatch.tap()
    XCTAssertTrue(start.waitForExistence(timeout: 5))

    app.swipeDown()
    snapshot("04-setup")
    tap(start)
    XCTAssertTrue(app.buttons["Score Round 1"].waitForExistence(timeout: 5))

    // Cancelling "End game?" keeps playing.
    tap(app.buttons["End game"])
    dismissConfirmation()
    XCTAssertTrue(app.buttons["Score Round 1"].waitForExistence(timeout: 5))

    playRound(1, bids: ["Patrick": "4", "Dee": "3", "Marcus": "3", "Linda": "2"], tricks: (7, 6))
    playRound(2, bids: ["Patrick": "5", "Dee": "nil", "Marcus": "4", "Linda": "3"], tricks: (6, 7), nilMade: true)
    playRound(3, bids: ["Patrick": "3", "Dee": "4", "Marcus": "2", "Linda": "3"], tricks: (8, 5))
    XCTAssertTrue(app.buttons["Score Round 4"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["292"].exists)
    XCTAssertTrue(app.staticTexts["171"].exists)
    snapshot("01-scoreboard")

    tap(app.buttons["Score Round 4"])
    for (name, bid) in [("Patrick", "4"), ("Dee", "2"), ("Marcus", "3")] {
      tap(app.buttons["\(name) bids \(bid)"])
    }
    app.swipeDown(velocity: .slow)
    snapshot("02-bidding")
    app.navigationBars.buttons["Cancel"].tap()

    // The game survives a relaunch.
    app.terminate()
    app.launchArguments = ["-uiTestFreshState", "-uiTestKeepState"]
    app.launch()
    XCTAssertTrue(app.buttons["Score Round 4"].waitForExistence(timeout: 30))

    tap(app.buttons["End game"])
    let endGame = app.buttons["End Game"]
    XCTAssertTrue(endGame.waitForExistence(timeout: 5))
    endGame.tap()
    XCTAssertTrue(app.buttons["Rematch (same teams)"].waitForExistence(timeout: 5))
    snapshot("03-game-over")
  }

  private func playRound(_ n: Int, bids: KeyValuePairs<String, String>, tricks: (Int, Int), nilMade: Bool = false) {
    tap(app.buttons["Score Round \(n)"])
    let next = app.buttons["Next: Tricks"]
    XCTAssertTrue(next.waitForExistence(timeout: 5))
    for (name, bid) in bids { tap(app.buttons["\(name) bids \(bid)"]) }
    XCTAssertTrue(next.isEnabled)
    next.tap()
    tap(app.buttons["Patrick & Dee took \(tricks.0)"])
    tap(app.buttons["Marcus & Linda took \(tricks.1)"])
    if nilMade { tap(app.buttons["Yes ✓"]) }
    app.buttons["Preview Score"].tap()
    let confirm = app.buttons["Confirm"]
    XCTAssertTrue(confirm.waitForExistence(timeout: 5))
    confirm.tap()
  }

  // MARK: - Helpers

  private func tap(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertTrue(element.waitForExistence(timeout: 5), "missing \(element)", file: file, line: line)
    var swipes = 0
    while !element.isHittable && swipes < 10 {
      app.swipeUp(velocity: .slow)
      swipes += 1
    }
    element.tap()
  }

  /// iPhone shows a Cancel button; on iPad the dialog is a popover dismissed by tapping outside.
  private func dismissConfirmation() {
    let cancel = app.buttons["Cancel"]
    if cancel.waitForExistence(timeout: 3) && cancel.isHittable {
      cancel.tap()
    } else {
      app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.95)).tap()
    }
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
