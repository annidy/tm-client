//
//  room.swift
//  tm-client
//
//  Created by FengXing on 3/30/15.
//  Copyright (c) 2015 annidy. All rights reserved.
//

import Foundation

class TodaysMeetRoom {
    var roomId = 0
    var roomName = ""
    var senderName: String

    
    init(_ room: NSString, sender aSender: String = "robot"){
        roomName = room
        senderName = aSender
    }
    
    func connectRoom() -> Bool {
        let url = NSURL(string:"https://todaysmeet.com/\(roomName)")!
        let request = NSURLRequest(URL: url)
        var respons: NSURLResponse?
        var error: NSError?
        var body = NSURLConnection.sendSynchronousRequest(request, returningResponse:&respons, error:&error)
        if body == nil {
            println("request \(url) failed. \(error)")
            return false
        }
        
        let bodyString = NSString(data:body!, encoding:NSUTF8StringEncoding)!
        let roomRange = bodyString.rangeOfString("data-room")
        if roomRange.length == 0 {
            println("not contain data-owner")
            return false
        }

        var scanner = NSScanner(string: bodyString)
        scanner.charactersToBeSkipped = NSCharacterSet(charactersInString: "=\"")
        
        if scanner.scanUpToString("data-room", intoString: nil) {
            var roomStr: NSString?
            if scanner.scanUpToCharactersFromSet(NSCharacterSet.newlineCharacterSet(), intoString: &roomStr) {
                scanner = NSScanner(string: roomStr!)
                scanner.charactersToBeSkipped = NSCharacterSet.decimalDigitCharacterSet().invertedSet
                while !scanner.atEnd {
                    if (scanner.scanInteger(&roomId)) {
                        return true
                    }
                }
            }
        }
        println("not found")
        return false
    }
    
    func post(text: String) -> Bool {
        if countElements(text) > 140 {
            println("too much words")
            return false
        }
        if roomId == 0 {
            println("not connect")
            return false
        }
        let url = NSURL(string: "https://todaysmeet.com/api/room/\(roomId)/post")!

        var csrftoken: NSString?
        if let cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookiesForURL(url) {
            for ck in cookies {
                if ck.name == "csrftoken" {
                    csrftoken = ck.value
                }
            }
        }
        if csrftoken == nil {
            println("inner error")
            return false
        }
        
        var postRequest = NSMutableURLRequest(URL: url)
        var body = String("csrfmiddlewaretoken=\(csrftoken!)&message=\(text)&sender_name=\(senderName)&room=\(roomId)")
        postRequest.HTTPMethod = "POST"
        postRequest.addValue("https://todaysmeet.com/\(roomId)", forHTTPHeaderField: "referer")
        postRequest.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        if let result = NSURLConnection.sendSynchronousRequest(postRequest, returningResponse: nil, error: nil) {
            println(NSString(data: result, encoding: NSUTF8StringEncoding))
        }
        return true
    }
    
    func listMessages(_ since: Int = 0, maxMessage aMax: Int = 40) -> AnyObject? {
        let url = NSURL(string: "https://todaysmeet.com/api/room/\(roomId)/messages?since=\(since)&max=\(aMax)")!
        let request = NSURLRequest(URL: url)
        var respons: NSURLResponse?
        var error: NSError?
        let body = NSURLConnection.sendSynchronousRequest(request, returningResponse:&respons, error:&error)
        if body == nil {
            println("request \(url) failed. \(error)")
            return nil
        }
        
        if let jsonValue = NSJSONSerialization.JSONObjectWithData(body!, options: NSJSONReadingOptions.MutableContainers, error: &error) as [String:AnyObject]? {
            return jsonValue["messages"]
        }

        println("bad json msg. \(error)")
        return nil
    }
}