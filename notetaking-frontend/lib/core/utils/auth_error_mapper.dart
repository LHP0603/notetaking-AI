String getErrorMessage(String serverMessage) {
  switch (serverMessage) {
    case 'USER_REGISTERED_SUCCESS':
      return 'Registration successful! Please login.';
    case 'LOGIN_SUCCESS':
      return 'Welcome back!';
    case 'TOKEN_REFRESHED_SUCCESS':
      return 'Session refreshed';
    case 'USER_ALREADY_EXISTS':
      return 'This email is already registered';
    case 'INVALID_CREDENTIALS':
      return 'Invalid email or password';
    case 'TOKEN_EXPIRED':
      return 'Session expired. Please login again.';
    case 'INVALID_TOKEN':
      return 'Invalid session. Please login again.';
    default:
      return 'An error occurred. Please try again.';
  }
}
