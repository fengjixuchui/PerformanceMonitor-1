//
//  PerformanceMonitor.swift
//  PerformanceMonitor
//
//  Created by roy.cao on 2019/8/24.
//  Copyright © 2019 roy. All rights reserved.
//

import UIKit

public class PerformanceMonitor {
    
    public static let `default` = PerformanceMonitor()

    private let performanceView = PerformanceView()
    
    public struct DisplayOptions: OptionSet {
        public let rawValue: Int

        public static let cpu = DisplayOptions(rawValue: 1 << 0)

        public static let memory = DisplayOptions(rawValue: 1 << 1)

        public static let fps = DisplayOptions(rawValue: 1 << 2)

        public static let caton = DisplayOptions(rawValue: 1 << 3)
        
        public static let all: DisplayOptions = [.cpu, .memory, .fps, .caton]
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
    
    private var monitoringTimer: DispatchSourceTimer?
    private var displayOptions: DisplayOptions = .all
    private var fpsMonitor: FPSMonitor?
    private var catonMonitor: CatonMonitor?

    public init(displayOptions: DisplayOptions = .all) {
        self.displayOptions = displayOptions
        if displayOptions.contains(.fps) {
            fpsMonitor = FPSMonitor()
            fpsMonitor?.delegate = self
        }

        if displayOptions.contains(.caton) {
            catonMonitor = CatonMonitor()
            catonMonitor?.start()
        }
    }

    public func start() {
        performanceView.isHidden = false

        monitoringTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global())
        monitoringTimer?.schedule(deadline: .now(), repeating: 1)
        monitoringTimer?.setEventHandler(handler: { [weak self] in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }
                var string = ""
                if strongSelf.displayOptions.contains(.cpu) {
                    let cpu = String.init(format: "%.1f", CPUMonitor.usage())
                    string += "CPU: \(cpu)% \n"
                }

                if strongSelf.displayOptions.contains(.memory) {
                    let memory = String.init(format: "%.1f", MemoryMonitor.usage())
                    string += "Memory: \(memory) MB \n"
                }

                strongSelf.performanceView.configureTitle(string)
            }
        })
        monitoringTimer?.resume()
    }
    
    public func stop() {
        performanceView.isHidden = true
        monitoringTimer?.cancel()
    }
    
    public func pause() {
        monitoringTimer?.suspend()
    }
    
    public func resume() {
        monitoringTimer?.resume()
    }
    
    deinit {
        monitoringTimer?.cancel()
    }
}

extension PerformanceMonitor: FPSMonitorDelegate {

    public func fpsMonitor(with monitor: FPSMonitor, fps: Double) {
        DispatchQueue.main.async {
            self.performanceView.configureFPS(fps)
        }
    }
}
