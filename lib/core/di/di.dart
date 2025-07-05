import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:pro/core/API/dio_consumer.dart';
import 'package:pro/core/API/api_consumer.dart';
import 'package:pro/cubit/activeTrip/active_trips_cubit.dart';
import 'package:pro/cubit/add-supporter-cubit/add_supporter_cubit.dart';
import 'package:pro/cubit/adult-type-cubit/adult_type_cubit.dart';
import 'package:pro/cubit/end-trip/end_trip_cubit.dart';
import 'package:pro/cubit/forgetCubit/forget_password_cubit.dart';
import 'package:pro/cubit/otp/otp_cubit.dart';
import 'package:pro/cubit/otp_check/otp_check_cubit.dart';
import 'package:pro/cubit/resetpassCubit/reset_password_cubit.dart';
import 'package:pro/cubit/kid_supporter_cubit.dart';
import 'package:pro/cubit/sos/sos_cubit.dart';
import 'package:pro/cubit/startTrip/start_trip_cubit.dart';
import 'package:pro/cubit/traveler/traveler_cubit.dart';
import 'package:pro/cubit/tripLocation/trip_location_cubit.dart';
import 'package:pro/cubit/updateLocation/updatelocation_cubit.dart';
import 'package:pro/repo/KidSupporterRepository.dart';
import 'package:pro/repo/SosRepository.dart';
import 'package:pro/repo/end_trip_repo.dart';
import 'package:pro/repo/start_trip_repo.dart';
import 'package:pro/repo/supporter_tracking_repo.dart';
import 'package:pro/repo/update_location_repo.dart';
import 'package:pro/services/app_timer_service.dart';

import 'package:pro/repo/SupporterRepository.dart';
import 'package:pro/repo/TravelerRepository.dart';
import 'package:pro/repo/adult_type_repository.dart';
import 'package:pro/repo/forgetrepo.dart';
import 'package:pro/repo/otp_check_repo.dart';
import 'package:pro/repo/otp_repo.dart';
import 'package:pro/repo/reset_password_repo.dart';
import 'package:pro/services/notification_service.dart';
import 'package:pro/services/signalr_service.dart';
import 'package:pro/services/offline_database_service.dart';
import 'package:pro/services/offline_sync_service.dart';
import 'package:pro/cubit/offline_sync/offline_sync_cubit.dart';

final GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  // Register Dio
  getIt.registerLazySingleton<Dio>(() => Dio());

  // Register DioConsumer
  getIt
      .registerLazySingleton<DioConsumer>(() => DioConsumer(dio: getIt<Dio>()));

  // Register ApiConsumer (alias for DioConsumer)
  getIt.registerLazySingleton<ApiConsumer>(() => getIt<DioConsumer>());

  // // Register UserRepository
  // getIt.registerLazySingleton<UserRepository>(
  //     () => UserRepository(api: getIt<DioConsumer>()));

  // // Register UserCubit
  // getIt.registerFactory<UserCubit>(() => UserCubit(getIt<UserRepository>()));

  // // Register CacheHelper
  // getIt.registerLazySingleton<CacheHelper>(() => CacheHelper());

  // Register OtpRepository
  getIt.registerLazySingleton<OtpRepository>(
      () => OtpRepository(api: getIt<DioConsumer>()));

  // Register OtpCubit
  getIt.registerFactory<OtpCubit>(() => OtpCubit(getIt<OtpRepository>()));

  // forget
  getIt.registerLazySingleton<ForgetRepo>(
      () => ForgetRepo(api: getIt<DioConsumer>()));

  getIt.registerFactory<ForgetPasswordCubit>(
      () => ForgetPasswordCubit(getIt<ForgetRepo>()));

  getIt.registerLazySingleton<OtpCheckRepository>(
      () => OtpCheckRepository(api: getIt<DioConsumer>()));

  // Register OtpCubit
  getIt.registerFactory<OtpCheckCubit>(
      () => OtpCheckCubit(getIt<OtpCheckRepository>()));

  getIt.registerLazySingleton<ResetPasswordRepository>(
      () => ResetPasswordRepository(api: getIt<DioConsumer>()));

  getIt.registerFactory<ResetPasswordCubit>(
      () => ResetPasswordCubit(getIt<ResetPasswordRepository>()));

  // Register AdultTypeRepository
  getIt.registerLazySingleton<AdultTypeRepository>(() => AdultTypeRepository());

  // Register AdultTypeCubit
  getIt.registerFactory<AdultTypeCubit>(
      () => AdultTypeCubit(getIt<AdultTypeRepository>()));

  // Register SupporterRepository
  getIt.registerLazySingleton<SupporterRepository>(
    () => SupporterRepository(api: getIt<DioConsumer>()),
  );

  // Register AddSupporterCubit
  getIt.registerFactory<AddSupporterCubit>(
    () => AddSupporterCubit(getIt<SupporterRepository>()),
  );

  // Register TravelerRepository
  getIt.registerLazySingleton<TravelerRepository>(
    () => TravelerRepository(api: getIt<DioConsumer>()),
  );

  // Register TravelerCubit
  getIt.registerFactory<TravelerCubit>(
    () => TravelerCubit(travelerRepository: getIt<TravelerRepository>()),
  );

  // Register KidSupporterRepository
  getIt.registerLazySingleton<KidSupporterRepository>(
    () => KidSupporterRepository(api: getIt<DioConsumer>()),
  );

  // Register KidSupporterCubit
  getIt.registerFactory<KidSupporterCubit>(
    () => KidSupporterCubit(getIt<KidSupporterRepository>()),
  );

  // Register SignalR Service
  getIt.registerLazySingleton<SignalRService>(() => SignalRService.instance);

  // Register Notification Service
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());

  // Register SOS Repository
  getIt.registerLazySingleton<SosRepository>(() => SosRepository(
        api: getIt<DioConsumer>(),
        signalRService: getIt<SignalRService>(),
      ));

  // Register SOS Cubit
  getIt.registerFactory<SosCubit>(() => SosCubit(
        sosRepository: getIt<SosRepository>(),
      ));

  // Register App Timer Service
  getIt.registerLazySingleton<AppTimerService>(() => AppTimerService());

  // Register TrackingTravelerKidRepository
  getIt.registerLazySingleton<StartTripRepository>(
    () => StartTripRepository(api: getIt<DioConsumer>()),
  );

  // Register StartTripCubit
  getIt.registerFactory<StartTripCubit>(
    () => StartTripCubit(getIt<StartTripRepository>()),
  );
// Update Location
  getIt.registerLazySingleton<UpdateLocationRepository>(
    () => UpdateLocationRepository(api: getIt<DioConsumer>()),
  );
  getIt.registerFactory<UpdateLocationCubit>(
    () => UpdateLocationCubit(getIt<UpdateLocationRepository>()),
  );

  // End Trip
  getIt.registerLazySingleton<EndTripRepository>(
    () => EndTripRepository(api: getIt<DioConsumer>()),
  );
  getIt.registerFactory<EndTripCubit>(
    () => EndTripCubit(getIt<EndTripRepository>()),
  );
  // Register SupporterTrackingRepository
  getIt.registerLazySingleton<SupporterTrackingRepository>(
    () => SupporterTrackingRepository(getIt<DioConsumer>()),
  );
// Register ActiveTripsCubit
  getIt.registerFactory<ActiveTripsCubit>(
    () => ActiveTripsCubit(getIt<SupporterTrackingRepository>()),
  );
  // Register TripLocationCubit
  getIt.registerFactory<TripLocationCubit>(
    () => TripLocationCubit(getIt<SupporterTrackingRepository>()),
  );

  // Register Offline Database Service
  getIt.registerLazySingleton<OfflineDatabaseService>(
      () => OfflineDatabaseService());

  // Register Offline Sync Service
  getIt.registerLazySingleton<OfflineSyncService>(() => OfflineSyncService());

  // Register Offline Sync Cubit
  getIt.registerFactory<OfflineSyncCubit>(() => OfflineSyncCubit());
}
