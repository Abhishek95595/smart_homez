# Open Smart Homez on Windows with Android Studio

## Requirements

1. Install the latest stable Flutter SDK that includes Dart 3.9.2 or newer.
2. Add Flutter's `bin` directory to the Windows PATH.
3. Install Android Studio with the Flutter and Dart plugins.
4. In Android Studio's SDK Manager, install an Android SDK and Android SDK Command-line Tools.

## Open and run

1. Extract this ZIP to a short path, for example `C:\FlutterProjects\smart_homez`.
2. In Android Studio, choose **Open** and select the extracted `smart_homez` folder (the folder containing `pubspec.yaml`). Do not open only the `android` folder.
3. Open Android Studio's terminal in the project root and run:

   ```powershell
   flutter doctor
   flutter pub get
   flutter run
   ```

4. Choose an Android emulator or a connected Android phone from the device selector.

## Run as a Windows desktop application

Install Visual Studio 2022 (not Visual Studio Code) with **Desktop development with C++**, then run:

```powershell
flutter config --enable-windows-desktop
flutter doctor
flutter pub get
flutter run -d windows
```

The project intentionally does not contain `android/local.properties`; Flutter creates it with the correct SDK paths for your Windows computer.
