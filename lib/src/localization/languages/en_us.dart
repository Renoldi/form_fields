/// English (US) localization strings for form fields package
library;

const Map<String, String> enUSStrings = {
  // OTP Countdown
  'otpResendPrefix': 'Didn\'t receive activation code? ',
  'otpResendLink': 'Resend',
  'otpResendCountdown': 'Resend in {value} seconds',
  // Common UI
  'cancel': 'Cancel',
  'save': 'Save',
  'submit': 'Submit',
  'clear': 'Clear',
  'selectPrefix': 'Select ',
  'enterPrefix': 'Enter ',
  'searchHint': 'Type to search',
  'clearSearch': 'Clear search',
  'clearSearchTooltip': 'Clear search input',
  // Search validation
  'searchMinChars': 'Please enter at least {n} characters',

  // Validation - Required
  'required': '{label} is required',
  'selectRequired': 'Please select {label}',
  'enterRequired': 'Please enter {label}',

  // Validation - Format
  'enterValidEmail': 'Please enter a valid email address',
  'enterValidPhone': 'Please enter a valid phone number',
  'enterValidInteger': 'Please enter a valid integer for {label}',
  'enterValidNumber': 'Please enter a valid number for {label}',

  // Selection
  'select': 'Please select {label}',
  'selectAtLeastOne': 'Please select at least one {label}',
  'selectAtLeast': 'Please select at least {value} items',
  'selectAtMost': 'Please select at most {value} items',
  'noItemsFound': 'No items found',
  'selectAll': 'Select All',
  'deselectAll': 'Deselect All',
  'itemCount': '{value} items selected',
  // ListData / general UI
  'showMore': 'Show More',
  'refresh': 'Refresh',

  // Checkbox
  'checkboxRequired': 'Please select at least one {label}',
  'selectOptions': 'Select options',
  'cbLabelInBorder': 'Label Hidden (InBorder)',

  // Radio
  'radioRequired': 'Please select {label}',
  'selectOption': 'Select an option',

  // Dropdown
  'dropdownRequired': 'Please select {label}',
  'selectFromList': 'Select from list',

  // Password
  'passwordRequired': 'Password is required',
  'passwordMinLength': 'Password must be at least {value} characters',
  'verificationLength': 'Please enter a {value}-digit verification code',

  // Image / Signature Pad Validation
  'imageRequired': 'Please upload {label}',
  'imageRequiredDefault': 'Please upload an image',
  'signatureRequired': 'Please provide {label}',
  'signatureRequiredDefault': 'Please provide a signature',

  // Signature Pad + Live Camera
  'signatureClear': 'Clear signature',
  'signatureExport': 'Export signature',
  'liveCaptureTitle': 'Live Capture',
  'liveCaptureAutoOnSign': 'auto on sign',
  'noLiveCapture': 'No live capture',
  'cameraInitializing': 'Initializing camera...',
  'cameraNoCamerasFound': 'No cameras found',
  'cameraAvailableTimeout':
      'Camera initialization timed out (no cameras found)',
  'cameraInitializeTimeout': 'Camera failed to initialize in time',
  'cameraReady': 'Ready',
  'cameraCaptured': 'Captured',
  'cameraQueued': 'Queued',
  'cameraUploading': 'Uploading',
  'cameraFailed': 'Failed',
  'permissionRequiredTitle': 'Permission required',
  'permissionCameraContent':
      'This feature requires camera permission. Please enable it in the app settings.',
  'permissionGenericContent':
      'This feature requires permission. Please enable it in the app settings.',
  'openSettings': 'Open Settings',
  'permissionsRequiredShort': 'Permissions are required to use this feature.',
  'requestAgain': 'Request Again',

  // Optional/Labels
  'optional': '(optional)',
  'optionalLabel': '(optional)',
  'notSet': 'Not set',
  'yes': 'Yes',
  'description': 'Description',

  // Upload Result
  'uploadSuccessTitle': 'Upload Success',
  'uploadFailedTitle': 'Upload Failed',
  'uploadErrorTitle': 'Upload Error',
  'uploadSuccessMessage': 'Upload successful!',
  'uploadFailedMessage': 'Upload failed:',
  'uploadErrorMessage': 'Upload error:',
  // Dialog / common labels
  'ok': 'OK',
  'stay': 'Stay',
  'exit': 'Exit',
  'exitApplication': 'Exit Application',
  'exitApplicationMessage':
      'Are you sure you want to close the application? Any unsaved changes may be lost.',
  'loading': 'Loading...',
  'success': 'Success',
  'successMessage': 'Operation completed successfully.',
  'cancelProcessTitle': 'Cancel Process?',
  'cancelProcessMessage':
      'The operation is still in progress. Do you want to cancel it?',
};
