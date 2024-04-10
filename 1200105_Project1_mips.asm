.data

filename: .asciiz "testResults.txt"
openFlags: .word 0x0001       # Flag for write and create
mode: .word 0x01B6            # Mode for file permissions (0644)


promptID: .asciiz "Enter Patient ID (7 digits): "
idBuffer: .space 11 # Buffer for ID, assuming max 10 chars + null terminator

promptTestName: .asciiz "\nEnter Test Name: "
testName: .space 7 # Space for the name

promptTestDate: .asciiz "\nEnter Test Date (YYYY-MM): "
testDate: .space 9  # Space for "YYYY-MM" + null terminator

promptTestResult: .asciiz "\nEnter Test Result (as a floating-point number): "
.align 3  # Align the next data declaration on a doubleword boundary
floatBuffer: .space 8  # Reserve 8 bytes for storing a double-precision float


msgValid: .asciiz "\nValid ID.\n"
msgInvalid: .asciiz "\nInvalid ID. Must be exactly 7 digits.\n"


menu: .asciiz "\n--- Medical Test System Menu ---\n1. Add a new medical test\n2. Search for a test by patient ID\n3. Retrieve all up normal patient tests\n4. Retrieve all patient tests in a given specific period\n5. Search for unnormal tests\n6. Average test value\n7. Update an existing test result\n8. Delete a test\n9. Exit\nSelect an option: "
invalidOption: .asciiz "Invalid option. Please try again.\n"
prompt: .asciiz "Your choice: "


menuTestNames: .asciiz "\n Select a Medical Test by entering the corresponding number:\n 1. Hemoglobin (Hgb)\n 2. Blood Glucose Test (BGT)\n 3. LDL Cholesterol (LDL)\n 4. Blood Pressure Test (BPT)\n Enter your choice: "

promptInvalid: .asciiz "Invalid choice. Please try again.\n"

hemoglobin: .asciiz "Hgb"
blood_glucose_test: .asciiz "BGT"
ldl_cholesterol: .asciiz "LDL"
blood_pressure_test: .asciiz "BPT"



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

#-----------------------------------Selecting the test name--------------------------------    

test_name:

    #promt
    li $v0, 4
    la $a0, menuTestNames
    syscall

    # Read user's choice
    li $v0, 5
    syscall
    move $t0, $v0  # Move user's choice into $t0

    # Compare user's choice and jump to the corresponding procedure

    li $t1, 1
    beq $t0, $t1, hemoglobin_label

    li $t1, 2
    beq $t0, $t1, blood_glucose_test_label

    li $t1, 3
    beq $t0, $t1, ldl_cholesterol_label

    li $t1, 4
    beq $t0, $t1, blood_pressure_test_label

    # If invalid option, show error and go back to menu
    li $v0, 4
    la $a0, promptInvalid
    syscall
    j test_name

    # now save the test choises in in testName buffer



    hemoglobin_label:
                la $a0, testName     # Load the address of testName buffer
                la $a1, hemoglobin    # Load the address of "Hgb" string
                jal copy_loop        # Copy the "Hgb" string to the testName buffer
                j test_date          # Jump to the next step

    
    blood_glucose_test_label:
                la $a0, testName     # Load the address of testName buffer
                la $a1, blood_glucose_test    # Load the address of "BGT" string
                jal copy_loop        # Copy the "BGT" string to the testName buffer
                j test_date          # Jump to the next step


    ldl_cholesterol_label: 
                la $a0, testName     # Load the address of testName buffer
                la $a1, ldl_cholesterol    # Load the address of "LDL" string
                jal copy_loop        # Copy the "LDL" string to the testName buffer
                j test_date          # Jump to the next step

    blood_pressure_test_label:
                la $a0, testName     # Load the address of testName buffer
                la $a1, blood_pressure_test    # Load the address of "BPT" string
                jal copy_loop        # Copy the "BPT" string to the testName buffer
                j test_date          # Jump to the next step


                     


#-----------------------------------End of Selecting the test name--------------------------------


test_date:
    
    # Prompt and Read Test Date
    li $v0, 4
    la $a0, promptTestDate
    syscall

    li $v0, 8
    la $a0, testDate
    li $a1, 9
    syscall


    # Prompt the user for input
    li $v0, 4                  # Syscall for print string
    la $a0, promptTestResult             # Address of prompt string
    syscall


    li $v0, 8                  # Syscall code for reading a string
    la $a0, floatBuffer       # Address of buffer to store the string
    li $a1, 8                 # The maximum number of characters to read
    syscall

