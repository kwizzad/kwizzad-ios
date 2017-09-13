//
//  PlacementTests.swift
//  KwizzadSDK
//
//  Created by Fares Ben Hamouda on 19.05.17.
//  Copyright © 2017 Kwizzad. All rights reserved.
//

import XCTest
import KwizzadSDK

class PlacementTests: XCTestCase , KwizzadSDKDelegate {

    var mockedUserData : [String : String]!
    var placementOptions : [String : Any]?
    
    let incentiveText = "Earn up to 5 spears and up to 20 flintstones with a quiz!";
    
    var mockedRewards : [[String : Any]]!
    var mockedAdResponse : AdResponseEvent?
    var mockedOpenTransactions : [[String : Any]]?
    var mockedOpenTransactionsResponse : [String : Any]?

    let placementId = "tvsa"
    
    var kwizzadController : UIViewController?
    let kwizzad = KwizzadSDK.instance
    
    var expectOnAdAvailable = XCTestExpectation()
    var expectOnAdReady = XCTestExpectation()
    
    var testRequestWithInvalidAdStatePerformed = false
    
    override func setUp()
    {
        super.setUp()
        
        mockedUserData = ["id" : "12345" , "gender" : "female" , "name" : "Stefanie Müller" , "facebookUserId" : "777" ]
        placementOptions = ["baseUrl" : "https://api.example.com" , "apiKey" : "abc123" , "placementId" : "tvsa" , "installId" : "aabbccdd-aabb-ccdd-eeff-112233445566"]
        
        mockedRewards = [["type":"call2ActionStarted","amount":5,"currency":"smiles"],["type":"callback","amount":0,"currency":"smiles"]]
        
        mockedAdResponse = AdResponseEvent(["adType" : "adFullscreen" , "url" : "http://komet.example.com" ,"closeButtonVisibility" : "BEFORE_CALL2ACTION" , "kometArchiveUrl" : "https://labs.tvsmiles.tv/versions/2016-11-24-11.43.32.077-abc.tar.gz" , "rewards" : mockedRewards! , "placementId" : "tvsa" , "type" : "adResponse" , "adId" : "xyz" ])
        
        mockedOpenTransactions = [["adId" : "adId2", "transactionId": 4712, "conversionTimestamp": "2016-04-24T16:00:00Z", "reward": mockedRewards![0]] , ["adId" : "adId1", "transactionId": 4711, "conversionTimestamp": "2016-04-24T16:00:00Z", "reward": mockedRewards![1]]]
        
        mockedOpenTransactionsResponse = [ "transactions" : mockedOpenTransactions! , "type" : "openTransactions"]
        
        KwizzadSDK.setup(configuration :
            Configuration(
                apiKey: "b7220655bd54399edac9d9c6962f521d7c1cfed0f168e908a37ce4b2b6c7bcd2",
                overrideServer: "https://labs.tvsmiles.tv/api/sdk/",
                debug: true)
        )
        
        kwizzad.delegate = self
    }
    
    func testInitState() {
        XCTAssert(kwizzad.placementModel(placementId: placementId).adState == .INITIAL)
    }
    
//    func testRequestWithInvalidState() {
//        testRequestWithInvalidAdStatePerformed = true
//        kwizzad.placementModel(placementId: placementId).adState = AdState.NOFILL
//        kwizzad.requestAd(placementId: placementId)
//    }
//    
    func testRequestAd() {
        kwizzad.placementModel(placementId: placementId).adState = AdState.INITIAL
        kwizzad.requestAd(placementId: placementId)
        
        expectOnAdAvailable = expectation(description: "Waiting for callback OnAdAvailable to be called")

        // expect OnAdAvailable callback in a 5 sec range
        waitForExpectations(timeout: 5) { error in
            if error != nil {
                XCTFail("timout (5 sec) when waiting for receive onAdAvailable")
            }
        }
    }
    
    func testCanShowAd () {
        if (kwizzad.placementModel(placementId: placementId).adState == .AD_READY) {
            XCTAssert( kwizzad.canShowAd(placementId: placementId), "Ad is ready and can be shown")
        } else {
            XCTAssert( !kwizzad.canShowAd(placementId: placementId), "Ad is not ready / Different state")
        }

    }
    
    func testStartAd() {
        expectOnAdReady = expectation(description: "Waiting for callback OnAdReady to be called")

        // expect OnAdReady callback in a 5 sec range
        waitForExpectations(timeout: 5) { error in
            if error != nil {
                XCTFail("timout (5 sec) when waiting for receive OnAdReady")
            }
        }
    }
    
    func testClosePlacement() {
        let currentAdState = kwizzad.placementModel(placementId: placementId).adState ;
        if ( currentAdState != .INITIAL) {
            kwizzad.close(placementId)
            XCTAssertEqual(kwizzad.placementModel(placementId: placementId).adState , AdState.DISMISSED)
        }
    }
    
    func testOpenTransactionModel () {
        let openTransactions = OpenTransactionsEvent.init(mockedOpenTransactionsResponse!)
        
        let transaction = openTransactions.transactions
        XCTAssert(transaction?[0].adId == mockedOpenTransactions![0]["adId"] as? String)
        XCTAssert(transaction?[0].conversionTimestamp == mockedOpenTransactions![0]["conversionTimestamp"] as? String)
        XCTAssert(transaction?[0].transactionId == (mockedOpenTransactions![0]["transactionId"] as? NSNumber)?.stringValue)
        
        XCTAssert(transaction?[1].adId == mockedOpenTransactions![1]["adId"] as? String)
        XCTAssert(transaction?[1].conversionTimestamp == mockedOpenTransactions![1]["conversionTimestamp"] as? String)
        XCTAssert(transaction?[1].transactionId == (mockedOpenTransactions![1]["transactionId"] as? NSNumber)?.stringValue)
    }
    
