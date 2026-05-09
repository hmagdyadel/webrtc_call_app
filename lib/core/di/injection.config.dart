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
import 'package:sawa/core/network/dio_client.dart' as _i611;
import 'package:sawa/core/services/presence_service.dart' as _i360;
import 'package:sawa/core/services/push_notification_service.dart' as _i19;
import 'package:sawa/features/auth/data/repositories/auth_repository.dart'
    as _i880;
import 'package:sawa/features/auth/data/sources/auth_remote_source.dart'
    as _i1036;
import 'package:sawa/features/auth/data/sources/user_remote_source.dart'
    as _i1004;
import 'package:sawa/features/auth/viewmodel/auth_cubit.dart' as _i804;
import 'package:sawa/features/chat/data/repositories/chat_repository.dart'
    as _i697;
import 'package:sawa/features/chat/data/sources/chat_remote_source.dart'
    as _i112;
import 'package:sawa/features/chat/viewmodel/chat_cubit.dart' as _i283;
import 'package:sawa/features/chat/viewmodel/message_cubit.dart' as _i161;
import 'package:sawa/features/contacts/data/repositories/contacts_repository.dart'
    as _i765;
import 'package:sawa/features/contacts/data/sources/contacts_remote_source.dart'
    as _i93;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.singleton<_i611.DioClient>(() => _i611.DioClient());
    gh.lazySingleton<_i19.PushNotificationService>(
      () => _i19.PushNotificationService(),
    );
    gh.lazySingleton<_i1004.UserRemoteSource>(
      () => _i1004.UserRemoteSourceImpl(),
    );
    gh.lazySingleton<_i93.ContactsRemoteSource>(
      () => _i93.ContactsRemoteSourceImpl(),
    );
    gh.lazySingleton<_i1036.AuthRemoteSource>(
      () => _i1036.AuthRemoteSourceImpl(),
    );
    gh.lazySingleton<_i112.ChatRemoteSource>(
      () => _i112.ChatRemoteSourceImpl(),
    );
    gh.lazySingleton<_i765.ContactsRepository>(
      () => _i765.ContactsRepositoryImpl(gh<_i93.ContactsRemoteSource>()),
    );
    gh.lazySingleton<_i880.AuthRepository>(
      () => _i880.AuthRepositoryImpl(
        gh<_i1036.AuthRemoteSource>(),
        gh<_i1004.UserRemoteSource>(),
      ),
    );
    gh.lazySingleton<_i697.ChatRepository>(
      () => _i697.ChatRepositoryImpl(gh<_i112.ChatRemoteSource>()),
    );
    gh.lazySingleton<_i804.AuthCubit>(
      () => _i804.AuthCubit(gh<_i880.AuthRepository>()),
    );
    gh.lazySingleton<_i360.PresenceService>(
      () => _i360.PresenceService(gh<_i880.AuthRepository>()),
    );
    gh.factory<_i283.ChatCubit>(
      () => _i283.ChatCubit(gh<_i697.ChatRepository>()),
    );
    gh.factory<_i161.MessageCubit>(
      () => _i161.MessageCubit(gh<_i697.ChatRepository>()),
    );
    return this;
  }
}
