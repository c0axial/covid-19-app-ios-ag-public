//
// Copyright © 2020 NHSX. All rights reserved.
//

import Common
import TestSupport
import XCTest
@testable import Domain

class SymptomsQuestionnaireEndpointTests: XCTestCase {
    
    private let endpoint = SymptomsQuestionnaireEndpoint()
    
    func testEndpoint() throws {
        let expected = HTTPRequest.get("/distribution/symptomatic-questionnaire")
        
        let actual = try endpoint.request(for: ())
        
        TS.assert(actual, equals: expected)
    }
    
    func testDecodingEmptyList() throws {
        let response = HTTPResponse.ok(with: .json(#"""
        {
            "symptoms": [],
            "riskThreshold": 0.5,
            "symptomsOnsetWindowDays": 14
        }
        """#))
        
        let questionnaire = try endpoint.parse(response)
        
        TS.assert(questionnaire.riskThreshold, equals: 0.5)
        TS.assert(questionnaire.dateSelectionWindow, equals: 14)
        XCTAssert(questionnaire.symptoms.isEmpty)
    }
    
    func testDecodingSymptomList() throws {
        let title1en = String.random()
        let description1en = String.random()
        let title1de = String.random()
        let description1de = String.random()
        let title2 = String.random()
        let description2 = String.random()
        
        let response = HTTPResponse.ok(with: .json(#"""
        {
            "symptoms": [
              {
                "title": {
                  "en-GB": "\#(title1en)",
                  "de-DE": "\#(title1de)"
                },
                "description": {
                  "en-GB": "\#(description1en)",
                  "de-DE": "\#(description1de)"
                },
                "riskWeight": 1
              },
              {
                "title": {
                  "en-GB": "\#(title2)"
                },
                "description": {
                  "en-GB": "\#(description2)"
                },
                "riskWeight": 0
              }
            ],
            "riskThreshold": 0.8,
            "symptomsOnsetWindowDays": 14
        }
        """#))
        
        let expected = SymptomsQuestionnaire(
            symptoms: [
                Symptom(
                    title: ["en-GB": title1en, "de-DE": title1de],
                    description: ["en-GB": description1en, "de-DE": description1de],
                    riskWeight: 1
                ),
                Symptom(
                    title: ["en-GB": title2],
                    description: ["en-GB": description2],
                    riskWeight: 0
                ),
            ],
            riskThreshold: 0.8,
            dateSelectionWindow: 14
        )
        
        let actual = try endpoint.parse(response)
        
        TS.assert(actual, equals: expected)
    }
}