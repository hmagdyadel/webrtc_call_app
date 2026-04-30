// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:webrtc_call_app/core/network/dio_client.dart' as _i385;
import 'package:webrtc_call_app/features/auth/data/repositories/auth_repository.dart'
    as _i1016;
import 'package:webrtc_call_app/features/auth/data/sources/auth_remote_source.dart'
    as _i980;
import 'package:webrtc_call_app/features/auth/data/sources/user_remote_source.dart'
    as _i1044;
import 'package:webrtc_call_app/features/auth/viewmodel/auth_cubit.dart'
    as _i140;
import 'package:webrtc_call_app/features/chat/data/repositories/chat_repository.dart'
    as _i634;
import 'package:webrtc_call_app/features/chat/data/sources/chat_remote_source.dart'
    as _i552;
import 'package:webrtc_call_app/features/chat/viewmodel/chat_cubit.dart'
    as _i572;
import 'package:webrtc_call_app/features/contacts/data/repositories/contacts_repository.dart'
    as _i689;
import 'package:webrtc_call_app/features/contacts/data/sources/contacts_remote_source.dart'
    as _i88;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.singleton<_i385.DioClient>(() => _i385.DioClient());
    gh.lazySingleton<_i980.AuthRemoteSource>(
      () => _i980.AuthRemoteSourceImpl(),
    );
    gh.lazySingleton<_i88.ContactsRemoteSource>(
      () => _i88.ContactsRemoteSourceImpl(),
    );
    gh.lazySingleton<_i552.ChatRemoteSource>(
      () => _i552.ChatRemoteSourceImpl(),
    );
    gh.lazySingleton<_i1044.UserRemoteSource>(
      () => _i1044.UserRemoteSourceImpl(),
    );
    gh.lazySingleton<_i634.ChatRepository>(
      () => _i634.ChatRepositoryImpl(gh<_i552.ChatRemoteSource>()),
    );
    gh.lazySingleton<_i689.ContactsRepository>(
      () => _i689.ContactsRepositoryImpl(gh<_i88.ContactsRemoteSource>()),
    );
    gh.lazySingleton<_i1016.AuthRepository>(
      () => _i1016.AuthRepositoryImpl(
        gh<_i980.AuthRemoteSource>(),
        gh<_i1044.UserRemoteSource>(),
      ),
    );
    gh.factory<_i140.AuthCubit>(
      () => _i140.AuthCubit(gh<_i1016.AuthRepository>()),
    );
    gh.factory<_i572.ChatCubit>(
      () => _i572.ChatCubit(gh<_i634.ChatRepository>()),
    );
    return this;
  }
}
