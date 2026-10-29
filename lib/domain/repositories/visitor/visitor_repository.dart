import 'package:visitor_management_app/domain/entities/visitor/visitor_entity.dart';

abstract interface class VisitorRepository {
  Future<List<Visitor>> getVisitors();

  Future<Visitor> getVisitorsById(String id);

  Future<Visitor> createVisitor(Visitor visitor);

  Future<Visitor> updateVisitor(String id, Visitor visitor);

  Future<void> deleteVisitor(String id);
}