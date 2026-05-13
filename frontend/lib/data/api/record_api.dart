import 'package:xiaojia_ledger/data/api/api_client.dart';
import 'package:xiaojia_ledger/data/models/api_response.dart';
import 'package:xiaojia_ledger/data/models/record.dart';

class RecordApi {
  static final ApiClient _client = ApiClient();

  static Future<ApiResponse<List<Record>>> getRecords({String? month}) async {
    final response = await _client.get('/records',
        queryParameters: month != null ? {'month': month} : null);
    final apiResp = ApiResponse.fromJson(response.data, null);
    if (apiResp.isSuccess && apiResp.data != null) {
      final list = (apiResp.data as List<dynamic>)
          .map((e) => Record.fromJson(e))
          .toList();
      return ApiResponse(code: 0, message: 'ok', data: list);
    }
    return ApiResponse(code: apiResp.code, message: apiResp.message);
  }

  static Future<ApiResponse<Record>> addRecord({
    required String type,
    required double amount,
    required int categoryId,
    required String date,
    String? note,
  }) async {
    final response = await _client.post('/records', data: {
      'type': type,
      'amount': amount,
      'category_id': categoryId,
      'date': date,
      'note': note ?? '',
    });
    final apiResp = ApiResponse.fromJson(response.data, Record.fromJson);
    return apiResp;
  }

  static Future<bool> updateRecord(int id, String field, dynamic value) async {
    final response = await _client
        .put('/records/$id', data: {'field': field, 'value': value});
    return response.data['code'] == 0;
  }

  static Future<bool> deleteRecord(int id) async {
    final response = await _client.delete('/records/$id');
    return response.data['code'] == 0;
  }
}
