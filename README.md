# HypoGuardian – iOS Hypoglycemia Prediction App (Public Demo)

## 📖 Overview

HypoGuardian is an iOS application prototype designed to explore how mobile apps can support diabetes management by visualizing glucose data and providing hypoglycemia risk predictions.

This public repository contains a **UI and architecture demo version** of the app.  
Proprietary machine learning models and research-specific algorithms are excluded due to confidentiality constraints.

## 📱 Application Features

- Built with **SwiftUI**.
- Integration-ready for **Apple HealthKit** glucose data.
- Interactive daily glucose charts.
- MVVM architecture with clean separation of concerns.
- Prepared for **on-device ML inference using CoreML**.

<img width="483" height="523" alt="app_screenshot" src="https://github.com/user-attachments/assets/d8e6bdb1-5034-47f7-8196-587c96fe4cae" />

## 🧠 Technical Background

The original project combines mobile development and machine learning:

- Designed and implemented an iOS application to predict hypoglycemia events using **on-device ML inference with CoreML and HealthKit data**.
- **Built Python pipelines for data preprocessing and model training to generate CoreML models used in the mobile app.**
- Applied convolutional neural networks (CNNs) to identify glucose patterns and improve prediction accuracy.

> This demo repository does not include the original ML models, training code or proprietary algorithms.

<img width="1702" height="1408" alt="arch-diagram" src="https://github.com/user-attachments/assets/e049a5d9-5fc7-45f4-9f43-16d6a7fce0f1" />

## 🛠️ Tech Stack

- **iOS App**: SwiftUI, SwiftData, HealthKit
- **Architecture**: MVVM
- **Machine Learning (excluded in demo)**: CoreML (model integration layer mocked)

## 🎓 Context

This project was originally developed as part of my Final Degree Project in Computer Engineering.  
This repository showcases the **mobile architecture and UI design only**.

