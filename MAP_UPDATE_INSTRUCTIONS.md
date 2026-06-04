# Cập Nhật Bản Đồ Vệ Tinh

## Những thay đổi đã thực hiện

1. **Thêm Dependency**: Đã thêm `google_maps_flutter: ^2.5.0` vào `pubspec.yaml`

2. **Viết lại CustomMap.dart**: 
   - Thay thế bản đồ mô phỏng bằng CustomPaint bằng bản đồ thực tế từ Google Maps
   - Sử dụng `MapType.satellite` để hiển thị ảnh vệ tinh
   - Giữ nguyên tất cả chức năng existente:
     - Hiển thị vị trí người cao tuổi (marker)
     - Hiển thị vị trí nhà/vùng an toàn trung tâm (marker)
     - Vẽ vòng tròn vùng an toàn (circle)
     - Hiển thị đường dẫn SOS khi ở chế độ khẩn cấp (polyline)
     - Các nút điều khiển (recenter, zoom in/out)

3. **Cấu hình API Key**:
   - **Android**: Thêm vào `android/app/src/main/AndroidManifest.xml`:
     ```xml
     <meta-data
         android:name="com.google.android.geo.API_KEY"
         android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"/>
     ```
   - **iOS**: Thêm vào `ios/Runner/Info.plist`:
     ```xml
     <key>GMSServicesAPIKey</key>
     <string>YOUR_GOOGLE_MAPS_API_KEY_HERE</string>
     ```

## Hướng dẫn lấy Google Maps API Key

Để bản đồ vệ tinh hoạt động properly, bạn cần lấy một API key từ Google Cloud Console:

1. Truy cập [Google Cloud Console](https://console.cloud.google.com/)
2. Tạo một dự án mới hoặc chọn dự án hiện có
3. Bật "Maps SDK for Android" và "Maps SDK for iOS"
4. Vào "Credentials" → "Create credentials" → "API key"
5. Sao chép API key và thay thế `"YOUR_GOOGLE_MAPS_API_KEY_HERE"` bằng key thực tế của bạn
6. (Tùy chọn) Giới hạn API key để chỉ cho phép sử dụng với các SDK của bạn để tăng bảo mật

## Lưu ý quan trọng

- Khi chạy ứng dụng lần đầu, bản đồ có thể hiển thị màn hình loading cho đến khi khởi tạo hoàn tất
- Đảm bảo thiết bị có kết nối internet để tải xuống bản đồ vệ tinh
- Độ zoom mặc định được设为 15.0 để hiển thị đủ chi tiết địa hình
- Trong chế độ SOS, đường dẫn sẽ được hiển thị bằng línea đỏ đứt đoạn từ nhà tới vị trí người cao tuổi
- Tất cả các marker và vòng tròn sẽ tự động cập nhật khi có thay đổi dữ liệu

## Khắc phục sự cố

Nếu thấy lỗi "API key not found" hoặc bản đồ không hiển thị:
1. Kiểm tra lại rằng bạn đã đặt đúng API key trong cả hai file cấu hình
2. Đảm bảo đã bật Maps SDK for Android/iOS trong Google Cloud Console
3. Kiểm tra kết nối internet của thiết bị
4. Xóa cache và chạy lại ứng dụng: `flutter clean && flutter pub get && flutter run`