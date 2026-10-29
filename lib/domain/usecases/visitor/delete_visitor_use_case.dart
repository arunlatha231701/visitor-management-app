import 'package:visitor_management_app/domain/repositories/visitor/visitor_repository.dart';

class DeleteVisitorUseCase {
  const DeleteVisitorUseCase(this._visitorRepository);

  final VisitorRepository _visitorRepository;

  Future<void> call(String id) {
    return _visitorRepository.deleteVisitor(id);
  }
}