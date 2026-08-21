# Hasomi — Windows-ready Flutter project

This copy is prepared to run on **Windows 10/11** with Android Studio or from a PowerShell terminal.

## 1. Install prerequisites

- Flutter SDK (stable)
- Android Studio
- Flutter + Dart plugins in Android Studio
- For **Windows desktop**: Visual Studio 2022 with **Desktop development with C++**
- Android SDK + Android SDK Command-line Tools

Check your installation:

```powershell
flutter doctor
```

## 2. Run on Windows desktop

From the folder containing `pubspec.yaml`:

```powershell
flutter config --enable-windows-desktop
flutter clean
flutter pub get
flutter run -d windows
```

The Windows executable is named `smart_homez.exe`.

## 3. Run on an Android phone/emulator from Windows

```powershell
flutter clean
flutter pub get
flutter devices
flutter run
```

Select your Android emulator or connected phone in Android Studio.

### Important

The original archive contained an `android/local.properties` file pointing to a Mac path (`/Users/...`). That file has been removed because Flutter must generate it for the Windows machine.

## 4. One-click PowerShell helper

You can also run:

```powershell
.\run_windows.ps1
```

If PowerShell blocks scripts, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\run_windows.ps1
```

## Firebase / authentication

The Windows desktop build does **not** initialize Firebase Phone Auth. Windows uses the app's existing backend OTP endpoints instead. Android/iOS continue to use Firebase Phone Auth.

This avoids requiring a separate Windows Firebase app configuration just to launch the desktop application.

