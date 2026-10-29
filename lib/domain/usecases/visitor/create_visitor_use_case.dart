import 'package:visitor_management_app/domain/entities/visitor/visitor_entity.dart';
import 'package:visitor_management_app/domain/repositories/visitor/visitor_repository.dart';

class CreateVisitorUseCase {
  const CreateVisitorUseCase(this._visitorRepository);

  final VisitorRepository _visitorRepository;

  Future<Visitor> call(Visitor visitor) {
    return _visitorRepository.createVisitor(visitor);
  }
}