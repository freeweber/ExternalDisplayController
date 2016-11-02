//
//  AppDelegate.swift
//  ExternalDisplayController
//
//  Created by Georg on 23.10.16.
//  Copyright © 2016 -. All rights reserved.
//

import Cocoa
import ORSSerial


@NSApplicationMain
class AppDelegate: NSObject, ORSSerialPortDelegate, NSApplicationDelegate {
    /**
     *  Called when a serial port is removed from the system, e.g. the user unplugs
     *  the USB to serial adapter for the port.
     *
     *	In this method, you should discard any strong references you have maintained for the
     *  passed in `serialPort` object. The behavior of `ORSSerialPort` instances whose underlying
     *  serial port has been removed from the system is undefined.
     *
     *  @param serialPort The `ORSSerialPort` instance representing the port that was removed.
     */
    public func serialPortWasRemoved(fromSystem serialPort: ORSSerialPort) {
        self.port = nil
    }
    public func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
        /*if let string = "Test" { // NSString(data, ) {
           print("\(string)")
        }*/
        NSLog("Got Data")
    }

    
    public func serialPort(_ serialPort: ORSSerialPort, didEncounterError error: Error) {
        NSLog("Serial port (\(serialPort)) encountered error: \(error)")
    }
    public func serialPortWasRemovedFromSystem(fromSystem serialPort: ORSSerialPort) {
        self.port = nil
    }
    public func serialPortWasOpened(fromSystem serialPort: ORSSerialPort) {
        NSLog("Serial port \(serialPort) was opened")
    }



    let statusItem = NSStatusBar.system().statusItem(withLength: -2)
    var port = ORSSerialPort(path: "")
    var slider = NSSlider(value: 0.5, minValue: 0.0, maxValue: 1.0, target: self, action:#selector(sliderChanged))

    @IBOutlet weak var window: NSWindow!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        // Insert code here to initialize your application
        // Search in /dev/ for tty.usbmodem* devices
        let fManager = FileManager()
        let tmpDir = "/dev/"
        var devModem: [String] = []
        do {
            let devList = try fManager.contentsOfDirectory(atPath: tmpDir)
            for file in devList {
                if(file.contains("tty.usbmodem")) {
                    NSLog(String(file))
                    devModem.append(file)
                }
            }
        }
        catch
        {
            NSLog("Error parsing /dev/")
        }
        
        // Monitor USB found -> Connect to it.
        if(devModem.count > 0) {
            port = ORSSerialPort(path: "/dev/" + devModem[0])
            NSLog("Connected to /dev/" + devModem[0])
            port!.baudRate = 115200
        }
        else {
        // No Monitor found -> Error window
            dialogExit(question: "Connection Failed", text: "Could not connect to monitor")
            exit(0)
        }
        
        let mainDisplay = CGMainDisplayID()
        if(CGDisplayIsActive(mainDisplay) == 0) { //  == 1
            NSLog("Display is asleep")
        }
        else {
            NSLog("Display is on")
        }
        // Create Menubar Button
        if let button = statusItem.button {
            button.image = NSImage(named: "StatusBarButtonImage")
            button.action = Selector("terminate:")
        }
        
        // Create MenuBar with entries
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Turn Display On", action: #selector(displayOn), keyEquivalent: "O"))
        menu.addItem(NSMenuItem(title: "Turn Display Off", action: #selector(displayOff), keyEquivalent: "F"))
        let menuItem = NSMenuItem(title: "Brightness", action: nil, keyEquivalent: "B")

        // Adjust Slider size to fill the whole bar
        slider.frame = NSRect(x: 0.0, y: 0.0, width: menu.size.width, height: menu.size.height/2.0)

        menuItem.view = slider
        menu.addItem(menuItem)
        
        // Quit Button
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: Selector("terminate:"), keyEquivalent: "q"))

        statusItem.menu = menu
    }
    
    func dialogExit(question: String, text: String) {
        // Error Dialog PopUp
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = question
        myPopup.informativeText = text
        myPopup.alertStyle = NSAlertStyle.critical
        myPopup.addButton(withTitle: "Exit")
        return
    }
    
    func applicationWillTerminate( aNotification: Notification) {
        // Insert code here to tear down your application
        if(self.port!.isOpen){
            self.port!.close()
            self.port = nil
        }
    }
    
    func sliderChanged() {
        
        NSLog(slider.stringValue)
        let value = slider.floatValue
        let commandValue = (1.0-value) * 940.0 + 10.0
        NSLog("Slider changed called")
        var command = "set brightness="
        command += String(Int(commandValue))
        command += "\r\n"
        NSLog(command)
        sendCommand(sendCmd: command)
    }
    
    func displayOn() {
        let command = "control bl on\r\n"
        sendCommand(sendCmd: command)
    }
    
    func displayOff() {
        let command = "control bl off\r\n"
        sendCommand(sendCmd: command)
    }
    
    func sendCommand(sendCmd: String) {
        let data = sendCmd.data(using: .ascii)
        if(!self.port!.isOpen) {
            self.port!.open()
        }
        self.port!.send(data!)
        // Close port after 10ms
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10), execute: {
            // Put your code which should be executed with a delay here
            self.port?.close()
        })
    }


}

