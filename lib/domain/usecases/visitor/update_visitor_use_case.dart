import 'package:visitor_management_app/domain/entities/visitor/visitor_entity.dart';
import 'package:visitor_management_app/domain/repositories/visitor/visitor_repository.dart';

class UpdateVisitorUseCase {
  const UpdateVisitorUseCase(this._visitorRepository);

  final VisitorRepository _visitorRepository;

  Future<Visitor> call(String id, Visitor visitor) {
    return _visitorRepository.updateVisitor(id, visitor);
  }
}