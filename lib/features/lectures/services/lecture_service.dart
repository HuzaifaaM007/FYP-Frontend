import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/lecture.dart';
import '../models/lecture_detail.dart';


class LectureService {
  final _dio = ApiClient().dio;


  Future<Lecture> uploadLecture(String? filePath, String fileName, {Uint8List? bytes}) async {
  final part = bytes != null
      ? MultipartFile.fromBytes(bytes, filename: fileName)
      : await MultipartFile.fromFile(filePath!, filename: fileName);
  final response = await _dio.post('/lectures/upload',
      data: FormData.fromMap({'file': part}),
      options: Options(receiveTimeout: const Duration(minutes: 3)));
  return Lecture.fromJson(response.data);
}

Future<void> deleteLecture(String lectureId) async {
  await _dio.delete('/lectures/$lectureId');
}
  Future<List<Lecture>> listLectures() async {
    final response = await _dio.get('/lectures');
    return (response.data as List).map((item) => Lecture.fromJson(item)).toList();
  }

  Future<LectureDetail> getLecture(String lectureId) async {
    final response = await _dio.get('/lectures/$lectureId');
    return LectureDetail.fromJson(response.data);
  }

  Future<LectureDetail> generateSummary(String lectureId, {int maxWords = 220}) async {
    await _dio.post(
      '/lectures/$lectureId/summary',
      data: {'max_words': maxWords},
      options: Options(receiveTimeout: const Duration(minutes: 2)),
    );
    return getLecture(lectureId); // re-fetch full detail so the UI has topics + summary together
  }
}