#----------------------------------- writing the information to the file--------------------------------


 # Replace newline with colon in testDate if present
    la $a0, idBuffer
    jal replace_newline_with_colon

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
    li $a2, 7             # Example length, adjust as needed
    syscall

    # Replace newline with comma in testDate if present
    la $a0, testDate
    jal replace_newline_with_comma

    # Write Test Date
    li $v0, 15
    move $a0, $s7
    la $a1, testDate
    li $a2, 9                  # Example length, adjust as needed
    syscall

    # Replace newline with space in floatBuffer if present

    la $a0, floatBuffer
    jal replace_newline_with_space

    # Write Test Result to the file
    li $v0, 15                 # Syscall for write to file
    move $a0, $s7             
    la $a1, floatBuffer      
    li $a2, 8 
    syscall


    # Write newline to the file
    li $v0, 15
    move $a0, $s7
    la $a1, newline
    li $a2, 1
    syscall


#-----------------------------------End of writing the information to the file--------------------------------


    # Return to the menu
    j menu_loop

  


#------------------------------------Getting information from the user----------------------------  

search_test: 





   




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
    lb $t0, 0($a0)                # Load the current byte from the buffer into $t0
    beq $t0, $zero, end_replacement  # If we've hit the null terminator, exit the loop
    
    li $t1, 0x0A                  # ASCII value of '\n'
    li $t3, 0x20                  # ASCII value of space ' '
    bne $t0, $t1, check_space     # If the current byte is not '\n', check for space

    # If we've found a newline character, replace it with a comma
    li $t2, 0x2C                  # ASCII value of ','
    sb $t2, 0($a0)                # Store the comma in place of the newline character
    j next_char                   # Proceed to the next character

check_space:
    bne $t0, $t3, next_char       # If the current byte is not space, go to the next character
    
    # Here, we found a space and want to "remove" it by shifting subsequent characters left.
    # This loop will start from the current space character's position.
shift_loop:
    lb $t4, 1($a0)                # Load the next byte into $t4
    sb $t4, 0($a0)                # Overwrite the current byte with the next byte
    beqz $t4, end_replacement     # If we've hit a null terminator during shifting, we're done
    addiu $a0, $a0, 1             # Move to the next character in the buffer
    j shift_loop                  # Continue shifting until we hit a null terminator

next_char:
    addiu $a0, $a0, 1             # Move to the next character in the buffer
    j replace_newline_with_comma  # Repeat the loop

end_replacement:
    jr $ra                        # Return from the function




replace_newline_with_space:
    lb $t0, 0($a0)            # Load the current byte from the buffer into $t0

loop2:
    beq $t0, $zero, end2       # If we've hit the null terminator, exit the loop
    li $t1, 0x0A              # ASCII value of '\n'
    bne $t0, $t1, check_next2  # If the current byte is not '\n', go to the next character
    
    # If we've found a newline character, replace it with a space
    li $t2, 0x20              # ASCII value of space ' '
    sb $t2, 0($a0)            # Store the space in place of the newline character

check_next2:
    addiu $a0, $a0, 1         # Move to the next character in the buffer
    lb $t0, 0($a0)            # Load the next byte from the buffer into $t0
    j loop2                    # Repeat the loop

end2:
    jr $ra                    # Return from the function


replace_newline_with_colon:
    lb $t0, 0($a0)            # Load the current byte from the buffer into $t0

loop3:
    beq $t0, $zero, end3       # If we've hit the null terminator, exit the loop
    li $t1, 0x0A              # ASCII value of '\n'
    bne $t0, $t1, check_next3  # If the current byte is not '\n', go to the next character
    
    # If we've found a newline character, replace it with a colon
    li $t2, 0x3A              # ASCII value of ':'
    sb $t2, 0($a0)            # Store the colon in place of the newline character

check_next3:
    addiu $a0, $a0, 1         # Move to the next character in the buffer
    lb $t0, 0($a0)            # Load the next byte from the buffer into $t0
    j loop3                    # Repeat the loop

end3:
    jr $ra                    # Return from the function


copy_loop:
    lb $t0, 0($a1)       # Load byte from source string
    sb $t0, 0($a0)       # Store byte in destination buffer
    beqz $t0, add_newline # If null terminator, prepare to add newline
    addiu $a0, $a0, 1    # Increment destination address
    addiu $a1, $a1, 1    # Increment source address
    j copy_loop          # Jump back to start of loop

add_newline:
    li $t1, 0x0A        # Load ASCII value of '\n'
    sb $t1, 0($a0)      # Store newline character at the end
    addiu $a0, $a0, 1   # Increment destination address
    sb $zero, 0($a0)    # Add null terminator after the newline

    jr $ra              # Return from function
    
#---------------------------------------Functions area--------------------------------------------        

end:
    # Exit program
    li $v0, 10
    syscall
