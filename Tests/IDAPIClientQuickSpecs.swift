// Copyright (c) 2018 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import XCTest
import UIKit
import Quick
import Nimble
import Teapot
@testable import Toshi

// swiftlint:disable cyclomatic_complexity - QuickSpec actually treats these as separate methods.
class IDAPIClientQuickSpecs: QuickSpec {
    override func spec() {
        describe("the id API Client") {

            context("Ok status") {
                // swiftlint:disable:next implicitly_unwrapped_optional - Testing setup
                var subject: IDAPIClient!

                it("fetches the timestamp") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: IDAPIClientQuickSpecs.self), mockFilename: "timestamp")
                    subject = IDAPIClient(teapot: mockTeapot)

                    waitUntil { done in
                        subject.fetchTimestamp { timestamp, error in
                            expect(timestamp).toNot(beNil())
                            expect(error).to(beNil())
                            
                            expect(timestamp).to(equal("1503648141"))
                            
                            done()
                        }
                    }
                }

                it("registers user if needed") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: IDAPIClientQuickSpecs.self), mockFilename: "user")
                    mockTeapot.overrideEndPoint("timestamp", withFilename: "timestamp")

                    if Cereal.hasSharedCereal {
                        mockTeapot.overrideEndPoint(Cereal.shared.address, withFilename: "nonExistingUser")
                    }

                    subject = IDAPIClient(teapot: mockTeapot)

                    waitUntil { done in
                        subject.registerUserIfNeeded { status in
                            expect(status).to(equal(UserRegisterStatus.registered))
 
                            done()
                        }
                    }
                }

                it("updates Avatar") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: IDAPIClientQuickSpecs.self), mockFilename: "userAfterImageUpdate")
                    mockTeapot.overrideEndPoint("timestamp", withFilename: "timestamp")
                    subject = IDAPIClient(teapot: mockTeapot)

                    guard let testImage = UIImage(named: "testImage.png", in: Bundle(for: IDAPIClientQuickSpecs.self), compatibleWith: nil) else {
                        fail("Could not create test image")
                        return
                    }
                    waitUntil { done in
                        subject.updateAvatar(testImage) { success, error in
                            expect(success).to(beTrue())
                            expect(error).to(beNil())
                            
                            expect(Profile.current?.avatar).to(equal("https://token-id-service-development.herokuapp.com/avatar/0x1ad0bb2d14595fa6ad885e53eaaa6c82339f9b98.png"))
                            
                            done()
                        }
                    }
                }

                it("updates the user") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: IDAPIClientQuickSpecs.self), mockFilename: "userAfterDataUpdate")
                    mockTeapot.overrideEndPoint("timestamp", withFilename: "timestamp")
                    subject = IDAPIClient(teapot: mockTeapot)

                    let tokenID = "van Diemenstraat 328"
                    let paymentAddress = "Longstreet 200"
                    let username = "marijn2000"
                    let about = "test user dict!"
                    let location = "Leiden"
                    let name = "Marijntje"
                    let isPublic = true
                    let avatarPath = "http://www.someURL.com"
                    
                    let userDict: [String: Any] = [
                        "token_id": tokenID,
                        "payment_address": paymentAddress,
                        "username": username,
                        "about": about,
                        "location": location,
                        "name": name,
                        "avatar": avatarPath,
                        "is_app": false,
                        "public": isPublic,
                        "verified": false
                    ]

                    waitUntil { done in
                        subject.updateUser(userDict) { success, message in
                            expect(success).to(beTrue())
                            expect(message).to(beNil())
                            
                            guard let user = Profile.current else {
                                fail("No current user!")
                                done()
                                
                                return
                            }
                            
                            expect(user.toshiId).to(equal(tokenID))
                            expect(user.paymentAddress).to(equal(paymentAddress))
                            expect(user.username).to(equal(username))
                            expect(user.description).to(equal(about))
                            expect(user.location).to(equal(location))
                            expect(user.name).to(equal(name))
                            expect(user.avatar).to(equal(avatarPath))
                            expect(user.isPublic).to(equal(isPublic))
                            
                            expect(user.type).to(equal("user"))
                            expect(user.averageRating).to(equal(3.1))
                            expect(user.reputationScore).to(equal(2.4))
                            
                            done()
                        }
                    }
                }

                it("finds a user by address") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: IDAPIClientQuickSpecs.self), mockFilename: "fetchUsersFromPaymentAddresses")
                    subject = IDAPIClient(teapot: mockTeapot)

                    let paymentAddress = "0x1ad0bb2d14595fa6ad885e53eaaa6c82339f9b98"

                    waitUntil { done in
                        subject.findUserWithPaymentAddress(paymentAddress) { users, _, _  in
                            guard let user = users?.first else {
                                fail("User is nil")
                                return
                            }

                            expect(user.name).to(equal("Marijn Schilling"))
                            expect(user.paymentAddress).to(equal("0x1ad0bb2d14595fa6ad885e53eaaa6c82339f9b98"))
                            expect(user.type).to(equal("user"))
                            expect(user.reputationScore).to(equal(2.2))
                            expect(user.username).to(equal("marijnschilling"))
                            expect(user.averageRating).to(equal(3.0))
                            expect(user.toshiId).to(equal("0x6f70800cb47f7f84b6c71b3693fc02595eae7378"))
                            expect(user.location).to(equal("Amsterdam"))
                            expect(user.description).to(equal("Oh hai tests"))
                            expect(user.avatar).to(equal("https://token-id-service-development.herokuapp.com/avatar/0x6f70800cb47f7f84b6c71b3693fc02595eae7378.png"))
                            expect(user.isPublic).to(beFalse())

                            done()
                        }
                    }
                }

                it("retrieve user") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: IDAPIClientQuickSpecs.self), mockFilename: "user")
                    subject = IDAPIClient(teapot: mockTeapot)

                    let username = "marijnschilling"

                    waitUntil { done in
                        subject.retrieveUser(username: username) { user, _ in
                            guard let user = user else {
                                fail("User is nil")
                                return
                            }
                            
                            expect(user.name).to(equal("Marijn Schilling"))
                            expect(user.paymentAddress).to(equal("0x1ad0bb2d14595fa6ad885e53eaaa6c82339f9b98"))
                            expect(user.type).to(equal("user"))
                            expect(user.reputationScore).to(equal(2.2))
                            expect(user.username).to(equal("marijnschilling"))
                            expect(user.averageRating).to(equal(3.0))
                            expect(user.toshiId).to(equal("0x6f70800cb47f7f84b6c71b3693fc02595eae7378"))
                            expect(user.location).to(equal("Amsterdam"))
                            expect(user.description).to(equal("Oh hai tests"))
                            expect(user.avatar).to(equal("https://token-id-service-development.herokuapp.com/avatar/0x6f70800cb47f7f84b6c71b3693fc02595eae7378.png"))
                            expect(user.isPublic).to(beFalse())
                            
                            done()
                        }
                    }
                }

                it("finds a contact") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: IDAPIClientQuickSpecs.self), mockFilename: "contact")
                    subject = IDAPIClient(teapot: mockTeapot)
                    
                    let username = "designatednerd"

                    waitUntil { done in
                        subject.findContact(name: username) { user, _  in
                            guard let user = user else {
                                fail("User is nil")
                                return
                            }
                            
                            expect(user.name).to(equal("Ellen Shapiro"))
                            expect(user.paymentAddress).to(equal("123 Fake Street"))
                            expect(user.type).to(equal("user"))
                            expect(user.reputationScore).to(equal(2.1))
                            expect(user.username).to(equal("designatednerd"))
                            expect(user.averageRating).to(equal(4.1))
                            expect(user.toshiId).to(equal("Some ungodly long hex thing"))
                            expect(user.location).to(equal("Nijmegen"))
                            expect(user.description).to(equal("Moar Tests Always"))
                            expect(user.avatar).to(equal("https://frinkiac.com/meme/S08E14/661860.jpg?b64lines=V0hFTiBJVENIWSBQTEFZUyBTQ1JBVENIWSdTIApTS0VMRVRPTiBMSUtFIEEgWFlMT1BIT05FIAoKCgoKCgoKSEUgU1RSSUtFUyBUSEUgU0FNRSBSSUIgVFdJQ0UKSU4gU1VDQ0VTU0lPTiwgWUVUIEhFIFBST0RVQ0VTIApUV08gQ0xFQVJMWSBESUZGRVJFTlQgVE9ORVMu"))
                            expect(user.isPublic).to(beTrue())
                            done()
                        }
                    }
                }

                it("searches contacts") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: IDAPIClientQuickSpecs.self), mockFilename: "searchContacts")
                    subject = IDAPIClient(teapot: mockTeapot)

                    let search = "search result"

                    waitUntil { done in
                        subject.searchContacts(name: search) { users, _  in
                            guard let users = users else { return }
                            expect(users.count).to(equal(2))
                            expect(users.map { $0.name }).to(equal([
                                    "Search result 1",
                                    "Search result 2"
                                ]))
                            expect(users.map { $0.location }).to(equal([
                                    "Amsterdam",
                                    "Springfield"
                                ]))
                            expect(users.map { $0.username }).to(equal([
                                    "marijnschilling",
                                    "homersimpson"
                                ]))

                            done()
                        }
                    }
                }

                it("gets a bunch of users from their IDs") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: IDAPIClientQuickSpecs.self), mockFilename: "fetchUsersFromIDs")
                    subject = IDAPIClient(teapot: mockTeapot)
                    
                    let ids = [
                        "0xe629d9ff7a3f0abe637bed15988759abc2822fb8",
                        "0x1c0e100fcf093c64cdaa54562c84c8fa0171a38c",
                        "0xeedde9afd8ac67e3564f69d0c1a144e9d7536af1"
                    ]
                    
                    waitUntil { done in
                        subject.fetchUsers(with: ids) { users, error in
                            guard let users = users else {
                                fail("User is nil")
                                return
                            }
                            expect(error).to(beNil())
                            
                            expect(users.count).to(equal(3))
                            
                            expect(users.map { $0.toshiId }).to(equal(ids))
                            expect(users.map { $0.username }).to(equal([
                                "NodeOnlyBot1",
                                "tristan",
                                "user03555"
                            ]))
                            expect(users.map { $0.name }).to(equal([
                                "Node Only Bot",
                                "Tristan",
                                nil
                            ]))
                            expect(users.map { $0.type }).to(equal([
                                "groupbot",
                                "user",
                                "user"
                            ]))
                            expect(users.map { $0.isPublic }).to(equal([
                                false,
                                true,
                                false
                            ]))
                        
                            done()
                        }
                    }
                }

                it("reports a user") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: IDAPIClientQuickSpecs.self), mockFilename: "", statusCode: .noContent)
                    mockTeapot.overrideEndPoint("timestamp", withFilename: "timestamp")
                    subject = IDAPIClient(teapot: mockTeapot)

                    let address = "0x6f70800cb47f7f84b6c71b3693fc02595eae7378"

                    waitUntil { done in
                        subject.reportUser(address: address, reason: "Not good") { success, error in
                            expect(success).to(beTrue())
                            expect(error).to(beNil())
                            
                            done()
                        }
                    }
                }

                it("logs in") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: IDAPIClientQuickSpecs.self), mockFilename: "", statusCode: .noContent)
                    mockTeapot.overrideEndPoint("timestamp", withFilename: "timestamp")
                    subject = IDAPIClient(teapot: mockTeapot)

                    let token = "f500a3cc32dbb78b"

                    waitUntil { done in
                        subject.adminLogin(loginToken: token) { success, error in
                            expect(success).to(beTrue())
                            expect(error).to(beNil())
                            
                            done()
                        }
                    }
                }
            }

            context("Error status") {
                // swiftlint:disable:next implicitly_unwrapped_optional - Testing setup
                var subject: IDAPIClient!

                it("fetches the timestamp") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: IDAPIClientQuickSpecs.self), mockFilename: "timestamp", statusCode: .unauthorized)
                    subject = IDAPIClient(teapot: mockTeapot)

                    waitUntil { done in
                        subject.fetchTimestamp { timestamp, error in
                            guard let error = error else {
                                fail("Error is nil")
                                return
                            }

                            expect(timestamp).to(beNil())

                            expect(error.responseStatus).to(equal(401))
                            expect(error.type).to(equal(.invalidResponseStatus))
                            
                            done()
                        }
                    }
                }

                it("registers user if needed") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: IDAPIClientQuickSpecs.self), mockFilename: "user", statusCode: .unauthorized)
                    mockTeapot.overrideEndPoint("timestamp", withFilename: "timestamp")
                    mockTeapot.overrideEndPoint(Cereal.shared.address, withFilename: "nonExistingUser")
                    subject = IDAPIClient(teapot: mockTeapot)

                    waitUntil { done in
                        subject.registerUserIfNeeded { status in
                            expect(status).to(equal(UserRegisterStatus.failed))
                            
                            done()
                        }
                    }
                }

                it("updates Avatar") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: IDAPIClientQuickSpecs.self), mockFilename: "user", statusCode: .unauthorized)
                    mockTeapot.overrideEndPoint("timestamp", withFilename: "timestamp")
                    subject = IDAPIClient(teapot: mockTeapot)

                    guard let testImage = UIImage(named: "testImage.png", in: Bundle(for: IDAPIClientQuickSpecs.self), compatibleWith: nil) else {
                        fail("Could not create test image")
                        
                        return
                    }
                    waitUntil { done in
                        subject.updateAvatar(testImage) { success, error in
                            guard let error = error else {
                                fail("Error is nil")
                                return
                            }

                            expect(success).to(beFalse())

                            expect(error.responseStatus).to(equal(401))
                            expect(error.type).to(equal(.invalidResponseStatus))
                            
                            done()
                        }
                    }
                }

                it("updates the user") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: IDAPIClientQuickSpecs.self), mockFilename: "user", statusCode: .unauthorized)
                    mockTeapot.overrideEndPoint("timestamp", withFilename: "timestamp")
                    subject = IDAPIClient(teapot: mockTeapot)

                    let userDict: [String: Any] = [
                        "token_id": "van Diemenstraat 328",
                        "payment_address": "Longstreet 200",
                        "username": "marijn2000",
                        "about": "test user dict!",
                        "location": "Leiden",
                        "name": "Marijntje",
                        "avatar": "someURL",
                        "is_app": false,
                        "public": true,
                        "verified": false
                    ]

                    waitUntil { done in
                        subject.updateUser(userDict) { success, error in
                            guard let error = error else {
                                fail("Error is nil")
                                return
                            }

                            expect(success).to(beFalse())

                            expect(error.responseStatus).to(equal(401))
                            expect(error.type).to(equal(.invalidResponseStatus))
                            
                            done()
                        }
                    }
                }

                it("retrieve user") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: IDAPIClientQuickSpecs.self), mockFilename: "user", statusCode: .unauthorized)
                    subject = IDAPIClient(teapot: mockTeapot)

                    let username = "testUsername"

                    waitUntil { done in
                        subject.retrieveUser(username: username) { user, _ in
                            expect(user).to(beNil())
                            
                            done()
                        }
                    }
                }

                it("finds a contact") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: IDAPIClientQuickSpecs.self), mockFilename: "user", statusCode: .unauthorized)
                    subject = IDAPIClient(teapot: mockTeapot)

                    let username = "somethingCompletelyDifferent"

                    waitUntil { done in
                        subject.findContact(name: username) { user, _ in
                            expect(user).to(beNil())

                            done()
                        }
                    }
                }

                it("searches contacts") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: IDAPIClientQuickSpecs.self), mockFilename: "searchContacts", statusCode: .unauthorized)
                    subject = IDAPIClient(teapot: mockTeapot)

                    let search = "search key"

                    waitUntil { done in
                        subject.searchContacts(name: search) { users, _ in

                            expect(users).to(beNil())
                            done()
                        }
                    }
                }

                it("gets a bunch of users from their IDs") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: IDAPIClientQuickSpecs.self),
                                                mockFilename: "fetchUsersFromIDs",
                                                statusCode: .unauthorized)
                    subject = IDAPIClient(teapot: mockTeapot)
                    
                    let ids = [
                        "0xe629d9ff7a3f0abe637bed15988759abc2822fb8",
                        "0x1c0e100fcf093c64cdaa54562c84c8fa0171a38c",
                        "0xeedde9afd8ac67e3564f69d0c1a144e9d7536af1"
                    ]
                    
                    waitUntil { done in
                        subject.fetchUsers(with: ids) { users, error in
                            guard let error = error else {
                                fail("Error is nil")
                                return

                            }
                            expect(users).to(beNil())

                            expect(error.responseStatus).to(equal(401))
                            expect(error.type).to(equal(.invalidResponseStatus))

                            done()
                        }
                    }
                }

                it("finds a user by address") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: IDAPIClientQuickSpecs.self),
                                                mockFilename: "fetchUsersFromPaymentAddresses",
                                                statusCode: .unauthorized)
                    subject = IDAPIClient(teapot: mockTeapot)

                    let paymentAddress = "0x1ad0bb2d14595fa6ad885e53eaaa6c82339f9b98"

                    waitUntil { done in
                        subject.findUserWithPaymentAddress(paymentAddress) { user, _, error  in
                            guard let error = error else {
                                fail("Error is nil")
                                return
                            }

                            expect(user).to(beNil())

                            expect(error.responseStatus).to(equal(401))
                            expect(error.type).to(equal(.invalidResponseStatus))

                            done()
                        }
                    }
                }

                it("reports a user") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: IDAPIClientQuickSpecs.self), mockFilename: "", statusCode: .unauthorized)
                    mockTeapot.overrideEndPoint("timestamp", withFilename: "timestamp")
                    subject = IDAPIClient(teapot: mockTeapot)

                    let address = "0x6f70800cb47f7f84b6c71b3693fc02595eae7378"

                    waitUntil { done in
                        subject.reportUser(address: address, reason: "Not good") { success, error in
                            guard let error = error else {
                                fail("Error is nil")
                                return
                            }

                            expect(success).to(beFalse())

                            expect(error.type).to(equal(.invalidResponseStatus))
                            expect(error.responseStatus).to(equal(401))
                            done()
                        }
                    }
                }

                it("logs in") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: IDAPIClientQuickSpecs.self), mockFilename: "", statusCode: .unauthorized)
                    mockTeapot.overrideEndPoint("timestamp", withFilename: "timestamp")
                    subject = IDAPIClient(teapot: mockTeapot)

                    let token = "f500a3cc32dbb78b"

                    waitUntil { done in
                        subject.adminLogin(loginToken: token) { success, error in
                            guard let error = error else {
                                fail("Error is nil")
                                return
                            }

                            expect(success).to(beFalse())

                            expect(error.type).to(equal(.invalidResponseStatus))
                            expect(error.responseStatus).to(equal(401))
                            
                            done()
                        }
                    }
                }
            }
        }
    }
}
