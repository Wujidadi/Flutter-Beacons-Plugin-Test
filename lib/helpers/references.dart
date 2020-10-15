/// 限定目標基站或 beacon 的名稱及 UUID
final Map<String, String> myUuid = {
    'Region1': '0a4d8b73-7f74-4a83-b2ca-4fe84e870427',  // STU
    'Region2': '0a4d8b73-7f74-4a83-b2ca-4fe84e870437',  // TUT
    'Region3': 'b5b182c7-eab1-4988-aa99-b5c1517008d9'
};

/// 執行定期動作的時間間隔
final Duration period = const Duration(seconds: 1);

/// Beacon 未回傳過期時限（微秒）
final int beaconExpiredMus = 5 * 1000000;
