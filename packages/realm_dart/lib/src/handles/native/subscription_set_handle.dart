// Copyright 2024 MongoDB, Inc.
// SPDX-License-Identifier: Apache-2.0

import 'dart:ffi';

import 'package:cancellation_token/cancellation_token.dart';

import '../../realm_dart.dart';
import '../subscription_set_handle.dart' as intf;
import 'convert.dart';
import 'convert_native.dart';
import 'error_handling.dart';
import 'ffi.dart';
import 'mutable_subscription_set_handle.dart';
import 'realm_bindings.dart';
import 'realm_handle.dart';
import 'realm_library.dart';
import 'results_handle.dart';
import 'rooted_handle.dart';
import 'scheduler_handle.dart';
import 'subscription_handle.dart';
class SubscriptionSetHandle extends RootedHandleBase<realm_flx_sync_subscription_set> implements intf.SubscriptionSetHandle {
  @override
  bool get shouldRoot => true;

  SubscriptionSetHandle(Pointer<realm_flx_sync_subscription_set> pointer, RealmHandle root) : super(root, pointer, 128);

  @override
  void refresh() => realmLib.realm_sync_subscription_set_refresh(pointer).raiseLastErrorIfFalse();

  @override
  int get size => realmLib.realm_sync_subscription_set_size(pointer);

  @override
  Exception? get error {
    final error = realmLib.realm_sync_subscription_set_error_str(pointer);
    final message = error.cast<Utf8>().toRealmDartString(treatEmptyAsNull: true);
    return message.convert(RealmException.new);
  }

  @override
  SubscriptionHandle operator [](int index) => SubscriptionHandle(realmLib.realm_sync_subscription_at(pointer, index));

  @override
  SubscriptionHandle? findByName(String name) {
    return using((arena) {
      final result = realmLib.realm_sync_find_subscription_by_name(
        pointer,
        name.toCharPtr(arena),
      );
      return result.convert(SubscriptionHandle.new);
    });
  }

  @override
  SubscriptionHandle? findByResults(covariant ResultsHandle results) {
    final result = realmLib.realm_sync_find_subscription_by_results(
      pointer,
      results.pointer,
    );
    return result.convert(SubscriptionHandle.new);
  }

  @override
  int get version => realmLib.realm_sync_subscription_set_version(pointer);

  @override
  SubscriptionSetState get state => SubscriptionSetState.values[realmLib.realm_sync_subscription_set_state(pointer)];

  @override
  MutableSubscriptionSetHandle toMutable() => MutableSubscriptionSetHandle(realmLib.realm_sync_make_subscription_set_mutable(pointer), root);

  static void _stateChangeCallback(Object userdata, int state) {
    final completer = userdata as CancellableCompleter<SubscriptionSetState>;
    if (!completer.isCancelled) {
      completer.complete(SubscriptionSetState.values[state]);
    }
  }

  @override
  Future<SubscriptionSetState> waitForStateChange(SubscriptionSetState notifyWhen, [CancellationToken? cancellationToken]) {
    final completer = CancellableCompleter<SubscriptionSetState>(cancellationToken);
    if (!completer.isCancelled) {
      final callback = Pointer.fromFunction<Void Function(Handle, Int32)>(_stateChangeCallback);
      final userdata = realmLib.realm_dart_userdata_async_new(completer, callback.cast(), schedulerHandle.pointer);
      realmLib.realm_sync_on_subscription_set_state_change_async(pointer, notifyWhen.index,
          realmLib.addresses.realm_dart_sync_on_subscription_state_changed_callback, userdata.cast(), realmLib.addresses.realm_dart_userdata_async_free);
    }
    return completer.future;
  }
}
