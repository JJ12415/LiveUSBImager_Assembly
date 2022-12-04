section .text

; Define the main function
global main

main:
  ; Check the number of command-line arguments
  cmp dword [esp + 4], 3
  jne usage

  ; Parse the ISO file and USB device from the command-line arguments
  mov ebx, [esp + 8]
  mov ecx, [esp + 12]

  ; Check that the ISO file exists and is readable
  push ebx
  call checkFile
  add esp, 4
  test eax, eax
  jz error

  ; Check that the USB device exists and is writable
  push ecx
  call checkFile
  add esp, 4
  test eax, eax
  jz error

  ; Open the ISO file and USB device
  push ecx
  push ebx
  call copyFile
  add esp, 8
  test eax, eax
  jz error

  ; Print success message
  push success
  call printf
  add esp, 4

  ; Return 0 to indicate success
  mov eax, 0
  ret

usage:
  ; Print usage message and return 1 to indicate error
  push usage
  call printf
  add esp, 4
  mov eax, 1
  ret

error:
  ; Print error message and return 1
  push error
  call printf
  add esp, 4
  mov eax, 1
  ret
  
section .data

; Define the usage and success messages
usage db "Usage: LiveUSBImager [iso file] [usb device]", 0
success db "Live USB creation successful!", 0

section .text

; Check whether a file exists and is readable or writable
checkFile:
  ; Push the error code and file name onto the stack
  push ebx
  push 0

  ; Open the file in read-only or write-only mode, depending on the mode flag
  cmp byte [esp + 8], 1
  je readOnly
  jmp writeOnly

readOnly:
  push 0
  push ebx
  call fopen
  jmp checkDone

writeOnly:
  push 1
  push ebx
  call fopen
  jmp checkDone

checkDone:
  ; Check the result of fopen and set the return value accordingly
  test eax, eax
  setne al
  movzx eax, al

  ; Pop the error code and file name from the stack
  add esp, 8

  ; Return the result
  ret

; Copy the contents of one file to another
copyFile:
  ; Push the error code and file names onto the stack
  push ebx
  push ecx
  push 0

  ; Open the source and destination files in read-only and write-only mode, respectively
  push 0
  push ebx
  call fopen
  push 1
  push ecx
  call fopen

  ; Check the result of fopen and set the return value accordingly
  test eax, eax
  setne al
  movzx eax, al
  jz copyError

  ; Allocate a buffer to hold the contents of the source file
  push bufferSize
  call malloc

  ; Read from the source file and write to the destination file
  .loop:
    push eax
    push ebx
    call fread
    add esp, 8
    push ecx
    push eax
    call fwrite
    add esp, 8

    ; Check the result of fread and break out of the loop if it is 0
    cmp dword [esp - 4], 0
    je .done
    jmp .loop

  .done:
    ; Free the buffer
    add esp, 4
    call free

    ; Close the files
    push ecx
    call fclose
    add esp, 4
    push ebx
    call fclose

    ; Set the return value to 1 to indicate success
    mov eax, 1
	ret