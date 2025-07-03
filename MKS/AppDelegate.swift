//
//  AppDelegate.swift
//  MechKey
//
//  Created by Bogdan Ryabyshchuk on 9/5/18.
//  Copyright © 2018 Bogdan Ryabyshchuk. All rights reserved.
//

import Cocoa
import AVFoundation
import Darwin
import AppKit
import Foundation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: App Wide Variables and Settings
    
    // Player Arrays and Sound Profiles    
    var profile: Int = 0
    
    let soundFiles: [[Int: (String, String)]] = [[3: ("profile-1-mouse-down", "profile-1-mouse-up")],
                                                 [3: ("profile-2-mouse-down", "profile-2-mouse-up")],
                                                 [3: ("profile-3-mouse-down", "profile-3-mouse-up")]]
    
    var players: [Int: ([AVAudioPlayer?], [AVAudioPlayer?])] = [:]
    var playersCurrentPlayer: [Int: (Int, Int)] = [:]
    var playersMax: Int = 15
    
    // App Settings
    var volumeLevel:Float = 1.0
    var volumeMuted:Bool = false
    
    var stereoWidth:Float = 0.2
    var stereoWidthDefult:Float = 0.2
    
    var keyUpSound = true
    
    var keyRandomize = false
    
    var mouseEffects = true
    
    // Other Variables
    var menuItem:NSStatusItem? = nil
    
    // Debugging Messages
    var debugging = false
    
    // MARK: Start and Exit Functions
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Load Settings
        volumeLoad()
        stereoWidthLoad()
        profileLoad()
        keyUpSoundLoad()
        keyRandomizeLoad()
        volumeUpdate()
        mouseEffectsLoad()
        
        // Create the Menu
        menuCreate()
        
        // Check for Permissions
        checkPrivecyAccess()
        
        // Add Mouse Listeners
        loadMouseListeners()
    }
    
    // MARK: Event Listeners
    
    func loadMouseListeners() {
        NSEvent.addGlobalMonitorForEvents(matching: NSEvent.EventTypeMask.leftMouseDown, handler: { (event) -> Void in
            self.mousePressDown(event: event)
        })
        
        NSEvent.addGlobalMonitorForEvents(matching: NSEvent.EventTypeMask.leftMouseUp, handler: { (event) -> Void in
            self.mousePressUp(event: event)
        })
        
        NSEvent.addGlobalMonitorForEvents(matching: NSEvent.EventTypeMask.rightMouseDown, handler: { (event) -> Void in
            self.mousePressDown(event: event)
        })
        
        NSEvent.addGlobalMonitorForEvents(matching: NSEvent.EventTypeMask.rightMouseUp, handler: { (event) -> Void in
            self.mousePressUp(event: event)
        })
    }
    
    // MARK: Mouse Functions
    var mousePrevDown: NSDate = NSDate()
    var mousePrevUp: NSDate = NSDate()
    
    // Mouse Press Down Event Function
    func mousePressDown(event:NSEvent){
        if self.mouseEffects {
            let timeSinceLastMouseDownEvent = mousePrevDown.timeIntervalSinceNow
            mousePrevDown = NSDate()
            let prevEventTooClose: Bool = (timeSinceLastMouseDownEvent >= -0.045)
            if self.debugging {
                if prevEventTooClose {
                    systemMenuMessage(message: "Mouse - Too Close")
                } else {
                    systemMenuMessage(message: "Mouse - Ok")
                }
            }
            if !volumeMuted && !prevEventTooClose {
                playSoundForKey(key: 1000, keyIsDown: true)
            }
        }
    }
    
    // Mouse Press Up Event Function
    func mousePressUp(event:NSEvent){
        if self.mouseEffects {
            let timeSinceLastMouseUpEvent = mousePrevUp.timeIntervalSinceNow
            mousePrevUp = NSDate()
            let prevEventTooClose: Bool = (timeSinceLastMouseUpEvent >= -0.045)
            if self.debugging {
                if prevEventTooClose {
                    systemMenuMessage(message: "Mouse - Too Close")
                } else {
                    systemMenuMessage(message: "Mouse - Ok")
                }
            }
            if !volumeMuted && !prevEventTooClose {
                playSoundForKey(key: 1000, keyIsDown: false)
            }
        }
    }
    
    // MARK: Mouse Sound Function
    
    // The Map of All the Keys with Location and Sound to Play.
    // [key: [location, sound]]
    // The key is the numerical key, location is 0-10, 0 is left 10 is right, 5 is middle
    // Mouse clicks use key 1000 and sound type 3
    
    let keyMap: [Int: Array<Int>] =  [1000:  [5,3]] // Mouse Key only
    
    // Load an Array of Sound Players
    
    func loadSounds() {
        for (sound, files) in soundFiles[self.profile] {
            var downFiles: [AVAudioPlayer?] = []
            if let soundURL = Bundle.main.url(forResource: files.0, withExtension: "wav"){
                for _ in 0...self.playersMax {
                    do {
                        try downFiles.append( AVAudioPlayer(contentsOf: soundURL) )
                    } catch {
                        print("Failed to load \(files.0)")
                    }
                }
            }else{
                print("Can't Find Sound Files \(files.0)")
            }
            var upFiles: [AVAudioPlayer?] = []
            if let soundURL = Bundle.main.url(forResource: files.1, withExtension: "wav"){
                for _ in 0...self.playersMax {
                    do {
                        try upFiles.append( AVAudioPlayer(contentsOf: soundURL) )
                    } catch {
                        print("Failed to load \(files.1)")
                    }
                }
            }else{
                print("Can't Find Sound Files \(files.1)")
            }
            
            self.players[sound] = (downFiles, upFiles)
            self.playersCurrentPlayer[sound] = (0, 0)
        }
        
        // Set the Sound Level to the Settings Level
        volumeUpdate()
    }
    
    func playSoundForKey(key: Int, keyIsDown down: Bool){
        
        var keyLocation: Float = 0
        var keySound: Int = 0
        
        if let keySetings = keyMap[key] {
            keyLocation = (Float(keySetings[0]) - 5) / 5 * self.stereoWidth
            keySound = keySetings[1]
        }
        
        func play(player: AVAudioPlayer, keyLocation: Float){
            if !player.isPlaying {
                // Randomize pitch and Sound.
                if self.keyRandomize {
                    // Randomize Pitch
                    player.enableRate = true
                    player.rate = Float.random(in: 0.9 ... 1.1 )
                    
                    // Randomize Volume
                    player.volume = self.volumeLevel * Float.random(in: 0.95 ... 1.0 )
                }
                
                // Set the Location of the Mouse Click and Play the sound
                player.pan = keyLocation
                player.play()
            }
        }
        
        if down {
            if let player = self.players[keySound]?.0[(self.playersCurrentPlayer[keySound]?.0)!]{
                play(player: player, keyLocation: keyLocation)
            }
            self.playersCurrentPlayer[keySound]?.0 += 1
            if (self.playersCurrentPlayer[keySound]?.0)! >= self.playersMax {
                self.playersCurrentPlayer[keySound]?.0 = 0
            }
        } else if self.keyUpSound {
            if let player = self.players[keySound]?.1[(self.playersCurrentPlayer[keySound]?.1)!]{
                play(player: player, keyLocation: keyLocation)
            }
            self.playersCurrentPlayer[keySound]?.1 += 1
            if (self.playersCurrentPlayer[keySound]?.1)! >= self.playersMax {
                self.playersCurrentPlayer[keySound]?.1 = 0
            }
        }
    }
    
    // MARK: System Menu Setup
    let menuItemVolumeMute = NSMenuItem(title: "Mute Mouse Clicks", action: #selector(menuSetVolMute), keyEquivalent: "")
    let menuItemVolume10 = NSMenuItem(title: "10% Volume", action: #selector(menuSetVol0), keyEquivalent: "")
    let menuItemVolume25 = NSMenuItem(title: "25% Volume", action: #selector(menuSetVol1), keyEquivalent: "")
    let menuItemVolume50 = NSMenuItem(title: "50% Volume", action: #selector(menuSetVol2), keyEquivalent: "")
    let menuItemVolume75 = NSMenuItem(title: "75% Volume", action: #selector(menuSetVol3), keyEquivalent: "")
    let menuItemVolume100 = NSMenuItem(title: "100% Volume", action: #selector(menuSetVol4), keyEquivalent: "")
    let menuItemSoundStereo = NSMenuItem(title: "Stereo Sound", action: #selector(menuStereo), keyEquivalent: "")
    let menuItemSoundMono = NSMenuItem(title: "Mono Sound", action: #selector(menuMono), keyEquivalent: "")
    
    let menuItemKeyUpOn = NSMenuItem(title: "Mouse Up Sound On", action: #selector(menuKeyupSoundOn), keyEquivalent: "")
    let menuItemKeyUpOff = NSMenuItem(title: "Mouse Up Sound Off", action: #selector(menuKeyupSoundOff), keyEquivalent: "")
    
    let menuItemRandomizeOn = NSMenuItem(title: "Randomize Pitch On", action: #selector(menuRandomizeOn), keyEquivalent: "")
    let menuItemRandomizeOff = NSMenuItem(title: "Randomize Pitch Off", action: #selector(menuRandomizeOff), keyEquivalent: "")
    
    let menuItemProfile0 = NSMenuItem(title: "Profile 1", action: #selector(menuProfile0), keyEquivalent: "")
    let menuItemProfile1 = NSMenuItem(title: "Profile 2", action: #selector(menuProfile1), keyEquivalent: "")
    let menuItemProfile2 = NSMenuItem(title: "Profile 3", action: #selector(menuProfile2), keyEquivalent: "")
    
    let menuItemMouseEffectsOn = NSMenuItem(title: "Mouse Effects On", action: #selector(menuMouseEffectsOn), keyEquivalent: "")
    let menuItemMouseEffectsOff = NSMenuItem(title: "Mouse Effects Off", action: #selector(menuMouseEffectsOff), keyEquivalent: "")
    
    let menuItemAbout = NSMenuItem(title: "About MKS", action: #selector(menuAbout), keyEquivalent: "")
    let menuItemQuit = NSMenuItem(title: "Quit", action: #selector(menuQuit), keyEquivalent: "")
    
    func menuCreate(){
        self.menuItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        self.menuItem?.highlightMode = true

        if let imgURL = Bundle.main.url(forResource: "sysmenuicon", withExtension: "png"){
            let image = NSImage(byReferencing: imgURL)
            image.isTemplate = true
            image.size.width = 18
            image.size.height = 18
            self.menuItem?.image = image
        } else {
            self.menuItem?.title = "MechKey"
        }
        
        let menu = NSMenu()
        menu.addItem(self.menuItemVolumeMute)
        menu.addItem(self.menuItemVolume10)
        menu.addItem(self.menuItemVolume25)
        menu.addItem(self.menuItemVolume50)
        menu.addItem(self.menuItemVolume75)
        menu.addItem(self.menuItemVolume100)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(self.menuItemSoundStereo)
        menu.addItem(self.menuItemSoundMono)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(self.menuItemKeyUpOn)
        menu.addItem(self.menuItemKeyUpOff)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(self.menuItemRandomizeOn)
        menu.addItem(self.menuItemRandomizeOff)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(self.menuItemProfile0)
        menu.addItem(self.menuItemProfile1)
        menu.addItem(self.menuItemProfile2)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(self.menuItemMouseEffectsOn)
        menu.addItem(self.menuItemMouseEffectsOff)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(self.menuItemAbout)
        menu.addItem(self.menuItemQuit)
        
        self.menuItem?.menu = menu
    }
    
    @objc func menuSetVolMute(){
        volumeSet(vol: self.volumeLevel, muted: true)
    }
    
    @objc func menuSetVol0(){
        volumeSet(vol: 0.10, muted: false)
    }
    
    @objc func menuSetVol1(){
        volumeSet(vol: 0.25, muted: false)
    }
    
    @objc func menuSetVol2(){
        volumeSet(vol: 0.50, muted: false)
    }
    
    @objc func menuSetVol3(){
        volumeSet(vol: 0.75, muted: false)
    }
    
    @objc func menuSetVol4(){
        volumeSet(vol: 1.00, muted: false)
    }
    
    @objc func menuStereo(){
        stereoWidthSet(width: self.stereoWidthDefult)
    }
    
    @objc func menuMono(){
        stereoWidthSet(width: 0)
    }
    
    @objc func menuKeyupSoundOn(){
        keyUpSoundSet(on: true)
    }
    
    @objc func menuKeyupSoundOff(){
        keyUpSoundSet(on: false)
    }
    
    @objc func menuRandomizeOn(){
        keyRandomizeSet(on: true)
    }
    
    @objc func menuRandomizeOff(){
        keyRandomizeSet(on: false)
    }
    
    @objc func menuProfile0(){
        profileSet(profile: 0)
    }
    
    @objc func menuProfile1(){
        profileSet(profile: 1)
    }
    
    @objc func menuProfile2(){
        profileSet(profile: 2)
    }
    
    @objc func menuMouseEffectsOn(){
        mouseEffectsSet(on: true)
    }
    
    @objc func menuMouseEffectsOff(){
        mouseEffectsSet(on: false)
    }
    
    @objc func menuAbout(){
        NSWorkspace.shared.open(NSURL(string: "http://www.zynath.com/MKS")! as URL)
    }
    
    @objc func menuQuit(){
        NSApp.terminate(nil)
    }
    
    // MARK: Volume Settings
    func volumeLoad(){
        if UserDefaults.standard.object(forKey: "VolumeLevel") != nil {
            self.volumeLevel = UserDefaults.standard.float(forKey: "VolumeLevel")
        }
        if UserDefaults.standard.object(forKey: "VolumeMuted") != nil {
            self.volumeMuted = UserDefaults.standard.bool(forKey: "VolumeMuted")
        }
    }
    
    func volumeSave(){
        UserDefaults.standard.set(self.volumeLevel, forKey: "VolumeLevel")
        UserDefaults.standard.set(self.volumeMuted, forKey: "VolumeMuted")
        UserDefaults.standard.synchronize()
    }
    
    func volumeSet(vol: Float, muted: Bool){
        self.volumeMuted = muted
        self.volumeLevel = vol
        
        volumeUpdate()
        volumeSave()
        playSoundForKey(key: 0, keyIsDown: true)
    }
    
    func volumeUpdate(){
        for (_, players) in self.players{
            for player in players.0 {
                player?.volume = self.volumeLevel
                player?.enableRate = false
                player?.rate = 1
            }
            for player in players.1 {
                player?.volume = self.volumeLevel
                player?.enableRate = false
                player?.rate = 1
            }
        }
        
        // Update Menu to Match the Setting
        self.menuItemVolumeMute.state = NSControl.StateValue.off
        self.menuItemVolume10.state = NSControl.StateValue.off
        self.menuItemVolume25.state = NSControl.StateValue.off
        self.menuItemVolume50.state = NSControl.StateValue.off
        self.menuItemVolume75.state = NSControl.StateValue.off
        self.menuItemVolume100.state = NSControl.StateValue.off
        
        if self.volumeMuted {
            self.menuItemVolumeMute.state = NSControl.StateValue.on
        } else if self.volumeLevel == 0.10 {
            self.menuItemVolume10.state = NSControl.StateValue.on
        } else if self.volumeLevel == 0.25 {
            self.menuItemVolume25.state = NSControl.StateValue.on
        } else if self.volumeLevel == 0.50 {
            self.menuItemVolume50.state = NSControl.StateValue.on
        } else if self.volumeLevel == 0.75 {
            self.menuItemVolume75.state = NSControl.StateValue.on
        } else if self.volumeLevel == 1 {
            self.menuItemVolume100.state = NSControl.StateValue.on
        }
    }
    
    // MARK: Stereo Settings
    
    func stereoWidthLoad(){
        
        if UserDefaults.standard.object(forKey: "stereoWidth") != nil {
            self.stereoWidth = UserDefaults.standard.float(forKey: "stereoWidth")
        }
        stereoWidthUpdate()
    }
    
    func stereoWidthSet(width: Float){
        self.stereoWidth = width
        UserDefaults.standard.set(self.stereoWidth, forKey: "stereoWidth")
        UserDefaults.standard.synchronize()
        stereoWidthUpdate()
    }
    
    func stereoWidthUpdate(){
        if self.stereoWidth == 0 {
            menuItemSoundMono.state = NSControl.StateValue.on
            menuItemSoundStereo.state = NSControl.StateValue.off
        } else {
            menuItemSoundMono.state = NSControl.StateValue.off
            menuItemSoundStereo.state = NSControl.StateValue.on
        }
    }
    
    // MARK: Mouse Up Sound Settings
    
    func keyUpSoundLoad() {
        if UserDefaults.standard.object(forKey: "keyUpSound") != nil {
            self.keyUpSound = UserDefaults.standard.bool(forKey: "keyUpSound")
        }
        keyUpSoundUpdate()
    }
    
    func keyUpSoundSet(on: Bool) {
        self.keyUpSound = on
        UserDefaults.standard.set(self.keyUpSound, forKey: "keyUpSound")
        UserDefaults.standard.synchronize()
        keyUpSoundUpdate()
    }
    
    func keyUpSoundUpdate() {
        if self.keyUpSound {
            menuItemKeyUpOn.state = NSControl.StateValue.on
            menuItemKeyUpOff.state = NSControl.StateValue.off
        } else {
            menuItemKeyUpOn.state = NSControl.StateValue.off
            menuItemKeyUpOff.state = NSControl.StateValue.on
        }
    }
    
    // MARK: Mouse Effect Settings
    
    func mouseEffectsLoad() {
        if UserDefaults.standard.object(forKey: "mouseEffects") != nil {
            self.mouseEffects = UserDefaults.standard.bool(forKey: "mouseEffects")
        }
        mouseEffectsUpdate()
    }
    
    func mouseEffectsSet(on: Bool) {
        self.mouseEffects = on
        UserDefaults.standard.set(self.mouseEffects, forKey: "mouseEffects")
        UserDefaults.standard.synchronize()
        mouseEffectsUpdate()
    }
    
    func mouseEffectsUpdate() {
        if self.mouseEffects {
            menuItemMouseEffectsOn.state = NSControl.StateValue.on
            menuItemMouseEffectsOff.state = NSControl.StateValue.off
        } else {
            menuItemMouseEffectsOn.state = NSControl.StateValue.off
            menuItemMouseEffectsOff.state = NSControl.StateValue.on
        }
    }
    
    // MARK: Randomize Sound Setting
    
    func keyRandomizeLoad() {
        if UserDefaults.standard.object(forKey: "keyRandomize") != nil {
            self.keyRandomize = UserDefaults.standard.bool(forKey: "keyRandomize")
        }
        keyRandomizeUpdate()
    }
    
    func keyRandomizeSet(on: Bool) {
        self.keyRandomize = on
        UserDefaults.standard.set(self.keyRandomize, forKey: "keyRandomize")
        UserDefaults.standard.synchronize()
        keyRandomizeUpdate()
    }
    
    func keyRandomizeUpdate() {
        if self.keyRandomize {
            menuItemRandomizeOn.state = NSControl.StateValue.on
            menuItemRandomizeOff.state = NSControl.StateValue.off
        } else {
            menuItemRandomizeOn.state = NSControl.StateValue.off
            menuItemRandomizeOff.state = NSControl.StateValue.on
            // Update the preset Volume and Rates
            volumeUpdate()
        }
    }
    
    // MARK: Profile Settings
    
    func profileLoad(){
        if UserDefaults.standard.object(forKey: "profile") != nil {
            self.profile = UserDefaults.standard.integer(forKey: "profile")
        }
        profileUpdate()
    }
    func profileSet(profile: Int) {
        self.profile = profile
        UserDefaults.standard.set(self.profile, forKey: "profile")
        UserDefaults.standard.synchronize()
        profileUpdate()
    }
    func profileUpdate(){
        self.players = [:]
        self.playersCurrentPlayer = [:]
        loadSounds()
        
        self.menuItemProfile0.state = NSControl.StateValue.off
        self.menuItemProfile1.state = NSControl.StateValue.off
        self.menuItemProfile2.state = NSControl.StateValue.off
        
        if self.profile == 0 {
            self.menuItemProfile0.state = NSControl.StateValue.on
        } else if self.profile == 1 {
            self.menuItemProfile1.state = NSControl.StateValue.on
        } else if self.profile == 2 {
            self.menuItemProfile2.state = NSControl.StateValue.on
        }
    }
    
    // MARK: Permissions Request
    func checkPrivecyAccess(){
        //get the value for accesibility
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        //set the options: false means it wont ask
        //true means it will popup and ask
        let options = [checkOptPrompt: true]
        //translate into boolean value
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary?)
        
        if !accessEnabled {
            let alert = NSAlert()
            alert.messageText = "MKS Needs Permissions"
            alert.informativeText = "macOS is awesome at protecting your privacy! However, as a result, in order for MKS to work, you will need to add it to the list of apps that are allowed to control your computer. That's the only way MKS can know when you press a key to play that sweet mechanical keyboard sound :) To add MKS to the list of trusted apps do the following: \n\nOpen System Preferences > Security & Privacy > Privacy > Accessibility, click on the Padlock in the bottom lefthand corner, and drag the MKS app into the list. \n\nHitting OK will close MKS. After you have done this, restart the app."
            alert.runModal()
            NSApp.terminate(nil)
        }
    }
    
    // MARK: Debugging Functions
    
    func systemMenuMessage(message: String){
        if self.debugging {
            self.menuItem?.title = message
        }
    }
}