    func testRewardModel () {
        let firstReward = Reward.init((mockedRewards?[0])!)
        XCTAssert(firstReward.amount == mockedRewards![0]["amount"] as? NSNumber)
        XCTAssert(firstReward.currency == mockedRewards![0]["currency"] as? String)
        XCTAssert(firstReward.maxAmount == mockedRewards![0]["maxAmount"] as? NSNumber)
        XCTAssert(firstReward.type == mockedRewards![0]["type"] as? String)
        
        let secondReward = Reward.init((mockedRewards?[1])!)
        XCTAssert(secondReward.amount == mockedRewards![1]["amount"] as? NSNumber)
        XCTAssert(secondReward.currency == mockedRewards![1]["currency"] as? String)
        XCTAssert(secondReward.maxAmount == mockedRewards![1]["maxAmount"] as? NSNumber)
        XCTAssert(secondReward.type == mockedRewards![1]["type"] as? String)
    }
    
    func testLocalization() {
        let reward = Reward.init((mockedRewards?[0])!)

        let confirmationText = Reward.confirmationText(rewards: [reward])
        
        XCTAssert("Herzlichen Glückwunsch zu 5 smiles!".localizedCompare(confirmationText) == .orderedSame)
    }

    /////////////////////////////////////////////////////////////////////
    //                                                                 //
    //  The following delegate methods are called by the Kwizzad SDK.  //
    //                                                                 //
    /////////////////////////////////////////////////////////////////////
    
    func kwizzadDidRequestAd(placementId: String) {

        XCTAssertEqual(kwizzad.placementModel(placementId: self.placementId).adState, AdState.REQUESTING_AD)
        let userData = self.kwizzad.userDataModel;

        userData.userId = mockedUserData["id"]!
        userData.gender = Gender.Female
        userData.userName = mockedUserData["name"]!
        userData.facebookUserId = mockedUserData["facebookUserId"]!

        // AdRequest Should include userData and custom params
        let adRequest = AdRequestEvent(placementId: placementId)
        
        var adRequestProperties = [String: Any]()
        adRequest.toDict(&adRequestProperties)
        
        // Verify UserData
        var adRequestUserData = adRequestProperties["userData"] as! [String : Any]
        
        XCTAssertEqual(adRequestUserData["gender"] as! String, kwizzad.userDataModel.gender.description)
        XCTAssertEqual(adRequestUserData["userName"] as! String, kwizzad.userDataModel.userName)
        XCTAssertEqual(adRequestUserData["facebookUserId"] as! String, kwizzad.userDataModel.facebookUserId)
        XCTAssertEqual(adRequestUserData["userId"] as! String, kwizzad.userDataModel.userId)
        
    }
    
    func kwizzadOnAdAvailable(placementId: String, potentialRewards: [Reward], adResponse: AdResponseEvent) {
        // State should be RECEIVED_AD at this stage
        XCTAssertEqual(self.kwizzad.placementModel(placementId: self.placementId).adState, AdState.RECEIVED_AD)

        let myCustomParameters : [String:Any] = [:]; // Optionally, you can supply custom parameters for special use cases here.
        self.kwizzadController = self.kwizzad.loadAd(placementId: self.placementId, customParameters: myCustomParameters)
        
        
        // Ensure kwizzadController not nil.
        XCTAssert(self.kwizzadController != nil)
        
        // Expiry date should be bigger than current date.
        XCTAssert((adResponse.expiry)! > Date())
        
        // Test adResponse properties
        XCTAssertEqual(adResponse.type, self.mockedAdResponse?.type)
        XCTAssertEqual(adResponse.placementId, self.mockedAdResponse?.placementId)

        expectOnAdAvailable.fulfill()
    }
    
    func kwizzadOnAdReady(placementId: String) {
        XCTAssertEqual(self.kwizzad.placementModel(placementId: self.placementId).adState, AdState.AD_READY)
        expectOnAdReady.fulfill()
    }
    
    func kwizzadDidShowAd(placementId: String) {
        XCTAssertEqual(self.kwizzad.placementModel(placementId: self.placementId).adState, AdState.SHOWING_AD)
    }
    
    func kwizzadDidDismissAd(placementId: String) {
        XCTAssertEqual(self.kwizzad.placementModel(placementId: self.placementId).adState, AdState.DISMISSED)
    }

    func kwizzadGotOpenTransactions(openTransactions: Set<OpenTransaction>) {
        
    }
    
    func kwizzadOnNoFill(placementId: String) {
        XCTAssertEqual(self.kwizzad.placementModel(placementId: self.placementId).adState, AdState.NOFILL)
    }
    
    // optional
    func kwizzadOnErrorOccured(placementId: String, reason: String) {
        if ( testRequestWithInvalidAdStatePerformed) {
            XCTAssert(true, reason)
            testRequestWithInvalidAdStatePerformed = false
        } else {
            
        }
        print("error occred : ",reason)
    }
    
    // optional
    func kwizzadWillPresentAd(placementId: String) {
    }
    
    // optional
    func kwizzadWillDismissAd(placementId: String) {
    }
    
    // optional
    func kwizzadOnGoalReached(placementId: String) {
    }
    
    // optional
    func kwizzadCallToActionClicked(placementId: String) {
    }

}
