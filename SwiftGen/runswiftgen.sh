#!/bin/bash

SRCSROOT="$1"

echo "SwiftGen processing..."

# Setting initial value of the error flag
SwiftGenFailed=0
echo "SwiftGenFailed=${SwiftGenFailed}" > "${SRCROOT}/SwiftGen-failed.txt"

error_message=$( $SRCSROOT/SwiftGen/vendor/swiftgen config run --config $SRCSROOT/SwiftGen/swiftgen.yml 2>&1)

# saving the script exit status to variable
status=$?

# Check the exit status and exit with an error code if necessary
if [ $status -ne 0 ]; then
  # Use awk to extract all occurrences of the desired substring
  escaped_error_message=$(printf "%s" "$error_message" | sed 's/"/\\"/g')
  error_codes=$(echo "$escaped_error_message" | awk -F 'Code=3840 |UserInfo={NSDebugDescription' '{for (i=2;i<=NF;i+=2) print $i}')
  concatenated=""
  for code in "${error_codes[@]}"
  do
    concatenated+="Error code: $code\n"
  done

  echo "concatenated: $concatenated"

  /usr/bin/osascript -e "set titleText to \"SwiftGen не смог\"
set dialogText to \"Ошибки:\\n$concatenated\\nЕсли текст ошибки непонятен, то стоит посмотреть в лог сборки\"
display dialog dialogText with icon caution with title titleText buttons {\"Закрыть\"} default button \"Закрыть\""

  # Setting actual value of the error flag
  SwiftGenFailed=1
  echo "SwiftGenFailed=${SwiftGenFailed}" > "${SRCROOT}/SwiftGen-failed.txt"

  exit 1
fi

exit 0