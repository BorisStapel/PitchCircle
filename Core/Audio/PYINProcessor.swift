import Foundation
import Accelerate

struct PYINProcessor: Sendable {
    private let minHz: Float = 30.0
    private let maxHz: Float = 2000.0
    private let threshold: Float = 0.10
    
    nonisolated func getPitchCandidates(samples: [Float], sampleRate: Float) -> [(hz: Float, probability: Float)] {
        let n = samples.count
        let maxTau = Int(sampleRate / minHz)
        let minTau = Int(sampleRate / maxHz)
        if n < maxTau { return [] }
        
        var difference = [Float](repeating: 0, count: maxTau)
        for tau in 1..<maxTau {
            var diff: Float = 0
            let length = n - tau
            var subResult = [Float](repeating: 0, count: length)
            vDSP_vsub(samples, 1, Array(samples[tau..<n]), 1, &subResult, 1, vDSP_Length(length))
            vDSP_svesq(subResult, 1, &diff, vDSP_Length(length))
            difference[tau] = diff
        }
        
        var cmnd = [Float](repeating: 1, count: maxTau)
        var runningSum: Float = 0
        for tau in 1..<maxTau {
            runningSum += difference[tau]
            cmnd[tau] = difference[tau] / ((1/Float(tau)) * runningSum)
        }
        
        var candidates: [(hz: Float, probability: Float)] = []
        for tau in minTau..<maxTau - 1 {
            if cmnd[tau] < threshold {
                if cmnd[tau] < cmnd[tau - 1] && cmnd[tau] < cmnd[tau + 1] {
                    let alpha = cmnd[tau - 1]
                    let beta = cmnd[tau]
                    let gamma = cmnd[tau + 1]
                    let denominator = alpha - 2 * beta + gamma
                    let refinedTau: Float
                    if abs(denominator) > 1e-12 {
                        let offset = 0.5 * (alpha - gamma) / denominator
                        let clampedOffset = min(max(offset, -0.5), 0.5)
                        refinedTau = Float(tau) + clampedOffset
                    } else {
                        refinedTau = Float(tau)
                    }
                    candidates.append((hz: sampleRate / refinedTau, probability: 1.0 - beta))
                    break
                }
            }
        }
        return candidates
    }
}
