# Beacons Plugin Test

Flutter `beacons_plugin` 套件測試。

`archived/main.dart` 為官方範例，基本上沒有修改。


## 參考資料

* **`beacons_plugin` 的 pub.dev 主頁**<br>
  [beacons_plugin | Flutter Package](https://pub.dev/packages/beacons_plugin)<br>
  **`beacons_plugin` 的 GitHub 主頁**<br>
  [umair13adil/simple_beacons_flutter: A flutter plugin project to range & monitor iBeacons.](https://github.com/umair13adil/simple_beacons_flutter)

* **如何改寫別人的 library**（簡單結論：自己 fork 一個）<br>
  [How to modify an existing pub package to use in your flutter project | by Dhavalkansara | Flutter Community | Medium](https://medium.com/flutter-community/how-to-modify-an-existing-pub-package-to-use-in-your-flutter-project-4e909452ee66)

* **建置自己的 Android 套件**<br>
  [Android Library建置：建立自己的Android 套件 – RayHung-PGR](https://rayhungpdpgrbarista.wordpress.com/2018/07/18/android-library建置：建立自己的android-套件/)<br>
  *注意：*
    1. `build.gradle` 的設定，可於最後要把專案推上 JitPack.io 時，直接參考官方的 How to 即可<br>
       （原文是 2018 年的方法，已經過時，尤其 `com.github.dcendents:android-maven-gradle-plugin` 套件本身都已經 abandon 了）
    2. `./gradlew wrapper` 指令，若執行時一直報錯（如 `Could not initialize class org.codehaus.groovy.runtime.InvokerHelper`），可先執行 `gradle wrapper`

* **Kotlin log 工具 `Timber` 的 GitHub 主頁**（`beacons_plugin` 有用到）<br>
  [JakeWharton/timber: A logger with a small, extensible API which provides utility on top of Android's normal Log class.](https://github.com/JakeWharton/timber)

* **Dart 官方關於 `DateFormat` 的說明文件**<br>
  [DateFormat class - intl library - Dart API](https://api.flutter.dev/flutter/intl/DateFormat-class.html)

* **`ansicolor` 的 pub.dev 主頁**<br>
  [ansicolor | Dart Package](https://pub.dev/packages/ansicolor)

* **ANSI 256 色**<br>
  [ANSI跳脫序列 - 維基百科，自由的百科全書](https://zh.wikipedia.org/wiki/ANSI转义序列#8位)

* **`get_mac` 的 pub.dev 主頁**<br>
  [get_mac | Flutter Package](https://pub.dev/packages/get_mac)<br>
  **`get_mac` 的 GitLab 主頁**<br>
  [Vinod Dirishala / Get MAC Plugin · GitLab](https://gitlab.com/vinod_dirishala/get-mac-plugin)
