import XCTest
@testable import NestMind

final class ProfileDraftTests: XCTestCase {
  func testSplitCSVRemovesWhitespaceAndEmpties() {
    XCTAssertEqual(
      ProfileDraft.splitCSV("focus, health,  , family "),
      ["focus", "health", "family"]
    )
  }

  func testOnboardingSubmissionRequiresAnswersAndPreferenceFields() {
    var draft = ProfileDraft.empty
    draft.preferredName = "Asher"
    draft.assistantTone = "Warm"
    draft.supportStyle = "Direct"
    draft.onboardingAnswers[OnboardingPrompt.whatMattersMost.rawValue] = "My family and my work."

    XCTAssertTrue(draft.isReadyForOnboardingSubmission)
  }
}
