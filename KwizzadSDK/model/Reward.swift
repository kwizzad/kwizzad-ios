//
//  Reward.swift
//  KwizzadSDK
//
//  Created by Sandro Manke on 20.10.16.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

import Foundation


func enumerateAsText(_ array: [String]) -> String {
    switch (array.count) {
    case 1: return array[0];
    case 2: return KwizzadLocalized("enum.two", replacements: ["#first#": array[0], "#second#": array[1]])
    default: return KwizzadLocalized(
        "enum.moreThanTwo",
        replacements: [
            "#commaSeparated#": array.dropLast().joined(separator: ", "),
            "#last#": array.last!,
            ]);
    }
}


/// Reward object obtained when an ad is available.
@objc(KwizzadReward)
open class Reward : NSObject, FromDict {
    /// Defines the amount of the reward.
    public let amount : NSNumber?

    /// Defines the currency of the reward.
    public let currency : String?
    
    /// Optional: maximal potential amount of the reward. The actual reward the user receives can be lower than this.
    public let maxAmount : NSNumber?
    
    /// Optional: Defines the state to user has to reach to be rewarded.
    public let type : String?
    
    let UnknownType = "UNKNOWN";

    /// Initialize the reward model with a JSON object.
    public required init(_ map: [String : Any]) {
        amount = map["amount"] as? NSNumber
        maxAmount = map["maxAmount"] as? NSNumber
        currency = map["currency"] as? String
        
        if let rt = map["type"] as? String? {
            if let type = rt {
                self.type = type
            }
            else {
                type = UnknownType
            }
        }
        else {
            type = UnknownType
        }
    }
    
    
    public init(amount: Int, maxAmount: Int, currency: String) {
        self.amount = amount as NSNumber;
        self.maxAmount = maxAmount as NSNumber;
        self.currency = currency;
        self.type = UnknownType;
    }
    
    /// - returns: a string that describes the (potential) reward that you can
    /// display to a user.
    public func valueDescription() -> String? {
        if let maxAmount = self.maxAmount, let currency = self.currency {
            if (maxAmount.intValue > 0) {
                return KwizzadLocalized("reward.withLimit", replacements: ["#reward#": "\(maxAmount) \(currency)"])
            }
        }
        if let amount = self.amount, let currency = self.currency {
            return "\(amount) \(currency)"
        }
        return nil;
    }
    
    /// - returns: A string that describes the (potential) reward that you can
    @objc
    public func valueOrMaxValue() -> NSNumber? {
        if let maxAmount = self.maxAmount {
            if (maxAmount.intValue > 0) {
                return maxAmount;
            }
        }
        if let amount = self.amount {
            return amount;
        }
        return nil;
    }
    
    /// use for debugging rewards.
    public func asDebugString() -> String? {
        if let maxAmount = self.maxAmount, let currency = self.currency {
            if (maxAmount.intValue > 0) {
                return "up to \(maxAmount) \(currency) for \(String(describing: type))"
            }
        }
        if let amount = self.amount, let currency = self.currency {
            return "\(amount) \(currency) for \(String(describing: type))"
        }
        return nil;
    }
    
    /// - returns: One `Reward` object for each found currency in the given rewards. The amount of each reward
    /// is the sum of the given reward amounts in the same currency.
    public static func summarize(rewards: [Reward]) -> [Reward] {
        var rewardsByCurrency: [String: [Reward]] = [:]
        for reward in rewards {
            if let currency = reward.currency {
                if case nil = rewardsByCurrency[currency]?.append(reward) {
                    rewardsByCurrency[currency] = [reward]
                }
            }
        }

        return rewardsByCurrency.flatMap({ (key: String, value: [Reward]) -> Reward in
            let amount = value.reduce(0) { $0 + ($1.amount?.intValue ?? 0) }
            let maxAmount = value.reduce(0) { $0 + ($1.maxAmount?.intValue ?? 0) }
            return Reward(amount: amount, maxAmount: maxAmount, currency: key);
        })
    }

    /// Returns a text describing the given rewards. This does not take maximal amounts into account.
    public static func enumerateRewardsAsText(rewards: [Reward]) -> String {
        return enumerateAsText(summarize(rewards: rewards).flatMap({ $0.valueDescription() }));
    }
    
    /// Returns a text that you can use to incentivize the user to earn the given rewards.
    public static func incentiveTextFor(rewards: [Reward]) -> String? {
        let currencyCount = Set(rewards.flatMap({ $0.currency })).count;
        if (currencyCount == 0) {
            return nil;
        }
        if (currencyCount == 1) {
            let totalAmount = rewards.reduce(0) { $0 + ($1.amount?.intValue ?? 0) };
            let maxTotalAmount = rewards.reduce(0) { $0 + ($1.maxAmount?.intValue ?? $1.amount?.intValue ?? 0) };
            let currency = rewards[0].currency;
            let currencySuffix = (currency != nil) ? " \(currency ?? "")" : "";
            let hasPotentiallyHigherAmount = maxTotalAmount > totalAmount;
            let rewardsHaveDifferentTypes = Set(rewards.flatMap({ $0.type })).count > 1;
            let useRewardWithLimit = hasPotentiallyHigherAmount || rewardsHaveDifferentTypes;
            let potentialTotalReward = useRewardWithLimit ?
                KwizzadLocalized("reward.withLimit", replacements: ["#reward#": "\(maxTotalAmount)\(currencySuffix)"])
                :
                "\(totalAmount)\(currencySuffix)";
            return KwizzadLocalized("reward.incentiveText", replacements: ["#potentialTotalReward#": potentialTotalReward])
        }
        
        return KwizzadLocalized(
            "reward.incentiveText",
            replacements: [
                "#potentialTotalReward#": enumerateAsText(rewards.flatMap({ $0.valueDescription() }))
            ]
        );

    }
}
