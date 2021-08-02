import 'package:matrix/matrix.dart';
import 'package:flushbar/flushbar_helper.dart';
import 'package:flutter/material.dart';

class SimpleDialogs {
  final BuildContext context;

  const SimpleDialogs(this.context);

  Future<dynamic> tryRequestWithLoadingDialog(Future<dynamic> request,
      {Function(MatrixException) onAdditionalAuth}) async {
    final futureResult = tryRequestWithErrorToast(
      request,
      onAdditionalAuth: onAdditionalAuth,
    );
    return showDialog<dynamic>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        futureResult.then(
          (result) => Navigator.of(context).pop<dynamic>(result),
        );
        return AlertDialog(
          title: Text("loadingPleaseWait"),
          content: LinearProgressIndicator(),
        );
      },
    );
  }

  Future<dynamic> tryRequestWithErrorToast(Future<dynamic> request,
      {Function(MatrixException) onAdditionalAuth}) async {
    try {
      return await request;
    } on MatrixException catch (exception) {
      if (exception.requireAdditionalAuthentication &&
          onAdditionalAuth != null) {
        return await tryRequestWithErrorToast(onAdditionalAuth(exception));
      } else {
        await FlushbarHelper.createError(message: exception.errorMessage)
            .show(context);
      }
    } catch (exception) {
      await FlushbarHelper.createError(message: exception.toString())
          .show(context);
    }
    return false;
  }
}
