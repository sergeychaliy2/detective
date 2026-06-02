import '../entities/case_entity.dart';

abstract interface class CaseRepository {
  Future<List<CaseEntity>> fetchCases();
}
