.data

filename: .asciiz "testResults.txt"
openFlags: .word 0x0001       # Flag for write and create
mode: .word 0x01B6            # Mode for file permissions (0644)


promptID: .asciiz "Enter Patient ID (7 digits): "
idBuffer: .space 11 # Buffer for ID, assuming max 10 chars + null terminator

promptTestName: .asciiz "\nEnter Test Name: "
testName: .space 5 # Space for the name

promptTestDate: .asciiz "\nEnter Test Date (YYYY-MM): "
testDate: .space 8  # Space for "YYYY-MM" + null terminator

promptTestResult: .asciiz "\nEnter Test Result (as a floating-point number): "
.align 3  # Align the next data declaration on a doubleword boundary
floatBuffer: .space 8  # Reserve 8 bytes for storing a double-precision float


msgValid: .asciiz "\nValid ID.\n"
msgInvalid: .asciiz "\nInvalid ID. Must be exactly 7 digits.\n"


menu: .asciiz "\n--- Medical Test System Menu ---\n1. Add a new medical test\n2. Search for a test by patient ID\n3. Retrieve all up normal patient tests\n4. Retrieve all patient tests in a given specific period\n5. Search for unnormal tests\n6. Average test value\n7. Update an existing test result\n8. Delete a test\n9. Exit\nSelect an option: "
invalidOption: .asciiz "Invalid option. Please try again.\n"
prompt: .asciiz "Your choice: "


completeRecord: .space 100  # Adjust based on your needs
delimiter: .asciiz ", "
newline: .asciiz "\n"

.text
.globl main

main:


#----------------------------------------Opening the file for writing----------------------------------------

# Open the file for writing
    li $v0, 13                 # Syscall: open file
    la $a0, filename           # Filename: pointer to "testResults.txt"
    lw  $a1, openFlags          # Flags: write and create
    lw  $a2, mode               # Mode: file permissions
    syscall
    move $s7, $v0              # Save the file descriptor to $s7
  

#---------------------------------------- End of Opening the file for writing--------------------------------




#----------------------------------------Menu--------------------------------     

menu_loop:

    # Display menu
    li $v0, 4
    la $a0, menu
    syscall

    # Read user's choice
    li $v0, 5
    syscall
    move $t0, $v0  # Move user's choice into $t0

    # Compare user's choice and jump to the corresponding procedure
    li $t1, 1
    beq $t0, $t1, add_test
    
    li $t1, 2
    beq $t0, $t1, search_test

    li $t1, 3
    beq $t0, $t1, retrieve_all_up_normal_tests
    
    li $t1, 4
    beq $t0, $t1, retrieve_all_tests_in_period

    li $t1, 5
    beq $t0, $t1, search_unnormal_tests

    li $t1, 6
    beq $t0, $t1, average_test_value

    li $t1, 7
    beq $t0, $t1, update_existing_test_result

    li $t1, 8
    beq $t0, $t1, delete_test

   # Process user's choice
    li $t1, 9  # Exit option number
    beq $t0, $t1, exit_program  # If user chooses to exit

    # If invalid option, show error and go back to menu
    li $v0, 4
    la $a0, invalidOption
    syscall
    j menu_loop


exit_program:
    # Exit the program
    li $v0, 10
    syscall

#----------------------------------------Getting information from the user (Add test) --------------------------------

add_test:

    # Prompt for Patient ID
    li $v0, 4
    la $a0, promptID
    syscall

    # Read Patient ID as a string
    li $v0, 8
    la $a0, idBuffer
    li $a1, 11 # Max length to read
    syscall
    
    
      # Validate Patient ID
    la $a0, idBuffer # Load address of the ID buffer
    jal validatePatientID # Jump to the validation function

    # Check if ID is valid (result returned in $v0, 1 = valid, 0 = invalid)
    li $t1, 1
    beq $v0, $t1, validID
    j invalidID
    
    finish_check: 
    
    
    #Read test name 
   
    #promt
    li $v0, 4
    la $a0, promptTestName
    syscall

    #read	 	
    li $v0, 8
    la $a0, testName
    li $a1, 5
    syscall
    
    # Prompt and Read Test Date
    li $v0, 4
    la $a0, promptTestDate
    syscall

    li $v0, 8
    la $a0, testDate
    li $a1, 8  
    syscall
    
    # Prompt the user for input
    li $v0, 4                  # Syscall for print string
    la $a0, promptTestResult             # Address of prompt string
    syscall


    # Read double-precision floating-point number
    li $v0, 7  # Syscall code for reading double-precision float
    syscall  # Read value is now in $f0 and $f1

    # Store the double-precision value into the buffer
    la $t0, floatBuffer   # Load address of buffer
    sdc1 $f0, 0($t0)  # Store double-precision value from $f0-$f1 into buffer


 # Replace newline with comma in idBuffer if present
    la $a0, idBuffer
    jal replace_newline_with_comma

    # Write Patient ID to the file
    li $v0, 15
    move $a0, $s7
    la $a1, idBuffer
    li $a2, 11                 # Example length, adjust based on actual content length
    syscall

    # Replace newline with comma in testName if present
    la $a0, testName
    jal replace_newline_with_comma

    # Write Test Name
    li $v0, 15
    move $a0, $s7
    la $a1, testName
    li $a2, 5               # Example length, adjust as needed
    syscall

    # Replace newline with comma in testDate if present
    la $a0, testDate
    jal replace_newline_with_comma

    # Write Test Date
    li $v0, 15
    move $a0, $s7
    la $a1, testDate
    li $a2, 8                  # Example length, adjust as needed
    syscall

    # Optionally, handle the floating-point result here, if conversion to string is managed

    # Write a newline to finish this record
    li $v0, 15
    move $a0, $s7
    la $a1, newline
    li $a2, 1
    syscall

    # Return to the menu
    j menu_loop

  


