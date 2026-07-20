import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/repositories/auth_repository.dart';

// ─── EVENTS ──────────────────────────────────────────────────────────────────
abstract class RegistrationEvent extends Equatable {
  const RegistrationEvent();
  @override
  List<Object?> get props => [];
}

class SubmitCustomerRegistrationEvent extends RegistrationEvent {
  final String name;
  final String phone;
  final String addressDetails; // Combined string or separate
  final double lat;
  final double lng;

  const SubmitCustomerRegistrationEvent({
    required this.name,
    required this.phone,
    required this.addressDetails,
    required this.lat,
    required this.lng,
  });

  @override
  List<Object?> get props => [name, phone, addressDetails, lat, lng];
}

class SubmitShopkeeperRegistrationEvent extends RegistrationEvent {
  final String ownerName;
  final String phone;
  final String cnic;
  final String bankDetails;
  final String shopName;
  final String category;
  final String openingTime;
  final String closingTime;
  final String shopAddress;
  final double lat;
  final double lng;
  final String? cnicFrontPath;
  final String? cnicBackPath;
  final String? shopPhotoPath;

  const SubmitShopkeeperRegistrationEvent({
    required this.ownerName,
    required this.phone,
    required this.cnic,
    required this.bankDetails,
    required this.shopName,
    required this.category,
    required this.openingTime,
    required this.closingTime,
    required this.shopAddress,
    required this.lat,
    required this.lng,
    this.cnicFrontPath,
    this.cnicBackPath,
    this.shopPhotoPath,
  });

  @override
  List<Object?> get props => [
        ownerName,
        phone,
        cnic,
        bankDetails,
        shopName,
        category,
        openingTime,
        closingTime,
        shopAddress,
        lat,
        lng,
        cnicFrontPath,
        cnicBackPath,
        shopPhotoPath,
      ];
}

class SubmitRiderRegistrationEvent extends RegistrationEvent {
  final String fullName;
  final String phone;
  final String cnic;
  final String currentAddress;
  final String emergencyContact;
  final String vehicleType;
  final String vehicleNumber;
  final String bankDetails;
  final String? cnicFrontPath;
  final String? cnicBackPath;
  final String? licensePath;
  final String? selfiePath;

  const SubmitRiderRegistrationEvent({
    required this.fullName,
    required this.phone,
    required this.cnic,
    required this.currentAddress,
    required this.emergencyContact,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.bankDetails,
    this.cnicFrontPath,
    this.cnicBackPath,
    this.licensePath,
    this.selfiePath,
  });

  @override
  List<Object?> get props => [
        fullName,
        phone,
        cnic,
        currentAddress,
        emergencyContact,
        vehicleType,
        vehicleNumber,
        bankDetails,
        cnicFrontPath,
        cnicBackPath,
        licensePath,
        selfiePath,
      ];
}

// ─── STATES ──────────────────────────────────────────────────────────────────
abstract class RegistrationState extends Equatable {
  const RegistrationState();
  @override
  List<Object?> get props => [];
}

class RegistrationInitial extends RegistrationState {}
class RegistrationLoading extends RegistrationState {}
class RegistrationSuccess extends RegistrationState {
  final String message;
  final String redirectRoute;

  const RegistrationSuccess({required this.message, required this.redirectRoute});

  @override
  List<Object?> get props => [message, redirectRoute];
}
class RegistrationFailure extends RegistrationState {
  final String error;
  const RegistrationFailure(this.error);
  @override
  List<Object?> get props => [error];
}

// ─── BLOC ─────────────────────────────────────────────────────────────────────
class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  final AuthRepository authRepository;

  RegistrationBloc({required this.authRepository}) : super(RegistrationInitial()) {
    on<SubmitCustomerRegistrationEvent>(_onSubmitCustomer);
    on<SubmitShopkeeperRegistrationEvent>(_onSubmitShopkeeper);
    on<SubmitRiderRegistrationEvent>(_onSubmitRider);
  }

  Future<void> _onSubmitCustomer(
    SubmitCustomerRegistrationEvent event,
    Emitter<RegistrationState> emit,
  ) async {
    emit(RegistrationLoading());
    try {
      final combinedLocation = "${event.addressDetails} | Coordinates: ${event.lat}, ${event.lng}";
      
      // Hit updateProfile to save customer details
      await authRepository.updateProfile(
        name: event.name,
        phone: event.phone,
        location: combinedLocation,
      );

      emit(const RegistrationSuccess(
        message: 'Profile completed successfully!',
        redirectRoute: '/customer_dashboard',
      ));
    } catch (e) {
      emit(RegistrationFailure(e.toString()));
    }
  }

  Future<void> _onSubmitShopkeeper(
    SubmitShopkeeperRegistrationEvent event,
    Emitter<RegistrationState> emit,
  ) async {
    emit(RegistrationLoading());
    try {
      final combinedMapLocation = "${event.lat},${event.lng}";
      
      // Update owner's name inside users table
      await authRepository.updateProfile(
        name: event.ownerName,
        phone: event.phone,
        location: event.shopAddress,
      );

      // Register the shop details in shops table
      final shopDetails = "${event.ownerName} | Bank: ${event.bankDetails}";
      await authRepository.registerShop(
        shopName: event.shopName,
        shopAddress: event.shopAddress,
        mapLocation: combinedMapLocation,
        cnic: "${event.cnic} | Account: $shopDetails",
        openingTime: event.openingTime,
        closingTime: event.closingTime,
        imageUrl: event.shopPhotoPath ?? '',
      );

      emit(const RegistrationSuccess(
        message: 'Shop registration submitted successfully. Pending Admin approval.',
        redirectRoute: '/pending_approval',
      ));
    } catch (e) {
      emit(RegistrationFailure(e.toString()));
    }
  }

  Future<void> _onSubmitRider(
    SubmitRiderRegistrationEvent event,
    Emitter<RegistrationState> emit,
  ) async {
    emit(RegistrationLoading());
    try {
      // Update rider's name
      await authRepository.updateProfile(
        name: event.fullName,
        phone: event.phone,
        location: event.currentAddress,
      );

      // Register rider details in riders table
      final combinedDetails = "${event.emergencyContact} | Bank: ${event.bankDetails}";
      await authRepository.registerRider(
        vehicleType: event.vehicleType,
        vehicleNumber: event.vehicleNumber,
        cnic: "${event.cnic} | Details: $combinedDetails",
        currentLocation: event.currentAddress,
      );

      emit(const RegistrationSuccess(
        message: 'Rider registration submitted successfully. Pending Admin approval.',
        redirectRoute: '/pending_approval',
      ));
    } catch (e) {
      emit(RegistrationFailure(e.toString()));
    }
  }
}
