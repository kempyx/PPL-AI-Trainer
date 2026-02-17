import Foundation
import SwiftUI

enum XPSource: String, CaseIterable {
    case correctAnswer = "correct_answer"
    case incorrectAnswer = "incorrect_answer"
    case srsBonus = "srs_bonus"
    case streakBonus3 = "streak_bonus_3"
    case streakBonus5 = "streak_bonus_5"
    case streakBonus10 = "streak_bonus_10"
    case dailyGoalComplete = "daily_goal"
    case mockExamPass = "mock_exam_pass"
    
    var amount: Int {
        switch self {
        case .correctAnswer: return 10
        case .incorrectAnswer: return 3
        case .srsBonus: return 5
        case .streakBonus3: return 15
        case .streakBonus5: return 25
        case .streakBonus10: return 50
        case .dailyGoalComplete: return 50
        case .mockExamPass: return 100
        }
    }
}

struct PilotLevel {
    let title: String
    let minXP: Int
    let icon: String
    
    static let allLevels: [PilotLevel] = [
        PilotLevel(title: "Student Pilot", minXP: 0, icon: "airplane"),
        PilotLevel(title: "Solo Pilot", minXP: 500, icon: "airplane.circle"),
        PilotLevel(title: "Cross-Country", minXP: 2_000, icon: "map"),
        PilotLevel(title: "Instrument Rated", minXP: 5_000, icon: "cloud.fog"),
        PilotLevel(title: "Commercial", minXP: 10_000, icon: "building.2"),
        PilotLevel(title: "ATP", minXP: 25_000, icon: "star.circle.fill"),
    ]
    
    static func level(for xp: Int) -> PilotLevel {
        allLevels.last(where: { $0.minXP <= xp }) ?? allLevels[0]
    }
    
    static func nextLevel(for xp: Int) -> PilotLevel? {
        allLevels.first(where: { $0.minXP > xp })
    }
    
    static func progressToNext(xp: Int) -> Double {
        let current = level(for: xp)
        guard let next = nextLevel(for: xp) else { return 1.0 }
        return Double(xp - current.minXP) / Double(next.minXP - current.minXP)
    }
}

enum AchievementDefinition: String, CaseIterable {
    case firstSolo = "first_solo"
    case ironWill = "iron_will"
    case marathon = "marathon"
    case eagleEye = "eagle_eye"
    case perfectFlight = "perfect_flight"
    case mockMaster = "mock_master"
    case masteryAirLaw = "mastery_551"
    case masteryHumanPerformance = "mastery_552"
    case masteryMeteorology = "mastery_553"
    case masteryCommunications = "mastery_554"
    case masteryPrinciplesOfFlight = "mastery_555"
    case masteryOperationalProcedures = "mastery_556"
    case masteryMassBalance = "mastery_557"
    case masteryPerformance = "mastery_558"
    case masteryFlightPlanning = "mastery_559"
    case masteryAirframe = "mastery_560"
    case masteryInstrumentation = "mastery_528"
    case masteryGeneralNav = "mastery_501"
    case masteryRadioNav = "mastery_500"
    case nightOwl = "night_owl"
    case earlyBird = "early_bird"
    case comebackKid = "comeback_kid"
    case askTheInstructor = "ask_the_instructor"
    case memoryPalace = "memory_palace"
    
    var displayName: String {
        switch self {
        case .firstSolo: return "First Solo"
        case .ironWill: return "Iron Will"
        case .marathon: return "Marathon"
        case .eagleEye: return "Eagle Eye"
        case .perfectFlight: return "Perfect Flight"
        case .mockMaster: return "Mock Master"
        case .masteryAirLaw: return "Air Law Master"
        case .masteryHumanPerformance: return "Human Performance Master"
        case .masteryMeteorology: return "Meteorology Master"
        case .masteryCommunications: return "Communications Master"
        case .masteryPrinciplesOfFlight: return "Principles of Flight Master"
        case .masteryOperationalProcedures: return "Operational Procedures Master"
        case .masteryMassBalance: return "Mass & Balance Master"
        case .masteryPerformance: return "Performance Master"
        case .masteryFlightPlanning: return "Flight Planning Master"
        case .masteryAirframe: return "Airframe Master"
        case .masteryInstrumentation: return "Instrumentation Master"
        case .masteryGeneralNav: return "General Navigation Master"
        case .masteryRadioNav: return "Radio Navigation Master"
        case .nightOwl: return "Night Owl"
        case .earlyBird: return "Early Bird"
        case .comebackKid: return "Comeback Kid"
        case .askTheInstructor: return "Ask the Instructor"
        case .memoryPalace: return "Memory Palace"
        }
    }
    
    var description: String {
        switch self {
        case .firstSolo: return "Complete your first study session"
        case .ironWill: return "Maintain a 7-day study streak"
        case .marathon: return "Maintain a 30-day study streak"
        case .eagleEye: return "Answer 10 questions correctly in a row"
        case .perfectFlight: return "Complete a session with 20+ questions, all correct"
        case .mockMaster: return "Pass a mock exam"
        case .masteryAirLaw: return "Master all Air Law questions"
        case .masteryHumanPerformance: return "Master all Human Performance questions"
        case .masteryMeteorology: return "Master all Meteorology questions"
        case .masteryCommunications: return "Master all Communications questions"
        case .masteryPrinciplesOfFlight: return "Master all Principles of Flight questions"
        case .masteryOperationalProcedures: return "Master all Operational Procedures questions"
        case .masteryMassBalance: return "Master all Mass & Balance questions"
        case .masteryPerformance: return "Master all Performance questions"
        case .masteryFlightPlanning: return "Master all Flight Planning questions"
        case .masteryAirframe: return "Master all Airframe questions"
        case .masteryInstrumentation: return "Master all Instrumentation questions"
        case .masteryGeneralNav: return "Master all General Navigation questions"
        case .masteryRadioNav: return "Master all Radio Navigation questions"
        case .nightOwl: return "Study between 10 PM and 4 AM"
        case .earlyBird: return "Study between 4 AM and 7 AM"
        case .comebackKid: return "Master a question you got wrong 3+ times"
        case .askTheInstructor: return "Create 10 mnemonics"
        case .memoryPalace: return "Create 20 mnemonics"
        }
    }
    
    var icon: String {
        switch self {
        case .firstSolo: return "airplane.departure"
        case .ironWill: return "flame"
        case .marathon: return "figure.run"
        case .eagleEye: return "eye"
        case .perfectFlight: return "star.fill"
        case .mockMaster: return "checkmark.seal.fill"
        case .masteryAirLaw, .masteryHumanPerformance, .masteryMeteorology, .masteryCommunications,
             .masteryPrinciplesOfFlight, .masteryOperationalProcedures, .masteryMassBalance,
             .masteryPerformance, .masteryFlightPlanning, .masteryAirframe, .masteryInstrumentation,
             .masteryGeneralNav, .masteryRadioNav:
            return "graduationcap.fill"
        case .nightOwl: return "moon.stars.fill"
        case .earlyBird: return "sunrise.fill"
        case .comebackKid: return "arrow.uturn.up"
        case .askTheInstructor: return "lightbulb.fill"
        case .memoryPalace: return "brain.head.profile"
        }
    }
    
    static func masteryAchievement(for categoryId: Int64) -> AchievementDefinition? {
        AchievementDefinition(rawValue: "mastery_\(categoryId)")
    }
}
