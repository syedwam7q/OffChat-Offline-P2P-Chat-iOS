# OffChat Deployment Guide

This document outlines the process for building, testing, and deploying the OffChat application to the App Store and for internal testing.

## Prerequisites

Before deploying OffChat, ensure you have the following:

- **Apple Developer Account**: Active membership in the Apple Developer Program ($99/year)
- **Xcode**: Version 15.0 or later
- **Certificates and Profiles**: Valid distribution certificates and provisioning profiles
- **App Store Connect Access**: Appropriate permissions to submit builds
- **Marketing Assets**: App icon, screenshots, and promotional text
- **Privacy Policy**: A URL to your privacy policy (required for all apps)

## Deployment Preparation

### 1. Version Management

Update the version information in the project:

1. Open the project in Xcode
2. Select the OffChat target
3. Go to the "General" tab
4. Update the "Version" (e.g., 1.0.0) and "Build" numbers (e.g., 1)

Alternatively, update the version in the project.yml file and regenerate the project:

```yaml
# In project.yml
targets:
  OffChat:
    settings:
      MARKETING_VERSION: 1.0.0
      CURRENT_PROJECT_VERSION: 1
```

Then regenerate the project:

```bash
xcodegen generate
```

### 2. Code Signing Configuration

Ensure proper code signing is configured:

1. In Xcode, select the OffChat project
2. Select the OffChat target
3. Go to the "Signing & Capabilities" tab
4. Select your Team
5. Ensure "Automatically manage signing" is checked
6. Verify that the signing certificate is set to "Apple Distribution" for Release builds

### 3. App Store Connect Setup

Before submitting your build, set up the app in App Store Connect:

