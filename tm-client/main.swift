//
//  main.swift
//  tm-client
//
//  Created by FengXing on 3/30/15.
//  Copyright (c) 2015 annidy. All rights reserved.
//

import Foundation

var room:String?
var senderName:String?
var postText:String?
var listFlag:Bool = false

let pattern = "lm:s::"

func usage() {
    println("Example:")
    println("\t\(Process.arguments[0].lastPathComponent) -m 'swift' text ;Post text to the room swift")
    println("\t\(Process.arguments[0].lastPathComponent) -m 'swift' -l   ;List message in the room swift")
    println("\t\(Process.arguments[0].lastPathComponent) -m 'swift' -s 'jack' text   ;Post text with sender name jack")
    exit(1)
}
var buffer = Array(pattern.utf8).map { Int8($0) }

while true {
    let option = Int(getopt(C_ARGC, C_ARGV, buffer))

    if option == -1 {
        break
    }
    switch "\(UnicodeScalar(option))" {
        case "m":
            room = String.fromCString(optarg)!
        case "s":
            senderName = String.fromCString(optarg)!
        case "l":
            listFlag = true
        default:
            usage()
    }
    if C_ARGC > optind {
        var opt = String.fromCString(C_ARGV[Int(optind)])!
        if !(opt.hasPrefix("-")) {
            postText = opt
        }
    }
}

if room == nil {
    usage()
}

let tmRoom = TodaysMeetRoom(room!)
if senderName != nil {
    tmRoom.senderName = senderName!
}

if tmRoom.connectRoom() == false {
    exit(1)
}

if postText != nil {
    tmRoom.post(postText!)
}

if listFlag {
    if let messages = tmRoom.listMessages(0, maxMessage: 20) as [AnyObject]? {
        var sortedMessages = sorted(messages) { (s1: AnyObject, s2: AnyObject) -> Bool in
            var d1 = s1["created"] as String
            var d2 = s2["created"] as String
            return d1 > d2
        }
        for msg in sortedMessages as [AnyObject] {
            var created = msg["created"] as String
            var sender_name = msg["sender_name"] as String
            var message = msg["message"] as String
            println("\(created) \(sender_name): \(message)")
        }
    }
}