#------------------------------------Getting information from the user----------------------------  

search_test: 

    # Prompt for Patient ID
    li $v0, 4
    la $a0, promptID
    syscall

    # Read Patient ID as a string
    li $v0, 8
    la $a0, idBuffer
    li $a1, 11 # Max length to read
    syscall
    
    
      # Validate Patient ID
    la $a0, idBuffer # Load address of the ID buffer
    jal validatePatientID # Jump to the validation function

    # Check if ID is valid (result returned in $v0, 1 = valid, 0 = invalid)
    li $t1, 1
    beq $v0, $t1, validID
    j invalidID





retrieve_all_up_normal_tests:
    j menu_loop


retrieve_all_tests_in_period:
    j  menu_loop


search_unnormal_tests:
    j menu_loop


average_test_value:
    j menu_loop


update_existing_test_result:
    j menu_loop


delete_test:
    j menu_loop







    
#---------------------------------------Functions area--------------------------------------------
validID:
    li $v0, 4
    la $a0, msgValid
    syscall
    j finish_check

invalidID:
    li $v0, 4
    la $a0, msgInvalid
    syscall
    j finish_check

validatePatientID:
    li $t0, 0 # Counter for digits
    loop:
        lb $t1, 0($a0) # Load byte (character) from buffer
        
	beq $t1, 10, checkLength # If end of string (\n), go to checkLength
        # Check if the character is a digit
        li $t2, 48 # ASCII '0'
        li $t3, 57 # ASCII '9'
        
        blt $t1, $t2, invalid # Less than '0'
        bgt $t1, $t3, invalid # Greater than '9'
        
        addi $t0, $t0, 1 # Increment counter
        addi $a0, $a0, 1 # Move to the next character
        j loop
    
    checkLength:
        li $t1, 7
        bne $t0, $t1, invalid # If counter != 7, invalid
        li $v0, 1 # Set return value to valid
        jr $ra

    invalid:
        li $v0, 0 # Set return value to invalid
        jr $ra

replace_newline_with_comma:
    lb $t0, 0($a0)            # Load the current byte from the buffer into $t0
    beq $t0, $zero, end_replacement  # If we've hit the null terminator, exit the loop
    
    li $t1, 0x0A              # ASCII value of '\n'
    li $t3, 0x20              # ASCII value of space ' '
    bne $t0, $t1, check_space # If the current byte is not '\n', check for space

    # If we've found a newline character, replace it with a comma
    li $t2, 0x2C              # ASCII value of ','
    sb $t2, 0($a0)            # Store the comma in place of the newline character
    j next_char               # Proceed to the next character

check_space:
    bne $t0, $t3, next_char   # If the current byte is not space, go to the next character

    # If we've found a space character, we effectively "remove" it by shifting
    # all subsequent characters one position to the left
    add $a1, $a0, 1           # $a1 points to the next character in the buffer
shift_loop:
    lb $t4, 0($a1)            # Load the next byte into $t4
    sb $t4, 0($a0)            # Overwrite the current byte with the next byte
    beqz $t4, end_replacement # If we've hit the null terminator, we're done
    addiu $a0, $a0, 1         # Move to the next character in the buffer
    addiu $a1, $a1, 1         # $a1 also moves to its next character
    j shift_loop              # Continue shifting

next_char:
    addiu $a0, $a0, 1         # Move to the next character in the buffer
    j replace_newline_with_comma  # Repeat the loop

end_replacement:
    jr $ra                    # Return from the function   

#---------------------------------------Functions area--------------------------------------------        

end:
    # Exit program
    li $v0, 10
    syscall