1. Log in to [App Store Connect](https://appstoreconnect.apple.com/)
2. Go to "Apps" and click the "+" button to create a new app
3. Fill in the required information:
   - Platform: iOS
   - App Name: OffChat
   - Primary Language: English (or your preferred language)
   - Bundle ID: Select the bundle ID from your developer account
   - SKU: A unique identifier for your app (e.g., com.yourcompany.offchat)
4. Click "Create"

### 4. App Information

Complete the App Store listing information:

1. App Information:
   - Privacy Policy URL
   - Category: Social Networking
   
2. Pricing and Availability:
   - Set price (or free)
   - Select available territories

3. App Review Information:
   - Contact information
   - Notes for the review team (explain that the app requires two physical devices for testing)
   - Demo account (if applicable)

4. Version Information:
   - App description
   - Keywords
   - Support URL
   - Marketing URL (optional)
   - Promotional text (optional)

### 5. App Store Screenshots

Prepare screenshots for all required device sizes:

- iPhone 6.5" Display (iPhone 11 Pro Max, iPhone XS Max)
- iPhone 5.5" Display (iPhone 8 Plus, iPhone 7 Plus)
- iPhone 5.8" Display (iPhone 11 Pro, iPhone X)
- iPad Pro 12.9" Display (3rd generation)
- iPad Pro 11" Display

Use the following script to capture screenshots for all required devices:

```bash
# Example using fastlane snapshot
fastlane snapshot
```

## Build and Archive

### 1. Prepare for Submission

Before archiving, perform these final checks:

- Run all unit and UI tests to ensure everything passes
- Verify app functionality on multiple device types
- Check that all required app permissions are properly configured in Info.plist
- Ensure all third-party dependencies are up to date
- Verify that the app icon and launch screen are properly set up

### 2. Create Archive

Create an archive of your app for submission:

1. In Xcode, select the OffChat scheme
2. Select "Generic iOS Device" as the build destination
3. Select Product > Archive from the menu
4. Wait for the archiving process to complete

### 3. Validate Archive

Validate the archive before submission:

1. In the Xcode Organizer (Window > Organizer), select the archive you just created
2. Click "Validate App"
3. Select your distribution method (App Store Connect)
4. Follow the prompts to validate the app
5. Address any validation issues that arise

## App Store Submission

### 1. Upload to App Store Connect

Upload the validated archive:

1. In the Xcode Organizer, select the validated archive
2. Click "Distribute App"
3. Select "App Store Connect" as the distribution method
4. Follow the prompts to upload the build
5. Wait for the upload to complete and for App Store Connect to process the build

### 2. Submit for Review

Once the build is processed in App Store Connect:

1. Log in to App Store Connect
2. Select your app and the version you just uploaded
3. Complete any missing information
4. Click "Submit for Review"

### 3. Monitor Review Status

Monitor the review status in App Store Connect:

1. The app will initially show "Waiting for Review"
2. It will then move to "In Review"
3. Finally, it will either be "Approved" or "Rejected"
4. If rejected, address the issues and resubmit

## TestFlight Distribution

For beta testing before App Store release:

### 1. Internal Testing

Set up internal testing with your development team:

1. In App Store Connect, go to your app
2. Select the "TestFlight" tab
3. Under "Internal Testing", add team members by email
4. Once your build is processed, enable it for internal testing

### 2. External Testing

Set up external testing with users outside your development team:

1. In the "TestFlight" tab, go to "External Testing"
2. Create a new group (e.g., "Beta Testers")
3. Add email addresses of external testers
4. Provide test information (what to test, known issues)
5. Submit for review (external testing requires App Review approval)
6. Once approved, invite your external testers

## Automated Deployment

For more efficient deployment, consider setting up CI/CD:

### Using GitHub Actions

Create a workflow file for automated builds:

```yaml
# .github/workflows/deploy.yml
name: Deploy to TestFlight

on:
  push:
    branches: [ main ]
    tags: [ 'v*' ]

jobs:
  build:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Set up Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: '15.0'
    
    - name: Install dependencies
      run: |
        brew install xcodegen
        xcodegen generate
    
    - name: Setup provisioning profile
      env:
        PROVISIONING_PROFILE_BASE64: ${{ secrets.PROVISIONING_PROFILE_BASE64 }}
        CERTIFICATE_BASE64: ${{ secrets.CERTIFICATE_BASE64 }}
        P12_PASSWORD: ${{ secrets.P12_PASSWORD }}
      run: |
        # Decode and install certificate and provisioning profile
        mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
        echo -n "$PROVISIONING_PROFILE_BASE64" | base64 --decode > ~/Library/MobileDevice/Provisioning\ Profiles/profile.mobileprovision
        echo -n "$CERTIFICATE_BASE64" | base64 --decode > certificate.p12
        security create-keychain -p "" build.keychain
        security import certificate.p12 -t agg -k build.keychain -P "$P12_PASSWORD" -A
        security list-keychains -s build.keychain
        security default-keychain -s build.keychain
        security unlock-keychain -p "" build.keychain
        security set-key-partition-list -S apple-tool:,apple: -s -k "" build.keychain
    
    - name: Build and archive
      env:
        APPLE_ID: ${{ secrets.APPLE_ID }}
        APPLE_APP_SPECIFIC_PASSWORD: ${{ secrets.APPLE_APP_SPECIFIC_PASSWORD }}
      run: |
        xcodebuild -project OffChat.xcodeproj -scheme OffChat -configuration Release -archivePath $RUNNER_TEMP/OffChat.xcarchive archive
        xcodebuild -exportArchive -archivePath $RUNNER_TEMP/OffChat.xcarchive -exportOptionsPlist ExportOptions.plist -exportPath $RUNNER_TEMP/build
        xcrun altool --upload-app --type ios --file $RUNNER_TEMP/build/OffChat.ipa --username "$APPLE_ID" --password "$APPLE_APP_SPECIFIC_PASSWORD"
```

Create an ExportOptions.plist file:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
</dict>
</plist>
```

### Using Fastlane

For more advanced automation, set up Fastlane:

1. Install Fastlane:
```bash
brew install fastlane
```

2. Initialize Fastlane in your project:
```bash
cd OffChat
fastlane init
```

3. Configure Fastfile:
```ruby
# Fastfile
default_platform(:ios)

platform :ios do
  desc "Build and upload to TestFlight"
  lane :beta do
    # Generate project
    sh("xcodegen generate")
    
    # Update build number
    increment_build_number
    
    # Build the app
    build_app(
      scheme: "OffChat",
      export_method: "app-store"
    )
    
    # Upload to TestFlight
    upload_to_testflight(
      skip_waiting_for_build_processing: true
    )
  end
  
  desc "Build and upload to App Store"
  lane :release do
    # Generate project
    sh("xcodegen generate")
    
    # Update version and build number
    increment_version_number
    increment_build_number
    
    # Build the app
    build_app(
      scheme: "OffChat",
      export_method: "app-store"
    )
    
    # Upload to App Store
    upload_to_app_store(
      skip_metadata: false,
      skip_screenshots: false,
      submit_for_review: true,
      force: true,
      automatic_release: true
    )
  end
end
```

## Post-Deployment Tasks

After successful deployment:

### 1. Version Control

Tag the release in your version control system:

```bash
git tag -a v1.0.0 -m "Version 1.0.0"
git push origin v1.0.0
```

### 2. Documentation

Update documentation to reflect the released version:

- Update README.md with the latest version information
- Update changelog.md with the changes in this version

### 3. Monitoring

Set up monitoring for the released app:

- Configure crash reporting (e.g., Firebase Crashlytics)
- Set up analytics to track user engagement
- Monitor App Store reviews

## App Store Optimization

To improve visibility in the App Store:

### 1. Keywords

Choose relevant keywords that potential users might search for:
- offline messaging
- peer-to-peer chat
- no internet chat
- bluetooth messaging
- local network chat

### 2. App Description

Craft a compelling app description:
- Start with a strong, clear first paragraph (visible without expanding)
- Highlight key features and benefits
- Use bullet points for readability
- Include testimonials if available

### 3. Screenshots and Preview Video

Create visually appealing screenshots:
- Show the app in action with real-world scenarios
- Add captions highlighting key features
- Consider creating an app preview video (up to 30 seconds)

## Troubleshooting Common Deployment Issues

### 1. Provisioning Profile Issues

If you encounter provisioning profile errors:
- Verify that your Apple Developer account has the correct entitlements
- Regenerate provisioning profiles in the Apple Developer portal
- Ensure the bundle identifier matches your registered App ID

### 2. App Store Rejection

Common reasons for rejection and solutions:
- **Incomplete Information**: Ensure all required metadata is provided
- **Crashes**: Thoroughly test on all supported devices
- **Privacy Concerns**: Implement proper permission requests and privacy policy
- **Misleading Description**: Ensure app description accurately reflects functionality

### 3. TestFlight Processing Issues

If your build is stuck in processing:
- Check that the build was uploaded successfully
- Verify that the build number is higher than previous builds
- Wait at least 30 minutes (processing can take time)
- If still stuck after several hours, contact Apple Developer Support

## Release Checklist

Use this checklist for each release:

- [ ] Update version and build numbers
- [ ] Run all tests and fix any failures
- [ ] Verify all required permissions are properly configured
- [ ] Check that app icons and launch screen are properly set up
- [ ] Archive and validate the build
- [ ] Upload to App Store Connect
- [ ] Complete all required metadata in App Store Connect
- [ ] Submit for review
- [ ] Tag the release in version control
- [ ] Update documentation
- [ ] Prepare marketing materials for launch
- [ ] Monitor review status
- [ ] After approval, announce the release to users