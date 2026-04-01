
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'localization_services.dart';

class ApiServices {
  static const String baseUrl = "http://ec2-3-22-111-60.us-east-2.compute.amazonaws.com/rapi";
  static const String imageUrl = "http://ec2-3-22-111-60.us-east-2.compute.amazonaws.com/images/personal/";
  ApiServices() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          "Content-Type": "application/json",
          "Cache-Control": "no-cache",
        },
      ),
    );
  }

  late final Dio _dio;

  Dio get client => _dio;

  /* -------------------------------------------------------------------------- */
  /*                            Connectivity Check                               */
  /* -------------------------------------------------------------------------- */

  Future<void> _checkConnectivity() async {
    final locale = localizationService.loc;
    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult.contains(ConnectivityResult.none)) {
      throw locale.noInternet;
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                              Error Handling                                */
  /* -------------------------------------------------------------------------- */

  String _handleError(DioException e) {
    final tr = localizationService.loc;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return tr.timeOutMessage;

      case DioExceptionType.cancel:
        return tr.requestCancelMessage;

      case DioExceptionType.connectionError:
        return tr.noInternet;

      case DioExceptionType.badResponse:
        switch (e.response?.statusCode) {
          case 400:
            return tr.badRequest;
          case 401:
            return tr.unAuthorized;
          case 403:
            return tr.forbidden;
          case 404:
            return tr.url404;
          case 405:
            return tr.notAllowedError;
          case 500:
            return tr.internalServerError;
          case 503:
            return tr.serviceUnavailable;
          default:
            return "${tr.serverError}: ${e.response?.statusCode}";
        }

      default:
        return tr.networkError;
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                   GET                                      */
  /* -------------------------------------------------------------------------- */

  Future<Response> get({
    required String endpoint,
    Map<String, dynamic>? queryParams,
    CancelToken? cancelToken,
  }) async {
    try {
      await _checkConnectivity();
      return await _dio.get(
        endpoint,
        queryParameters: queryParams,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw e.toString();
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                   POST                                     */
  /* -------------------------------------------------------------------------- */

  Future<Response> post({
    required String endpoint,
    required dynamic data,
    CancelToken? cancelToken,
  }) async {
    try {
      await _checkConnectivity();
      return await _dio.post(
        endpoint,
        data: data,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw e.toString();
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                   PUT                                      */
  /* -------------------------------------------------------------------------- */

  Future<Response> put({
    required String endpoint,
    required dynamic data,
    CancelToken? cancelToken,
  }) async {
    try {
      await _checkConnectivity();
      return await _dio.put(
        endpoint,
        data: data,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw e.toString();
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                  DELETE                                    */
  /* -------------------------------------------------------------------------- */

  Future<Response> delete({
    required String endpoint,
    dynamic data,
    CancelToken? cancelToken,
  }) async {
    try {
      await _checkConnectivity();
      return await _dio.delete(
        endpoint,
        data: data,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw e.toString();
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                               FILE UPLOAD                                  */
  /* -------------------------------------------------------------------------- */

  Future<Response> uploadFile({
    required String endpoint,
    required FormData data,
    CancelToken? cancelToken,
  }) async {
    try {
      await _checkConnectivity();
      return await _dio.post(
        endpoint,
        data: data,
        cancelToken: cancelToken,
        options: Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw e.toString();
    }
  }

  // Add this method to your ApiServices class after the uploadFile method:

/* -------------------------------------------------------------------------- */
/*                              FILE DOWNLOAD                                 */
/* -------------------------------------------------------------------------- */

  Future<Response> downloadFile({
    required String endpoint,
    required String savePath,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      await _checkConnectivity();
      return await _dio.download(
        endpoint,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw e.toString();
    }
  }

}


