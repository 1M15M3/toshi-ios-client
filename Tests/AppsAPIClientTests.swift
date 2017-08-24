// Copyright (c) 2017 Token Browser, Inc
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

//swiftlint:disable force_cast
class AppsAPIClientTests: QuickSpec {

    override func spec() {
        describe("the Apps API Client") {

            context("Happy path 😎") {
                var subject: AppsAPIClient!
                let mockTeapot = MockTeapot(bundle: Bundle(for: AppsAPIClientTests.self))
                subject = AppsAPIClient(teapot: mockTeapot)

                it("fetches the top rated apps") {
                    waitUntil { done in
                        subject.getTopRatedApps { users, _ in
                            expect(users?.first?.about).to(equal("The toppest of all the apps"))
                            
                            done()
                        }
                    }
                }

                it("fetches the featured apps") {
                    waitUntil { done in
                        subject.getFeaturedApps { users, _ in
                            expect(users?.first?.about).to(equal("It's all about tests"))
                            done()
                        }
                    }
                }

                it("searches") {
                    waitUntil { done in
                        subject.search("Test") { users, _ in
                            expect(users[2].about).to(equal("The third most searchest of all the apps"))
                            done()
                        }
                    }
                }
            }

            context("⚠ Unauthorized error 🔒") {
                var subject: AppsAPIClient!
                let mockTeapot = MockTeapot(bundle: Bundle(for: AppsAPIClientTests.self), statusCode: .unauthorized)
                subject = AppsAPIClient(teapot: mockTeapot)

                it("fetches the top rated apps") {
                    waitUntil { done in
                        subject.getTopRatedApps { users, error in
                            expect(users?.count).to(equal(0))
                            expect(error).toNot(beNil())

                            done()
                        }
                    }
                }

                it("fetches the featured apps") {
                    waitUntil { done in
                        subject.getFeaturedApps { users, error in
                            expect(users?.count).to(equal(0))
                            expect(error).toNot(beNil())
                            done()
                        }
                    }
                }

                it("searches") {
                    waitUntil { done in
                        subject.search("Test") { user, error in
                            expect(user.count).to(equal(0))
                            expect(error).toNot(beNil())
                            done()
                        }
                    }
                }
            }

            context("⚠ Not found error 🕳") {
                var subject: AppsAPIClient!
                let mockTeapot = MockTeapot(bundle: Bundle(for: AppsAPIClientTests.self), statusCode: .notFound)
                subject = AppsAPIClient(teapot: mockTeapot)

                it("fetches the top rated apps") {
                    waitUntil { done in
                        subject.getTopRatedApps { users, error in
                            expect(users?.count).to(equal(0))
                            expect(error).toNot(beNil())

                            done()
                        }
                    }
                }

                it("fetches the featured apps") {
                    waitUntil { done in
                        subject.getFeaturedApps { users, error in
                            expect(users?.count).to(equal(0))
                            expect(error).toNot(beNil())
                            done()
                        }
                    }
                }

                it("searches") {
                    waitUntil { done in
                        subject.search("Test") { user, error in
                            expect(user.count).to(equal(0))
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }
            }
        }
    }
}
//swiftlint:enable force_cast
