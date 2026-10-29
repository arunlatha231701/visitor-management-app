import 'package:visitor_management_app/data/datasources/visitor/visitor_remote_data_source.dart';
import 'package:visitor_management_app/data/models/visitor/visitor_response_model.dart';
import 'package:visitor_management_app/domain/entities/visitor/visitor_entity.dart';
import 'package:visitor_management_app/domain/repositories/visitor/visitor_repository.dart';

class VisitorRepositoryImpl implements VisitorRepository {
  const VisitorRepositoryImpl(this.remoteDataSource);

  final VisitorRemoteDataSource remoteDataSource;

  Visitor _toEntity(VisitorModel model) {
    return Visitor(
      id: model.id,
      name: model.name,
      mobile: model.mobile,
      email: model.email,
      visitorsType: model.visitorsType,
      project: model.project,
      purpose: model.purpose,
      status: model.status,
      createdAt: model.createdAt,
      checkInTime: model.checkInTime,
      checkOutTime: model.checkOutTime,
    );
  }

  VisitorModel _toModel(Visitor visitor) {
    return VisitorModel(
      id: visitor.id,
      name: visitor.name,
      mobile: visitor.mobile,
      email: visitor.email,
      visitorsType: visitor.visitorsType,
      project: visitor.project,
      purpose: visitor.purpose,
      status: visitor.status,
      createdAt: visitor.createdAt,
      checkInTime: visitor.checkInTime,
      checkOutTime: visitor.checkOutTime,
    );
  }

  @override
  Future<List<Visitor>> getVisitors() async {
    final models = await remoteDataSource.getVisitors();
    return models.map(_toEntity).toList();
  }

  @override
  Future<Visitor> getVisitorsById(String id) async {
    final model = await remoteDataSource.getVisitorsById(id);
    return _toEntity(model);
  }

  @override
  Future<Visitor> createVisitor(Visitor visitor) async {
    final model = await remoteDataSource.createVisitor(
      _toModel(visitor),
    );

    return _toEntity(model);
  }

  @override
  Future<Visitor> updateVisitor(String id, Visitor visitor) async {
    final model = await remoteDataSource.updateVisitor(
      id,
      _toModel(visitor),
    );

    return _toEntity(model);
  }

  @override
  Future<void> deleteVisitor(String id) {
    return remoteDataSource.deleteVisitor(id);
  }
}