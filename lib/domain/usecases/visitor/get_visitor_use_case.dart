import 'package:visitor_management_app/domain/entities/visitor/visitor_entity.dart';
import 'package:visitor_management_app/domain/repositories/visitor/visitor_repository.dart';

class GetVisitorUseCase {
  const GetVisitorUseCase(this._visitorRepository);

  final VisitorRepository _visitorRepository;

  Future<Visitor> call(String id) {
    return _visitorRepository.getVisitorsById(id);
  }
}