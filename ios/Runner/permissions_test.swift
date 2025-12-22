//
//  permissions_test.swift
//  Runner
//
//  Created by TraeAI on 2025/12/19.
//  用于测试iOS权限配置
//

import Foundation
import CoreBluetooth
import CoreLocation
import AVFoundation
import Photos
import Contacts
import EventKit
import MediaPlayer
import Speech
import UserNotifications
import AppTrackingTransparency
import BackgroundTasks
import CallKit
import HealthKit
import Intents
import LocalAuthentication
import MapKit
import MessageUI
import Network
import PassKit
import PushKit
import QuickLook
import SafariServices
import StoreKit
import SystemConfiguration
import UIKit
import WebKit

// 权限测试类
class PermissionsTest {
    
    // 检查蓝牙权限状态
    func checkBluetoothPermission() {
        if #available(iOS 13.0, *) {
            let status = CBManager.authorization
            print("蓝牙权限状态: \(status)")
            
            switch status {
            case .notDetermined:
                print("蓝牙权限: 未决定")
            case .restricted:
                print("蓝牙权限: 受限")
            case .denied:
                print("蓝牙权限: 拒绝")
            case .allowedAlways:
                print("蓝牙权限: 允许始终")
            case .allowedWhenInUse:
                print("蓝牙权限: 允许使用时")
            @unknown default:
                print("蓝牙权限: 未知")
            }
        } else {
            print("iOS 13以下，蓝牙权限检查方式不同")
        }
    }
    
    // 检查位置权限状态
    func checkLocationPermission() {
        let status = CLLocationManager.authorizationStatus()
        print("位置权限状态: \(status)")
        
        switch status {
        case .notDetermined:
            print("位置权限: 未决定")
        case .restricted:
            print("位置权限: 受限")
        case .denied:
            print("位置权限: 拒绝")
        case .authorizedAlways:
            print("位置权限: 允许始终")
        case .authorizedWhenInUse:
            print("位置权限: 允许使用时")
        @unknown default:
            print("位置权限: 未知")
        }
    }
    
    // 检查所有相关权限
    func checkAllPermissions() {
        print("=== 权限检查开始 ===")
        
        // 蓝牙权限
        if #available(iOS 13.0, *) {
            checkBluetoothPermission()
        }
        
        // 位置权限
        checkLocationPermission()
        
        // 相机权限
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        print("相机权限: \(cameraStatus)")
        
        // 照片库权限
        let photoStatus = PHPhotoLibrary.authorizationStatus()
        print("照片库权限: \(photoStatus)")
        
        // 麦克风权限
        let audioStatus = AVAudioSession.sharedInstance().recordPermission
        print("麦克风权限: \(audioStatus)")
        
        print("=== 权限检查结束 ===")
    }
    
    // 请求蓝牙权限（用于测试）
    func requestBluetoothPermission() {
        if #available(iOS 13.0, *) {
            let centralManager = CBCentralManager(delegate: nil, queue: nil)
            print("蓝牙管理器状态: \(centralManager.state)")
        }
    }
    
    // 请求位置权限（用于测试）
    func requestLocationPermission() {
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        print("已请求位置权限")
    }
}

// 使用示例：
// let test = PermissionsTest()
// test.checkAllPermissions()
// test.requestBluetoothPermission()
// test.requestLocationPermission()