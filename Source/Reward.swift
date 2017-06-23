//
//  Reward.swift
//  KwizzadSDK
//
//  Created by Sandro Manke on 20.10.16.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

import Foundation


func enumerateAsText(_ array: [String]) -> String? {
    switch (array.count) {
    case 0: return nil;
    case 1: return array[0];
    case 2:
        let format = LocalizedString("%@ and %@", comment: "Joins two strings with an 'and' to generate a human-readable enumeration");
        return String.init(format: format, array[0], array[1]);
    default:
        let format = LocalizedString("%@, and %@", comment: "Joins a list of comma-separated values with a last values to form a human-readable enumeration (e.g. with oxford comma)");
        return String.init(format: format, array.dropLast().joined(separator: ", "), array.last!);
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
                let format = LocalizedString("up to %@", comment: "Description of an amount with an upper limit");
                return String.init(format: format, "\(maxAmount.intValue) \(currency)");
            }
        }
        if let amount = self.amount, let currency = self.currency {
            return "\(amount.intValue) \(currency)"
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
    
    public static func limitedAmountString(maxAmount: Int, currency: String) -> String {
        let format = LocalizedString("up to %@", comment: "Description of an amount with an upper limit");
        return String.init(format: format, "\(maxAmount) \(currency)");
    }
    
    public static func staticAmountString(amount: Int, currency: String) -> String {
        return "\(amount) \(currency)";
    }
    
    /// use for debugging rewards.
    public func asDebugString() -> String? {
        if let maxAmount = self.maxAmount, let currency = self.currency {
            if (maxAmount.intValue > 0) {
                return "up to \(maxAmount) \(currency) for \(String(describing: type))"
            }
        }
        if let amount = self.amount, let currency = self.currency {
            return "\(amount) \(currency) for \(String(describing: type))"
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
    public static func enumerateRewardsAsText(rewards: [Reward]) -> String? {
        guard !rewards.isEmpty else { return nil };
        return enumerateAsText(summarize(rewards: rewards).flatMap({ $0.valueDescription() }));
    }
    
    /// Returns a text that you can use to incentivize the user to earn the given rewards.
    public static func incentiveTextFor(rewards: [Reward]) -> String? {
        let currencyCount = Set(rewards.flatMap({ $0.currency })).count;
        if (currencyCount == 0) {
            return nil;
        }

        let formatString = LocalizedString("Earn %@ with a quiz.", comment: "Can be shown as incentive text, for example on an ad banner. First parameter is the potential total reward.");

        if (currencyCount == 1) {
            let totalAmount = rewards.reduce(0) { $0 + ($1.amount?.intValue ?? 0) };
            let maxTotalAmount = rewards.reduce(0) { $0 + ($1.maxAmount?.intValue ?? $1.amount?.intValue ?? 0) };
            let currency = rewards[0].currency ?? "";
            let hasPotentiallyHigherAmount = maxTotalAmount > totalAmount;
            let rewardsHaveDifferentTypes = Set(rewards.flatMap({ $0.type })).count > 1;
            let useRewardWithLimit = hasPotentiallyHigherAmount || rewardsHaveDifferentTypes;
            let potentialTotalReward = useRewardWithLimit ? limitedAmountString(maxAmount: maxTotalAmount, currency: currency) : staticAmountString(amount: totalAmount, currency: currency);
            return String.init(format: formatString, potentialTotalReward);
        }
        
        let potentialTotalReward = enumerateAsText(rewards.flatMap({ $0.valueDescription() })) ?? "";
        return String.init(format: formatString, potentialTotalReward);
    }
    
    public static func confirmationText(rewards: [Reward]) -> String {
        if let enumeration = enumerateRewardsAsText(rewards: rewards) {
            let format = LocalizedString("Congratulations, you earned %@!", comment: "Shown in a confirmation dialog when the user earns a known, specific reward.");
            return String.init(format: format, enumeration);
        }
        return LocalizedString("Congratulations, you earned a reward!", comment: "Shown in a confirmation dialog when the user earns an unspecified reward.");
    }
}
