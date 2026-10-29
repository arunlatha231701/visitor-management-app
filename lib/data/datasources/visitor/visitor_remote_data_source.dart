import 'package:visitor_management_app/core/errors/app_exception.dart';
import 'package:visitor_management_app/core/network/api_service.dart';
import 'package:visitor_management_app/data/models/visitor/visitor_response_model.dart';

abstract class VisitorRemoteDataSource {
  Future<List<VisitorModel>> getVisitors();

  Future<VisitorModel> getVisitorsById(String id);

  Future<VisitorModel> createVisitor(VisitorModel visitor);

  Future<VisitorModel> updateVisitor(
      String id,
      VisitorModel visitor,
      );

  Future<void> deleteVisitor(String id);
}

class VisitorRemoteDataSourceImpl implements VisitorRemoteDataSource {
  VisitorRemoteDataSourceImpl(this.apiService);

  final ApiService apiService;

  Map<String, dynamic>? _extractVisitor(dynamic response) {
    if (response is! Map) return null;

    final json = Map<String, dynamic>.from(response);
    final data = json['data'];

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return json.containsKey('id') ? json : null;
  }

  @override
  Future<List<VisitorModel>> getVisitors() async {
    final response = await apiService.get('/visitors');
    final data = response is Map ? response['data'] : response;

    if (data is! List) {
      throw const AppException(
        'Invalid visitors response from the server.',
      );
    }

    return data.map<VisitorModel>((item) {
      if (item is! Map) {
        throw const AppException(
          'Invalid visitor item in API response.',
        );
      }

      return VisitorModel.fromJson(
        Map<String, dynamic>.from(item),
      );
    }).toList();
  }

  @override
  Future<VisitorModel> getVisitorsById(String id) async {
    final response = await apiService.get('/visitors/$id');
    final visitor = _extractVisitor(response);

    if (visitor == null) {
      throw const AppException(
        'Invalid visitor response from the server.',
      );
    }

    return VisitorModel.fromJson(visitor);
  }

  @override
  Future<VisitorModel> createVisitor(VisitorModel visitor) async {
    final response = await apiService.post(
      '/visitors',
      data: visitor.toJson(included: false),
    );

    final data = _extractVisitor(response);

    if (data == null || data['id'] == null) {
      throw const AppException(
        'The create request returned no visitor ID. '
            'Check the API response to confirm whether the visitor was created.',
      );
    }

    return VisitorModel.fromJson(data);
  }

  @override
  Future<VisitorModel> updateVisitor(
      String id,
      VisitorModel visitor,
      ) async {
    final response = await apiService.put(
      '/visitors/$id',
      data: visitor.toJson(included: false),
    );

    final data = _extractVisitor(response);

    if (data != null) {
      return VisitorModel.fromJson(data);
    }

    return getVisitorsById(id);
  }

  @override
  Future<void> deleteVisitor(String id) async {
    await apiService.delete('/visitors/$id');
  }
}