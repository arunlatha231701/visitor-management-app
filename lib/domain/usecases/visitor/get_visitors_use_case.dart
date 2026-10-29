import 'package:visitor_management_app/domain/entities/visitor/visitor_entity.dart';
import 'package:visitor_management_app/domain/repositories/visitor/visitor_repository.dart';

class GetVisitorsUseCase {
  const GetVisitorsUseCase(this._visitorRepository);

  final VisitorRepository _visitorRepository;

  Future<List<Visitor>> call() {
    return _visitorRepository.getVisitors();
  }
}