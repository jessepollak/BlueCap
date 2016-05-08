//
//  BCPeripheralTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 1/7/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
import CoreBluetooth
import CoreLocation
@testable import BlueCapKit

// MARK - BCPeripheralTests -
class BCPeripheralTests: XCTestCase {

    let RSSI = -45
    let updatedRSSI1 = -50
    let updatedRSSI2 = -75

    var centralManagerMock = CBCentralManagerMock(state: .PoweredOn)
    var centralManager: BCCentralManager!
    let immediateContext = ImmediateContext()

    let mockServices = [
        CBServiceMock(UUID:CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6ccc")),
        CBServiceMock(UUID:CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6fff"))
    ]

    var mockCharateristics = [
        CBCharacteristicMock(UUID: CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6111"), properties: [.Read, .Write], isNotifying: false),
        CBCharacteristicMock(UUID: CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6222"), properties: [.Read, .Write], isNotifying: false),
        CBCharacteristicMock(UUID: CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6333"), properties: [.Read, .Write], isNotifying: false)
    ]
    
    override func setUp() {
        super.setUp()
        self.centralManager = CentralManagerUT(centralManager: self.centralManagerMock)
    }
    
    override func tearDown() {
        super.tearDown()
    }

    // MARK: discoverAllServices
    func testDiscoverAllServices_WhenConnectedAndNoErrorInResponse_CompletesSuccessfully() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.discoverAllServices()
        peripheral.didDiscoverServices(self.mockServices.map { $0 as CBServiceInjectable }, error:nil)
        XCTAssertFutureSucceeds(future, context: self.immediateContext) { _ in
            let discoveredServices = peripheral.services
            XCTAssertEqual(discoveredServices.count, 2, "Peripheral service count invalid")
            XCTAssertEqual(mockPeripheral.discoverServicesCalledCount, 1, "CBPeripheral#discoverServices called more than once")
            XCTAssert(mockPeripheral.discoverServicesCalled, "BC#discoverServices not called")
            XCTAssertFalse(mockPeripheral.discoverCharacteristicsCalled, "CBPeripheral#discoverChracteristics called")
        }
    }

    func testDiscoverAllServices_WhenConnectedAndErrorInResponse_CompletesWithResponseError() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.discoverAllServices()
        peripheral.didDiscoverServices(self.mockServices.map { $0 as CBServiceInjectable }, error: TestFailure.error)
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            let discoveredServices = peripheral.services
            XCTAssertEqual(discoveredServices.count, 0, "Peripheral service count invalid")
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            XCTAssertEqual(mockPeripheral.discoverServicesCalledCount, 1, "CBPeripheral#discoverServices called more than once")
            XCTAssert(mockPeripheral.discoverServicesCalled, "CBPeripheral#discoverServices not called")
            XCTAssertFalse(mockPeripheral.discoverCharacteristicsCalled, "CBPeripheral#discoverChracteristics called")
        }
    }

    func testDiscoverAllServices_WhenDisconnected_CompletesWithPeripheralDisconnected() {
        let mockPeripheral = CBPeripheralMock(state: .Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.discoverAllServices()
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            let discoveredServices = peripheral.services
            XCTAssertEqual(discoveredServices.count, 0, "Peripheral service count invalid")
            XCTAssertEqual(error.code, BCError.peripheralDisconnected.code, "Error code invalid")
            XCTAssertEqual(mockPeripheral.discoverServicesCalledCount, 0, "CBPeripheral#discoverServices called more than once")
            XCTAssertFalse(mockPeripheral.discoverServicesCalled, "CBPeripheral#discoverServices called")
            XCTAssertFalse(mockPeripheral.discoverCharacteristicsCalled, "CBPeripheral#discoverChracteristics called")
        }

    }

    func testDiscoverAllServices_WhenConnectedOnTimeout_CompletesWithServiceDiscoveryTimeout() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = peripheral.discoverAllServices(1.0)
        future.onSuccess { _ in
            XCTFail("onSuccess called")
        }
        future.onFailure { error in
            expectation.fulfill()
            let discoveredServices = peripheral.services
            XCTAssertEqual(discoveredServices.count, 0, "Peripheral service count invalid")
            XCTAssertEqual(error.code, BCError.peripheralServiceDiscoveryTimeout.code, "Error code invalid")
            XCTAssertEqual(mockPeripheral.discoverServicesCalledCount, 1, "CBPeripheral#discoverServices called more than once")
            XCTAssert(mockPeripheral.discoverServicesCalled, "CBPeripheral#discoverServices not called")
            XCTAssertFalse(mockPeripheral.discoverCharacteristicsCalled, "CBPeripheral#discoverChracteristics called")
        }
        waitForExpectationsWithTimeout(2) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    // MARK: discoverAllPeripheralServices
    func testDiscoverAllPeripheralServices_WhenConnectedAndNoErrorInResponse_CompletesSuccessfully() {
        let mockPeripheral = CBPeripheralMock(state:.Connected)
        let peripheral = PeripheralUT(cbPeripheral:mockPeripheral, centralManager:self.centralManager, advertisements:peripheralAdvertisements, rssi: self.RSSI, error:nil)
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheral.discoverAllPeripheralServices()
        future.onSuccess { _ in
            onSuccessExpectation.fulfill()
            let discoveredServices = peripheral.services
            XCTAssertEqual(discoveredServices.count, 2, "Peripheral service count invalid")
            XCTAssert(mockPeripheral.discoverServicesCalled, "CBPeripheral#discoverServices not called")
        }
        future.onFailure { error in
            XCTFail("onFailure called")
        }
        peripheral.didDiscoverServices(self.mockServices.map { $0 as CBServiceInjectable }, error:nil)
        waitForExpectationsWithTimeout(20) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDiscoverAllPeripheralServices_WhenConnectedAndErrorInServiceDiscoveryResponse_CompletesWithResponseError() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = PeripheralUT(cbPeripheral:mockPeripheral, centralManager:self.centralManager, advertisements:peripheralAdvertisements, rssi: self.RSSI, error:TestFailure.error)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = peripheral.discoverAllPeripheralServices()
        future.onSuccess { _ in
            XCTFail("onSuccess called")
        }
        future.onFailure {error in
            expectation.fulfill()
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            XCTAssert(mockPeripheral.discoverServicesCalled, "CBPeripheral#discoverServices not called")
        }
        peripheral.didDiscoverServices(self.mockServices.map { $0 as CBServiceInjectable }, error:nil)
        waitForExpectationsWithTimeout(20) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDiscoverAllPeripheralServices_WhenConnectedAndNoServicesDiscovered_CompletesWithPeripheralNoServices() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = peripheral.discoverAllPeripheralServices()
        future.onSuccess { _ in
            XCTFail("onSuccess called")
        }
        future.onFailure {error in
            expectation.fulfill()
            XCTAssertEqual(error.domain, BCError.domain, "message domain invalid")
            XCTAssertEqual(error.code, BCError.peripheralNoServices.code, "message code invalid")
        }
        peripheral.didDiscoverServices([], error:nil)
        waitForExpectationsWithTimeout(20) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    // MARK: connect
    func testConnect_WhenDisconnected_CompletesSuccesfullyWithEventConnect() {
        let mockPeripheral = CBPeripheralMock(state:.Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = peripheral.connect(connectionTimeout: 120.0)
        future.onSuccess { (peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                expectation.fulfill()
            case .Timeout:
                XCTFail("onSuccess Timeout invalid")
            case .Disconnect:
                XCTFail("onSuccess Disconnect invalid")
            case .ForceDisconnect:
                XCTFail("onSuccess ForceDisconnect invalid")
            case .GiveUp:
                XCTFail("onSuccess GiveUp invalid")
            }
        }
        future.onFailure { error in
            XCTFail("onFailure called")
        }
        peripheral.didConnectPeripheral()
        XCTAssert(self.centralManagerMock.connectPeripheralCalled, "CentralManager#connectPeripheralCalled not called")
        waitForExpectationsWithTimeout(120) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testConnect_WhenConnected_DoesNotConnect() {
        let mockPeripheral = CBPeripheralMock(state:.Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        peripheral.connect()
        XCTAssertFalse(self.centralManagerMock.connectPeripheralCalled, "CentralManager#connectPeripheralCalled called")
    }

    func testConnect_WhenDisconnectedWithConnectionError_CompletesWithConnectionError() {
        let mockPeripheral = CBPeripheralMock(state: .Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = peripheral.connect(connectionTimeout: 120.0)
        future.onSuccess { _ in
            XCTFail("onSuccess called")
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTAssert(error.code == TestFailure.error.code, "Error code invalid")
        }
        peripheral.didFailToConnectPeripheral(TestFailure.error)
        XCTAssert(self.centralManagerMock.connectPeripheralCalled, "CentralManager#connectPeripheralCalled not called")
        waitForExpectationsWithTimeout(120) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testConnect_WhenDisconnectedAndForcedDisconnect_CompletesWithPeripheralDisconnected() {
        let mockPeripheral = CBPeripheralMock(state: .Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = peripheral.connect()
        future.onSuccess { _ in
            XCTFail("onSuccess called")
        }
        future.onFailure { error in
            XCTAssertEqual(error.code, BCError.peripheralDisconnected.code, "Error code invalid")
            expectation.fulfill()
        }
        peripheral.disconnect()
        waitForExpectationsWithTimeout(120) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testConnect_WhenConnectedAndForcedDisconnect_CompletesSuccessfullyWithEventForceDisconnect() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = peripheral.connect()
        future.onSuccess { (peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                XCTFail("onSuccess Connect invalid")
            case .Timeout:
                XCTFail("onSuccess Timeout invalid")
            case .Disconnect:
                XCTFail("onSuccess Disconnect invalid")
            case .ForceDisconnect:
                expectation.fulfill()
            case .GiveUp:
                XCTFail("onSuccess GiveUp invalid")
            }
        }
        future.onFailure { error in
            XCTFail("onFailure called")
        }
        peripheral.disconnect()
        waitForExpectationsWithTimeout(120) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testConnect_WhenConnectedAndPeripheralDisconnectsWithoutError_CompletesSuccessfullyWithEventDisconnect() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = peripheral.connect()
        future.onSuccess { (peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                XCTFail("onSuccess Connect invalid")
            case .Timeout:
                XCTFail("onSuccess Timeout invalid")
            case .Disconnect:
                expectation.fulfill()
            case .ForceDisconnect:
                XCTFail("onSuccess ForceDisconnect invalid")
            case .GiveUp:
                XCTFail("onSuccess GiveUp invalid")
            }
        }
        future.onFailure { _ in
            XCTFail("onFailure called")
        }
        peripheral.didDisconnectPeripheral(nil)
        waitForExpectationsWithTimeout(120) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testConnect_WhenConnectedAndPeripheralDisconnectsWithError_CompletesDisconnectError() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = peripheral.connect()
        future.onSuccess { _ in
            XCTFail("onSuccess called")
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
        }
        peripheral.didDisconnectPeripheral(TestFailure.error)
        waitForExpectationsWithTimeout(120) { error in
            XCTAssertNil(error, "\(error)")
        }
    }


    func testConnect_WhenDisconnetedAndConnectionTimeout_CompletesSuccessfullyWithEventTimeout() {
        let mockPeripheral = CBPeripheralMock(state: .Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = peripheral.connect(connectionTimeout: 0.25)
        future.onSuccess { (peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                XCTFail("onSuccess Connect invalid")
            case .Timeout:
                expectation.fulfill()
            case .Disconnect:
                XCTFail("onSuccess Disconnect invalid")
            case .ForceDisconnect:
                XCTFail("onSuccess ForceDisconnect invalid")
            case .GiveUp:
                XCTFail("onSuccess GiveUp invalid")
            }
        }
        future.onFailure { _ in
            XCTFail("onFailure called")
        }
        waitForExpectationsWithTimeout(20) { error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testConnect_WhenDisconnetedAndExceedsTimeoutRetries_CompletesSuccessfullyWithEventGiveUp() {
        let mockPeripheral = CBPeripheralMock(state: .Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = peripheral.connect(connectionTimeout: 0.25, timeoutRetries: 1)
        future.onSuccess { (peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                XCTFail("onSuccess Connect invalid")
            case .Timeout:
                peripheral.reconnect()
            case .Disconnect:
                XCTFail("onSuccess Disconnect invalid")
            case .ForceDisconnect:
                XCTFail("onSuccess ForceDisconnect invalid")
            case .GiveUp:
                expectation.fulfill()
            }
        }
        future.onFailure { _ in
            XCTFail("onFailure called")
        }
        waitForExpectationsWithTimeout(20) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testConnect_WhenDisconnectedWithNoErrorAndExceedsDisconnectRetries_CompletesSuccessfullyWithEventGiveUp() {
        let mockPeripheral = CBPeripheralMock(state:.Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = peripheral.connect(disconnectRetries: 1)
        future.onSuccess { (peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                peripheral.didDisconnectPeripheral(nil)
            case .Timeout:
                XCTFail("onSuccess Timeout invalid")
            case .Disconnect:
                peripheral.reconnect()
                peripheral.didConnectPeripheral()
            case .ForceDisconnect:
                XCTFail("onSuccess ForceDisconnect invalid")
            case .GiveUp:
                expectation.fulfill()
            }
        }
        peripheral.didDisconnectPeripheral(nil)
        future.onFailure { _ in
            XCTFail("onFailure called")
        }
        waitForExpectationsWithTimeout(20) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    
    func testConnect_WhenDisconnectedWithErrorAndExceedsDisconnectRetries_CompletesSuccessfullyWithEventGiveUp() {
        let mockPeripheral = CBPeripheralMock(state:.Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = peripheral.connect(disconnectRetries: 1)
        future.onSuccess { (peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                peripheral.didDisconnectPeripheral(TestFailure.error)
            case .Timeout:
                XCTFail("onSuccess Timeout invalid")
            case .Disconnect:
                XCTFail("onSuccess Disconnect invalid")
            case .ForceDisconnect:
                XCTFail("onSuccess ForceDisconnect invalid")
            case .GiveUp:
                expectation.fulfill()
            }
        }
        peripheral.didDisconnectPeripheral(TestFailure.error)
        future.onFailure { _ in
            peripheral.reconnect()
            peripheral.didConnectPeripheral()
        }
        waitForExpectationsWithTimeout(20) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    // MARK: Read RSSI
    func testReadRSSI_WhenConnected_CompletesSuccessfully() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.readRSSI()
        peripheral.didReadRSSI(NSNumber(int: Int32(self.updatedRSSI1)), error: nil)
        XCTAssertFutureSucceeds(future, context: self.immediateContext) { rssi in
            XCTAssertEqual(rssi, self.updatedRSSI1, "RSSI invalid")
            XCTAssertEqual(peripheral.RSSI, self.updatedRSSI1, "RSSI invalid")
        }
    }

    func testReadRSSI_WhenDisconnected_CompletesWithPeripheralDisconnected() {
        let mockPeripheral = CBPeripheralMock(state: .Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.readRSSI()
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            XCTAssertEqual(error.code, BCError.peripheralDisconnected.code, "Error code invalid")
        }
    }

    func testReadRSSI_WhenConnectedAndErrorInResponse_CompletesWithResponseError() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.readRSSI()
        peripheral.didReadRSSI(NSNumber(int: Int32(self.updatedRSSI1)), error: TestFailure.error)
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
        }
    }

    func testStartPollingRSSI_WhenConnectedAndNoErrorInAck_CompletesSuccessfully() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        mockPeripheral.bcPeripheral = peripheral
        let future = peripheral.startPollingRSSI(0.25)
        let validations: [(Int -> Void)] = [
            { (rssi: Int) -> Void in
                XCTAssertEqual(rssi, mockPeripheral.RSSI, "Recieved RSSI invalid")
                XCTAssertEqual(peripheral.RSSI, mockPeripheral.RSSI, "Peripheral RSSI invalid")
                XCTAssertEqual(mockPeripheral.readRSSICalledCount, 1, "readRSSICalled count invalid")
            },
            { (rssi: Int) -> Void in
                XCTAssertEqual(rssi, mockPeripheral.RSSI, "Recieved RSSI invalid")
                XCTAssertEqual(peripheral.RSSI, mockPeripheral.RSSI, "Peripheral RSSI invalid")
                XCTAssertEqual(mockPeripheral.readRSSICalledCount, 2, "readRSSICalled count invalid")
                peripheral.stopPollingRSSI()
            }]
        XCTAssertFutureStreamSucceeds(future, timeout: 120, validations: validations)
    }

    func testStartPollingRSSI_WhenDisconnected_CompletesWithPeripheralDisconnected() {
        let mockPeripheral = CBPeripheralMock(state: .Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.startPollingRSSI()
        XCTAssertFutureStreamFails(future, context:self.immediateContext, validations: [{ error in
            peripheral.stopPollingRSSI()
            XCTAssertEqual(error.code, BCError.peripheralDisconnected.code, "Error code invalid")
        }])
    }


   func testStartPollingRSSI_WhenDisconnectedAfterStart_CompletesWithPeripheralDisconnected() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        mockPeripheral.bcPeripheral = peripheral
        let expectation = expectationWithDescription("expectation fulfilled for future")
        var completed = false
        let future = peripheral.startPollingRSSI(0.25)
        future.onSuccess { rssi in
            if (!completed) {
                completed = true
                XCTAssertEqual(rssi, mockPeripheral.RSSI, "Recieved RSSI invalid")
                XCTAssertEqual(peripheral.RSSI, mockPeripheral.RSSI, "Peripheral RSSI invalid")
                XCTAssertEqual(mockPeripheral.readRSSICalledCount, 1, "readRSSICalled count invalid")
                peripheral.state = .Disconnected
            } else {
                expectation.fulfill()
                XCTFail("onSuccess called")
            }
        }
        future.onFailure { error in
            expectation.fulfill()
            peripheral.stopPollingRSSI()
            XCTAssertEqual(error.code, BCError.peripheralDisconnected.code, "Error code invalid")
        }
        waitForExpectationsWithTimeout(120) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartPollingRSSI_WhenConnectedAndErrorInResponse_CompletedWithResponceError() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = peripheral.startPollingRSSI(0.25)
        mockPeripheral.error = TestFailure.error
        mockPeripheral.bcPeripheral = peripheral
        XCTAssertFutureStreamFails(future, validations: [{ error in
            peripheral.stopPollingRSSI()
            expectation.fulfill()
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
        }])
    }

    func testStopPollingRSSI_WhenConnected_StopsRSSIUpdates() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        var count = 0
        let future = peripheral.startPollingRSSI(0.25)
        mockPeripheral.bcPeripheral = peripheral
        future.onSuccess(QueueContext.global) { _ in
            count += 1
            peripheral.stopPollingRSSI()
        }
        future.onFailure(QueueContext.global) { error in
            XCTFail("onFailure called")
        }
        sleep(5)
        XCTAssertEqual(count, 1, "stopPollingRSSI failed")
    }

    func testStopPollingRSSI_WhenDisconnected_StopsRSSIUpdates() {
        let mockPeripheral = CBPeripheralMock(state: .Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        var count = 0
        let future = peripheral.startPollingRSSI(0.25)
        mockPeripheral.bcPeripheral = peripheral
        future.onSuccess(QueueContext.global) { _ in
            XCTFail("onSuccess called")
        }
        future.onFailure(QueueContext.global) { error in
            count += 1
            peripheral.stopPollingRSSI()
        }
        sleep(5)
        XCTAssertEqual(count, 1, "stopPollingRSSI failed")
   }
}
