/// US English language strings
/// This is the default language for the form_fields package
final Map<String, String> enUSStrings = {
  // Common actions
  'cancel': 'CANCEL',
  'ok': 'OK',
  'done': 'DONE',
  'submit': 'SUBMIT',
  'validate': 'VALIDATE',
  'select': 'Select {label}',
  'selectPrefix': 'Select',

  // Search/Filter
  'searchHint': 'Search...',
  'typeToSearch': 'Type to search {label}...',
  'noResultsFound': 'No results found',

  // Field types & labels
  'fieldTypeString': 'text',
  'fieldTypeEmail': 'email',
  'fieldTypePhone': 'phone',
  'fieldTypePassword': 'password',
  'fieldTypeNumber': 'number',
  'fieldTypeInteger': 'integer',
  'fieldTypeDate': 'date',
  'fieldTypeTime': 'time',
  'fieldTypeDateRange': 'date range',

  // Validation messages - Required & General
  'required': '{label} is required',
  'enterPrefix': 'Enter ',
  'enter': 'Enter {label}',
  'enterValid': 'Enter valid {type} for {label}',

  // Email validation
  'enterValidEmail': 'Enter a valid email address',
  'emailRequired': 'Email address is required',

  // Phone validation
  'enterValidPhone': 'Enter valid phone number',
  'phoneRequired': 'Phone number is required',

  // Integer validation
  'enterValidInteger': 'Enter valid integer for {label}',
  'integerRequired': 'Integer is required',

  // Number/Decimal validation
  'enterValidNumber': 'Enter valid number for {label}',
  'numberRequired': 'Number is required',

  // Password validation
  'passwordRequired': 'Password is required',
  'passwordMinLength': 'Password must be at least {value} characters',
  'passwordTooShort': 'Password must be {value}+ characters',
  'passwordNeedsUppercase': 'Must contain uppercase letter',
  'passwordNeedsLowercase': 'Must contain lowercase letter',
  'passwordNeedsNumber': 'Must contain a number',
  'passwordNeedsSpecialChar': 'Must contain special character',

  // Length validation
  'tooShort': '{label} is too short (minimum {value} characters)',
  'tooLong': '{label} is too long (maximum {value} characters)',

  // Range validation
  'minimumValue': '{label} must be at least {value}',
  'maximumValue': '{label} must be at most {value}',
  'betweenValue': '{label} must be between {min} and {max}',

  // Pattern/Format validation
  'invalid': '{label} is invalid',
  'invalidFormat': 'Invalid format for {label}',

  // Selection/Dropdown validation
  'selectAtLeastOne': 'Select at least one {label}',
  'selectAtLeast': 'Select at least {value} items',
  'selectAtMost': 'Select at most {value} items',
  'selectExactly': 'Select exactly {value} items',

  // Date/Time validation
  'selectDate': 'Select date',
  'selectTime': 'Select time',
  'selectDateRange': 'Select date range',
  'dateRequired': 'Date is required',
  'timeRequired': 'Time is required',

  // Hints & Instructions
  'selectFromList': 'Select from list',
  'selectMultiple': 'Select multiple items',
  'typeHere': 'Type here...',

  // Accessibility & UI
  'selectedItems': '{value} items selected',
  'noItemsSelected': 'No items selected',
  'tapToSelect': 'Tap to select',
  'tapToEdit': 'Tap to edit',
  'tapToRemove': 'Tap to remove',
  'clear': 'Clear',
  'clearAll': 'Clear all',

  // Messages
  'success': 'Success',
  'error': 'Error',
  'warning': 'Warning',
  'info': 'Information',
  'validationFailed': 'Validation failed',
  'formSubmitted': 'Form submitted successfully',
};
