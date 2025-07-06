class EndPoint {
  static const String baseUrl = "https://followsafe.runasp.net/";

  // Supporter endpoints
  static const String addSupporter =
      "https://followsafe.runasp.net/addsupporter/add";
  static const String getSupportersList =
      "https://followsafe.runasp.net/addsupporter/mine";

  // Traveler endpoints
  static const String addTraveler =
      "https://followsafe.runasp.net/addtraveler/add";
  static const String getTravelersList =
      "https://followsafe.runasp.net/addtraveler/mine";

  // Kid Trusted Contacts endpoints - fallback to regular supporter endpoint for now
  static const String kidTrustedContacts =
      "https://followsafe.runasp.net/KidTrustedContacks/kid-add";

  static const String kidSupportersMine =
      "https://followsafe.runasp.net/KidTrustedContacks/kid-mine";

  // TrackingTravelerKid endpoints
  static const String startTrip =
      "https://followsafe.runasp.net/api/TrackingTravelerKid/start-trip";

  static const String updateLocation =
      "https://followsafe.runasp.net/api/TrackingTravelerKid/location";

  static const String endTrip =
      "https://followsafe.runasp.net/api/TrackingTravelerKid/end-trip";

  // Supporter Tracking endpoints
  static const String getActiveTrips =
      "https://followsafe.runasp.net/api/SupporterTracking/active-trips";

  static String getTripLocations(String tripId) =>
      "https://followsafe.runasp.net/api/SupporterTracking/trip-locations/$tripId";

  // Authentication endpoints
  static const String signUp = "/Authentication/register";
  static const String confirmEmail = "/Authentication/confirm-email";
  static const String signIn = "/Authentication/login";
  static const String resendConfirmationEmail =
      "/Authentication/resend-confirmation-email";
  static const String forgotPassword = "/Authentication/forget-password";
  static const String resetPassword = "/Authentication/reset-password";
  static const String adultType = "/Authentication/adult-type";
  static const String checkOtp = "/Authentication/Check_otp";

  // ✅ OTP Endpoints
  static const String sendOtp = "/Authentication/send-otp";
  static const String verifyOtp = "/Authentication/verify-otp";

  static String getUserDataEndPoint(String id) {
    return "/user/get-user/$id";
  }
}

class ApiKey {
  static const String tripId = "TripId";
  static const String latitude = "Latitude";
  static const String longitude = "Longitude";
  static const String success = "success";
  static const String timestamp = "timestamp";
  static const String adultType = "adultType";
  static const String status = "statusCode";
  static const String errorMessage = "ErrorMessage";
  static const String email = "email";
  static const String password = "password";
  static const String token = "token";
  static const String message = "message";
  static const String id = "userId";
  static const String name = "fullname";
  static const String phone = "phone";
  static const String ConfirmNewPassword = "ConfirmNewPassword";
  static const String newpassword = "newpassword";
  static const String location = "location";
  static const String profilePic = "profilePic";
  static const String userType = "userType";

  // ✅ OTP Keys
  static const String userId = "UserId";
  static const String code = "code";
}
